

module i2c_tx(
    input logic rst_p,
    input logic CLK100MHZ,

    input logic i_scl_low_edge_detect,
    input logic i_scl,

    input logic [7:0] i_data,
    input logic tx_begin,


    output logic SDA,
    output logic o_enable_count
    );

    typedef enum logic [3:0] { 
    IDLE,
    START,
    BIT6,
    BIT5,
    BIT4,
    BIT3,
    BIT2,
    BIT1,
    BIT0,
    RW
    } e_state;

    e_state state, nextstate;
    

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if(rst_p) begin
            state <= IDLE;
        end else begin
            state <= nextstate;
        end
    end

    always_comb begin
        nextstate = state;
        case (state)
            IDLE: if (tx_begin)
                    nextstate = START;
            START: if (i_scl)
                    nextstate = BIT6;
            BIT6: if (i_scl_low_edge_detect)
                    nextstate = BIT5;
            BIT5: if (i_scl_low_edge_detect)
                    nextstate = BIT4;
            BIT4: if (i_scl_low_edge_detect)
                    nextstate = BIT3;
            BIT3: if (i_scl_low_edge_detect)
                    nextstate = BIT2;
            BIT2: if (i_scl_low_edge_detect)
                    nextstate = BIT1;
            BIT1: if (i_scl_low_edge_detect)
                    nextstate = BIT0;
            BIT0: if (i_scl_low_edge_detect)
                    nextstate = RW;
            RW: if (i_scl_low_edge_detect)
                    nextstate = IDLE;

            default: nextstate = IDLE;
        endcase    
    end

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p)
            SDA <= 1;
        else begin
            case (state)
                IDLE:   SDA <= 1; 
                START: begin
                    SDA <= 0;
                    o_enable_count <= 1;
                end 
                BIT6:   SDA <= i_data[7]; 
                BIT5:   SDA <= i_data[6]; 
                BIT4:   SDA <= i_data[5]; 
                BIT3:   SDA <= i_data[4]; 
                BIT2:   SDA <= i_data[3]; 
                BIT1:   SDA <= i_data[2]; 
                BIT0:   SDA <= i_data[1]; 
                RW:     SDA <= i_data[0]; 
                default : SDA <= 1;
            endcase 
        end

    end


endmodule
