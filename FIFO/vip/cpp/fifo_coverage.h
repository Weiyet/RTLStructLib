/**
 * FIFO VIP Coverage
 * C++ Verilator equivalent to functional coverage
 * Create Date: 2026-04-23
 */

#ifndef FIFO_COVERAGE_H
#define FIFO_COVERAGE_H

#include "fifo_transaction.h"
#include <set>
#include <map>
#include <iostream>
#include <iomanip>
#include <bitset>

namespace fifo_vip {

/**
 * FIFO Coverage Collector
 * Tracks functional coverage metrics
 */
class FifoCoverage {
public:
    // Configuration
    int depth;
    int data_width;

    // Constructor
    FifoCoverage()
        : depth(12)
        , data_width(8)
    {}

    /**
     * Sample a transaction
     */
    void sample(const FifoTransaction& item) {
        // Track operation types
        op_coverage_[item.op] = true;

        // Track data values seen
        if (item.op == FifoOp::WRITE) {
            write_data_values_.insert(item.data);
        } else if (item.op == FifoOp::READ && item.success) {
            read_data_values_.insert(item.read_data);
        }

        // Track flag conditions
        if (item.full) full_seen_ = true;
        if (item.empty) empty_seen_ = true;

        // Track corner cases
        if (item.op == FifoOp::WRITE && item.full) {
            write_when_full_ = true;
        }
        if (item.op == FifoOp::READ && item.empty) {
            read_when_empty_ = true;
        }
    }

    /**
     * Sample FIFO fill level
     */
    void sample_fill_level(size_t level) {
        fill_levels_.insert(level);
        if (level == 0) {
            empty_level_seen_ = true;
        }
        if (level >= static_cast<size_t>(depth)) {
            full_level_seen_ = true;
        }
    }

    /**
     * Calculate operation coverage percentage
     */
    double get_op_coverage() const {
        int covered = 0;
        if (op_coverage_.count(FifoOp::WRITE)) covered++;
        if (op_coverage_.count(FifoOp::READ)) covered++;
        // IDLE is optional
        return (covered / 2.0) * 100.0;
    }

    /**
     * Calculate data coverage percentage
     * Based on how many unique values were written
     */
    double get_data_coverage() const {
        uint64_t max_values = 1ULL << data_width;
        // Cap at reasonable sample for large data widths
        uint64_t target = std::min(max_values, static_cast<uint64_t>(256));
        size_t covered = write_data_values_.size();
        return (static_cast<double>(covered) / target) * 100.0;
    }

    /**
     * Calculate fill level coverage percentage
     */
    double get_fill_level_coverage() const {
        // All levels from 0 to depth should be covered
        size_t target = depth + 1;
        size_t covered = fill_levels_.size();
        return (static_cast<double>(covered) / target) * 100.0;
    }

    /**
     * Calculate corner case coverage percentage
     */
    double get_corner_case_coverage() const {
        int total = 4;  // full, empty, write_when_full, read_when_empty
        int covered = 0;
        if (full_seen_) covered++;
        if (empty_seen_) covered++;
        if (write_when_full_) covered++;
        if (read_when_empty_) covered++;
        return (static_cast<double>(covered) / total) * 100.0;
    }

    /**
     * Reset coverage data
     */
    void reset() {
        op_coverage_.clear();
        write_data_values_.clear();
        read_data_values_.clear();
        fill_levels_.clear();
        full_seen_ = false;
        empty_seen_ = false;
        write_when_full_ = false;
        read_when_empty_ = false;
        empty_level_seen_ = false;
        full_level_seen_ = false;
    }

    /**
     * Print coverage report
     */
    void report() const {
        std::cout << std::endl;
        std::cout << "==================================================" << std::endl;
        std::cout << "FIFO VIP Coverage Report" << std::endl;
        std::cout << "==================================================" << std::endl;

        // Operation coverage
        std::cout << std::endl << "Operation Coverage:" << std::endl;
        std::cout << "  WRITE:    " << (op_coverage_.count(FifoOp::WRITE) ? "YES" : "NO") << std::endl;
        std::cout << "  READ:     " << (op_coverage_.count(FifoOp::READ) ? "YES" : "NO") << std::endl;
        std::cout << "  Coverage: " << std::fixed << std::setprecision(1)
                  << get_op_coverage() << "%" << std::endl;

        // Data coverage
        std::cout << std::endl << "Data Coverage:" << std::endl;
        std::cout << "  Unique Write Values: " << write_data_values_.size() << std::endl;
        std::cout << "  Unique Read Values:  " << read_data_values_.size() << std::endl;
        std::cout << "  Coverage: " << std::fixed << std::setprecision(1)
                  << get_data_coverage() << "%" << std::endl;

        // Fill level coverage
        std::cout << std::endl << "Fill Level Coverage:" << std::endl;
        std::cout << "  Levels Seen: ";
        for (size_t level : fill_levels_) {
            std::cout << level << " ";
        }
        std::cout << std::endl;
        std::cout << "  Coverage: " << std::fixed << std::setprecision(1)
                  << get_fill_level_coverage() << "%" << std::endl;

        // Corner cases
        std::cout << std::endl << "Corner Case Coverage:" << std::endl;
        std::cout << "  FIFO Full Seen:      " << (full_seen_ ? "YES" : "NO") << std::endl;
        std::cout << "  FIFO Empty Seen:     " << (empty_seen_ ? "YES" : "NO") << std::endl;
        std::cout << "  Write When Full:     " << (write_when_full_ ? "YES" : "NO") << std::endl;
        std::cout << "  Read When Empty:     " << (read_when_empty_ ? "YES" : "NO") << std::endl;
        std::cout << "  Coverage: " << std::fixed << std::setprecision(1)
                  << get_corner_case_coverage() << "%" << std::endl;

        // Overall
        double overall = (get_op_coverage() + get_data_coverage() +
                         get_fill_level_coverage() + get_corner_case_coverage()) / 4.0;
        std::cout << std::endl << "Overall Coverage: " << std::fixed << std::setprecision(1)
                  << overall << "%" << std::endl;

        std::cout << "==================================================" << std::endl;
        std::cout << std::endl;
    }

private:
    // Coverage bins
    std::map<FifoOp, bool> op_coverage_;
    std::set<uint64_t> write_data_values_;
    std::set<uint64_t> read_data_values_;
    std::set<size_t> fill_levels_;

    // Corner case flags
    bool full_seen_ = false;
    bool empty_seen_ = false;
    bool write_when_full_ = false;
    bool read_when_empty_ = false;
    bool empty_level_seen_ = false;
    bool full_level_seen_ = false;
};

} // namespace fifo_vip

#endif // FIFO_COVERAGE_H
