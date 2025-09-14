module top_i2c_temp_sensor(
    input  logic       CLK100MHZ,
    inout  logic       TMP_SDA,
    input  logic [0:0] SW,
    output logic       TMP_SCL,
    output logic [7:0] AN,
    output logic [7:0] sevenSeg
);

    logic enable_count;
    logic rx_begin;
    logic tick;
    logic scl_low_edge_detect;
    logic scl_rising_edge_detect;
    logic byte_complete;
    logic tx_error;
    logic ack_complete;
    logic stop_complete;
    logic [7:0] data;
    logic top_tx_begin;
    logic stop_flag;
    logic [15:0] temp_data;
    logic repeat_start;
    logic start_complete;

    logic tx_o_sda;
    logic rx_o_sda;

    clk_divider #(
        .CLK_HALF_PERIOD(143)
    ) inst_clk_divider (
        .CLK100MHZ      (CLK100MHZ),
        .rst_p          (SW[0]),
        .i_enable_count (enable_count),
        .o_tick         (tick)
    );

    i2c_falling_edge_detect inst_i2c_falling_edge_detect (
        .CLK100MHZ             (CLK100MHZ),
        .rst_p                 (SW[0]),
        .i_enable_count        (enable_count),
        .i_tick                (tick),
        .o_scl                 (TMP_SCL),
        .o_scl_low_edge_detect (scl_low_edge_detect)
    );

    i2c_rising_edge_detect inst_i2c_rising_edge_detect (
        .CLK100MHZ                (CLK100MHZ),
        .rst_p                    (SW[0]),
        .i_enable_count           (enable_count),
        .i_tick                   (tick),
        .i_scl                    (TMP_SCL),
        .o_scl_rising_edge_detect (scl_rising_edge_detect)
    );

    I2C_Master inst_I2C_Master (
        .rst_p           (SW[0]),
        .CLK100MHZ       (CLK100MHZ),
        .i_sda           (TMP_SDA),
        .i_byte_complete (byte_complete),
        .i_ack_complete  (ack_complete),
        .i_stop_complete (stop_complete),
        .o_data          (data),
        .o_tx_begin      (top_tx_begin),
        .o_stop_flag     (stop_flag),
        .o_rx_begin      (rx_begin),
        .i_scl_low_edge_detect (scl_low_edge_detect),
        .o_initiate_repeated_start (repeat_start),
        .i_start_complete (start_complete)
    );

    i2c_tx inst_i2c_tx (
        .rst_p                     (SW[0]),
        .CLK100MHZ                 (CLK100MHZ),
        .i_scl_low_edge_detect     (scl_low_edge_detect),
        .i_scl                     (TMP_SCL),
        .i_scl_rising_edge_detect  (scl_rising_edge_detect),
        .i_data_command            (data),
        .i_tx_begin                (top_tx_begin),
        .i_sda                     (TMP_SDA),
        .i_stop_flag               (stop_flag),
        .o_sda                     (tx_o_sda),   // use internal net
        .o_enable_count            (enable_count),
        .o_tx_error                (tx_error),  // Error debugging
        .o_ack_complete            (ack_complete),
        .o_stop_complete           (stop_complete),
        .i_initiate_repeated_start (repeat_start),
        .o_start_complete          (start_complete),
        .i_rx_begin                (rx_begin)
    );

    i2c_rx #(
        .MEASUREMENT_TIMER(24_000_000)
    ) inst_i2c_rx (
        .rst_p                    (SW[0]),
        .CLK100MHZ                (CLK100MHZ),
        .i_scl_low_edge_detect    (scl_low_edge_detect),
        .i_scl_rising_edge_detect (scl_rising_edge_detect),
        .i_rx_begin               (rx_begin),
        .i_sda                    (TMP_SDA),
        .o_temp_data              (temp_data),
        .o_sda                    (rx_o_sda),   // use internal net
        .o_byte_complete          (byte_complete)
    );

    seven_seg_display #(
        .CLKDIVIDER(100_000)
    ) inst_seven_seg_display (
        .CLK100MHZ   (CLK100MHZ),
        .rst_p       (SW[0]),
        .i_temp_data (temp_data),
        .AN          (AN),
        .sevenSeg   (sevenSeg)
    );


    assign TMP_SDA = (tx_o_sda == 1'b0 || rx_o_sda == 1'b0) ? 1'b0 : 1'bz;

endmodule