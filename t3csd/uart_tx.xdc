set_property -dict { PACKAGE_PIN E3   IOSTANDARD LVCMOS33 } 		[get_ports { clock }];
create_clock -add -name clock_master -period 10.00 -waveform {0 5} 	[get_ports { clock }];

set_property -dict { PACKAGE_PIN F4 IOSTANDARD LVCMOS33 PULLUP true } [get_ports { ps2_clk }];
set_property -dict { PACKAGE_PIN B2 IOSTANDARD LVCMOS33 PULLUP true } [get_ports { ps2_data }];

set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { reset }];

#tx_data
#tx_done
