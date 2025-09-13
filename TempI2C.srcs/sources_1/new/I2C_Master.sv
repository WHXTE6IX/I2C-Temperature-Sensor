
module I2C_Master(
    input logic rst_p,
    input logic CLK100MHZ,

    input logic i_sda,
    input logic i_scl,

    input logic i_byte_complete, // from rx mod
    input logic i_tx_error, //from tx mod
    input logic i_ack_complete, // from tx module
    input logic i_stop_complete,
    input logic i_scl_low_edge_detect,
    input logic i_rep_start_complete,


    (* mark_debug = "true", keep = "true" *) output logic [7:0] o_data,
    (* mark_debug = "true", keep = "true" *) output logic o_tx_begin,
    (* mark_debug = "true", keep = "true" *) output logic o_stop_flag,
    output logic o_initiate_repeated_start,
    output logic o_rx_begin
    );

    localparam CONFIG_REGISTER = 8'h03;
    localparam CONFIG_REGISTER_DATA = 8'b00000001;

    localparam TEMP_VALUE_MSB_REGISTER = 8'h00;
    localparam TEMP_VALUE_LSB_REGISTER = 8'h01;

    localparam SLAVE_ADDRESS = 7'h4B;
    localparam READ = 1'b1;
    localparam WRITE = 1'b0;

    logic [5:0] stop_counter;

    typedef enum logic [3:0] { 
    IDLE,
    START,
    WAIT_FOR_ACK,
    ACK_HOLD,
    ERROR,
    STOP,
    READ_TEMP_START,
    REPEATED_START
    } e_state;

    (* mark_debug = "true", keep = "true" *) e_state state;
    (* mark_debug = "true", keep = "true" *) logic [2:0] internal_counter;

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            internal_counter <= 0;
            o_stop_flag <= 0;
            state <= IDLE;       
        end else begin
            case (state)
                IDLE: begin 
                    o_tx_begin <= 1;
                    state <= START;
                end

                START: begin
                    o_tx_begin <= 0; 
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
                            o_data <= {SLAVE_ADDRESS, READ};
                            state <= WAIT_FOR_ACK;
                        end
                        
                    end
                end

                WAIT_FOR_ACK: begin 
                    if (i_ack_complete) begin
                        state <= ACK_HOLD;
                        internal_counter <= internal_counter + 1;
                    end else if (i_tx_error) begin
                        state <= ERROR;
                    end
                end

                ACK_HOLD: begin
                    if (i_scl_low_edge_detect) begin
                        state <= START;
                    end
                end

                ERROR: begin 
                    o_tx_begin <= 0;
                    o_data <= 8'b1111_1101;
                end

                STOP: begin
                    o_stop_flag <= 1;
                    if (i_stop_complete) begin
                        o_stop_flag <= 0;
                        state <= READ_TEMP_START;
                        stop_counter <= 0;
                    end
                end

                READ_TEMP_START: begin 
                    o_initiate_repeated_start <= 0;
                    stop_counter <= stop_counter + 1;
                    if (stop_counter > 60) begin
                        o_tx_begin <= 1;
                        internal_counter <= internal_counter + 1;
                        state <= START;
                    end
                end

                REPEATED_START : begin 
                    if (i_rep_start_complete)
                        state <= START;
                        internal_counter <= internal_counter + 1;
                end
            
                default : state <= IDLE;
            endcase
        end
    end


endmodule