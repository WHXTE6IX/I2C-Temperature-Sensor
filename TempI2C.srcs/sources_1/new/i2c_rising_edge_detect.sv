module i2c_rising_edge_detect(
    input logic CLK100MHZ,
    input logic rst_p,
    input logic i_enable_count,
    input logic i_tick,
    input logic i_scl,

    (* mark_debug = "true", keep = "true" *) output logic o_scl_rising_edge_detect
    );


    typedef enum logic [1:0] { IDLE, RISING_EDGE_DETECT, SCL_HIGH } state_t;
    
    state_t state;
    
    logic phase;
    
    // Toggle phase each tick while enabled; idle released high when not enabled
    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p || ~i_enable_count)
            phase <= 1'b1;       // idle high
        else if (i_tick)
            phase <= ~phase;
    end
    
    // Method to detect rising edge
    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p || ~i_enable_count) begin
            state <= IDLE;
        end else begin
            if ((state == IDLE) && i_scl) begin
                state <= RISING_EDGE_DETECT;
            end else if (state == RISING_EDGE_DETECT) begin
                state <= SCL_HIGH;
            end else if ((state == SCL_HIGH) && ~i_scl) begin
                state <= IDLE;
            end
        end
    end

    // Assign value to edge detect flag
    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            o_scl_rising_edge_detect <= 0;
        end else
            o_scl_rising_edge_detect <= (state == RISING_EDGE_DETECT);
    end

endmodule