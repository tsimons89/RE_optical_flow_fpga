`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/20/2016 08:22:37 AM
// Design Name: 
// Module Name: rgb2gray
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rgb2gray(
        input [23:0] rgb,
        output [7:0] gray
    );
    
    assign gray = (rgb[23:16] + rgb[15:8] +rgb[7:0])/3;
    
endmodule
