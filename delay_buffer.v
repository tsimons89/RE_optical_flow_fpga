`timescale 1ns / 1ps

module delay_buffer(
    input clk,
    input en,
    input [WORD_WIDTH - 1:0] word_in,
    output [WORD_WIDTH - 1:0] word_out    
);
    parameter WORD_WIDTH = 4;
    parameter WORDS_DELAYED = 4;
    parameter BUFFER_SIZE = WORDS_DELAYED * WORD_WIDTH;
    
    reg [BUFFER_SIZE - 1:0] buffer; 
    
    always @(posedge clk)
        if(en)
            buffer <= {buffer,word_in};
    
    assign word_out = buffer[BUFFER_SIZE - WORD_WIDTH+:WORD_WIDTH];
endmodule
