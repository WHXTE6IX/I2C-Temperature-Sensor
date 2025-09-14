module i2c_falling_edge_detect(
    input logic CLK100MHZ,
    input logic rst_p,
    input logic i_enable_count,
    input logic i_tick,

    output logic o_scl,             // Used as Master-Out SCL bus
    output logic o_scl_low_edge_detect
    );


    typedef enum logic [1:0] { IDLE, LOW_EDGE_DETECT, SCL_LOW } state_t;
    
    state_t state;
    
    logic phase;
    logic oe_low;
    
    // Toggle phase each tick while enabled; idle released high when not enabled
    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p || ~i_enable_count)
            phase <= 1'b1;       // idle high
        else if (i_tick)
            phase <= ~phase;
    end
    
    // Method to detect falling edge
    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p || ~i_enable_count) begin
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

    // oe_low is high when enable == 1 and SCL is low
    // o_scl is SCL clock according to divider   
    assign oe_low             = (i_enable_count && ~phase);
    assign o_scl              = oe_low ? 1'b0 : 1'b1;

endmodule