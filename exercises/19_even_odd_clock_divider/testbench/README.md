# Testbench 目录

此目录保存该题共用的 SystemVerilog（系统级硬件描述与验证语言）自检测试平台与 Verdi（波形调试工具）回放脚本。

- `tb_even_odd_clock_divider.sv` 同时用于 `golden/` 与 `practice/`。
- 默认参数使用偶数 6 分频、奇数 5 分频。
- 自动检查异步复位、复位后启动相位、偶数分频半周期、奇数分频半周期与 50% 占空比。
- `verdi.tcl` 只使用冻结端口路径，不依赖参考实现内部信号。
