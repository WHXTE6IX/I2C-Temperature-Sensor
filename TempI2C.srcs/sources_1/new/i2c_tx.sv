module i2c_tx(
    input logic rst_p,
    input logic CLK100MHZ,

    input logic i_scl_low_edge_detect,
    input logic i_scl,
    input logic i_scl_rising_edge_detect,

    (* mark_debug = "true", keep = "true" *) input logic [7:0] i_data_command,
    input logic i_tx_begin,
    input logic i_initiate_repeated_start,
    (* mark_debug = "true", keep = "true" *) input logic i_sda,

    input logic i_stop_flag, // Comes from master mod

    (* mark_debug = "true", keep = "true" *) output logic o_sda,
    output logic o_enable_count,
    output logic o_tx_error,
    (* mark_debug = "true", keep = "true" *) output logic o_ack_complete,
    output logic o_stop_complete
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
    RW,
    ACK,
    STOP,
    REPEATED_START
    } e_state;

    (* mark_debug = "true", keep = "true" *) e_state state;
    e_state nextstate;
    logic repeated_start_success;
    

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
            IDLE: begin
                if (i_tx_begin)
                    nextstate = START;
                else if (i_scl_low_edge_detect && i_stop_flag)
                    nextstate = STOP;
            end
            START: if (i_scl_low_edge_detect)
                    nextstate = BIT6;
            BIT6:begin 
                if (i_stop_flag)
                    nextstate = STOP;
                else if (i_scl_low_edge_detect)
                    nextstate = BIT5;
            end
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
            RW:   if (i_scl_low_edge_detect)
                    nextstate = ACK;
            ACK: begin 
                if (i_scl_low_edge_detect)
                    nextstate = BIT6;
                else if (i_initiate_repeated_start)
                    nextstate = REPEATED_START;
            end
            STOP: if (o_stop_complete)
                    nextstate = IDLE;
            REPEATED_START: if (repeated_start_success)
                nextstate = BIT6;
            default: nextstate = IDLE;
        endcase    
    end

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            o_sda           <= 1;
            o_ack_complete  <= 0;
            o_tx_error      <= 0;
            o_enable_count  <= 0;
        end else begin
            o_ack_complete  <= 0;
            o_tx_error      <= 0;
            case (state)
                IDLE: begin
                    o_sda           <= 1;
                    o_ack_complete  <= 0;
                    o_tx_error      <= 0;
                    o_stop_complete <= 0;
                    repeated_start_success <= 0;
                end
                START: begin
                    o_sda <= 0;
                    o_enable_count <= 1;
                end 
                BIT6:   o_sda <= i_data_command[7]; 
                BIT5:   o_sda <= i_data_command[6]; 
                BIT4:   o_sda <= i_data_command[5]; 
                BIT3:   o_sda <= i_data_command[4]; 
                BIT2:   o_sda <= i_data_command[3]; 
                BIT1:   o_sda <= i_data_command[2]; 
                BIT0:   o_sda <= i_data_command[1]; 
                RW:     o_sda <= i_data_command[0]; 
                ACK: begin
                    o_sda <= 1; // Release SDA and wait for ack
                    if ((state == ACK) && i_scl_rising_edge_detect && ~i_sda)
                        o_ack_complete <= 1;
                    else if ((state == ACK) && i_scl_rising_edge_detect && i_sda)
                        o_tx_error <= 1; 
                end
                STOP: begin
                    if (i_scl_rising_edge_detect && (state == STOP)) begin
                        o_sda <= 1;
                        o_stop_complete <= 1;
                        o_enable_count <= 0;
                    end
                end
                REPEATED_START: begin 
                    if (i_scl && i_sda) begin
                        // HOLD IT FORA CERTAIN AMOUNT OFG TIME?? 
                    end
                        o_sda <= 0;
                            repeated_start_success <= 1;
                        end
                    end
                end  
                default : o_sda <= 1;
            endcase 
        end
    end
endmodule
