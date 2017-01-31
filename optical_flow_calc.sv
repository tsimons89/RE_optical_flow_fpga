`timescale 1ns / 1ps

module optical_flow_calc(
        input clk,
        input en,
        input [PIXEL_WIDTH * NUM_FRAMES - 1:0] pixels_in,
        output [RE_OF_OUT_WIDTH - 1:0] vx_out,
        output [RE_OF_OUT_WIDTH - 1:0] vy_out
    );
    parameter PIXEL_WIDTH = 8;
    parameter NUM_FRAMES = 7;
    parameter FRAME_WIDTH = 1280;
    parameter DER_WIDTH = 12;
    parameter DER_TRUNC_WIDTH = 8;
    parameter DER_SMOOTH_WIDTH = 12;
    parameter TENSOR_WIDTH = 14;
    parameter NUM_DERIVATIVE_FRAMES = 3;
    parameter DER_KERNEL_WIDTH = 5;
    parameter HALF_DER_KERNEL_WIDTH = DER_KERNEL_WIDTH/2 + 1;
    parameter RE_OF_OUT_WIDTH = 12;
    parameter UNKOWN_DELAY = 2; //This might come from latching of values somewhere
    
    parameter SPATIAL_KERNEL_WIDTH = 7;
    parameter SPATIAL_KERNEL_HEIGHT = 7;
    parameter SPATIAL_DIVISOR = 64;
    parameter SPACE_EXTRA_BITS = 6;
    parameter OF_CALC_MULTIPLY = 64;
    parameter integer SPATIAL_KERNEL [0 : SPATIAL_KERNEL_HEIGHT - 1] [0 : SPATIAL_KERNEL_WIDTH - 1] = '{'{1,1,1,2,1,1,1},
                                                                                                        '{1,1,1,2,1,1,1},
                                                                                                        '{1,1,1,2,1,1,1},
                                                                                                        '{2,2,2,4,2,2,2},
                                                                                                        '{1,1,1,2,1,1,1},
                                                                                                        '{1,1,1,2,1,1,1},
                                                                                                        '{1,1,1,2,1,1,1}};

    
    wire [DER_TRUNC_WIDTH*NUM_DERIVATIVE_FRAMES - 1:0] t_derivs;
    wire [DER_TRUNC_WIDTH*NUM_DERIVATIVE_FRAMES - 1:0] x_derivs;
    wire [DER_TRUNC_WIDTH*NUM_DERIVATIVE_FRAMES - 1:0] y_derivs;
    wire [DER_SMOOTH_WIDTH - 1:0] x_smooth_aligned,t_smooth_aligned;
    reg  [DER_SMOOTH_WIDTH - 1:0] y_smooth_aligned;
    wire [DER_SMOOTH_WIDTH - 1:0] t_smooth,x_smooth,y_smooth;
    wire [TENSOR_WIDTH - 1:0] xx,xy,yy,xt,yt,tt;
    wire [RE_OF_OUT_WIDTH - 1:0] vx,vy,vx_smooth,vy_smooth;
        
    
    derivative_calc #(
        .PIXEL_WIDTH(PIXEL_WIDTH),
        .FRAME_WIDTH(FRAME_WIDTH),
        .DER_BITS(DER_WIDTH),
        .NUM_DERIVATIVE_FRAMES(NUM_DERIVATIVE_FRAMES),
        .DER_TRUNC_BITS(DER_TRUNC_WIDTH))
    my_der_calc(clk,en,pixels_in,t_derivs,x_derivs,y_derivs);
    
    temp_space_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .VALUE_BITS(DER_TRUNC_WIDTH),
        .NUM_FRAMES(NUM_DERIVATIVE_FRAMES))
    my_temp_space_smooth(clk,en,t_derivs,x_derivs,y_derivs,t_smooth,x_smooth,y_smooth);
    
    always @(posedge clk)
        y_smooth_aligned <= y_smooth;
    
    delay_buffer #(
        .WORD_WIDTH(DER_SMOOTH_WIDTH),
        .WORDS_DELAYED(FRAME_WIDTH * 2 + UNKOWN_DELAY))
    t_delay_buffer(clk,en,t_smooth, t_smooth_aligned);    

    delay_buffer #(
        .WORD_WIDTH(DER_SMOOTH_WIDTH),
        .WORDS_DELAYED(FRAME_WIDTH * 2 - HALF_DER_KERNEL_WIDTH + UNKOWN_DELAY))
    x_delay_buffer(clk,en,x_smooth, x_smooth_aligned);
    
    tensor_calc #(
        .IN_WIDTH(DER_SMOOTH_WIDTH),
        .OUT_WIDTH(TENSOR_WIDTH),
        .FRAME_WIDTH(FRAME_WIDTH))
    my_tensor_calc(clk,en,x_smooth_aligned,y_smooth_aligned,t_smooth_aligned,xx,yy,xy,xt,yt,tt);    
    
    RE_optical_flow_calc #(
        .TENSOR_WIDTH(TENSOR_WIDTH))
    RE_OF_calc(clk,en,xx,yy,tt,xy,xt,yt,vx,vy);
    
    assign vx_out = vx_smooth;
    assign vy_out = vy_smooth;
    
    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(RE_OF_OUT_WIDTH),
        .EXTRA_BITS(SPACE_EXTRA_BITS),
        .OUT_BITS(RE_OF_OUT_WIDTH),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_vx(clk,en,vx,vx_smooth);
    
    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(RE_OF_OUT_WIDTH),
        .EXTRA_BITS(SPACE_EXTRA_BITS),
        .OUT_BITS(RE_OF_OUT_WIDTH),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_vy(clk,en,vy,vy_smooth);

    
    
                
endmodule
