from collections import Counter
from pyuvm import ConfigDB, uvm_subscriber


class PriorityVipScoreboard(uvm_subscriber):
    """Passive multiset oracle, driven exclusively by sampled DUT pins."""
    def build_phase(self):
        self.cfg = ConfigDB().get(self, "", "priority_vip_cfg")
        self.items = []
        self.pending = None
        self.occupancy = 0
        self.completed = self.accepted = self.aborted = 0
        self.stalled = None
        self.coverage = Counter()
        self.age = 0
        self.reset_seen = False

    def flags(self, sample):
        assert sample["count"] == self.occupancy, (sample["count"], self.occupancy)
        assert sample["full"] == (self.occupancy == self.cfg.depth)
        assert sample["empty"] == (self.occupancy == 0)

    def write(self, event):
        pre, post = event
        if pre["rst"]:
            self.reset_seen = True
            self.aborted += self.pending is not None
            self.items.clear()
            self.pending = None
            self.stalled = None
            self.occupancy = 0
            self.flags(post)
            assert not post["req_ready"] and not post["rsp_valid"]
            assert (post["rsp_error"], post["rsp_priority"], post["rsp_data"]) == (0, 0, 0)
            return
        assert self.reset_seen, "Observe reset before traffic"
        self.flags(pre)
        response = (pre["rsp_error"], pre["rsp_priority"], pre["rsp_data"])
        if self.stalled is not None:
            assert pre["rsp_valid"] and response == self.stalled, "Response changed while stalled"
        self.stalled = response if pre["rsp_valid"] and not pre["rsp_ready"] else None
        if pre["rsp_valid"]:
            assert self.pending is not None and not pre["req_ready"], "Unsolicited response / ready while busy"
            p = self.pending
            if not p["checked"]:
                assert response[0] == p["error"], (response, p)
                if p["error"] or p["op"] == 0:
                    assert response[1:] == (0, 0), "Nonzero acknowledgement"
                else:
                    pair = response[1:]
                    assert pair[0] == p["best"] and pair in self.items, (pair, self.items)
                    if p["op"] == 1:
                        self.items.remove(pair)
                p["checked"] = True
            if pre["rsp_ready"]:
                self.completed += 1
                self.pending = None
            else:
                self.coverage["stalled_cycles"] += 1
        if pre["req_valid"] and pre["req_ready"]:
            assert self.pending is None and not pre["rsp_valid"], "Overlapping commands"
            op = pre["req_op"]
            error = op == 3 or (op == 0 and self.occupancy == self.cfg.depth) or (op in (1, 2) and not self.occupancy)
            best = (min if self.cfg.min_first else max)(p for p, _ in self.items) if self.items else None
            self.pending = dict(op=op, error=error, best=best, checked=False)
            self.age = 0
            self.accepted += 1
            self.coverage[f"op_{op}"] += 1
            self.coverage[f"error_{op}"] += int(error)
            if not error and op == 0:
                self.items.append((pre["req_priority"], pre["req_data"]))
                self.occupancy += 1
            elif not error and op == 1:
                self.occupancy -= 1
        if self.pending is not None:
            assert not post["req_ready"], "Ready before command completion"
            self.age += 1
            if not self.pending["checked"]:
                assert self.age <= self.cfg.depth.bit_length() + 3, "Heap response timed out"
        else:
            assert post["req_ready"] and not post["rsp_valid"], "Not idle after completion"
        self.flags(post)

    def check_phase(self):
        assert self.reset_seen and self.completed > 0, "No verified transactions"
        assert self.pending is None, "Unfinished command"
        assert self.accepted == self.completed + self.aborted

    def report_phase(self):
        self.logger.info("PRIORITY VIP PASSED: %d responses, %d reset aborts; coverage=%s",
                         self.completed, self.aborted, dict(self.coverage))
