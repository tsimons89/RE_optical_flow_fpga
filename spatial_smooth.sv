`timescale 1ns / 1ps

module spatial_smooth(
        input clk,
        input en,
        input [VALUE_BITS - 1:0] value_in,
        output reg [OUT_BITS - 1:0] value_out_reg
    );
    parameter FRAME_WIDTH = 1024;
    parameter VALUE_BITS = 9;
    parameter OUT_BITS = 12;
    parameter KERNEL_WIDTH = 3;
    parameter KERNEL_HEIGHT = 3;
    parameter EXTRA_BITS = 8;
    (* mark_debug = "true" *)parameter integer KERNEL [0 : KERNEL_HEIGHT - 1] [0 : KERNEL_WIDTH - 1] = '{'{1,2,1},
                                                                                '{2,4,2},
                                                                                '{1,2,1}};
    parameter DIVISOR = 4;
    parameter KERNEL_AREA = KERNEL_WIDTH * KERNEL_HEIGHT * VALUE_BITS;
    reg [KERNEL_AREA - 1:0] window_out;
    wire [OUT_BITS - 1:0] value_out;
    
    
    sliding_window #(
        .WINDOW_WIDTH(KERNEL_WIDTH),
        .WINDOW_HEIGHT(KERNEL_HEIGHT),
        .IN_WIDTH(VALUE_BITS),
        .PIXLES_PER_LINE(FRAME_WIDTH))    
    sliding_window_inst(clk,en,value_in,window_out);

    kernel_calc #(
        .IN_WIDTH(VALUE_BITS),
        .KERNEL_WIDTH(KERNEL_WIDTH),
        .KERNEL_HEIGHT(KERNEL_HEIGHT),
        .OUT_WIDTH(OUT_BITS),
        .EXTRA_BITS(EXTRA_BITS),
        .KERNEL(KERNEL),
        .DIVISOR(DIVISOR)) 
    kernel_calc_inst(clk,en,window_out,value_out);
    
    always @(posedge clk)
        if(en)
            value_out_reg <= value_out; 
    
    
endmodule
