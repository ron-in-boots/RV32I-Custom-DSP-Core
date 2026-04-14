# -------------------------------------------------------------------------
# Zybo Z7-10 Constraints
# -------------------------------------------------------------------------

# Clock signal (Zybo Z7 clock is on pin K17)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports sysclk]
create_clock -add -name sysclk -period 60.00 [get_ports sysclk]

# Reset (Mapped to Zybo Button 0 'BTN0')
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports rst]

# LED (Mapped to Zybo LED 0, so Vivado doesn't optimize it away)
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports led]