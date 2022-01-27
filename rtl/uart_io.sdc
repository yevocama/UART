create_clock -name uart_baud_115200 -period 8700.000 -waveform {0 4350}
create_clock -name clk_in -period 20.000 -waveform {0 10}
# RX Line
set_input_delay -clock {uart_baud_115200} -min 0 [get_ports {rx_line}]
set_input_delay -clock {uart_baud_115200} -max 0 [get_ports {rx_line}]
# TX line
set_output_delay -clock {uart_baud_115200} -min 0 [get_ports {tx_line}]
set_output_delay -clock {uart_baud_115200} -max 0 [get_ports {tx_line}]
