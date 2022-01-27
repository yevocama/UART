# create modelsim working library
vlib work

# compile all the Verilog sources
vlog ../rtl/uart_tx.v
vlog ../rtl/uart_rx.v
vlog top_tb.v

# open the testbench module for simulation
vsim top_tb

# TX signals
add wave /top_tb/clk
add wave /top_tb/areset
add wave /top_tb/tx_data_valid
add wave -radix hex /top_tb/tx_byte
add wave /top_tb/tx_busy
add wave /top_tb/tx_done
add wave /top_tb/tx_serial

# RX signals
add wave -radix hex /top_tb/rx_byte
add wave /top_tb/rx_busy
add wave /top_tb/rx_valid

# TX state
add wave -radix unsigned /top_tb/uart_tx/state
add wave -radix unsigned /top_tb/uart_tx/next_state
add wave -radix unsigned /top_tb/uart_tx/next_bit

# RX state
add wave -radix unsigned /top_tb/uart_rx/state
add wave -radix unsigned /top_tb/uart_rx/next_state
run -all
wave zoom full
