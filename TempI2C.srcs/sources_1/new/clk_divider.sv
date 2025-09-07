// Clock divider from 100MHz to ~350kHz
module clk_divider #(
    parameter int CLK_HALF_PERIOD = 143
    )(
    input logic CLK100MHZ,
    input logic rst_p,
    input logic i_enable,   //From tx mod 

    output logic o_tick
    );

    logic [$clog2(CLK_HALF_PERIOD):0] scl_counter;

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

endmodule