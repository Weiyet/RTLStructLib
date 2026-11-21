from pyuvm import ConfigDB, uvm_subscriber


class BitmapVipScoreboard(uvm_subscriber):
    """Only pin samples reach this independent ownership-set model."""
    def build_phase(self):
        self.cfg = ConfigDB().get(self, "", "bitmap_vip_cfg")
        self.owned = set()
        self.checked = self.resets = 0
        self.reset_seen = False

    def write(self, event):
        (reset, allocate, release, ident), actual = event
        a_ok = f_ok = False
        selected = 0
        if reset:
            self.owned.clear()
            self.reset_seen = True
            self.resets += 1
        else:
            assert self.reset_seen, "Observe reset before traffic"
            f_ok = bool(release and ident in self.owned)
            if f_ok:
                self.owned.remove(ident)
            available = set(range(self.cfg.capacity)) - self.owned
            a_ok = bool(allocate and available)
            if a_ok:
                selected = min(available)
                self.owned.add(selected)
            self.checked += bool(allocate or release)
        count = self.cfg.capacity - len(self.owned)
        expected = (int(a_ok), int(allocate and not a_ok and not reset), selected,
                    int(f_ok), int(release and not f_ok and not reset), count,
                    int(count == 0), int(count == self.cfg.capacity))
        assert actual == expected, ("SCOREBOARD", event, expected, self.owned)

    def check_phase(self):
        assert self.reset_seen and self.checked > 0, "EMPTY_TEST: No checked traffic after reset"

    def report_phase(self):
        self.logger.info("BITMAP VIP PASSED: %d transactions; %d reset cycles", self.checked, self.resets)
