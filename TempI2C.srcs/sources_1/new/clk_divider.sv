// Clock divider from 100MHz to ~350kHz

module clk_divider #(
    parameter int CLK_HALF_PERIOD = 143
    )(
    input logic CLK100MHZ,
    input logic rst_p,
    input logic i_enable,

    output logic o_tick,
    output logic o_scl,
    output logic o_scl_low_edge_detect
    );

    typedef enum logic [1:0] { IDLE, LOW_EDGE_DETECT, SCL_LOW } state_t;

    logic [$clog2(CLK_HALF_PERIOD):0] scl_counter;
    state_t state;

    // Divider with counter
    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p || ~i_enable) begin
            o_tick        <= 0;
            scl_counter   <= 0;
        end else begin
            if (scl_counter == CLK_HALF_PERIOD-1) begin
                scl_counter   <= 0;
                o_tick        <= 1;
            end else begin
                scl_counter   <= scl_counter + 1;
                o_tick        <= 0;
            end
        end
    end


    // phase: 0 = low half, 1 = high half
    logic phase;
    logic oe_low;
    
    // Toggle phase each tick while enabled; idle released high when not enabled
    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p || ~i_enable)
            phase <= 1'b1;       // idle high
        else if (o_tick)
            phase <= ~phase;
    end

    // Method to detect falling edge
    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p || ~i_enable) begin
            state <= IDLE;
        end else begin
            if ((state == IDLE) && ~o_scl) begin
                state <= LOW_EDGE_DETECT;
            end else if (state == LOW_EDGE_DETECT) begin
                state <= SCL_LOW;
            end else if ((state == SCL_LOW) && o_scl) begin
                state <= IDLE;
            end
        end
    end

    // Assign value to edge detect flag
    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            o_scl_low_edge_detect <= 0;
        end else
            o_scl_low_edge_detect <= (state == LOW_EDGE_DETECT);
    end

    // oe_low is when enable == 1 and SCL is low   
    // o_scl is SCL clock according to divider   
    assign oe_low   = (i_enable && ~phase);
    assign o_scl    = oe_low ? 1'b0 : 1'b1;

endmodule