# round_robin_arbiter：使用实际 FSDB 层级，自动添加分组与颜色。
# Makefile 从 .sim/<variant>/ 启动 Verdi，因此 wave.fsdb 位于当前目录。
set fsdb_file [file normalize wave.fsdb]
if {![file exists $fsdb_file] || [file size $fsdb_file] == 0} {
    error "nWave: missing or empty FSDB: $fsdb_file"
}
foreach command {wvCreateWindow wvGetCurrentWindow wvOpenFile wvGetSignalOpen wvGetSignalClose wvAddSignal wvZoomAll} {
    if {[llength [info commands $command]] == 0} {
        error "nWave: required command unavailable: $command"
    }
}
wvCreateWindow
set wave_window [wvGetCurrentWindow]
wvOpenFile -win $wave_window $fsdb_file
puts "nWave: opened $fsdb_file"
wvGetSignalOpen -win $wave_window

# 颜色通过 W-2024.09 文档支持的 wvAddSignal -color 设置。
# 每组使用固定 literal payload；失败时记录组名，并继续添加其他组。
if {[catch {
    wvAddSignal -win $wave_window -group {Clock_Reset
        {/tb/clk} -height 16 -color ID_YELLOW5
        {/tb/rst_n} -height 16 -color ID_YELLOW5
    }
} message]} { puts "nWave: Clock_Reset add/color failed: $message" }

if {[catch {
    wvAddSignal -win $wave_window -group {Request_Accept_Control
        {/tb/req[2:0]} -height 16 -color ID_CYAN5
        {/tb/grant_accept} -height 16 -color ID_CYAN5
    }
} message]} { puts "nWave: Request_Accept_Control add/color failed: $message" }

if {[catch {
    wvAddSignal -win $wave_window -group {Grant
        {/tb/gnt[2:0]} -height 16 -color ID_GREEN5
    }
} message]} { puts "nWave: Grant add/color failed: $message" }

if {[catch {
    wvAddSignal -win $wave_window -group {Search_Pointers
        {/tb/dut/search_start_q[1:0]} -height 16 -color ID_ORANGE5
        {/tb/dut/granted_index[1:0]} -height 16 -color ID_ORANGE5
    }
} message]} { puts "nWave: Search_Pointers add/color failed: $message" }

if {[catch {
    wvAddSignal -win $wave_window -group {Arbitration_State
        {/tb/dut/grant_found} -height 16 -color ID_RED5
    }
} message]} { puts "nWave: Arbitration_State add/color failed: $message" }

if {[catch {
    wvAddSignal -win $wave_window -group {Expected_Check
        {/tb/expected_start[1:0]} -height 16 -color ID_PURPLE5
        {/tb/expected_gnt[2:0]} -height 16 -color ID_PURPLE5
        {/tb/errors[31:0]} -height 16 -color ID_PURPLE5
    }
} message]} { puts "nWave: Expected_Check add/color failed: $message" }

wvGetSignalClose -win $wave_window
if {[llength [info commands wvSetRadix]] != 0} {
    if {[catch {
        wvSetRadix -win $wave_window -format Dec {/tb/dut/search_start_q[1:0]} {/tb/dut/granted_index[1:0]} {/tb/expected_start[1:0]} {/tb/errors[31:0]}
    } message]} { puts "nWave: decimal radix failed: $message" }
} else {
    puts "nWave: wvSetRadix unavailable; keeping default radix"
}
wvZoomAll -win $wave_window
puts "nWave: zoom target is the full simulation range"
