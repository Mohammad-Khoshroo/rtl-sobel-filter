`timescale 1ns/1ps

`ifndef ACCELERATOR_SV
`define ACCELERATOR_SV

`include "controller.sv"
`include "SlidingWindowBuffer.sv"
`include "core.sv"

module accelerator #(
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
    output logic                   done,
    output logic                   valid_pixel,
    output logic [PIXEL_WIDTH-1:0] pixel_out
);

    logic                   linebuffer_wenable;
    logic                   window_shiften;
    logic                   row_pointer;
    logic [9:0]             waddress;
    logic [9:0]             raddress;

    logic [PIXEL_WIDTH-1:0] window [2:0][2:0];
    logic [PIXEL_WIDTH-1:0] core_G;

    assign pixel_out = core_G;

    controller #(
        .WIDTH_SIZE  (WIDTH_SIZE),
        .HEIGHT_SIZE (HEIGHT_SIZE)
    ) u_controller (
        .clk                (clk),
        .rst                (rst),
        .start              (start),
        .ready              (ready),
        .busy               (busy),
        .done               (done),
        .valid_pixel        (valid_pixel),
        .linebuffer_wenable (linebuffer_wenable),
        .window_shiften     (window_shiften),
        .row_pointer        (row_pointer),
        .waddress           (waddress),
        .raddress           (raddress)
    );

    SlidingWindowBuffer #(
        .WIDTH (PIXEL_WIDTH),
        .ROWS  (2),
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

    core u_core (
        .clk       (clk),
        .rst       (rst),
        .shift_en  (window_shiften),
        .window    (window),
        .G_sat_reg (core_G)
    );

endmodule

`endif // ACCELERATOR_SV
