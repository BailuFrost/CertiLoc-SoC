# Run a focused out-of-context synthesis for the T08 vertex RAM.
set script_directory [file dirname [file normalize [info script]]]
set project_directory [file dirname $script_directory]
if {[llength $argv] > 0} {
	set rtl_file [file normalize [lindex $argv 0]]
} else {
	set rtl_file [file join $project_directory rtl memory vertex_ram_dual_buffer.v]
}

read_verilog $rtl_file
synth_design -top vertex_ram_dual_buffer -part xc7a35tcpg236-1 -mode out_of_context
report_utilization -file utilization.rpt
report_ram_utilization -file ram_utilization.rpt
write_checkpoint -force vertex_ram_dual_buffer_ooc.dcp

set bram_36_cells [get_cells -hierarchical -filter {REF_NAME == RAMB36E1}]
set bram_18_cells [get_cells -hierarchical -filter {REF_NAME == RAMB18E1}]
puts "BRAM36_COUNT=[llength $bram_36_cells]"
puts "BRAM18_COUNT=[llength $bram_18_cells]"
