`timescale 1ns / 1ps

module y_derivative_calc(
        input clk,
        input en,
        input [PIXEL_WIDTH * NUM_DERIVATIVE_FRAMES - 1:0] pixels_in,
        output [DER_TRUNC_BITS*NUM_DERIVATIVE_FRAMES - 1:0] derivs_out
    );
    parameter PIXEL_WIDTH = 8;
    parameter FRAME_WIDTH = 1024;
    parameter KERNEL_WIDTH = 5;
    parameter KERNEL_HEIGHT = 1;
    parameter NUM_DERIVATIVE_FRAMES = 3;
    parameter integer KERNEL [0 : KERNEL_HEIGHT - 1] [0 : KERNEL_WIDTH - 1] = '{'{-1,8,0,-8,1}};
    parameter DER_BITS = 12;
    parameter DER_TRUNC_BITS = 9;
    reg [PIXEL_WIDTH * KERNEL_WIDTH - 1:0] windows_out [0:NUM_DERIVATIVE_FRAMES - 1];
    
    genvar i;
    generate
    for(i=0; i<NUM_DERIVATIVE_FRAMES; i = i + 1) begin : gen_window_calc   
    sliding_window #(
        .WINDOW_WIDTH(1),
        .WINDOW_HEIGHT(KERNEL_WIDTH),
        .IN_WIDTH(PIXEL_WIDTH),
        .PIXLES_PER_LINE(FRAME_WIDTH))    
    sliding_window_inst(clk,en,pixels_in[i*PIXEL_WIDTH+:PIXEL_WIDTH],windows_out[i]);
    end
    endgenerate
    
    genvar j;
    generate
    for(j=0; j<NUM_DERIVATIVE_FRAMES; j = j + 1) begin : gen_kernel_calc
    kernel_calc #(
        .IN_WIDTH(PIXEL_WIDTH),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .OUT_WIDTH(DER_TRUNC_BITS),
        .DIVISOR(8),
        .SIGNED_INPUT(0),
        .EXTRA_BITS(4),
        .KERNEL(KERNEL)) 
    kernel_calc_inst(clk,en,windows_out[j],derivs_out[j*DER_TRUNC_BITS+:DER_TRUNC_BITS]); 
    end
    endgenerate
endmodule
