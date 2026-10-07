# cdc_two_flop_sync 波形回放：显示异步输入、两级同步寄存器和对外输出。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Clock_Reset
gui_list_add_signal -id Wave.1 -group Clock_Reset -signal {tb.dst_clk tb.dst_rst_n}
gui_list_set_color -id Wave.1 -color yellow -signal {tb.dst_clk tb.dst_rst_n}
gui_list_add_group -id Wave.1 -name Async_Control
gui_list_add_signal -id Wave.1 -group Async_Control -signal {tb.async_in tb.dut.async_in}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.async_in tb.dut.async_in}
gui_list_add_group -id Wave.1 -name Synchronizer_Stages
gui_list_add_signal -id Wave.1 -group Synchronizer_Stages -signal {tb.dut.sync_stage1_q tb.dut.sync_stage2_q}
gui_list_set_color -id Wave.1 -color orange -signal {tb.dut.sync_stage1_q tb.dut.sync_stage2_q}
gui_list_add_group -id Wave.1 -name Output_Check
gui_list_add_signal -id Wave.1 -group Output_Check -signal {tb.sync_out tb.dut.sync_out tb.errors}
gui_list_set_color -id Wave.1 -color green -signal {tb.sync_out tb.dut.sync_out}
gui_list_set_color -id Wave.1 -color purple -signal {tb.errors}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
