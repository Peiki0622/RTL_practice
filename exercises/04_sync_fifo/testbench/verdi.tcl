# sync_fifo 波形回放脚本。
# 每个路径均为 tb 或 tb.dut 的真实端口/scoreboard 信号，可共用于两种 RTL。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Clock_Reset
gui_list_add_signal -id Wave.1 -group Clock_Reset -signal {tb.clk tb.rst_n}
gui_list_set_color -id Wave.1 -color yellow -signal {tb.clk tb.rst_n}
gui_list_add_group -id Wave.1 -name Read_Write_Control
gui_list_add_signal -id Wave.1 -group Read_Write_Control -signal {tb.wr_en tb.rd_en tb.dut.wr_en tb.dut.rd_en}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.wr_en tb.rd_en tb.dut.wr_en tb.dut.rd_en}
gui_list_add_group -id Wave.1 -name Data
gui_list_add_signal -id Wave.1 -group Data -signal {tb.wr_data tb.rd_data tb.dut.wr_data tb.dut.rd_data}
gui_list_set_color -id Wave.1 -color green -signal {tb.wr_data tb.rd_data tb.dut.wr_data tb.dut.rd_data}
gui_list_add_group -id Wave.1 -name Status_And_Check
gui_list_add_signal -id Wave.1 -group Status_And_Check -signal {tb.full tb.empty tb.dut.full tb.dut.empty tb.exp_count}
gui_list_set_color -id Wave.1 -color red -signal {tb.full tb.empty tb.dut.full tb.dut.empty}
gui_list_set_color -id Wave.1 -color purple -signal {tb.exp_count}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
