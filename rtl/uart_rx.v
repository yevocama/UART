module uart_rx #(
    parameter CLK_FREQ   = 50_000_000,
    parameter BAUD_RATE  = 115200,
    parameter DATA_WIDTH = 8
) (
    input                       clk,
    input                       areset,
    input                       rx_data,
    output [DATA_WIDTH - 1 : 0] rx_byte,
    output                      rx_valid,
    output                      rx_busy
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
        else begin
            state <= next_state;
        end
    end

    reg [1:0] rx_data_ff;
    always @(posedge clk or negedge areset) begin
        if(!areset)
            rx_data_ff <= {2{1'b1}};
        else begin
            rx_data_ff <= {rx_data_ff[0], rx_data};
        end
    end

    reg [COUNT_REG_LEN - 1 : 0] ticks_counter;
    wire next_bit      = (ticks_counter == TICKS_PER_BIT);
    wire next_bit_half = (ticks_counter == (TICKS_PER_BIT >> 1)); 
    always @(posedge clk or negedge areset) begin
        if(!areset)
            ticks_counter <= {COUNT_REG_LEN{1'b0}};
        else if (next_bit) begin
            ticks_counter <= {COUNT_REG_LEN{1'b0}};
        end
        else if (state == START_BIT_S ||
                 state == DATA_BITS_S ||
                 state == STOP_BIT_S    ) begin
            ticks_counter <= ticks_counter + 1'b1;
        end
    end

    reg [3:0] bit_counter;
    wire rx_bits_done = (bit_counter == DATA_WIDTH);
    always @(posedge clk or negedge areset) begin
        if(!areset)
            bit_counter <= {4{1'b0}};
        else if (state == DATA_BITS_S) begin
            if(next_bit)
                bit_counter <= bit_counter + 1'b1;
        end
        else if (state != DATA_BITS_S) begin
            bit_counter <= {4{1'b0}};
        end
    end

    // Next state logic
    always @(*) begin
        next_state = state;
        case(state)
            IDLE_S     : next_state = !rx_data_ff[1] ? START_BIT_S : IDLE_S;
            START_BIT_S: begin
                if(next_bit_half) begin
                    if(!rx_data_ff[1])
                        next_state = DATA_BITS_S;
                    else
                        next_state = IDLE_S;
                end
                else begin
                    next_state = START_BIT_S;
                end
            end
            DATA_BITS_S: next_state = rx_bits_done   ? STOP_BIT_S  : DATA_BITS_S;
            STOP_BIT_S : next_state = next_bit       ? CLEANUP_S   : STOP_BIT_S;
            CLEANUP_S  : next_state = IDLE_S;
            default    : next_state = IDLE_S;
        endcase
    end

    reg [DATA_WIDTH - 1 : 0] rx_data_buff;
    always @(posedge clk or negedge areset) begin
        if(!areset)
            rx_data_buff <= {DATA_WIDTH{1'b0}};
        else begin
            if(state == DATA_BITS_S && next_bit)
                rx_data_buff <= {rx_data_ff[1], rx_data_buff[7:1]};
            else if(state == START_BIT_S)
                rx_data_buff <= {DATA_WIDTH{1'b0}};
        end
    end

    assign rx_byte  = rx_data_buff;
    assign rx_valid = (state == CLEANUP_S);
    assign rx_busy  = !((state == IDLE_S) || (state == CLEANUP_S));

endmodule
