# Source after synthesis and pass verified register-cell collections.
# This helper deliberately does not guess hierarchy or declare clock groups.
proc rtlstruct_fifo_cdc {wr_gray wr_meta rd_gray rd_meta wr_period rd_period} {
    if {$wr_period <= 0 || $rd_period <= 0} {
        error "FIFO clock periods must be positive (ns)"
    }
    set budget [expr {min($wr_period, $rd_period)}]
    foreach {source destination} [list $wr_gray $wr_meta $rd_gray $rd_meta] {
        if {[llength $source] < 2 || [llength $source] != [llength $destination]} {
            error "FIFO Gray source and first-stage register collections must match and be nonempty"
        }
        set_max_delay -datapath_only $budget -from $source -to $destination
        set_bus_skew $budget -from $source -to $destination
    }
}