`timescale 1ns / 1ps

module derivative_calc(
        input clk,
        input en,
        input [PIXEL_WIDTH * NUM_FRAMES - 1:0] pixels_in,
        output reg [DER_TRUNC_BITS*NUM_DERIVATIVE_FRAMES - 1:0] temp_derivs_out,
        output reg [DER_TRUNC_BITS*NUM_DERIVATIVE_FRAMES - 1:0] x_derivs_out,
        output reg [DER_TRUNC_BITS*NUM_DERIVATIVE_FRAMES - 1:0] y_derivs_out
    );
    parameter PIXEL_WIDTH = 8;
    parameter FRAME_WIDTH = 1024;
    parameter KERNEL_WIDTH = 5;
    parameter KERNEL_HEIGHT = 1;
    parameter NUM_DERIVATIVE_FRAMES = 3;
    parameter integer KERNEL [0 : KERNEL_HEIGHT - 1] [0 : KERNEL_WIDTH - 1] = '{'{1,-8,0,8,-1}};
    parameter DER_BITS = 12;
    parameter DER_TRUNC_BITS = 8;
    parameter PRE_SAT_DER_TRUNC_BITS = 9;
    parameter NUM_FRAMES = NUM_DERIVATIVE_FRAMES + KERNEL_WIDTH - 1;
    parameter SPATIAL_DER_PIXELS_IN_STARTING_INDEX = (KERNEL_WIDTH / 2 ) * PIXEL_WIDTH;
    
    wire [PRE_SAT_DER_TRUNC_BITS*NUM_DERIVATIVE_FRAMES - 1:0] temp_derivs,x_derivs,y_derivs;

    
    temporal_derivative_calc #(
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .NUM_DERIVATIVE_FRAMES(NUM_DERIVATIVE_FRAMES),
        .KERNEL(KERNEL),
        .DER_BITS(DER_BITS),
        .DER_TRUNC_BITS(PRE_SAT_DER_TRUNC_BITS))    
    my_temp_der_calc(clk,en, pixels_in,temp_derivs);
     
    x_derivative_calc #(
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .NUM_DERIVATIVE_FRAMES(NUM_DERIVATIVE_FRAMES),
        .KERNEL(KERNEL),
        .DER_BITS(DER_BITS),
        .DER_TRUNC_BITS(PRE_SAT_DER_TRUNC_BITS))    
    my_x_der_calc(clk,en,pixels_in[SPATIAL_DER_PIXELS_IN_STARTING_INDEX+:NUM_DERIVATIVE_FRAMES * PIXEL_WIDTH],x_derivs);
    
    y_derivative_calc #(
       .PIXEL_WIDTH(PIXEL_WIDTH),
       .FRAME_WIDTH(FRAME_WIDTH),
       .KERNEL_HEIGHT(KERNEL_HEIGHT),
       .KERNEL_WIDTH(KERNEL_WIDTH),
       .NUM_DERIVATIVE_FRAMES(NUM_DERIVATIVE_FRAMES),
       .KERNEL(KERNEL),
       .DER_BITS(DER_BITS),
       .DER_TRUNC_BITS(PRE_SAT_DER_TRUNC_BITS))    
    my_y_der_calc(clk,en,pixels_in[SPATIAL_DER_PIXELS_IN_STARTING_INDEX+:NUM_DERIVATIVE_FRAMES * PIXEL_WIDTH],y_derivs);
    
    saturate_values #(
        .IN_WIDTH(PRE_SAT_DER_TRUNC_BITS),    
        .OUT_WIDTH(DER_TRUNC_BITS),
        .NUM_PACKED_VALUES(NUM_DERIVATIVE_FRAMES))
    sat_temp_der(clk,en,temp_derivs,temp_derivs_out);

    saturate_values #(
        .IN_WIDTH(PRE_SAT_DER_TRUNC_BITS),    
        .OUT_WIDTH(DER_TRUNC_BITS),
        .NUM_PACKED_VALUES(NUM_DERIVATIVE_FRAMES))
    sat_x_der(clk,en,x_derivs,x_derivs_out);

    saturate_values #(
        .IN_WIDTH(PRE_SAT_DER_TRUNC_BITS),    
        .OUT_WIDTH(DER_TRUNC_BITS),
        .NUM_PACKED_VALUES(NUM_DERIVATIVE_FRAMES))
    sat_y_der(clk,en,y_derivs,y_derivs_out);
        
endmodule
