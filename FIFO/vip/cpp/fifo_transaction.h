/**
 * FIFO VIP Transaction
 * C++ Verilator equivalent to pyUVM/UVM sequence item
 * Create Date: 2026-04-23
 */

#ifndef FIFO_TRANSACTION_H
#define FIFO_TRANSACTION_H

#include <cstdint>
#include <string>
#include <sstream>
#include <iomanip>
#include <random>

namespace fifo_vip {

/**
 * FIFO operation types
 */
enum class FifoOp {
    WRITE,
    READ,
    IDLE
};

/**
 * Convert FifoOp to string
 */
inline std::string op_to_string(FifoOp op) {
    switch (op) {
        case FifoOp::WRITE: return "WRITE";
        case FifoOp::READ:  return "READ";
        case FifoOp::IDLE:  return "IDLE";
        default:            return "UNKNOWN";
    }
}

/**
 * FIFO Transaction class
 * Encapsulates all data for a single FIFO operation
 */
class FifoTransaction {
public:
    // Request fields
    FifoOp   op;
    uint64_t data;

    // Response fields (populated after driving)
    uint64_t read_data;
    bool     full;
    bool     empty;
    bool     success;

    // Configuration
    int data_width;

    // Constructor
    FifoTransaction()
        : op(FifoOp::WRITE)
        , data(0)
        , read_data(0)
        , full(false)
        , empty(false)
        , success(true)
        , data_width(8)
    {}

    /**
     * Randomize transaction fields
     */
    void randomize(std::mt19937& rng) {
        std::uniform_int_distribution<int> op_dist(0, 1);
        op = (op_dist(rng) == 0) ? FifoOp::WRITE : FifoOp::READ;

        uint64_t max_val = (1ULL << data_width) - 1;
        std::uniform_int_distribution<uint64_t> data_dist(0, max_val);
        data = data_dist(rng);
    }

    /**
     * Randomize with specific operation
     */
    void randomize_with_op(FifoOp target_op, std::mt19937& rng) {
        op = target_op;
        uint64_t max_val = (1ULL << data_width) - 1;
        std::uniform_int_distribution<uint64_t> data_dist(0, max_val);
        data = data_dist(rng);
    }

    /**
     * Set data width configuration
     */
    void set_data_width(int width) {
        data_width = width;
    }

    /**
     * Convert to string for logging
     */
    std::string to_string() const {
        std::ostringstream oss;
        oss << "Op:" << op_to_string(op)
            << " Data:0x" << std::hex << std::setfill('0') << std::setw((data_width + 3) / 4) << data
            << " ReadData:0x" << std::setw((data_width + 3) / 4) << read_data
            << std::dec
            << " Full:" << (full ? "1" : "0")
            << " Empty:" << (empty ? "1" : "0")
            << " Success:" << (success ? "1" : "0");
        return oss.str();
    }

    /**
     * Create a copy of this transaction
     */
    FifoTransaction clone() const {
        FifoTransaction t;
        t.op = op;
        t.data = data;
        t.read_data = read_data;
        t.full = full;
        t.empty = empty;
        t.success = success;
        t.data_width = data_width;
        return t;
    }
};

} // namespace fifo_vip

#endif // FIFO_TRANSACTION_H
