`timescale 1ns / 1ps


module RE_optical_flow_calc(
        input clk,
        input en,
        input [TENSOR_WIDTH - 1:0] xx,
        input [TENSOR_WIDTH - 1:0]yy,
        input [TENSOR_WIDTH - 1:0]tt,
        input [TENSOR_WIDTH - 1:0]xy,
        input [TENSOR_WIDTH - 1:0]xt,
        input [TENSOR_WIDTH - 1:0] yt,
        output [OUT_WIDTH - 1:0] vx,
        output [OUT_WIDTH - 1:0] vy
    );
    parameter TENSOR_WIDTH = 24;
    parameter OUT_WIDTH = 12;
    parameter DIV_WIDTH = 32;
    parameter FISRT_VEL_CALC_DELAY = 65;
    parameter K_CALC_DELAY = 12;
    
    
    wire [TENSOR_WIDTH - 1:0]vx_first,vy_first;
    wire [TENSOR_WIDTH*6 - 1:0] tensors,tensors_delayed_1,tensors_delayed_2;
    wire [TENSOR_WIDTH - 1:0]k;
    assign tensors = {xx,xy,xt,yy,yt,tt};
    velocity_calc #(
        .TENSOR_WIDTH(TENSOR_WIDTH),
        .OUT_WIDTH(TENSOR_WIDTH),
        .DIV_WIDTH(DIV_WIDTH))
    first_vel_calc(clk,en,tensors,0,vx_first,vy_first);
    
    delay_buffer #(
        .WORD_WIDTH(TENSOR_WIDTH * 6),
        .WORDS_DELAYED(FISRT_VEL_CALC_DELAY))
    first_vel_dealy(clk,en,tensors,tensors_delayed_1);
    
    RE_k_calc #(
        .TENSOR_WIDTH(TENSOR_WIDTH))
    k_calc(clk,en,tensors_delayed_1,vx_first,vy_first,k);
            
     delay_buffer #(
        .WORD_WIDTH(TENSOR_WIDTH * 6),
        .WORDS_DELAYED(K_CALC_DELAY))
    k_calc_dealy(clk,en,tensors_delayed_1,tensors_delayed_2);    
   
    velocity_calc #(
        .TENSOR_WIDTH(TENSOR_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .DIV_WIDTH(DIV_WIDTH))
    second_vel_calc(clk,en,tensors_delayed_2,k,vx,vy);

          
endmodule
