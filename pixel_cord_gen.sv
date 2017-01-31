`timescale 1ns / 1ps

module pixel_cord_gen(
        input clk,
        input valid,
        input HS,
        input VS,
        output reg [CORD_WIDTH  - 1:0] pixel_x,
        output reg [CORD_WIDTH  - 1:0] pixel_y
    );
    parameter CORD_WIDTH = 11;
    reg valid_prev,frame_started,frame_started_prev,VS_flag;
    parameter MAX_X = 1688; //For 1280x1024 res
    parameter MAX_Y = 1066;

    initial valid_prev = 0;
    initial VS_flag = 0;
    always @(posedge clk)begin
        valid_prev <= valid;
        if(pixel_x >= MAX_X - 1)
            pixel_x <= 0;
        else if(valid & ~ valid_prev)
            pixel_x <= 1;
        else
            pixel_x <= pixel_x + 1;
     end
    
    always @(posedge clk)
        if(valid & ~ valid_prev & VS_flag)
            pixel_y <= 0;
        else if(pixel_x >= MAX_X - 1)
            pixel_y <= pixel_y + 1;
    
    always @(posedge clk)
        if(~VS)
            VS_flag <=1;
        else if(valid)
            VS_flag <= 0;
    
endmodule
