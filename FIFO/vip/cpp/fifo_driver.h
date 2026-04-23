/**
 * FIFO VIP Driver
 * C++ Verilator equivalent to pyUVM/UVM driver
 * Create Date: 2026-04-23
 */

#ifndef FIFO_DRIVER_H
#define FIFO_DRIVER_H

#include "fifo_transaction.h"
#include <functional>
#include <iostream>

namespace fifo_vip {

/**
 * FIFO Driver class
 * Drives transactions to the DUT
 * Template parameter T is the Verilated DUT type
 */
template<typename T>
class FifoDriver {
public:
    // Configuration
    int  data_width;
    bool rd_buffer;
    bool verbose;

    // Callback for broadcasting driven transactions
    std::function<void(const FifoTransaction&)> on_transaction;

    // Constructor
    explicit FifoDriver(T* dut)
        : dut_(dut)
        , data_width(8)
        , rd_buffer(true)
        , verbose(false)
    {}

    /**
     * Initialize driver signals
     */
    void init() {
        dut_->wr_en = 0;
        dut_->rd_en = 0;
        dut_->data_wr = 0;
    }

    /**
     * Drive a single transaction
     * Returns the transaction with response fields populated
     */
    FifoTransaction drive(FifoTransaction& item) {
        item.set_data_width(data_width);

        switch (item.op) {
            case FifoOp::WRITE:
                drive_write(item);
                break;
            case FifoOp::READ:
                drive_read(item);
                break;
            case FifoOp::IDLE:
                drive_idle();
                break;
        }

        // Broadcast transaction
        if (on_transaction) {
            on_transaction(item);
        }

        return item;
    }

private:
    T* dut_;

    /**
     * Helper to advance one clock cycle
     * Caller must provide the clock toggle function
     */
    void tick_wr() {
        // Rising edge on wr_clk
        dut_->wr_clk = 1;
        dut_->eval();
        // Falling edge on wr_clk
        dut_->wr_clk = 0;
        dut_->eval();
    }

    void tick_rd() {
        // Rising edge on rd_clk
        dut_->rd_clk = 1;
        dut_->eval();
        // Falling edge on rd_clk
        dut_->rd_clk = 0;
        dut_->eval();
    }

    /**
     * Drive write transaction
     */
    void drive_write(FifoTransaction& item) {
        // Mask data to correct width
        uint64_t data_mask = (1ULL << data_width) - 1;
        dut_->data_wr = item.data & data_mask;
        dut_->wr_en = 1;
        tick_wr();

        // Capture response
        item.full = dut_->fifo_full;
        item.success = !item.full;
        dut_->wr_en = 0;
        tick_wr();

        if (verbose) {
            std::cout << "[WR_DRV] " << item.to_string() << std::endl;
        }
    }

    /**
     * Drive read transaction
     */
    void drive_read(FifoTransaction& item) {
        dut_->rd_en = 1;
        tick_rd();

        // Capture empty flag
        item.empty = dut_->fifo_empty;
        item.success = !item.empty;

        // Wait extra cycle for buffered read
        if (rd_buffer) {
            tick_rd();
        }

        // Capture read data
        item.read_data = dut_->data_rd;
        dut_->rd_en = 0;
        tick_rd();

        if (verbose) {
            std::cout << "[RD_DRV] " << item.to_string() << std::endl;
        }
    }

    /**
     * Drive idle cycles
     */
    void drive_idle() {
        tick_wr();
        tick_wr();
    }
};

/**
 * Unified FIFO Driver for synchronized clock domains
 * Simpler version when rd_clk == wr_clk
 */
template<typename T>
class FifoDriverSync {
public:
    int  data_width;
    bool rd_buffer;
    bool verbose;

    std::function<void(const FifoTransaction&)> on_write_transaction;
    std::function<void(const FifoTransaction&)> on_read_transaction;

    explicit FifoDriverSync(T* dut)
        : dut_(dut)
        , data_width(8)
        , rd_buffer(true)
        , verbose(false)
    {}

    void init() {
        dut_->wr_en = 0;
        dut_->rd_en = 0;
        dut_->data_wr = 0;
    }

    /**
     * Advance simulation by one clock cycle
     * Call this from the main testbench loop
     */
    void tick() {
        dut_->wr_clk = 1;
        dut_->rd_clk = 1;
        dut_->eval();
        dut_->wr_clk = 0;
        dut_->rd_clk = 0;
        dut_->eval();
    }

    /**
     * Drive write operation (non-blocking style)
     */
    void start_write(uint64_t data) {
        uint64_t data_mask = (1ULL << data_width) - 1;
        dut_->data_wr = data & data_mask;
        dut_->wr_en = 1;
    }

    void end_write() {
        dut_->wr_en = 0;
    }

    /**
     * Drive read operation (non-blocking style)
     */
    void start_read() {
        dut_->rd_en = 1;
    }

    void end_read() {
        dut_->rd_en = 0;
    }

    /**
     * Blocking write transaction
     */
    FifoTransaction write(uint64_t data) {
        FifoTransaction item;
        item.op = FifoOp::WRITE;
        item.data = data;
        item.set_data_width(data_width);

        start_write(data);
        tick();

        item.full = dut_->fifo_full;
        item.success = !item.full;
        end_write();
        tick();

        if (verbose) {
            std::cout << "[WR_DRV] " << item.to_string() << std::endl;
        }

        if (on_write_transaction) {
            on_write_transaction(item);
        }

        return item;
    }

    /**
     * Blocking read transaction
     */
    FifoTransaction read() {
        FifoTransaction item;
        item.op = FifoOp::READ;
        item.set_data_width(data_width);

        start_read();
        tick();

        item.empty = dut_->fifo_empty;
        item.success = !item.empty;

        if (rd_buffer) {
            tick();
        }

        item.read_data = dut_->data_rd;
        end_read();
        tick();

        if (verbose) {
            std::cout << "[RD_DRV] " << item.to_string() << std::endl;
        }

        if (on_read_transaction) {
            on_read_transaction(item);
        }

        return item;
    }

private:
    T* dut_;
};

} // namespace fifo_vip

#endif // FIFO_DRIVER_H
