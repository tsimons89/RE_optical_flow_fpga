`timescale 1ns / 1ps

module sliding_window(
    input clk,
    input en,
    input [IN_WIDTH - 1:0] value_in,
    output reg [WINDOW_AREA - 1:0] values_out    
    );
    parameter WINDOW_WIDTH = 3;
    parameter WINDOW_HEIGHT = 3;
    parameter IN_WIDTH = 4;
    parameter PIXLES_PER_LINE = 4;
    parameter WINDOW_AREA = WINDOW_WIDTH * WINDOW_HEIGHT * IN_WIDTH;
    parameter BUFFER_SIZE = (PIXLES_PER_LINE  * (WINDOW_HEIGHT - 1) + WINDOW_WIDTH) * IN_WIDTH;
    
    reg [BUFFER_SIZE - 1:0] buffer; 
    
    always @(posedge clk)
        if(en)
            buffer <= {buffer,value_in};
        
    
    
    integer i;
    always @(*)begin
        for( i = 0; i < WINDOW_HEIGHT;i = i+1)
            values_out[IN_WIDTH*WINDOW_WIDTH*i +: IN_WIDTH*WINDOW_WIDTH] <= buffer[IN_WIDTH*PIXLES_PER_LINE*i +: IN_WIDTH*WINDOW_WIDTH];
    end
    
endmodule
