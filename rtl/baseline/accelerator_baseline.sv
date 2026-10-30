`timescale 1ns/1ps

`ifndef ACCELERATOR_BASELINE_SV
`define ACCELERATOR_BASELINE_SV

`include "controller_baseline.sv"
`include "SlidingWindowBuffer_baseline.sv"
`include "core_baseline.sv"

module accelerator_baseline #(
    parameter WIDTH_SIZE  = 640,
    parameter HEIGHT_SIZE = 853,
    parameter PIXEL_WIDTH = 8
)(
    input  logic                   clk,
    input  logic                   rst,
    input  logic                   start,
    input  logic [PIXEL_WIDTH-1:0] pixel_in,

    output logic                   ready,
    output logic                   busy,
    output logic                   busy_load,
    output logic                   busy_process,
    output logic                   done,
    output logic                   linebuffer_wenable,
    output logic                   valid_pixel,
    output logic [PIXEL_WIDTH-1:0] pixel_out
);

    logic                   window_shiften;
    logic [1:0]             row_pointer;
    logic [9:0]             waddress;
    logic [9:0]             raddress;

    logic                   xy_ctrl;
    logic                   gx_en;
    logic                   gy_en;
    logic [1:0]             xm_ctrl;
    logic [1:0]             ym_ctrl;
    logic                   gx_sign;
    logic                   gy_sign;

    logic [PIXEL_WIDTH-1:0] window [2:0][2:0];
    logic [PIXEL_WIDTH-1:0] core_G;

    assign pixel_out = core_G;

    controller_baseline u_controller (
        .clk                (clk),
        .rst                (rst),
        .start              (start),
        .ready              (ready),
        .busy               (busy),
        .busy_load          (busy_load),
        .busy_process       (busy_process),
        .done               (done),
        .gx_sign            (gx_sign),
        .gy_sign            (gy_sign),
        .gx_en              (gx_en),
        .gy_en              (gy_en),
        .xy_ctrl            (xy_ctrl),
        .xm_ctrl            (xm_ctrl),
        .ym_ctrl            (ym_ctrl),
        .valid_pixel        (valid_pixel),
        .linebuffer_wenable (linebuffer_wenable),
        .window_shiften     (window_shiften),
        .row_pointer        (row_pointer),
        .waddress           (waddress),
        .raddress           (raddress)
    );

    SlidingWindowBuffer_baseline #(
        .WIDTH (PIXEL_WIDTH),
        .ROWS  (3),
        .SIZE  (WIDTH_SIZE),
        .XWIN  (3),
        .YWIN  (3)
    ) u_sliding_window_buffer (
        .clk      (clk),
        .rst      (rst),
        .wenable  (linebuffer_wenable),
        .wdata    (pixel_in),
        .wrow     (row_pointer),
        .waddress (waddress),
        .renable  (window_shiften),
        .rrow     (row_pointer),
        .raddress (raddress),
        .rdata    (window)
    );

    core_baseline u_core (
        .clk     (clk),
        .rst     (rst),
        .window  (window),
        .xy_ctrl (xy_ctrl),
        .gx_en   (gx_en),
        .gy_en   (gy_en),
        .xm_ctrl (xm_ctrl),
        .ym_ctrl (ym_ctrl),
        .gx_sign (gx_sign),
        .gy_sign (gy_sign),
        .G       (core_G)
    );

endmodule

`endif // ACCELERATOR_BASELINE_SV
