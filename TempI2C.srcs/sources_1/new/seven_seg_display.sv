module seven_seg_display #(
    parameter CLKDIVIDER = 100_000
    )(
    input logic CLK100MHZ,
    input logic rst_p,

    input logic [15:0] i_temp_data,
    input logic i_tx_error,

    output logic [7:0] AN,
    output logic [7:0] sevenSeg
    );

    logic [$clog2(CLKDIVIDER)-1:0] clk_counter;
    logic [1:0] r_digit_sel;

    logic signed [15:0] data_before_math;
    logic signed [31:0] temp_in_celc;
    logic signed [31:0] temp_in_F; 
    logic [3:0] temp_thousands;
    logic [3:0] temp_hundreds; 
    logic [3:0] temp_tens;     
    logic [3:0] temp_ones;     

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            clk_counter <= 0;
            r_digit_sel <= 0;
            data_before_math <= 0;
        end else begin
            clk_counter <= clk_counter + 1;
            if (clk_counter == CLKDIVIDER) begin
                r_digit_sel <= r_digit_sel + 1;
                data_before_math <= i_temp_data;
                clk_counter <= 0;
            end 
        end
    end

    assign temp_in_celc = (data_before_math * 100 / 128); // * 100 for decimal accuracy  
    assign temp_in_F = ((temp_in_celc * 9) / 5) + 3200;   // * 100 for decimal accuracy

    always_comb begin
        temp_thousands = (temp_in_F / 1000) % 10;
        temp_hundreds  = (temp_in_F / 100) % 10;
        temp_tens      = (temp_in_F / 10) % 10;
        temp_ones      = (temp_in_F / 1) % 10;
    end

    always_comb begin
        case (r_digit_sel)
            0: begin
                AN = 8'b0111_1111;
                sevenSeg = digit_to_7seg(temp_thousands); // MSB bit
            end
            1: begin
                AN = 8'b1011_1111;
                sevenSeg = digit_to_7seg(temp_hundreds); // Plus 1 for decimal point
                sevenSeg[7] = 0;
            end
            2: begin 
                AN = 8'b1101_1111;
                sevenSeg = digit_to_7seg(temp_tens); 
            end
            3: begin 
                AN = 8'b1110_1111;
                sevenSeg = digit_to_7seg(temp_ones); // LSB bit
            end
        endcase
    end

    function [7:0] digit_to_7seg(input [3:0] digit_spot);
        case (digit_spot)
            0: digit_to_7seg = 8'b1100_0000;          
            1: digit_to_7seg = 8'b1111_1001;    //
            2: digit_to_7seg = 8'b1010_0100;    
            3: digit_to_7seg = 8'b1011_0000;    //
            4: digit_to_7seg = 8'b1001_1001;    //
            5: digit_to_7seg = 8'b1001_0010;    //
            6: digit_to_7seg = 8'b1000_0010;    //
            7: digit_to_7seg = 8'b1111_1000;    
            8: digit_to_7seg = 8'b1000_0000;    //
            9: digit_to_7seg = 8'b1001_1000;    //
            default: digit_to_7seg = 8'b1111_1111; // Blank
        endcase
    endfunction

endmodule
