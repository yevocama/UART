`timescale 1ns/1ns
`define LOG_SIGNALS
module top_tb;

    localparam DATA_WIDTH = 8;
    // TX signals
    reg                     clk;
    reg                     areset;
    reg                     tx_data_valid;
    reg [DATA_WIDTH -1 : 0] tx_byte;
    wire                    tx_busy;
    wire                    tx_serial;
    wire                    tx_done;
    // RX signals
    wire [DATA_WIDTH - 1 : 0] rx_byte;
    wire                      rx_valid;
    wire                      rx_busy;

    uart_tx uart_tx (
        .clk          (clk          ),
        .areset       (areset       ),
        .tx_data_valid(tx_data_valid),
        .tx_byte      (tx_byte      ),
        .tx_busy      (tx_busy      ),
        .tx_serial    (tx_serial    ),
        .tx_done      (tx_done      )
    );

    uart_rx uart_rx (
        .clk     (clk      ),
        .areset  (areset   ),
        .rx_data (tx_serial),
        .rx_byte (rx_byte  ),
        .rx_valid(rx_valid ),
        .rx_busy (rx_busy  )
    );

    always #10 clk = ~clk;

    task areset_task;
        begin
            areset = 1'b1;
            #40;
            areset = 1'b0;
            #100;
            areset = 1'b1;
        end
    endtask

    task send_byte;
        input [DATA_WIDTH - 1 : 0] byte;
        begin
            @(negedge tx_busy)
            tx_byte       = byte;
            tx_data_valid = 1'b1;
            @(posedge clk)
            tx_data_valid = 1'b0;
        end
    endtask

    `ifdef LOG_SIGNALS
        // Internal DUT signals
        wire [3:0]                           state          = uart_rx.state;
        wire [3:0]                           next_state     = uart_rx.next_state;
        wire [uart_tx.COUNT_REG_LEN - 1 : 0] ticks_counter  = uart_tx.ticks_counter;
        wire                                 next_bit       = uart_tx.next_bit;
        wire [3:0]                           bit_counter    = uart_tx.bit_counter;
        wire                                 data_bits_done = uart_tx.data_bits_done;
        wire                                 rx_data_ff_0   = uart_rx.rx_data_ff[0];
        wire                                 rx_data_ff_1   = uart_rx.rx_data_ff[1];
    `endif

    integer i;
    initial begin
        clk           = 1'b0;
        areset        = 1'b1;
        tx_data_valid = 1'b0;
        tx_byte       = 8'h00;
        i             = 0;
        #20;
        areset_task;
        #100;
        repeat(10) begin
            if(i >= 9) begin
                #2000 $finish;
            end
            @(posedge clk)
            #50;
            tx_data_valid = 1'b1;
            tx_byte       = 8'hAA + i;
            @(posedge clk)
            tx_data_valid = 1'b0;
            @(negedge tx_busy)
            i = i + 1;
        end
    end

    always @(posedge clk) begin
        if(tx_done) begin
            if(rx_byte == tx_byte)
                $display("!! Correct TX byte -> %h RX byte -> %h !!", tx_byte, rx_byte);
            else
                $display("!! WRONG TX byte -> %h RX byte -> %h !!", tx_byte, rx_byte);
        end
    end

endmodule