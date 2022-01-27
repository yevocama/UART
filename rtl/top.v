module top(
    input        clk,
    input        reset,
    input        sw,
    input        rx_line,
    output       tx_line,
    output [7:0] leds_out
);

    reg  [1:0] tx_data_valid;
    always @(posedge clk or negedge reset) begin
        if(!reset)
            tx_data_valid <= 0;
        else begin
            tx_data_valid <= {tx_data_valid[0], sw};
        end
    end

    wire tx_data_valid_edge = sw & (!tx_data_valid[1]);

    wire [7:0] rx_buff;
    uart_rx 
    #(
        .CLK_FREQ   (50_000_000),
        .BAUD_RATE  (115200    ),
        .DATA_WIDTH (8         )
    ) uart_rx_inst (
        .clk     (clk    ),
        .areset  (reset  ),
        .rx_data (rx_line),
        .rx_byte (rx_buff),
        .rx_valid(       ),
        .rx_busy (       )
);

    uart_tx 
    #(
        .CLK_FREQ   (50_000_000),
        .BAUD_RATE  (115200    ),
        .DATA_WIDTH (8         )
    ) uart_tx_inst (
        .clk          (clk               ),
        .areset       (reset             ),
        .tx_data_valid(tx_data_valid_edge),
        .tx_byte      (rx_buff           ),
        .tx_busy      (                  ),
        .tx_serial    (tx_line           ),
        .tx_done      (                  )
    );

    assign leds_out = rx_buff;

endmodule