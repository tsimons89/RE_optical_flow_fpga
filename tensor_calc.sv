`timescale 1ns / 1ps

module tensor_calc(
        input clk,
        input en,
        input [IN_WIDTH - 1:0] x_in,
        input [IN_WIDTH - 1:0] y_in,
        input [IN_WIDTH - 1:0] t_in,
        output [OUT_WIDTH - 1:0] xx_smooth,
        output [OUT_WIDTH - 1:0] yy_smooth,
        output [OUT_WIDTH - 1:0] xy_smooth,
        output [OUT_WIDTH - 1:0] xt_smooth,
        output [OUT_WIDTH - 1:0] yt_smooth,
        output [OUT_WIDTH - 1:0] tt_smooth
    );
    
    parameter IN_WIDTH = 12;
    parameter PRODUCT_WIDTH = IN_WIDTH * 2;
    parameter TENS_TRUNC_WIDTH = 14;
    parameter OUT_WIDTH = 16;
    parameter EXTRA_BITS = PRODUCT_WIDTH - IN_WIDTH;
    parameter SPACE_EXTRA_BITS = 8;
    parameter SHIFT = PRODUCT_WIDTH - TENS_TRUNC_WIDTH;
    parameter FRAME_WIDTH = 1024;
    parameter SPATIAL_KERNEL_WIDTH = 3;
    parameter SPATIAL_KERNEL_HEIGHT = 3;
    parameter SPATIAL_DIVISOR = 64;
    parameter integer SPATIAL_KERNEL [0 : SPATIAL_KERNEL_HEIGHT - 1] [0 : SPATIAL_KERNEL_WIDTH - 1] = '{'{25,30,25},
                                                                                                        '{30,36,30},
                                                                                                        '{25,30,25}};

    wire [PRODUCT_WIDTH - 1:0] x_signx;
    wire [PRODUCT_WIDTH - 1:0] y_signx;
    wire [PRODUCT_WIDTH - 1:0] t_signx;
    reg [PRODUCT_WIDTH - 1:0] xx,yy,xy,xt,yt,tt;
    wire [TENS_TRUNC_WIDTH - 1:0] xx_trunc,yy_trunc,xy_trunc,xt_trunc,yt_trunc,tt_trunc;

    
    //Sign extend
    assign x_signx = {{EXTRA_BITS{x_in[IN_WIDTH - 1]}},x_in};
    assign y_signx = {{EXTRA_BITS{y_in[IN_WIDTH - 1]}},y_in};
    assign t_signx = {{EXTRA_BITS{t_in[IN_WIDTH - 1]}},t_in};
    //Multiplication
    always @(posedge clk) begin
        if(en) begin
            xx <= x_signx * x_signx;
            yy <= y_signx * y_signx;
            xy <= x_signx * y_signx;
            xt <= x_signx * t_signx;
            yt <= y_signx * t_signx;
            tt <= t_signx * t_signx;
        end
    end
    
    divide_and_round #(
        .IN_WIDTH(PRODUCT_WIDTH),
        .OUT_WIDTH(TENS_TRUNC_WIDTH),
        .SHIFT(SHIFT))
    div_round_xx(clk,en,xx,xx_trunc);
    
    divide_and_round #(
        .IN_WIDTH(PRODUCT_WIDTH),
        .OUT_WIDTH(TENS_TRUNC_WIDTH),
        .SHIFT(SHIFT))
    div_round_yy(clk,en,yy,yy_trunc);
    
    divide_and_round #(
        .IN_WIDTH(PRODUCT_WIDTH),
        .OUT_WIDTH(TENS_TRUNC_WIDTH),
        .SHIFT(SHIFT))
    div_round_tt(clk,en,tt,tt_trunc);
    
    divide_and_round #(
        .IN_WIDTH(PRODUCT_WIDTH),
        .OUT_WIDTH(TENS_TRUNC_WIDTH),
        .SHIFT(SHIFT))
    div_round_xy(clk,en,xy,xy_trunc);
    
    divide_and_round #(
        .IN_WIDTH(PRODUCT_WIDTH),
        .OUT_WIDTH(TENS_TRUNC_WIDTH),
        .SHIFT(SHIFT))
    div_round_xt(clk,en,xt,xt_trunc);
    
    divide_and_round #(
        .IN_WIDTH(PRODUCT_WIDTH),
        .OUT_WIDTH(TENS_TRUNC_WIDTH),
        .SHIFT(SHIFT))
    div_round_yt(clk,en,yt,yt_trunc);
    
    
        
    //Smooth
    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(TENS_TRUNC_WIDTH),
        .EXTRA_BITS(SPACE_EXTRA_BITS),
        .OUT_BITS(OUT_WIDTH),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_xx(clk,en,xx_trunc,xx_smooth);
    
    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(TENS_TRUNC_WIDTH),
        .EXTRA_BITS(SPACE_EXTRA_BITS),
        .OUT_BITS(OUT_WIDTH),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_xy(clk,en,xy_trunc,xy_smooth);
    
    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(TENS_TRUNC_WIDTH),
        .EXTRA_BITS(SPACE_EXTRA_BITS),
        .OUT_BITS(OUT_WIDTH),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_yy(clk,en,yy_trunc,yy_smooth);
    
    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(TENS_TRUNC_WIDTH),
        .EXTRA_BITS(SPACE_EXTRA_BITS),
        .OUT_BITS(OUT_WIDTH),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_tt(clk,en,tt_trunc,tt_smooth);
    
    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(TENS_TRUNC_WIDTH),
        .EXTRA_BITS(SPACE_EXTRA_BITS),
        .OUT_BITS(OUT_WIDTH),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_tx(clk,en,xt_trunc,xt_smooth);
    
    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(TENS_TRUNC_WIDTH),
        .EXTRA_BITS(SPACE_EXTRA_BITS),
        .OUT_BITS(OUT_WIDTH),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_yt(clk,en,yt_trunc,yt_smooth);
endmodule
