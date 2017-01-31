`timescale 1ns / 1ps


module RE_k_calc(
        input clk,
        input en,
        input [TENSOR_WIDTH*6 -1 :0]tensors,
        input [TENSOR_WIDTH -1 :0]vx,
        input [TENSOR_WIDTH -1 :0]vy,
        output [TENSOR_WIDTH -1 :0]k
    );
    parameter TENSOR_WIDTH = 14;
    parameter INTER_WIDTH = TENSOR_WIDTH*3 + 3;
    parameter V_SCALE = 1 <<  TENSOR_WIDTH;
    parameter RATIO = 8;
    parameter N = 10;
    parameter P = 2;
    parameter DIVIDER = RATIO * (N - P);
    
    
    
    wire [TENSOR_WIDTH - 1:0] xx,xy,xt,yy,yt,tt;
    reg [INTER_WIDTH - 1:0]xt_vx,yt_vy,vx_vx,xx_buf,vy_vy,yy_buf,xy_2,vx_vy,tt_buf_0;
    reg [INTER_WIDTH - 1:0]xt_vx_2,yt_vy_2,xx_vx_vx,yy_vy_vy,xy_vx_vy_2,tt_buf_1;
    reg [INTER_WIDTH - 1:0]gtt_minus_xt_vx_2,xx_vx_vx_minus_yt_vy_2,yy_vy_vy_plus_xy_vx_vy_2;
    reg [INTER_WIDTH - 1:0]gtt_minus_xt_vx_2_PLUS_xx_vx_vx_minus_yt_vy_2,yy_vy_vy_plus_xy_vx_vy_2_buf;
    reg [INTER_WIDTH - 1:0]error_variance;
    reg [INTER_WIDTH - 1:0]error_variance_mul;
    reg [INTER_WIDTH - 1:0]k_pre_scale;
    
    assign xx = tensors[TENSOR_WIDTH*5+:TENSOR_WIDTH];
    assign xy = tensors[TENSOR_WIDTH*4+:TENSOR_WIDTH];
    assign xt = tensors[TENSOR_WIDTH*3+:TENSOR_WIDTH];
    assign yy = tensors[TENSOR_WIDTH*2+:TENSOR_WIDTH];
    assign yt = tensors[TENSOR_WIDTH+:TENSOR_WIDTH];
    assign tt = tensors[0+:TENSOR_WIDTH];

    
    
    always @(posedge clk)begin
        if(en)begin
            xt_vx <= $signed(xt)*$signed(vx);
            yt_vy <= $signed(yt)*$signed(vy);
            vx_vx <= $signed(vx)*$signed(vx);
            xx_buf <= $signed(xx);
            vy_vy <= $signed(vy)*$signed(vy);
            yy_buf <= $signed(yy);
            xy_2 <= $signed(xy) * 2;
            vx_vy <= $signed(vx)*$signed(vy);
            tt_buf_0 <= $signed(tt);
        end
    end
    
    always @(posedge clk)begin
        if(en)begin
            //First clock
           xt_vx_2 <= $signed(xt_vx)*2;
           yt_vy_2 <= $signed(yt_vy)*2;
           xx_vx_vx <= $signed(xx_buf)*$signed(vx_vx);
           yy_vy_vy <= $signed(yy_buf)*$signed(vy_vy);
           xy_vx_vy_2 <= $signed(xy_2)*$signed(vx_vy);
           tt_buf_1 <= tt_buf_0;
           
            //Second clock
            gtt_minus_xt_vx_2 <= $signed(tt_buf_1 << TENSOR_WIDTH/2) - $signed(xt_vx_2);
            xx_vx_vx_minus_yt_vy_2 <= $signed(xx_vx_vx) - $signed(yt_vy_2  << TENSOR_WIDTH/2);
            yy_vy_vy_plus_xy_vx_vy_2 <= $signed(yy_vy_vy) + $signed(xy_vx_vy_2);
            
            //Third clock
            gtt_minus_xt_vx_2_PLUS_xx_vx_vx_minus_yt_vy_2 <= $signed(gtt_minus_xt_vx_2 << TENSOR_WIDTH/2)+$signed(xx_vx_vx_minus_yt_vy_2);
            yy_vy_vy_plus_xy_vx_vy_2_buf <= yy_vy_vy_plus_xy_vx_vy_2;
            
            //Fourth clock
            error_variance <= $signed(gtt_minus_xt_vx_2_PLUS_xx_vx_vx_minus_yt_vy_2) + $signed(yy_vy_vy_plus_xy_vx_vy_2_buf);
            //Fifth clock
            error_variance_mul <= $signed(error_variance) * P;
            //Sixth clock
            k_pre_scale <= $signed(error_variance_mul) / DIVIDER;
        end
    end
    
    
    divide_and_round #(
        .IN_WIDTH(INTER_WIDTH),
        .OUT_WIDTH(TENSOR_WIDTH),
        .DIVISOR(V_SCALE))
    my_div_round(clk,en,k_pre_scale,k);

    
    
endmodule
