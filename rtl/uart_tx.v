module uart_tx #(
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD_RATE  = 115200,
    parameter DATA_WIDTH = 8
) (
    input                      clk,
    input                      areset,
    input                      tx_data_valid,
    input [DATA_WIDTH - 1 : 0] tx_byte,
    output                     tx_busy,
    output                     tx_serial,
    output                     tx_done
);
    localparam TICKS_PER_BIT = CLK_FREQ / BAUD_RATE;
    localparam COUNT_REG_LEN = 1 + $clog2(TICKS_PER_BIT);

    // States
    localparam [2:0] IDLE_S      = 3'b000,
                     START_BIT_S = 3'b001,
                     DATA_BITS_S = 3'b010,
                     STOP_BIT_S  = 3'b011,
                     CLEANUP_S   = 3'b100;
    
    reg [2:0] state, next_state;
    always @(posedge clk or negedge areset) begin
        if(!areset)
            state <= IDLE_S;
        else
            state <= next_state;
    end

    reg [COUNT_REG_LEN - 1 : 0] ticks_counter;
    wire next_bit = (ticks_counter == TICKS_PER_BIT);
    always @(posedge clk or negedge areset) begin
        if(!areset)
            ticks_counter <= {COUNT_REG_LEN{1'b0}};
        else if (next_bit)
            ticks_counter <= {COUNT_REG_LEN{1'b0}};
        else if(state == START_BIT_S ||
                state == DATA_BITS_S ||
                state == STOP_BIT_S    )
            ticks_counter <= ticks_counter + 1'b1;
    end

    reg [3:0] bit_counter;
    wire data_bits_done = (bit_counter == DATA_WIDTH);
    always @(posedge clk or negedge areset) begin
        if(!areset)
            bit_counter <= {4{1'b0}};
        else if (state == DATA_BITS_S) begin
            if(next_bit) begin
                bit_counter <= bit_counter + 1'b1;
            end
        end
        else if (state != DATA_BITS_S) begin
            bit_counter <= {4{1'b0}};
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE_S     : next_state = tx_data_valid  ? START_BIT_S : IDLE_S;
            START_BIT_S: next_state = next_bit       ? DATA_BITS_S : START_BIT_S;
            DATA_BITS_S: next_state = data_bits_done ? STOP_BIT_S  : DATA_BITS_S;
            STOP_BIT_S : next_state = next_bit       ? CLEANUP_S   : STOP_BIT_S;
            CLEANUP_S  : next_state = IDLE_S;
            default    : next_state = IDLE_S;
        endcase
    end

    assign tx_busy   = !((state == IDLE_S) || (state == CLEANUP_S));
    assign tx_done   =  (state == CLEANUP_S);
    
    assign tx_serial =  (state == DATA_BITS_S) ? 
                        ((bit_counter < DATA_WIDTH) ? tx_byte[bit_counter] : 1'b1) : 
                        ((state == START_BIT_S) ? 1'b0 : 1'b1);

endmodule