`default_nettype none

module top (

    output wire test1,
    output wire test2,
    output wire test3,

    input   wire        clk25,
    input   wire        s1_n,
    input   wire        s2_n,
    inout   wire        kbclk,      // we will use an SB_IO to control direction
    inout   wire        kbdata,     // we will use an SB_IO to control direction
    output  wire [7:0]  led
    );

    wire reset_clean;
    wire s1_sync;

    wire [8:0] data;        // includes the parity bit

    // the 'inside' signals we use for the tri-state logic
    wire        kbdata_in, kbdata_out;
    wire        kbclk_in, kbclk_out;

    assign test1 = kbdata_out;
    assign test2 = kbclk_out;
    assign test3 = kbclk_in;

    // explicitly configure the PS2 IO pins (to make yosys happy)
    // See FPGA-TN-02026-3.2 (iCE40 Technology Library), page 83
    SB_IO #(
        .PIN_TYPE(6'b101001),
        .PULLUP(1'b1)
    ) io_buf_kbclk (
        .PACKAGE_PIN(kbclk),
        .OUTPUT_ENABLE(~kbclk_out), // turn on the output driver if kbclk is low else float
        .D_OUT_0(kbclk_out),        // when kbclk is low, drive pin to zero
        .D_IN_0(kbclk_in)           // this lets us look at the pin input
    );

    SB_IO #(
        .PIN_TYPE(6'b101001),
        .PULLUP(1'b1)
    ) io_buf_kbdata (
        .PACKAGE_PIN(kbdata),
        .OUTPUT_ENABLE(~kbdata_out),
        .D_OUT_0(kbdata_out),
        .D_IN_0(kbdata_in)
    );

    sync rsync (
        .clk(clk25),
        .in(~s1_n),
        .out(s1_sync)
    );

    // 25MHZ/250 = 10 usec = 100KHZ
    debounce #( .MAX_COUNT(250) ) deb (
        .clock(clk25),
        .in(s1_sync),
        .out(reset_clean)
    );

    ps2 kbd (
        .reset(~s1_n),
        .ps2_data_in(kbdata_in),
        .ps2_data_out(kbdata_out),
        .ps2_clk_in(kbclk_in),
        .ps2_clk_out(kbclk_out),
        .rx_data(data)       // note the MSB is pruned
        );

    assign led = ~data[7:0];

endmodule
