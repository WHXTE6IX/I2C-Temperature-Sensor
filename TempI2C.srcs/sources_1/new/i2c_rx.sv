
module i2c_rx(
    input logic rst_p,
    input logic CLK100MHZ,

    inout logic SDA,
    input logic i_tick,
    input logic i_scl,

    input logic [7:0] data,
    input logic data_begin,
    
    output logic o_enable_count 
    );
endmodule
