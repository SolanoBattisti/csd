set_property -dict { PACKAGE_PIN E3   IOSTANDARD LVCMOS33 } 		[get_ports { clock }];
create_clock -add -name clock_master -period 10.00 -waveform {0 5} 	[get_ports { clock }];

set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { right }];
set_property -dict { PACKAGE_PIN P17   IOSTANDARD LVCMOS33 } [get_ports { left }];
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { up }];
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { down }];

set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { reset }];

set_property -dict { PACKAGE_PIN A3   IOSTANDARD LVCMOS33 } [get_ports { color_red[0] }];
set_property -dict { PACKAGE_PIN B4   IOSTANDARD LVCMOS33 } [get_ports { color_red[1] }];
set_property -dict { PACKAGE_PIN C4   IOSTANDARD LVCMOS33 } [get_ports { color_red[2] }];
set_property -dict { PACKAGE_PIN A4   IOSTANDARD LVCMOS33 } [get_ports { color_red[3] }];

set_property -dict { PACKAGE_PIN C6   IOSTANDARD LVCMOS33 } [get_ports { color_green[0] }];
set_property -dict { PACKAGE_PIN A5   IOSTANDARD LVCMOS33 } [get_ports { color_green[1] }];
set_property -dict { PACKAGE_PIN B6   IOSTANDARD LVCMOS33 } [get_ports { color_green[2] }];
set_property -dict { PACKAGE_PIN A6   IOSTANDARD LVCMOS33 } [get_ports { color_green[3] }];

set_property -dict { PACKAGE_PIN B7   IOSTANDARD LVCMOS33 } [get_ports { color_blue[0] }];
set_property -dict { PACKAGE_PIN C7   IOSTANDARD LVCMOS33 } [get_ports { color_blue[1] }];
set_property -dict { PACKAGE_PIN D7   IOSTANDARD LVCMOS33 } [get_ports { color_blue[2] }];
set_property -dict { PACKAGE_PIN D8   IOSTANDARD LVCMOS33 } [get_ports { color_blue[3] }];

set_property -dict { PACKAGE_PIN B11   IOSTANDARD LVCMOS33 } [get_ports { vga_hs }];
set_property -dict { PACKAGE_PIN B12   IOSTANDARD LVCMOS33 } [get_ports { vga_vs }];