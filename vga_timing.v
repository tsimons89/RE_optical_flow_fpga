`timescale 1ns / 1ps

module vga_timing(
        input clk,
        output reg [PIXEL_CORD_WIDTH - 1:0] pixel_x,
        output reg [PIXEL_CORD_WIDTH - 1:0] pixel_y,
        output valid,
        output HS,
        output VS
    );
    
    parameter PIXEL_CORD_WIDTH = 10;
    parameter FRAME_WIDTH = 640;
    parameter FRAME_HEIGHT = 480;
    parameter MAX_X = 799;
    parameter MAX_Y = 524;
    parameter HS_START = 656;
    parameter HS_END = 752;
    parameter VS_START = 490;
    parameter VS_END = 492;
    
    initial pixel_x = 0;
    initial pixel_y = 0;
    
    always @(posedge clk)begin
        pixel_x <= (pixel_x >= MAX_X)?0:pixel_x+1;
        if(pixel_x >= MAX_X)
            pixel_y <= (pixel_y >= MAX_Y)?0:pixel_y+1;
    end
    
    assign HS = ~((pixel_x>=HS_START) && (pixel_x<HS_END));
    assign VS = ~((pixel_y>=VS_START) && (pixel_y<VS_END));
    assign valid = (pixel_x<FRAME_WIDTH) && (pixel_y<FRAME_HEIGHT);

    
    
endmodule
