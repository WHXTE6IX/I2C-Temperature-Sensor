
module I2C_Master(
    input logic rst_p,
    input logic CLK100MHZ,
    (* mark_debug = "true" *) input logic i_fpga_switch,

    input logic i_sda,
    input logic i_scl,

    input logic i_byte_complete, // from rx mod
    input logic i_tx_error, //from tx mod
    input logic i_ack_complete, // from tx module
    input logic i_stop_complete,


    output logic [7:0] o_data,
    output logic o_tx_begin,
    output logic o_stop_flag,
    input  logic data_begin,
    
    input  logic i_enable_count // from tx mod
    );

    localparam CONFIG_REGISTER = 8'h03;
    localparam CONFIG_REGISTER_DATA = 8'b00000001;

    localparam TEMP_VALUE_MSB_REGISTER = 8'h00;
    localparam TEMP_VALUE_LSB_REGISTER = 8'h01;

    localparam SLAVE_ADDRESS = 7'h4B;
    localparam READ = 1'b1;
    localparam WRITE = 1'b0;

    typedef enum logic [3:0] { 
    IDLE,
    START,
    WAIT_FOR_ACK,
    BIT5,
    BIT4,
    BIT3,
    BIT2,
    BIT1,
    ERROR,
    STOP
    } e_state;

    e_state state;
    logic [2:0] internal_counter;

    always_ff @(posedge CLK100MHZ or posedge rst_p) begin
        if (rst_p) begin
            internal_counter <= 0;
            o_stop_flag <= 0;
        end else begin
            case (state)
                IDLE: begin 
                    o_tx_begin <= 0;
                    o_stop_flag <= 0;
                    if (i_fpga_switch) begin
                        o_tx_begin <= 1;
                        state <= START;
                    end
                end

                START: begin 
                    o_tx_begin <= 0;
                    if (~i_sda) begin
                        if (internal_counter == 0) begin
                            o_data <= {SLAVE_ADDRESS, WRITE};
                            state <= WAIT_FOR_ACK;
                        end else if (internal_counter == 1) begin
                            o_data <= {CONFIG_REGISTER};
                            state <= WAIT_FOR_ACK;
                        end else if (internal_counter == 2) begin
                            o_data <= {CONFIG_REGISTER_DATA};
                            state <= WAIT_FOR_ACK;
                        end else if (internal_counter == 3) begin
                            state <= STOP;
                            o_data <= 0;
                        end
                        
                    end
                end

                WAIT_FOR_ACK: begin 
                    if (i_ack_complete) begin
                        state <= IDLE;
                        internal_counter <= internal_counter + 1;
                    end else if (i_tx_error) begin
                        state <= ERROR;
                    end
                end

                ERROR: begin 
                    o_tx_begin <= 0;
                    o_data <= 1111_1111;
                end

                STOP: begin
                    o_stop_flag <= 1;
                    if (i_stop_complete) begin
                        o_stop_flag <= 0;
                        state <= IDLE;
                    end
                end
            
                default : state <= IDLE;
            endcase
        end
    end


endmodule