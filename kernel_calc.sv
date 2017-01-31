`timescale 1ns / 1ps

module kernel_calc(
        input clk,
        input en,
        input [IN_WIDTH * KERNEL_WIDTH * KERNEL_HEIGHT - 1:0] values_in,
        output [OUT_WIDTH - 1:0] value_out
    );

    parameter IN_WIDTH = 4;
    parameter KERNEL_WIDTH = 1;
    parameter KERNEL_HEIGHT = 3;
    parameter OUT_WIDTH = 4;
    parameter DIVISOR = 1;
    parameter EXTRA_BITS = $clog2(DIVISOR);
    parameter SIGNED_INPUT = 1;
    parameter integer KERNEL [0 : KERNEL_HEIGHT - 1] [0 : KERNEL_WIDTH - 1] = '{'{-2},'{0},'{2}};
    reg [IN_WIDTH + EXTRA_BITS - 1:0] multiplication_calc [0 : KERNEL_HEIGHT - 1] [0 : KERNEL_WIDTH - 1];
    reg [IN_WIDTH + EXTRA_BITS - 1:0] multiplication_calc_buf [0 : KERNEL_HEIGHT - 1] [0 : KERNEL_WIDTH - 1];
    reg [0:0] calc_sign [0 : KERNEL_HEIGHT - 1] [0 : KERNEL_WIDTH - 1];
    reg [IN_WIDTH + EXTRA_BITS - 1:0] sum_calc;
    reg debug;
    reg [IN_WIDTH * KERNEL_WIDTH * KERNEL_HEIGHT - 1:0] values_in_reg;
    
    function integer clogb2;
        input [31:0] value;
        begin
            value = value - 1;
            for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
                value = value >> 1;
            end
        end
    endfunction    

    integer row,col;
    always @(posedge clk)begin
        if(en) begin
            for(row = 0; row < KERNEL_HEIGHT; row = row + 1)
                for(col = 0; col < KERNEL_WIDTH; col = col + 1) begin
                    if (SIGNED_INPUT) 
                        multiplication_calc[row][col] = {{EXTRA_BITS{values_in[col*IN_WIDTH + row*IN_WIDTH*KERNEL_WIDTH+IN_WIDTH - 1]}},values_in[col*IN_WIDTH + row*IN_WIDTH*KERNEL_WIDTH+:IN_WIDTH]} * KERNEL[row][col]; // Multiplication
                    else
                        multiplication_calc[row][col] = {{EXTRA_BITS{1'b0}},values_in[col*IN_WIDTH + row*IN_WIDTH*KERNEL_WIDTH+:IN_WIDTH]} * KERNEL[row][col]; // Multiplication
            end
        end
    end
    
    always @(posedge clk)begin
        if(en)begin
            values_in_reg <= values_in;
            multiplication_calc_buf <= multiplication_calc;
        end
    end    
    
    always @(posedge clk)begin
        if(en)begin
            sum_calc = 0;
            for(row = 0; row < KERNEL_HEIGHT; row = row + 1)
                for(col = 0; col < KERNEL_WIDTH; col = col + 1)
                    if(SIGNED_INPUT)
                        sum_calc = sum_calc + {multiplication_calc_buf[row][col]};// Accumulation
                    else
                        sum_calc = sum_calc + multiplication_calc_buf[row][col];
        end
    end
    divide_and_round #(
        .IN_WIDTH(IN_WIDTH + EXTRA_BITS),
        .OUT_WIDTH(OUT_WIDTH),
        .DIVISOR(DIVISOR))
    my_div_round(clk,en,sum_calc,value_out);
endmodule
