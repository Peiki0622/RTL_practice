# fixed_priority_arbiter 波形回放脚本。
# 请求、实际授权和独立期望授权分组显示，全部信号使用真实 tb/dut 路径。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Request_Control
gui_list_add_signal -id Wave.1 -group Request_Control -signal {tb.req tb.dut.req}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.req tb.dut.req}
gui_list_add_group -id Wave.1 -name Grant_Status
gui_list_add_signal -id Wave.1 -group Grant_Status -signal {tb.gnt tb.dut.gnt}
gui_list_set_color -id Wave.1 -color red -signal {tb.gnt tb.dut.gnt}
gui_list_add_group -id Wave.1 -name Expected_Check
gui_list_add_signal -id Wave.1 -group Expected_Check -signal {tb.expected_gnt}
gui_list_set_color -id Wave.1 -color purple -signal {tb.expected_gnt}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
