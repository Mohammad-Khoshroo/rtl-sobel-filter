# Clock signals
#set_property PACKAGE_PIN E7                 [get_ports CLK_33MHz]
#set_property IOSTANDARD LVCMOS33            [get_ports CLK_33MHz]
#create_clock -period 30.000 -name CLK_33MHz [get_ports CLK_33MHz]

# set_property PACKAGE_PIN U18                [get_ports clk]
# set_property IOSTANDARD LVCMOS33            [get_ports clk]

##############################
# for extract the Fmax:
##############################

# set clk_period [get_property PERIOD [get_clocks -of_objects [get_ports clk]]]
# set wns [get_property SLACK [get_timing_paths -max_paths 1 -setup]]
# set min_period [expr {$clk_period - $wns}]
# set fmax [expr {1000.0 / $min_period}]

# puts "==========================================="
# puts "Target Clock : $clk_period ns ([expr {1000.0/$clk_period}] MHz)"
# puts "WNS (Slack)  : $wns ns"
# puts "Min Period   : $min_period ns"
# puts "Max Freq     : [format "%.2f" $fmax] MHz"
# puts "==========================================="


##############################

create_clock -period 10.000 -name CLK_100MHz  [get_ports clk]

# LEDs
# set_property PACKAGE_PIN R19                [get_ports led1]
# set_property IOSTANDARD LVCMOS33            [get_ports led1]

# set_property PACKAGE_PIN V13                [get_ports led2]
# set_property IOSTANDARD LVCMOS33            [get_ports led2]

# set_property PACKAGE_PIN <LED1_PIN>         [get_ports done]
# set_property IOSTANDARD LVCMOS33            [get_ports done]

# set_property PACKAGE_PIN <LED2_PIN>         [get_ports busy]
# set_property IOSTANDARD LVCMOS33            [get_ports busy]

# Buttons
# set_property PACKAGE_PIN G14                [get_ports key1]
# set_property IOSTANDARD LVCMOS33            [get_ports key1]

# set_property PACKAGE_PIN J15                [get_ports key2]
# set_property IOSTANDARD LVCMOS33            [get_ports key2]

# set_property PACKAGE_PIN <BUTTON1_PIN>      [get_ports rst]
# set_property IOSTANDARD LVCMOS33            [get_ports rst]

# set_property PACKAGE_PIN <BUTTON2_PIN>      [get_ports start]
# set_property IOSTANDARD LVCMOS33            [get_ports start]