set_property -dict { PACKAGE_PIN E3   IOSTANDARD LVCMOS33 } 		[get_ports { clock }];
create_clock -add -name clock_master -period 10.00 -waveform {0 5} 	[get_ports {clock}];

set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { reset }];

set_property -dict { PACKAGE_PIN F4 IOSTANDARD LVCMOS33 PULLUP true } [get_ports { ps2_clk }];
set_property -dict { PACKAGE_PIN B2 IOSTANDARD LVCMOS33 PULLUP true } [get_ports { ps2_data }];

set_property -dict { PACKAGE_PIN J17   IOSTANDARD LVCMOS33 } [get_ports { display_en[0] }];
set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { display_en[1] }];
set_property -dict { PACKAGE_PIN T9    IOSTANDARD LVCMOS33 } [get_ports { display_en[2] }];
set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { display_en[3] }];
set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { display_en[4] }];
set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { display_en[5] }];
set_property -dict { PACKAGE_PIN K2    IOSTANDARD LVCMOS33 } [get_ports { display_en[6] }];
set_property -dict { PACKAGE_PIN U13   IOSTANDARD LVCMOS33 } [get_ports { display_en[7] }];

set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { display[7] }];
set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { display[6] }];
set_property -dict { PACKAGE_PIN R10   IOSTANDARD LVCMOS33 } [get_ports { display[5] }];
set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { display[4] }];
set_property -dict { PACKAGE_PIN K13   IOSTANDARD LVCMOS33 } [get_ports { display[3] }];
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { display[2] }];
set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { display[1] }];
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { display[0] }];

set_property -dict { PACKAGE_PIN C14   IOSTANDARD LVCMOS33 } [get_ports { scl }];
set_property -dict { PACKAGE_PIN C15   IOSTANDARD LVCMOS33 } [get_ports { sda }];

set_property -dict { PACKAGE_PIN D4   IOSTANDARD LVCMOS33 } [get_ports { tx_data }];
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { tx_done }]; 



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


