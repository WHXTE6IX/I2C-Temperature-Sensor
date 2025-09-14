module tb_clk_divider;

    logic CLK100MHZ;
    logic rst_p;
    initial begin
        CLK100MHZ = 0;
        forever #5 CLK100MHZ = ~CLK100MHZ; // 100 MHz = 10 ns period
    end

    // Control
    logic i_enable_count;

    // Wires between modules
    logic o_tick;
    logic o_scl;
    logic o_scl_low_edge_detect;
    logic o_scl_rising_edge_detect;

    // Master <-> TX wires
    logic [7:0] data_bus;
    logic tx_begin;
    logic stop_flag;
    logic rx_begin; // not used yet
    logic tx_error, ack_complete, stop_complete;

    // SDA line (shared between master + tx + "pull-up")
    logic sda_line;

    clk_divider #(
        .CLK_HALF_PERIOD(143)   // ~350 kHz
    ) inst_clk_divider (
        .CLK100MHZ      (CLK100MHZ),
        .rst_p          (rst_p),
        .i_enable_count (i_enable_count),
        .o_tick         (o_tick)
    );

    i2c_falling_edge_detect inst_i2c_falling_edge_detect (
        .CLK100MHZ              (CLK100MHZ),
        .rst_p                  (rst_p),
        .i_enable_count         (i_enable_count),
        .i_tick                 (o_tick),
        .o_scl                  (o_scl),
        .o_scl_low_edge_detect  (o_scl_low_edge_detect)
    );

    i2c_rising_edge_detect inst_i2c_rising_edge_detect (
        .CLK100MHZ                  (CLK100MHZ),
        .rst_p                      (rst_p),
        .i_enable_count             (i_enable_count),
        .i_tick                     (o_tick),
        .i_scl                      (o_scl),
        .o_scl_rising_edge_detect   (o_scl_rising_edge_detect)
    );

    I2C_Master inst_master (
        .rst_p          (rst_p),
        .CLK100MHZ      (CLK100MHZ),
        .i_fpga_switch  (1'b1),          // simulate switch ON to trigger start
        .i_sda          (sda_line),
        .i_scl          (o_scl),
        .i_byte_complete(1'b0),          // not connected yet
        .i_tx_error     (tx_error),
        .i_ack_complete (ack_complete),
        .i_stop_complete(stop_complete),
        .o_data         (data_bus),
        .o_tx_begin     (tx_begin),
        .o_stop_flag    (stop_flag),
        .i_rx_begin     (rx_begin)
    );

    i2c_tx inst_tx (
        .rst_p                  (rst_p),
        .CLK100MHZ              (CLK100MHZ),
        .i_scl_low_edge_detect  (o_scl_low_edge_detect),
        .i_scl                  (o_scl),
        .i_scl_rising_edge_detect(o_scl_rising_edge_detect),
        .i_data_command         (data_bus),
        .i_tx_begin             (tx_begin),
        .i_sda                  (sda_line),    // read line
        .i_stop_flag            (stop_flag),
        .o_sda                  (sda_line),    // drive line
        .o_enable_count         (i_enable_count),
        .o_tx_error             (tx_error),
        .o_ack_complete         (ack_complete),
        .o_stop_complete        (stop_complete)
    );

    initial begin
        rst_p = 1;
        i_enable_count = 0;
        #100;
        rst_p = 0;
        i_enable_count = 1;

        #40000;

        i_enable_count = 0;
        #500;
        $finish;
    end

    initial begin
    $monitor("[%0t] TX.state=%0d scl=%0b sda=%0b tick=%0b fall=%0b rise=%0b tx_begin=%0b stop_flag=%0b ack=%0b err=%0b",
             $time,
             tb_clk_divider.inst_tx.state,  // hierarchical reference to TX FSM
             o_scl, sda_line, o_tick,
             o_scl_low_edge_detect, o_scl_rising_edge_detect,
             tx_begin, stop_flag, ack_complete, tx_error);
end

endmodule
