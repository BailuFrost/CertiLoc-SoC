## Basys 3 board constraints for radio_localization_fpga_top
## Target device: xc7a35tcpg236-1
## Pin source: Digilent Basys-3-Master.xdc

## 100 MHz board clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports {clk_100mhz_i}]
create_clock -add -name clk_100mhz -period 10.000 -waveform {0.000 5.000} [get_ports {clk_100mhz_i}]

## Center push button, active-high external reset request
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports {reset_btn_i}]

## On-board USB-UART bridge
## B18 carries data from the PC to the FPGA.
## A18 carries data from the FPGA to the PC.
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports {uart_rx_i}]
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports {uart_tx_o}]

## User status LEDs: idle, receiving, computing, error
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {status_led_o[0]}]
set_property -dict { PACKAGE_PIN E19 IOSTANDARD LVCMOS33 } [get_ports {status_led_o[1]}]
set_property -dict { PACKAGE_PIN U19 IOSTANDARD LVCMOS33 } [get_ports {status_led_o[2]}]
set_property -dict { PACKAGE_PIN V19 IOSTANDARD LVCMOS33 } [get_ports {status_led_o[3]}]

## Optional external debug trigger on Pmod JA1
set_property -dict { PACKAGE_PIN J1 IOSTANDARD LVCMOS33 } [get_ports {debug_trigger_o}]

## Basys 3 configuration-bank voltage
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
