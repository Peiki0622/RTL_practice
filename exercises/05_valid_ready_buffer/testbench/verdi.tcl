# valid_ready_buffer 波形回放脚本。
# valid-ready 控制、数据和参考模型状态分色显示，便于分析反压与替换行为。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Clock_Reset
gui_list_add_signal -id Wave.1 -group Clock_Reset -signal {tb.clk tb.rst_n}
gui_list_set_color -id Wave.1 -color yellow -signal {tb.clk tb.rst_n}
gui_list_add_group -id Wave.1 -name Handshake_Control
gui_list_add_signal -id Wave.1 -group Handshake_Control -signal {tb.s_valid tb.s_ready tb.m_valid tb.m_ready tb.dut.s_valid tb.dut.s_ready tb.dut.m_valid tb.dut.m_ready}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.s_valid tb.s_ready tb.m_valid tb.m_ready tb.dut.s_valid tb.dut.s_ready tb.dut.m_valid tb.dut.m_ready}
gui_list_add_group -id Wave.1 -name Data
gui_list_add_signal -id Wave.1 -group Data -signal {tb.s_data tb.m_data tb.dut.s_data tb.dut.m_data}
gui_list_set_color -id Wave.1 -color green -signal {tb.s_data tb.m_data tb.dut.s_data tb.dut.m_data}
gui_list_add_group -id Wave.1 -name Expected_Check
gui_list_add_signal -id Wave.1 -group Expected_Check -signal {tb.exp_valid tb.exp_data}
gui_list_set_color -id Wave.1 -color purple -signal {tb.exp_valid tb.exp_data}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
