# even_odd_clock_divider 波形回放脚本。
# 只引用冻结端口，确保 golden 与 practice 都能使用同一脚本。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Clock_Reset
gui_list_add_signal -id Wave.1 -group Clock_Reset -signal {tb.clk tb.rst_n}
gui_list_set_color -id Wave.1 -color yellow -signal {tb.clk tb.rst_n}
gui_list_add_group -id Wave.1 -name Divided_Clocks
gui_list_add_signal -id Wave.1 -group Divided_Clocks -signal {tb.clk_div_even tb.clk_div_odd tb.dut.clk_div_even tb.dut.clk_div_odd}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.clk_div_even tb.clk_div_odd}
gui_list_set_color -id Wave.1 -color green -signal {tb.dut.clk_div_even tb.dut.clk_div_odd}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
