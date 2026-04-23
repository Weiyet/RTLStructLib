/**
 * FIFO VIP Monitor
 * C++ Verilator equivalent to pyUVM/UVM monitor
 * Create Date: 2026-04-23
 */

#ifndef FIFO_MONITOR_H
#define FIFO_MONITOR_H

#include "fifo_transaction.h"
#include <functional>
#include <iostream>

namespace fifo_vip {

/**
 * FIFO Monitor class
 * Passively observes DUT signals and broadcasts transactions
 * Template parameter T is the Verilated DUT type
 */
template<typename T>
class FifoMonitor {
public:
    // Configuration
    int  data_width;
    bool rd_buffer;
    bool verbose;

    // Callbacks for broadcasting observed transactions
    std::function<void(const FifoTransaction&)> on_write;
    std::function<void(const FifoTransaction&)> on_read;

    // Constructor
    explicit FifoMonitor(T* dut)
        : dut_(dut)
        , data_width(8)
        , rd_buffer(true)
        , verbose(false)
        , prev_wr_en_(false)
        , prev_rd_en_(false)
        , pending_read_(false)
        , read_wait_cycles_(0)
    {}

    /**
     * Sample DUT signals on clock edge
     * Call this after each clock cycle in the main loop
     */
    void sample() {
        sample_write();
        sample_read();
    }

private:
    T* dut_;

    // Previous signal values for edge detection
    bool prev_wr_en_;
    bool prev_rd_en_;

    // Read tracking for buffered reads
    bool pending_read_;
    int  read_wait_cycles_;

    /**
     * Sample write transactions
     */
    void sample_write() {
        bool wr_en = dut_->wr_en;

        // Detect falling edge of wr_en (end of write)
        if (prev_wr_en_ && !wr_en) {
            FifoTransaction item;
            item.op = FifoOp::WRITE;
            item.data = dut_->data_wr;
            item.full = dut_->fifo_full;
            item.success = !item.full;
            item.set_data_width(data_width);

            if (verbose) {
                std::cout << "[WR_MON] " << item.to_string() << std::endl;
            }

            if (on_write) {
                on_write(item);
            }
        }

        prev_wr_en_ = wr_en;
    }

    /**
     * Sample read transactions
     */
    void sample_read() {
        bool rd_en = dut_->rd_en;

        // Detect rising edge of rd_en (start of read)
        if (!prev_rd_en_ && rd_en) {
            pending_read_ = true;
            read_wait_cycles_ = rd_buffer ? 2 : 1;
        }

        // Count down wait cycles
        if (pending_read_ && read_wait_cycles_ > 0) {
            read_wait_cycles_--;
        }

        // Detect falling edge of rd_en or completion of buffered read
        if (prev_rd_en_ && !rd_en && pending_read_) {
            FifoTransaction item;
            item.op = FifoOp::READ;
            item.read_data = dut_->data_rd;
            item.empty = dut_->fifo_empty;
            item.success = !item.empty;
            item.set_data_width(data_width);

            if (verbose) {
                std::cout << "[RD_MON] " << item.to_string() << std::endl;
            }

            if (on_read) {
                on_read(item);
            }

            pending_read_ = false;
        }

        prev_rd_en_ = rd_en;
    }
};

/**
 * Passive monitor that can be attached to any FIFO
 * Uses signal polling rather than edge detection
 */
template<typename T>
class FifoMonitorPassive {
public:
    int  data_width;
    bool verbose;

    std::function<void(const FifoTransaction&)> on_write;
    std::function<void(const FifoTransaction&)> on_read;

    explicit FifoMonitorPassive(T* dut)
        : dut_(dut)
        , data_width(8)
        , verbose(false)
    {}

    /**
     * Check and report current FIFO state
     */
    void report_state() const {
        std::cout << "[MON] State: "
                  << "Full=" << (dut_->fifo_full ? "1" : "0")
                  << " Empty=" << (dut_->fifo_empty ? "1" : "0")
                  << " WrEn=" << (dut_->wr_en ? "1" : "0")
                  << " RdEn=" << (dut_->rd_en ? "1" : "0")
                  << std::endl;
    }

    /**
     * Get current FIFO flags
     */
    bool is_full() const { return dut_->fifo_full; }
    bool is_empty() const { return dut_->fifo_empty; }

private:
    T* dut_;
};

} // namespace fifo_vip

#endif // FIFO_MONITOR_H
