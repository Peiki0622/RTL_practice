# cdc_pulse_sync 波形回放：分组展示源事件编码、目标同步链和事件计数检查。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Clocks_Resets
gui_list_add_signal -id Wave.1 -group Clocks_Resets -signal {tb.src_clk tb.src_rst_n tb.dst_clk tb.dst_rst_n}
gui_list_set_color -id Wave.1 -color yellow -signal {tb.src_clk tb.src_rst_n tb.dst_clk tb.dst_rst_n}
gui_list_add_group -id Wave.1 -name Event_Control
gui_list_add_signal -id Wave.1 -group Event_Control -signal {tb.src_pulse tb.dst_pulse tb.dut.src_pulse tb.dut.dst_pulse}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.src_pulse tb.dut.src_pulse}
gui_list_set_color -id Wave.1 -color green -signal {tb.dst_pulse tb.dut.dst_pulse}
gui_list_add_group -id Wave.1 -name CDC_State
gui_list_add_signal -id Wave.1 -group CDC_State -signal {tb.dut.src_toggle_q tb.dut.dst_sync_stage1_q tb.dut.dst_sync_stage2_q tb.dut.dst_sync_delay_q}
gui_list_set_color -id Wave.1 -color orange -signal {tb.dut.src_toggle_q tb.dut.dst_sync_stage1_q tb.dut.dst_sync_stage2_q tb.dut.dst_sync_delay_q}
gui_list_add_group -id Wave.1 -name Event_Check
gui_list_add_signal -id Wave.1 -group Event_Check -signal {tb.expected_events tb.observed_events tb.errors}
gui_list_set_color -id Wave.1 -color purple -signal {tb.expected_events tb.observed_events tb.errors}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
