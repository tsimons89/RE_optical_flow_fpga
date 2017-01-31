`timescale 1ns / 1ps

module temporal_derivative_calc(
        input clk,
        input en,
        input [PIXEL_WIDTH * NUM_FRAMES - 1:0] pixels_in,
        output [DER_TRUNC_BITS*NUM_DERIVATIVE_FRAMES - 1:0] derivs_out
    );
    parameter PIXEL_WIDTH = 8;
    parameter KERNEL_WIDTH = 5;
    parameter KERNEL_HEIGHT = 1;
    parameter NUM_DERIVATIVE_FRAMES = 3;
    parameter integer KERNEL [0 : KERNEL_HEIGHT - 1] [0 : KERNEL_WIDTH - 1] = '{'{-1,8,0,-8,1}};
    parameter DER_BITS = 12;
    parameter DER_TRUNC_BITS = 9;
    parameter NUM_FRAMES = NUM_DERIVATIVE_FRAMES + KERNEL_WIDTH - 1;
  
    genvar i;
    generate
        for(i=0; i<NUM_DERIVATIVE_FRAMES; i = i + 1) begin : gen_kernel_calc
            kernel_calc #(
                .IN_WIDTH(PIXEL_WIDTH),
                .KERNEL_WIDTH(KERNEL_WIDTH),
                .KERNEL_HEIGHT(KERNEL_HEIGHT),
                .OUT_WIDTH(DER_TRUNC_BITS),
                .DIVISOR(8),
                .EXTRA_BITS(4),
                .SIGNED_INPUT(0),
                .KERNEL(KERNEL)) 
            kernel_calc_inst(clk,en,pixels_in[PIXEL_WIDTH*i+:PIXEL_WIDTH*KERNEL_WIDTH],derivs_out[i*DER_TRUNC_BITS+:DER_TRUNC_BITS]); 
        end
    endgenerate
    
    

endmodule
