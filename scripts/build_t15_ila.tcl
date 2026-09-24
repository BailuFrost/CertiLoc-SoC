# T15非工程模式实现脚本：插入ILA并生成bit/ltx和工程验收报告。

if {$argc != 1} {
    puts "ERROR: usage: vivado -mode batch -source build_t15_ila.tcl -tclargs <output_dir>"
    exit 2
}

set output_dir [file normalize [lindex $argv 0]]
set script_dir [file dirname [file normalize [info script]]]
set project_dir [file dirname $script_dir]
file mkdir $output_dir

set rtl_files [list \
    [file join $project_dir rtl comm crc16_ccitt_byte.v] \
    [file join $project_dir rtl comm uart_rx.v] \
    [file join $project_dir rtl comm uart_tx.v] \
    [file join $project_dir rtl comm packet_decoder.v] \
    [file join $project_dir rtl comm packet_encoder.v] \
    [file join $project_dir rtl geometry cordic_sincos.v] \
    [file join $project_dir rtl geometry bearing_constraint_gen.v] \
    [file join $project_dir rtl geometry halfplane_classifier.v] \
    [file join $project_dir rtl geometry segment_intersection.v] \
    [file join $project_dir rtl geometry polygon_clip_engine.v] \
    [file join $project_dir rtl geometry polygon_diameter_engine.v] \
    [file join $project_dir rtl memory initial_polygon_rom.v] \
    [file join $project_dir rtl memory initial_polygon_loader.v] \
    [file join $project_dir rtl memory vertex_ram_dual_buffer.v] \
    [file join $project_dir rtl control protocol_command_adapter.v] \
    [file join $project_dir rtl control localization_command_ctrl.v] \
    [file join $project_dir rtl control protocol_response_adapter.v] \
    [file join $project_dir rtl top radio_localization_fpga_top.v]]

read_verilog $rtl_files
read_xdc [file join $project_dir constraints basys3_radio_localization.xdc]
add_files -norecurse [file join $project_dir tb vectors initial_polygon_720_q16_16.mem]

synth_design -top radio_localization_fpga_top -part xc7a35tcpg236-1 \
    -generic C_ROM_INIT_FILE=[file join $project_dir tb vectors initial_polygon_720_q16_16.mem]

set debug_nets [lsort -unique [get_nets -hier -filter {MARK_DEBUG == 1}]]
if {[llength $debug_nets] == 0} {
    puts "ERROR: no MARK_DEBUG nets survived synthesis"
    exit 3
}
set clock_nets [get_nets clk_100mhz_i_IBUF_BUFG]
if {[llength $clock_nets] != 1} {
    puts "ERROR: expected one buffered 100 MHz clock net, found [llength $clock_nets]"
    exit 4
}

create_debug_core t15_ila ila
set_property C_DATA_DEPTH 4096 [get_debug_cores t15_ila]
set_property C_INPUT_PIPE_STAGES 1 [get_debug_cores t15_ila]
set_property C_EN_STRG_QUAL true [get_debug_cores t15_ila]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores t15_ila]
set_property port_width [llength $debug_nets] [get_debug_ports t15_ila/probe0]
connect_debug_port t15_ila/clk $clock_nets
connect_debug_port t15_ila/probe0 $debug_nets

write_checkpoint -force [file join $output_dir post_synth_ila.dcp]
opt_design
place_design
phys_opt_design
route_design

report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose \
    -file [file join $output_dir timing_summary_routed.rpt]
report_utilization -file [file join $output_dir utilization_routed.rpt]
report_power -file [file join $output_dir power_routed.rpt]
report_methodology -file [file join $output_dir methodology_routed.rpt]
report_drc -file [file join $output_dir drc_routed.rpt]
report_io -file [file join $output_dir io_routed.rpt]
report_debug_core -file [file join $output_dir debug_cores.rpt]

set worst_path [get_timing_paths -delay_type max -max_paths 1 -nworst 1]
if {[llength $worst_path] == 0} {
    puts "ERROR: no setup timing path was reported"
    exit 5
}
set worst_slack [get_property SLACK $worst_path]
if {$worst_slack < 0.0} {
    puts "ERROR: routed ILA design fails timing with WNS=$worst_slack ns"
    exit 6
}

write_checkpoint -force [file join $output_dir radio_localization_t15_ila_routed.dcp]
write_debug_probes -force [file join $output_dir radio_localization_t15_ila.ltx]
write_bitstream -force [file join $output_dir radio_localization_t15_ila.bit]
puts "PASS: T15 ILA image generated with [llength $debug_nets] marked nets and WNS=$worst_slack ns"
