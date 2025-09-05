
module I2C_Master(
    input logic rst_p,
    input logic CLK100MHZ,

    inout logic SDA,
    input logic i_tick,
    input logic i_scl,

    input logic [7:0] data,
    input logic data_begin,
    
    output logic o_enable_count 
    );

    logic [3:0] r_data_count; 

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin      // Shifting out bits
        if (~i_scl) begin
            
        end
    end

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin       // Sampling bits 
        if (rst_p) begin
            state <= IDLE;
        end else begin
        case (state)
            IDLE: begin
                SCL <= 1;
                SDA <= 1;
                r_data_count <= 0;
                if (data_begin) begin
                    SDA <= 0;
                    state <= STATE2;
                end
            end

            STATE2: begin
                SCL <= 0;
                o_enable_count <= 1;
            end

            STATE3: begin
                if (i_tick && SCL == 0) begin
                    SDA <= data[r_data_count];  //Command we are sending OUT
                    r_data_count <= r_data_count + 1;
                end
            end



            default : state <= IDLE;
        endcase
        end
    end

endmodule