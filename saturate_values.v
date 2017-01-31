`timescale 1ns / 1ps

module saturate_values(
        input clk,
        input en,
        input [IN_WIDTH*NUM_PACKED_VALUES - 1:0]in,
        output reg [OUT_WIDTH*NUM_PACKED_VALUES - 1:0] out
    );
    parameter IN_WIDTH = 9;
    parameter OUT_WIDTH = 8;
    parameter NUM_PACKED_VALUES = 3;
    parameter MAX_VALUE_ONES = OUT_WIDTH-1;
    parameter MAX_VALUE_ZEROS = IN_WIDTH-MAX_VALUE_ONES;
    parameter MAX_VALUE = {{MAX_VALUE_ZEROS{1'b0}},{MAX_VALUE_ONES{1'b1}}};
    parameter MIN_VALUE = ~MAX_VALUE;
    
    integer i;
    always @(posedge clk) begin
        if(en)begin
            for(i = 0; i < NUM_PACKED_VALUES; i = i + 1) begin
                if($signed(in[i*IN_WIDTH+:IN_WIDTH]) > $signed(MAX_VALUE))
                    out[i*OUT_WIDTH+:OUT_WIDTH] <= MAX_VALUE;
                else if($signed(in[i*IN_WIDTH+:IN_WIDTH]) < $signed(MIN_VALUE))
                    out[i*OUT_WIDTH+:OUT_WIDTH] <= MIN_VALUE;
                else
                    out[i*OUT_WIDTH+:OUT_WIDTH] <= in[i*IN_WIDTH+:OUT_WIDTH];
            end
        end
    end   
    
endmodule
