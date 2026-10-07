# parameterized_counter 波形回放脚本。
# 信号路径均为当前 tb/dut 的真实层次；同一脚本可用于 golden 与 practice。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Clock_Reset
gui_list_add_signal -id Wave.1 -group Clock_Reset -signal {tb.clk tb.rst_n}
gui_list_set_color -id Wave.1 -color yellow -signal {tb.clk tb.rst_n}
gui_list_add_group -id Wave.1 -name Control
gui_list_add_signal -id Wave.1 -group Control -signal {tb.enable tb.dut.enable}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.enable tb.dut.enable}
gui_list_add_group -id Wave.1 -name Count_Status
gui_list_add_signal -id Wave.1 -group Count_Status -signal {tb.count tb.wrap tb.dut.count tb.dut.wrap}
gui_list_set_color -id Wave.1 -color orange -signal {tb.count tb.wrap tb.dut.count tb.dut.wrap}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
