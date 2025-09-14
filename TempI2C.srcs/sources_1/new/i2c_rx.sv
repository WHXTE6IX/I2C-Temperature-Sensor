module i2c_rx#(
    parameter MEASUREMENT_TIMER = 24_000_000
    )(
    input logic rst_p,
    input logic CLK100MHZ,

    input logic i_scl_low_edge_detect,
    input logic i_scl_rising_edge_detect,

    input logic i_rx_begin,   // Comes from rx_begin in the master module
    input logic i_sda,

    output logic [15:0] o_temp_data,
    output logic o_sda,
    output logic o_byte_complete
    );

    typedef enum logic [4:0] { 
    IDLE,
    BIT15,
    BIT14,
    BIT13,
    BIT12,
    BIT11,
    BIT10,
    BIT9,
    BIT8,
    BIT7,
    BIT6,
    BIT5,
    BIT4,
    BIT3,
    BIT2,
    BIT1,
    BIT0,
    ACK,
    WAITPERIOD,
    DATADONE
    } e_state;

    // 240 ms timer for sensor to regather data
    logic [$clog2(MEASUREMENT_TIMER):0] r_measurement_timer;
    logic [15:0] r_temp_data;
    logic r_begin_again;

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
            IDLE: if (i_rx_begin)
                    nextstate = BIT15;
            BIT15: if (i_scl_low_edge_detect)
                    nextstate = BIT14;
            BIT14: if (i_scl_low_edge_detect)
                    nextstate = BIT13;
            BIT13: if (i_scl_low_edge_detect)
                    nextstate = BIT12;
            BIT12: if (i_scl_low_edge_detect)
                    nextstate = BIT11;
            BIT11: if (i_scl_low_edge_detect)
                    nextstate = BIT10;
            BIT10: if (i_scl_low_edge_detect)
                    nextstate = BIT9;
            BIT9: if (i_scl_low_edge_detect)
                    nextstate = BIT8;
            BIT8: if (i_scl_low_edge_detect)
                    nextstate = ACK;
            ACK:  if (i_scl_low_edge_detect)
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
                    nextstate = DATADONE;
            DATADONE: if (i_scl_low_edge_detect)
                    nextstate = WAITPERIOD;
            WAITPERIOD: if (r_begin_again && i_scl_low_edge_detect)
                    nextstate = IDLE; 
            default: nextstate = IDLE;
        endcase    
    end

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            o_temp_data <= 0;
            r_temp_data <= 0;
            o_sda <= 1;
            r_begin_again <= 0;
            r_measurement_timer <= 0;
        end else begin
            case (state)
                IDLE: o_byte_complete <= 0;
                BIT15: begin
                    o_sda <= 1;
                    if (i_scl_rising_edge_detect && (state == BIT15))
                        r_temp_data[15] <= i_sda;
                        r_begin_again <= 0;
                        r_measurement_timer <= 0;
                end
                BIT14: if (i_scl_rising_edge_detect && (state == BIT14))
                        r_temp_data[14] <= i_sda;
                BIT13: if (i_scl_rising_edge_detect && (state == BIT13))
                        r_temp_data[13] <= i_sda;
                BIT12: if (i_scl_rising_edge_detect && (state == BIT12))
                        r_temp_data[12] <= i_sda;
                BIT11: if (i_scl_rising_edge_detect && (state == BIT11))
                        r_temp_data[11] <= i_sda;
                BIT10: if (i_scl_rising_edge_detect && (state == BIT10))
                        r_temp_data[10] <= i_sda;
                BIT9: if (i_scl_rising_edge_detect && (state == BIT9))
                        r_temp_data[9] <= i_sda;
                BIT8: if (i_scl_rising_edge_detect && (state == BIT8))
                        r_temp_data[8] <= i_sda;
                ACK: o_sda <= 0;
                BIT7: begin
                    o_sda <= 1;
                    if (i_scl_rising_edge_detect && (state == BIT7))
                        r_temp_data[7] <= i_sda;
                end
                BIT6: if (i_scl_rising_edge_detect && (state == BIT6))
                        r_temp_data[6] <= i_sda;
                BIT5: if (i_scl_rising_edge_detect && (state == BIT5))
                        r_temp_data[5] <= i_sda;
                BIT4: if (i_scl_rising_edge_detect && (state == BIT4))
                        r_temp_data[4] <= i_sda;
                BIT3: if (i_scl_rising_edge_detect && (state == BIT3))
                        r_temp_data[3] <= i_sda;
                BIT2: if (i_scl_rising_edge_detect && (state == BIT2))
                        r_temp_data[2] <= i_sda;
                BIT1: if (i_scl_rising_edge_detect && (state == BIT1))
                        r_temp_data[1] <= i_sda;
                BIT0: if (i_scl_rising_edge_detect && (state == BIT0))
                        r_temp_data[0] <= i_sda;
                DATADONE: begin
                    o_temp_data <= r_temp_data;
                    o_sda <= 1;
                end
                WAITPERIOD: begin
                    // Begin 240 ms wait time
                    o_sda <= 1;
                    r_temp_data <= 0;
                    r_measurement_timer <= r_measurement_timer + 1;
                    if (r_measurement_timer > MEASUREMENT_TIMER) begin
                        r_begin_again <= 1;
                        r_measurement_timer <= 0;
                        o_byte_complete <= 1;   
                    end
                end                    
            endcase
        end
    end
endmodule