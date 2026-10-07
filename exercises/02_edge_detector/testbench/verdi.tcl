# edge_detector 波形回放脚本。
# 输入、脉冲输出及其 dut 端口以不同颜色分组，便于观察每次采样关系。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Clock_Reset
gui_list_add_signal -id Wave.1 -group Clock_Reset -signal {tb.clk tb.rst_n}
gui_list_set_color -id Wave.1 -color yellow -signal {tb.clk tb.rst_n}
gui_list_add_group -id Wave.1 -name Input_Control
gui_list_add_signal -id Wave.1 -group Input_Control -signal {tb.sig_in tb.dut.sig_in}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.sig_in tb.dut.sig_in}
gui_list_add_group -id Wave.1 -name Pulse_Status
gui_list_add_signal -id Wave.1 -group Pulse_Status -signal {tb.rise_pulse tb.fall_pulse tb.dut.rise_pulse tb.dut.fall_pulse}
gui_list_set_color -id Wave.1 -color red -signal {tb.rise_pulse tb.fall_pulse tb.dut.rise_pulse tb.dut.fall_pulse}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
