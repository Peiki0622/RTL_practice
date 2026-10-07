# async_fifo 波形回放：显示双时钟控制、握手、二进制/Gray 指针和 scoreboard。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Clocks_Resets
gui_list_add_signal -id Wave.1 -group Clocks_Resets -signal {tb.wr_clk tb.wr_rst_n tb.rd_clk tb.rd_rst_n}
gui_list_set_color -id Wave.1 -color yellow -signal {tb.wr_clk tb.wr_rst_n tb.rd_clk tb.rd_rst_n}
gui_list_add_group -id Wave.1 -name Handshake_Control
gui_list_add_signal -id Wave.1 -group Handshake_Control -signal {tb.wr_valid tb.wr_ready tb.rd_valid tb.rd_ready tb.dut.wr_valid tb.dut.wr_ready tb.dut.rd_valid tb.dut.rd_ready}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.wr_valid tb.wr_ready tb.rd_valid tb.rd_ready tb.dut.wr_valid tb.dut.wr_ready tb.dut.rd_valid tb.dut.rd_ready}
gui_list_add_group -id Wave.1 -name Data
gui_list_add_signal -id Wave.1 -group Data -signal {tb.wr_data tb.rd_data tb.dut.wr_data tb.dut.rd_data}
gui_list_set_color -id Wave.1 -color green -signal {tb.wr_data tb.rd_data tb.dut.wr_data tb.dut.rd_data}
gui_list_add_group -id Wave.1 -name Pointers
gui_list_add_signal -id Wave.1 -group Pointers -signal {tb.dut.wr_bin_q tb.dut.wr_gray_q tb.dut.rd_bin_q tb.dut.rd_gray_q tb.dut.rd_gray_sync2_q tb.dut.wr_gray_sync2_q}
gui_list_set_color -id Wave.1 -color orange -signal {tb.dut.wr_bin_q tb.dut.wr_gray_q tb.dut.rd_bin_q tb.dut.rd_gray_q tb.dut.rd_gray_sync2_q tb.dut.wr_gray_sync2_q}
gui_list_add_group -id Wave.1 -name Status
gui_list_add_signal -id Wave.1 -group Status -signal {tb.dut.wr_full_q tb.dut.rd_empty_q tb.dut.wr_fire tb.dut.rd_fire}
gui_list_set_color -id Wave.1 -color red -signal {tb.dut.wr_full_q tb.dut.rd_empty_q tb.dut.wr_fire tb.dut.rd_fire}
gui_list_add_group -id Wave.1 -name Scoreboard
gui_list_add_signal -id Wave.1 -group Scoreboard -signal {tb.expected_write_sequence tb.expected_read_sequence tb.stall_active tb.stalled_data tb.write_monitor_errors tb.read_monitor_errors tb.stimulus_errors}
gui_list_set_color -id Wave.1 -color purple -signal {tb.expected_write_sequence tb.expected_read_sequence tb.stall_active tb.stalled_data tb.write_monitor_errors tb.read_monitor_errors tb.stimulus_errors}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
