module top_i2c_temp_sensor(
    input  logic       CLK100MHZ,
    inout  logic       TMP_SDA,
    input  logic [1:0] SW,
    output logic       TMP_SCL
);

    logic enable_count;
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
    logic data_begin;
    logic [7:0] temp_data;

    // NEW internal nets for SDA drive
    logic tx_o_sda;
    logic rx_o_sda;

    clk_divider #(
        .CLK_HALF_PERIOD(143)
    ) inst_clk_divider (
        .CLK100MHZ (CLK100MHZ),
        .rst_p     (SW[0]),
        .i_enable  (enable_count),
        .o_tick    (tick)
    );

    i2c_falling_edge_detect inst_i2c_falling_edge_detect (
        .CLK100MHZ             (CLK100MHZ),
        .rst_p                 (SW[0]),
        .i_enable              (enable_count),
        .i_tick                (tick),
        .o_scl                 (TMP_SCL),
        .o_scl_low_edge_detect (scl_low_edge_detect)
    );

    i2c_rising_edge_detect inst_i2c_rising_edge_detect (
        .CLK100MHZ                (CLK100MHZ),
        .rst_p                    (SW[0]),
        .i_enable                 (enable_count),
        .i_tick                   (tick),
        .i_scl                    (TMP_SCL),
        .o_scl_rising_edge_detect (scl_rising_edge_detect)
    );

    I2C_Master inst_I2C_Master (
        .rst_p           (SW[0]),
        .CLK100MHZ       (CLK100MHZ),
        .i_fpga_switch   (SW[1]),
        .i_sda           (TMP_SDA),
        .i_scl           (TMP_SCL),
        .i_byte_complete (byte_complete),
        .i_tx_error      (tx_error),
        .i_ack_complete  (ack_complete),
        .i_stop_complete (stop_complete),
        .o_data          (data),
        .o_tx_begin      (top_tx_begin),
        .o_stop_flag     (stop_flag),
        .data_begin      (data_begin),
        .i_enable_count  (enable_count)
    );

    i2c_tx inst_i2c_tx (
        .rst_p                    (SW[0]),
        .CLK100MHZ                (CLK100MHZ),
        .i_scl_low_edge_detect    (scl_low_edge_detect),
        .i_scl                    (TMP_SCL),
        .i_scl_rising_edge_detect (scl_rising_edge_detect),
        .i_data_command           (data),
        .tx_begin                 (top_tx_begin),
        .i_sda                    (TMP_SDA),
        .i_stop_flag              (stop_flag),
        .o_sda                    (tx_o_sda),   // use internal net
        .o_enable_count           (enable_count),
        .o_tx_error               (tx_error),
        .o_ack_complete           (ack_complete),
        .o_stop_complete          (stop_complete)
    );

    i2c_rx inst_i2c_rx (
        .rst_p                    (SW[0]),
        .CLK100MHZ                (CLK100MHZ),
        .i_scl_low_edge_detect    (scl_low_edge_detect),
        .i_scl                    (TMP_SCL),
        .i_scl_rising_edge_detect (scl_rising_edge_detect),
        .rx_begin                 (data_begin),
        .i_sda                    (TMP_SDA),
        .o_temp_data              (temp_data),
        .o_sda                    (rx_o_sda),   // use internal net
        .o_byte_complete          (byte_complete)
    );

    // Tri-state driver for SDA (open-drain)
    assign TMP_SDA = (tx_o_sda == 1'b0 || rx_o_sda == 1'b0) ? 1'b0 : 1'bz;

endmodule
