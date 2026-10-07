# sequence_detector 波形回放脚本。
# 端口按时钟复位、串行控制和匹配状态分类，适用于两种被测实现目录。
gui_open_window -type Wave
gui_list_add_group -id Wave.1 -name Clock_Reset
gui_list_add_signal -id Wave.1 -group Clock_Reset -signal {tb.clk tb.rst_n}
gui_list_set_color -id Wave.1 -color yellow -signal {tb.clk tb.rst_n}
gui_list_add_group -id Wave.1 -name Serial_Input
gui_list_add_signal -id Wave.1 -group Serial_Input -signal {tb.bit_in tb.dut.bit_in}
gui_list_set_color -id Wave.1 -color cyan -signal {tb.bit_in tb.dut.bit_in}
gui_list_add_group -id Wave.1 -name Match_Status
gui_list_add_signal -id Wave.1 -group Match_Status -signal {tb.match tb.dut.match}
gui_list_set_color -id Wave.1 -color red -signal {tb.match tb.dut.match}
gui_list_expand -id Wave.1
gui_list_zoom -id Wave.1 -full
