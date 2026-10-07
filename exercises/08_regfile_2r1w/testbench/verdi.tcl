# regfile_2r1w 波形回放：区分时钟、写控制、读写地址、双读数据与检查状态。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Clock
gui_list_add_signal -id Wave.1 -group Clock -signal {tb.clk}
gui_list_set_color -id Wave.1 -color yellow -signal {tb.clk}
gui_list_add_group -id Wave.1 -name Write_Control
gui_list_add_signal -id Wave.1 -group Write_Control -signal {tb.we tb.dut.we}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.we tb.dut.we}
gui_list_add_group -id Wave.1 -name Addresses
gui_list_add_signal -id Wave.1 -group Addresses -signal {tb.waddr tb.raddr0 tb.raddr1 tb.dut.waddr tb.dut.raddr0 tb.dut.raddr1}
gui_list_set_color -id Wave.1 -color orange -signal {tb.waddr tb.raddr0 tb.raddr1 tb.dut.waddr tb.dut.raddr0 tb.dut.raddr1}
gui_list_add_group -id Wave.1 -name Data
gui_list_add_signal -id Wave.1 -group Data -signal {tb.wdata tb.rdata0 tb.rdata1 tb.dut.wdata tb.dut.rdata0 tb.dut.rdata1}
gui_list_set_color -id Wave.1 -color green -signal {tb.wdata tb.rdata0 tb.rdata1 tb.dut.wdata tb.dut.rdata0 tb.dut.rdata1}
gui_list_add_group -id Wave.1 -name Check_Status
gui_list_add_signal -id Wave.1 -group Check_Status -signal {tb.errors}
gui_list_set_color -id Wave.1 -color purple -signal {tb.errors}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
