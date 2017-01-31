`timescale 1ns / 1ps

module divide_and_round(
        input clk,
        input en,
        input [IN_WIDTH -1:0] in,
        output reg [OUT_WIDTH - 1:0] out
    );
    parameter IN_WIDTH = 12;
    parameter OUT_WIDTH = 9;
    parameter DIVISOR = 8;
    parameter SHIFT = $clog2(DIVISOR);
    function integer clogb2;
        input [31:0] value;
        begin
            value = value - 1;
            for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
                value = value >> 1;
            end
        end
    endfunction
    
//    assign out = in/DIVISOR;    
    
    reg sign_0,sign_1,sign_2,sign_3;
    reg  [IN_WIDTH -1:0] in_pos_0,in_0;
    reg [IN_WIDTH -1:0] in_pos_1;
    reg  [OUT_WIDTH - 1:0] rounded_pos,shift_pos;
        
    always @(posedge clk)begin
        if(en)begin
            sign_0 <= in[IN_WIDTH - 1];
            in_0 <= in;
            in_pos_0 <= (sign_0)?-in_0:in_0;
            shift_pos <= in_pos_0>>SHIFT;
            sign_1 <= sign_0;
            sign_2 <= sign_1;
            sign_3 <= sign_2;
            in_pos_1 <= in_pos_0;
            if(SHIFT > 0)
                rounded_pos <= shift_pos + {0,in_pos_1[SHIFT-1]};
            else
                rounded_pos <= shift_pos;
            if(sign_3)
                out <= -rounded_pos;
            else
                out <= rounded_pos;
        end
    end
    
    
endmodule
