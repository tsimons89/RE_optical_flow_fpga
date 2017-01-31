`timescale 1ns / 1ps

module temp_smooth(
        input clk,
        input en,
        input [VALUE_BITS*NUM_FRAMES - 1:0] values_in,
        output [OUT_BITS - 1:0] value_out
    );
    
    parameter VALUE_BITS = 8;
    parameter OUT_BITS = 9;
    parameter NUM_FRAMES = 3;
    parameter KERNEL_WIDTH = NUM_FRAMES;
    parameter KERNEL_HEIGHT = 1;
    parameter integer KERNEL [0 : KERNEL_HEIGHT - 1] [0 : KERNEL_WIDTH - 1] = '{'{1,2,1}};
    parameter DIVISOR = 0;
    parameter EXTRA_BITS = 2;
    wire [VALUE_BITS + EXTRA_BITS - 1:0] value_out_temp;
    
    kernel_calc #(
        .IN_WIDTH(VALUE_BITS),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .OUT_WIDTH(VALUE_BITS + EXTRA_BITS),
        .KERNEL(KERNEL),
        .DIVISOR(DIVISOR),
        .EXTRA_BITS(EXTRA_BITS)) 
    kernel_calc_inst(clk,en,values_in,value_out_temp); 

    saturate_values #(
        .IN_WIDTH(VALUE_BITS + EXTRA_BITS),
        .OUT_WIDTH(OUT_BITS),
        .NUM_PACKED_VALUES(1))
    my_sat(clk,en,value_out_temp,value_out);
endmodule
