/**
 * FIFO VIP Scoreboard
 * C++ Verilator equivalent to pyUVM/UVM scoreboard
 * Contains reference model for self-checking
 * Create Date: 2026-04-23
 */

#ifndef FIFO_SCOREBOARD_H
#define FIFO_SCOREBOARD_H

#include "fifo_transaction.h"
#include <queue>
#include <iostream>
#include <iomanip>

namespace fifo_vip {

/**
 * FIFO Scoreboard class
 * Maintains a reference model and checks DUT behavior
 */
class FifoScoreboard {
public:
    // Configuration
    int depth;
    int data_width;
    bool verbose;

    // Statistics
    int wr_count;
    int rd_count;
    int errors;
    int wr_full_count;    // Writes attempted when full
    int rd_empty_count;   // Reads attempted when empty

    // Constructor
    FifoScoreboard()
        : depth(12)
        , data_width(8)
        , verbose(false)
        , wr_count(0)
        , rd_count(0)
        , errors(0)
        , wr_full_count(0)
        , rd_empty_count(0)
    {}

    /**
     * Process a write transaction
     */
    void write_in(const FifoTransaction& item) {
        if (item.op != FifoOp::WRITE) return;

        if (item.success) {
            // Add to reference model
            fifo_model_.push(item.data);
            wr_count++;

            if (verbose) {
                std::cout << "[SB] Write: data=0x" << std::hex << item.data
                          << std::dec << ", queue_size=" << fifo_model_.size()
                          << std::endl;
            }

            // Check if model overflowed (should not happen if DUT is correct)
            if (fifo_model_.size() > static_cast<size_t>(depth)) {
                std::cerr << "[SB] ERROR: Reference model overflow! Size="
                          << fifo_model_.size() << " Depth=" << depth << std::endl;
                errors++;
            }
        } else {
            // Write was blocked (FIFO full)
            wr_full_count++;
            if (verbose) {
                std::cout << "[SB] Write blocked (FIFO full)" << std::endl;
            }
        }
    }

    /**
     * Process a read transaction
     */
    void read_in(const FifoTransaction& item) {
        if (item.op != FifoOp::READ) return;

        if (item.success) {
            rd_count++;

            if (fifo_model_.empty()) {
                std::cerr << "[SB] ERROR: Read from empty reference model!"
                          << std::endl;
                errors++;
                return;
            }

            uint64_t expected = fifo_model_.front();
            fifo_model_.pop();

            if (item.read_data == expected) {
                if (verbose) {
                    std::cout << "[SB] Read OK: data=0x" << std::hex << item.read_data
                              << std::dec << ", queue_size=" << fifo_model_.size()
                              << std::endl;
                }
            } else {
                std::cerr << "[SB] ERROR: Data mismatch! Expected:0x"
                          << std::hex << expected
                          << " Got:0x" << item.read_data << std::dec << std::endl;
                errors++;
            }
        } else {
            // Read was blocked (FIFO empty)
            rd_empty_count++;
            if (verbose) {
                std::cout << "[SB] Read blocked (FIFO empty)" << std::endl;
            }
        }
    }

    /**
     * Check full flag consistency
     */
    void check_full_flag(bool dut_full) {
        bool model_full = (fifo_model_.size() >= static_cast<size_t>(depth));
        if (dut_full != model_full) {
            std::cerr << "[SB] ERROR: Full flag mismatch! DUT:" << dut_full
                      << " Model:" << model_full
                      << " (size=" << fifo_model_.size() << ")" << std::endl;
            errors++;
        }
    }

    /**
     * Check empty flag consistency
     */
    void check_empty_flag(bool dut_empty) {
        bool model_empty = fifo_model_.empty();
        if (dut_empty != model_empty) {
            std::cerr << "[SB] ERROR: Empty flag mismatch! DUT:" << dut_empty
                      << " Model:" << model_empty
                      << " (size=" << fifo_model_.size() << ")" << std::endl;
            errors++;
        }
    }

    /**
     * Get current model size
     */
    size_t get_model_size() const {
        return fifo_model_.size();
    }

    /**
     * Check if model is empty
     */
    bool is_model_empty() const {
        return fifo_model_.empty();
    }

    /**
     * Check if model is full
     */
    bool is_model_full() const {
        return fifo_model_.size() >= static_cast<size_t>(depth);
    }

    /**
     * Reset the scoreboard
     */
    void reset() {
        while (!fifo_model_.empty()) {
            fifo_model_.pop();
        }
        wr_count = 0;
        rd_count = 0;
        errors = 0;
        wr_full_count = 0;
        rd_empty_count = 0;
    }

    /**
     * Print final report
     */
    void report() const {
        std::cout << std::endl;
        std::cout << "==================================================" << std::endl;
        std::cout << "FIFO VIP Scoreboard Report" << std::endl;
        std::cout << "==================================================" << std::endl;
        std::cout << "Total Writes:        " << wr_count << std::endl;
        std::cout << "Total Reads:         " << rd_count << std::endl;
        std::cout << "Writes when Full:    " << wr_full_count << std::endl;
        std::cout << "Reads when Empty:    " << rd_empty_count << std::endl;
        std::cout << "Errors:              " << errors << std::endl;
        std::cout << "Final Queue Size:    " << fifo_model_.size() << std::endl;
        std::cout << std::endl;

        if (errors == 0) {
            std::cout << "*** TEST PASSED ***" << std::endl;
        } else {
            std::cout << "*** TEST FAILED - " << errors << " errors ***" << std::endl;
        }
        std::cout << "==================================================" << std::endl;
        std::cout << std::endl;
    }

    /**
     * Return pass/fail status
     */
    bool passed() const {
        return errors == 0;
    }

private:
    std::queue<uint64_t> fifo_model_;
};

} // namespace fifo_vip

#endif // FIFO_SCOREBOARD_H
