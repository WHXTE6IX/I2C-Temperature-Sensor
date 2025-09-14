module i2c_tx(
    input logic rst_p,
    input logic CLK100MHZ,

    input logic i_scl_low_edge_detect,
    input logic i_scl,
    input logic i_scl_rising_edge_detect,
    input logic i_sda,

    input logic [7:0] i_data_command,      // Comes from i2c_master
    input logic i_tx_begin,                // Comes from i2c_master
    input logic i_rx_begin,                // Comes from i2c_master
    input logic i_initiate_repeated_start, // Comes from i2c_master
    input logic i_stop_flag,               // Comes from i2c_master

    output logic o_sda,
    output logic o_enable_count,
    output logic o_tx_error,
    output logic o_ack_complete,
    output logic o_stop_complete,
    output logic o_start_complete
    );

    localparam HOLDTIME = 62;

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

    e_state state, nextstate;
    logic [6:0] r_start_counter;     // 2 60 counts for 0.6us specification
    

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
                else if (i_scl_low_edge_detect && i_stop_flag && ~i_rx_begin)
                    nextstate = STOP;
            end
            START: if (o_start_complete && i_scl_low_edge_detect)
                    nextstate = BIT6;
            BIT6:begin 
                if (i_stop_flag)
                    nextstate = STOP;
                else if (i_initiate_repeated_start)
                    nextstate = REPEATED_START;
                else if (i_rx_begin)
                    nextstate = IDLE;
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
            ACK:  if (i_scl_low_edge_detect)
                    nextstate = BIT6;
            STOP: if (o_stop_complete)
                    nextstate = IDLE;
            REPEATED_START: if (o_start_complete && i_scl_low_edge_detect)
                nextstate = BIT6;
            default: nextstate = IDLE;
        endcase    
    end

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            o_sda             <= 1;
            o_ack_complete    <= 0;
            o_tx_error        <= 0;
            o_enable_count    <= 0;
        end else begin
            o_ack_complete         <= 0;
            o_tx_error             <= 0;
            o_stop_complete        <= 0;
            case (state)
                IDLE: begin
                    o_sda           <= 1;
                    o_ack_complete  <= 0;
                    o_tx_error      <= 0;
                    o_stop_complete <= 0;
                    r_start_counter <= 0;
                end
                START: begin
                    if (i_scl) begin
                        o_enable_count <= 1;    // Start the SCL clock

                        // SDA high for setup time
                        if (r_start_counter < HOLDTIME) begin
                            o_sda <= 1;
                            r_start_counter <= r_start_counter + 1;
                        end 
                        // SDA low for hold time
                        else if (r_start_counter < (HOLDTIME*2)) begin
                            o_sda <= 0;
                            r_start_counter <= r_start_counter + 1;
                        end 
                        else begin
                            o_sda <= 1;
                            o_start_complete <= 1;
                            r_start_counter <= 0;
                        end
                    end
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
                    o_start_complete <= 0;
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
                    if (i_scl) begin
                        // SDA high for setup time
                        if (r_start_counter < HOLDTIME) begin
                            o_sda <= 1;
                            r_start_counter <= r_start_counter + 1;
                        end 
                        // SDA low for hold time
                        else if (r_start_counter < (HOLDTIME*2)) begin
                            o_sda <= 0;
                            r_start_counter <= r_start_counter + 1;
                        end 
                        else begin
                            o_sda <= 1;
                            o_start_complete <= 1;
                            r_start_counter <= 0;
                        end
                    end
                end  
                default : o_sda <= 1;
            endcase 
        end
    end
endmodule