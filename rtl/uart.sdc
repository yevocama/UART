create_clock -name sys_clk_50M -period 20.000 -waveform {0 10} [get_ports {clk}]
derive_clock_uncertainty