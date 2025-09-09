module i2c_rx(
    input logic rst_p,
    input logic CLK100MHZ,

    input logic i_scl_low_edge_detect,
    input logic i_scl,
    input logic i_scl_rising_edge_detect,

    input logic i_rx_begin,   // Comes from rx_begin in the master module
    input logic i_sda,

    output logic [7:0] o_temp_data,
    output logic o_sda,
    output logic o_byte_complete
    );

    typedef enum logic [3:0] { 
    IDLE,
    BIT7,
    BIT6,
    BIT5,
    BIT4,
    BIT3,
    BIT2,
    BIT1,
    BIT0,
    ACK
    } e_state;

    e_state state, nextstate;
    

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if(rst_p) begin
            state <= IDLE;
        end else begin
            state <= nextstate;
        end
    end


    /////////////////////////////////////////////////////
    always_comb begin
        nextstate = state;
        case (state)
            IDLE: if (i_rx_begin)
                    nextstate = BIT7;
            BIT7: if (i_scl_low_edge_detect)
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
                    nextstate = ACK;
            ACK:  if (i_scl_low_edge_detect)
                    nextstate = IDLE;

            default: nextstate = IDLE;
        endcase    
    end

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            o_temp_data <= 0;
            o_sda <= 1;
            o_byte_complete <= 0;
        end else begin
            o_sda <= 1;
            case (state)
                BIT7: begin
                    if (i_scl_rising_edge_detect && (state == BIT7)) begin
                        o_temp_data[7] <= i_sda;
                    end
                end
                BIT6: begin
                    if (i_scl_rising_edge_detect && (state == BIT6)) begin
                        o_temp_data[6] <= i_sda;
                    end
                end
                BIT5: begin
                    if (i_scl_rising_edge_detect && (state == BIT5)) begin
                        o_temp_data[5] <= i_sda;
                    end
                end
                BIT4: begin
                    if (i_scl_rising_edge_detect && (state == BIT4)) begin
                        o_temp_data[4] <= i_sda;
                    end
                end
                BIT3: begin
                    if (i_scl_rising_edge_detect && (state == BIT3)) begin
                        o_temp_data[3] <= i_sda;
                    end
                end
                BIT2: begin
                    if (i_scl_rising_edge_detect && (state == BIT2)) begin
                        o_temp_data[2] <= i_sda;
                    end
                end
                BIT1: begin
                    if (i_scl_rising_edge_detect && (state == BIT1)) begin
                        o_temp_data[1] <= i_sda;
                    end
                end
                BIT0: begin
                    if (i_scl_rising_edge_detect && (state == BIT0)) begin
                        o_temp_data[0] <= i_sda;
                    end
                end
                ACK: begin
                    o_sda <= 0;     
                end
            endcase
        end
    end

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            o_byte_complete <= 0;
        end else begin
            o_byte_complete <= ((state == ACK) && i_scl_low_edge_detect);
        end
    end

endmodule