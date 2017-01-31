`timescale 1ns / 1ps

module temp_space_smooth(
        input clk,
        input en,
        input [VALUE_BITS*NUM_FRAMES - 1:0] t_values_in,
        input [VALUE_BITS*NUM_FRAMES - 1:0] x_values_in,
        input [VALUE_BITS*NUM_FRAMES - 1:0] y_values_in,
        output [SPATIAL_OUT_WIDTH - 1:0] t_out,
        output [SPATIAL_OUT_WIDTH - 1:0] x_out,
        output [SPATIAL_OUT_WIDTH - 1:0] y_out
    );
    parameter FRAME_WIDTH = 1024;
    parameter NUM_FRAMES = 3;
    parameter VALUE_BITS = 12;
    parameter TEMP_KERNEL_HEIGHT = 1;
    parameter TEMP_KERNEL_WIDTH = 3;
    parameter integer TEMP_SMOOTH_KERNEL [0 : TEMP_KERNEL_HEIGHT - 1] [0 : TEMP_KERNEL_WIDTH - 1] = '{'{1,2,1}};
    parameter TEMP_SMOOTH_DIVISOR = 0;
    parameter TEMP_EXTRA_BITS = 2;
    parameter TEMP_OUT_WIDTH = 9;
    parameter SPATIAL_OUT_WIDTH = 12;
    parameter SPATIAL_EXTRA_BITS = 8;
    parameter SPATIAL_KERNEL_WIDTH = 5;
    parameter SPATIAL_KERNEL_HEIGHT = 5;
    parameter SPATIAL_DIVISOR = 16;
    parameter integer SPATIAL_KERNEL [0 : SPATIAL_KERNEL_HEIGHT - 1] [0 : SPATIAL_KERNEL_WIDTH - 1] = '{'{9,9,12,9,9},
                                                                                                        '{9,9,12,9,9},
                                                                                                        '{12,12,16,12,12},
                                                                                                        '{9,9,12,9,9},
                                                                                                        '{9,9,12,9,9}};
//parameter SPATIAL_KERNEL_WIDTH = 1;
//parameter SPATIAL_KERNEL_HEIGHT = 5;
//parameter SPATIAL_DIVISOR = 8;
//parameter integer SPATIAL_KERNEL [0 : SPATIAL_KERNEL_HEIGHT - 1] [0 : SPATIAL_KERNEL_WIDTH - 1] = '{'{ 1}, '{1},'{4}, '{1}, '{1}};
                                                                                                      
    
    
    wire [TEMP_OUT_WIDTH - 1:0] t_temp_smooth;
    wire [TEMP_OUT_WIDTH - 1:0] x_temp_smooth;
    wire [TEMP_OUT_WIDTH - 1:0] y_temp_smooth;

    
    temp_smooth #(
        .VALUE_BITS(VALUE_BITS),
        .NUM_FRAMES(NUM_FRAMES),
        .KERNEL(TEMP_SMOOTH_KERNEL),
        .OUT_BITS(TEMP_OUT_WIDTH),
        .EXTRA_BITS(TEMP_EXTRA_BITS),
        .DIVISOR(TEMP_SMOOTH_DIVISOR))
    temp_smooth_t(clk,en,t_values_in,t_temp_smooth);
    
    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(TEMP_OUT_WIDTH),
        .OUT_BITS(SPATIAL_OUT_WIDTH),
        .EXTRA_BITS(SPATIAL_EXTRA_BITS),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_t(clk,en,t_temp_smooth,t_out);
    
    temp_smooth #(
        .VALUE_BITS(VALUE_BITS),
        .NUM_FRAMES(NUM_FRAMES),
        .KERNEL(TEMP_SMOOTH_KERNEL),
        .OUT_BITS(TEMP_OUT_WIDTH),
        .EXTRA_BITS(TEMP_EXTRA_BITS),
        .DIVISOR(TEMP_SMOOTH_DIVISOR))
    temp_smooth_x(clk,en,x_values_in,x_temp_smooth);

    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(TEMP_OUT_WIDTH),
        .OUT_BITS(SPATIAL_OUT_WIDTH),
        .EXTRA_BITS(SPATIAL_EXTRA_BITS),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_x(clk,en,x_temp_smooth,x_out);

    temp_smooth #(
        .VALUE_BITS(VALUE_BITS),
        .NUM_FRAMES(NUM_FRAMES),
        .KERNEL(TEMP_SMOOTH_KERNEL),
        .OUT_BITS(TEMP_OUT_WIDTH),
        .EXTRA_BITS(TEMP_EXTRA_BITS),
        .DIVISOR(TEMP_SMOOTH_DIVISOR))
    temp_smooth_y(clk,en,y_values_in,y_temp_smooth);

    spatial_smooth #(
        .FRAME_WIDTH(FRAME_WIDTH),
        .KERNEL(SPATIAL_KERNEL),
        .KERNEL_HEIGHT(SPATIAL_KERNEL_HEIGHT),
        .KERNEL_WIDTH(SPATIAL_KERNEL_HEIGHT),
        .VALUE_BITS(TEMP_OUT_WIDTH),
        .OUT_BITS(SPATIAL_OUT_WIDTH),
        .EXTRA_BITS(SPATIAL_EXTRA_BITS),
        .DIVISOR(SPATIAL_DIVISOR))
    spatial_smooth_y(clk,en,y_temp_smooth,y_out);
    
endmodule
