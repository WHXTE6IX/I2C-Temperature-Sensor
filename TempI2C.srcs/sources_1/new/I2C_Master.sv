
module I2C_Master(
    input logic rst_p,
    input logic CLK100MHZ,

    input logic i_sda,
    input logic i_scl,
      
    input logic i_byte_complete,      // from rx mod
    input logic i_ack_complete,       // from tx module
    input logic i_stop_complete,      // from tx module
    input logic i_scl_low_edge_detect,
    input logic i_repeated_start_complete, // from tx module


    (* mark_debug = "true", keep = "true" *) output logic [7:0] o_data,
    (* mark_debug = "true", keep = "true" *) output logic o_tx_begin,
    (* mark_debug = "true", keep = "true" *) output logic o_stop_flag,
    (* mark_debug = "true", keep = "true" *) output logic o_initiate_repeated_start,
    (* mark_debug = "true", keep = "true" *) output logic o_rx_begin
    );

    localparam CONFIG_REGISTER = 8'h03;
    localparam CONFIG_REGISTER_DATA = 8'b00000001;

    localparam TEMP_VALUE_MSB_REGISTER = 8'h00;
    localparam TEMP_VALUE_LSB_REGISTER = 8'h01;

    localparam SLAVE_ADDRESS = 7'h4B;
    localparam READ = 1'b1;
    localparam WRITE = 1'b0;

    logic [5:0] stop_counter;   // 60 count for 0.6us specification

    typedef enum logic [3:0] { 
    IDLE,                           
    START,                
    WAIT_FOR_ACK,                
    ACK_HOLD,                
    STOP,                
    HOLD_STOP,                
    REPEATED_START,                
    RX_BEGIN                
    } e_state;

    (* mark_debug = "true", keep = "true" *) e_state state;
    (* mark_debug = "true", keep = "true" *) logic [3:0] internal_counter;

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            internal_counter <= 0;
            o_stop_flag <= 0;
            state <= IDLE;
            o_tx_begin <= 0;
            o_rx_begin <= 0;       
        end else begin
            case (state)
                IDLE: begin 
                    o_tx_begin <= 1;
                    state <= START;
                end

                START: begin
                    o_tx_begin  <= 0;
                    o_rx_begin  <= 0;
                    o_stop_flag <= 0;
                    o_initiate_repeated_start <= 0;
                    if (~i_sda) begin
                        if (internal_counter == 0) begin         // Time to start setup data initialization 
                            o_data <= {SLAVE_ADDRESS, WRITE};
                            state  <= WAIT_FOR_ACK;
                        end else if (internal_counter == 1) begin
                            o_data <= {CONFIG_REGISTER};
                            state  <= WAIT_FOR_ACK;
                        end else if (internal_counter == 2) begin
                            o_data <= {CONFIG_REGISTER_DATA};
                            state  <= WAIT_FOR_ACK;
                        end else if (internal_counter == 3) begin
                            state  <= STOP;
                            o_data <= 0;
                        end else if (internal_counter == 4) begin   // Time to start data gathering sequence 
                            o_data <= {SLAVE_ADDRESS, WRITE};
                            state  <= WAIT_FOR_ACK;
                        end else if (internal_counter == 5) begin
                            o_data <= {TEMP_VALUE_MSB_REGISTER};
                            state  <= WAIT_FOR_ACK;
                        end else if (internal_counter == 6) begin
                            state <= REPEATED_START;
                            o_initiate_repeated_start <= 1;                           
                        end else if (internal_counter == 7) begin
                            state <= WAIT_FOR_ACK;
                            o_data <= {SLAVE_ADDRESS, READ};
                        end else if (internal_counter == 8) begin
                            o_rx_begin <= 1;
                            state <= RX_BEGIN;
                        end    
                    end else
                        state <= START;
                end

                WAIT_FOR_ACK: begin 
                    if (i_ack_complete) begin
                        state <= ACK_HOLD;
                        internal_counter <= internal_counter + 1;
                    end
                end

                ACK_HOLD: begin
                    if (i_scl_low_edge_detect) begin
                        state <= START;
                    end
                end

                STOP: begin
                    o_stop_flag <= 1;
                    if (i_stop_complete) begin
                        o_stop_flag <= 0;
                        state <= HOLD_STOP;
                        stop_counter <= 0;
                    end
                end

                HOLD_STOP: begin 
                    stop_counter <= stop_counter + 1;
                    if (stop_counter > 60) begin
                        o_tx_begin <= 1;
                        internal_counter <= internal_counter + 1;
                        state <= START;
                    end
                end

                REPEATED_START : begin 
                    if (i_repeated_start_complete) begin
                        state <= START;
                        o_initiate_repeated_start <= 0;
                        internal_counter <= internal_counter + 1;
                    end
                end   

                RX_BEGIN: begin 
                    if (i_byte_complete) begin
                        o_rx_begin <= 0;
                        internal_counter <= 4;
                        o_tx_begin <= 1;
                        state <= START;
                    end
                end    
                default : state <= IDLE;
            endcase
        end
    end


endmodule