`timescale 1ns / 1ps
module read_fifo(
    input clk,
    input rst,
    input pixel_clk,
    input [LINE_WIDTH - 1:0] line_in,
    input we,
    input rd,
    output full,
    output empty,
    output [WORD_WIDTH - 1:0] word_out
    );
    
    function integer clogb2;
        input [31:0] value;
        begin
            value = value - 1;
            for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
                value = value >> 1;
            end
        end
    endfunction
    parameter LINE_WIDTH = 32;
    parameter WORD_WIDTH = 8;
    parameter NUM_LINES = 4;
    localparam WORDS_PER_LINE = LINE_WIDTH / WORD_WIDTH;
    parameter PTR_BITS = $clog2(NUM_LINES);
    reg [LINE_WIDTH - 1:0] array [0:NUM_LINES - 1];
    reg [PTR_BITS:0] base,head;
    wire [PTR_BITS - 1:0] top;
    parameter LINE_COUNT_BITS = $clog2(WORDS_PER_LINE);
    reg [LINE_COUNT_BITS - 1:0] line_count;
    wire [LINE_WIDTH - 1:0] line_out_shift;
    initial base = 0;
    initial head = 0;
    initial line_count = 0;
    integer unsigned i;
    
    always @(posedge clk) begin
        for (i = 0; i < NUM_LINES; i = i + 1) array[i] <= array[i];
        if(we && !full)
            array[top] <= line_in;
    end
    
    always @(posedge pixel_clk) begin
        if(rst)
            line_count <= 0;
        else begin
            if(rd) begin
                if(line_count < (WORDS_PER_LINE -1))
                    line_count <= line_count + 1;
                else
                    line_count <= 0;
            end
            else
                line_count <= line_count;
        end  
    end
    
    always @(posedge clk) begin
        if (rst)
            head <= 0;
        else begin
            if(we)
                head <= head + 1;
            else
                head <= head;
        end
    end
    
    always @(posedge pixel_clk)begin
        if(rst)
            base <= 0;
        else begin
            if(line_count >= (WORDS_PER_LINE -1) && rd)
                base <= base + 1;
            else 
                base <= base;
        end
    end
    assign top = head[PTR_BITS - 1:0];
    assign full = (base[PTR_BITS - 1:0] == head[PTR_BITS - 1:0] && base[PTR_BITS] != head[PTR_BITS])?1'b1:1'b0;
    assign empty = (base == head)?1'b1:1'b0;
    assign line_out_shift = array[base[PTR_BITS - 1:0]] >> (line_count*WORD_WIDTH);
    assign word_out = line_out_shift[WORD_WIDTH-1:0];
    
endmodule
