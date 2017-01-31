`timescale 1ns / 1ps

module velocity_calc(
        input clk,
        input en,
        input [TENSOR_WIDTH*6 -1 :0]tensors,
        input [TENSOR_WIDTH -1 :0]k,
        output reg [OUT_WIDTH - 1:0] vx,
        output reg [OUT_WIDTH - 1:0] vy
    );
    parameter TENSOR_WIDTH = 24;
    parameter OUT_WIDTH = 12;
    parameter DIV_WIDTH = 32;
    parameter DIV_INT_WIDTH = 4;
    parameter VELOCITY_WIDTH = TENSOR_WIDTH * 2;
    parameter EXTRA_BITS = VELOCITY_WIDTH - TENSOR_WIDTH;
    parameter DIV_EXTRA = DIV_WIDTH - VELOCITY_WIDTH;
    parameter DIV_OUT_WIDTH = VELOCITY_WIDTH * 2;
    
    wire [VELOCITY_WIDTH - 1:0] xx_sign_x;
    wire [VELOCITY_WIDTH - 1:0] yy_sign_x;
    wire [VELOCITY_WIDTH - 1:0] xy_sign_x;
    wire [VELOCITY_WIDTH - 1:0] xt_sign_x;
    wire [VELOCITY_WIDTH - 1:0] yt_sign_x;
    wire vx_valid,vy_valid;
    reg [VELOCITY_WIDTH - 1:0] xt_yy,yt_xx,xt_xy,yt_xy,xx_yy,xy_xy;
    reg [VELOCITY_WIDTH - 1:0] vx_numerator,vy_numerator,v_denominator;
    wire [DIV_OUT_WIDTH - 1:0] vx_out,vy_out;
    wire [DIV_INT_WIDTH - 1:0] vx_int,vy_int;
    reg [OUT_WIDTH/2 :0] vx_frac,vy_frac;
    wire [DIV_WIDTH - 1:0] vx_numerator_sign_x,vy_numerator_sign_x,v_denominator_sign_x;
    reg vx_error,vy_error;
    reg [TENSOR_WIDTH - 1:0] xx,xy,xt,yy,yt,tt;
    
    always @(posedge clk)begin
        if(en) begin
            xx <= tensors[TENSOR_WIDTH*5+:TENSOR_WIDTH] + k;
            xy <= tensors[TENSOR_WIDTH*4+:TENSOR_WIDTH];
            xt <= tensors[TENSOR_WIDTH*3+:TENSOR_WIDTH];
            yy <= tensors[TENSOR_WIDTH*2+:TENSOR_WIDTH] + k;
            yt <= tensors[TENSOR_WIDTH+:TENSOR_WIDTH];
            tt <= tensors[0+:TENSOR_WIDTH];
        end
    end

    
    
    assign xx_sign_x = {{EXTRA_BITS{xx[TENSOR_WIDTH -1]}},xx};
    assign yy_sign_x = {{EXTRA_BITS{yy[TENSOR_WIDTH -1]}},yy};
    assign xy_sign_x = {{EXTRA_BITS{xy[TENSOR_WIDTH -1]}},xy};
    assign xt_sign_x = {{EXTRA_BITS{xt[TENSOR_WIDTH -1]}},xt};
    assign yt_sign_x = {{EXTRA_BITS{yt[TENSOR_WIDTH -1]}},yt};
    
    assign vx_numerator_sign_x = {{DIV_EXTRA{vx_numerator[VELOCITY_WIDTH -1]}},vx_numerator};
    assign vy_numerator_sign_x = {{DIV_EXTRA{vy_numerator[VELOCITY_WIDTH -1]}},vy_numerator};
    assign v_denominator_sign_x = {{DIV_EXTRA{v_denominator[VELOCITY_WIDTH -1]}},v_denominator};
    
    
    
    
    always @(posedge clk)begin
        if(en)begin
            xt_yy <= xt_sign_x * yy_sign_x;
            yt_xx <= yt_sign_x * xx_sign_x;
            xt_xy <= xt_sign_x * xy_sign_x;
            yt_xy <= yt_sign_x * xy_sign_x;
            xx_yy <= xx_sign_x * yy_sign_x;
            xy_xy <= xy_sign_x * xy_sign_x;
        end
    end

    always @(posedge clk)begin
        if(en)begin
            vx_numerator <= xt_yy - yt_xy;
            vy_numerator <= yt_xx - xt_xy;
            v_denominator <= xx_yy - xy_xy;
        end
    end


    div_gen_frac div_vx (
      .aclk(clk),                            // input wire aclk                           
      .s_axis_divisor_tvalid(1'b1),          // input wire s_axis_divisor_tvalid          
      .s_axis_divisor_tdata(v_denominator_sign_x),  // input wire [31 : 0] s_axis_divisor_tdata  
      .s_axis_dividend_tvalid(1'b1),         // input wire s_axis_dividend_tvalid         
      .s_axis_dividend_tdata(vx_numerator_sign_x),  // input wire [31 : 0] s_axis_dividend_tdata 
      .m_axis_dout_tvalid(vx_valid),    // output wire m_axis_dout_tvalid            
      .m_axis_dout_tdata(vx_out)       // output wire [55 : 0] m_axis_dout_tdata     
    );

    div_gen_frac div_vy (
      .aclk(clk),                            // input wire aclk                           
      .s_axis_divisor_tvalid(1'b1),          // input wire s_axis_divisor_tvalid          
      .s_axis_divisor_tdata(v_denominator_sign_x),  // input wire [31 : 0] s_axis_divisor_tdata  
      .s_axis_dividend_tvalid(1'b1),         // input wire s_axis_dividend_tvalid         
      .s_axis_dividend_tdata(vy_numerator_sign_x),  // input wire [31 : 0] s_axis_dividend_tdata 
      .m_axis_dout_tvalid(vy_valid),    // output wire m_axis_dout_tvalid            
      .m_axis_dout_tdata(vy_out)       // output wire [55 : 0] m_axis_dout_tdata     
    );
    
    
    
    saturate_values #(
        .IN_WIDTH(DIV_OUT_WIDTH/2),    
        .OUT_WIDTH(DIV_INT_WIDTH),
        .NUM_PACKED_VALUES(1))
    sat_vy(clk,en,vx_out[DIV_OUT_WIDTH - 1 -:DIV_OUT_WIDTH/2],vx_int);
    
    saturate_values #(
        .IN_WIDTH(DIV_OUT_WIDTH/2),    
        .OUT_WIDTH(DIV_INT_WIDTH),
        .NUM_PACKED_VALUES(1))
    sat_vx(clk,en,vy_out[DIV_OUT_WIDTH - 1 -:DIV_OUT_WIDTH/2],vy_int);

    
    always @(posedge clk) begin
        vx_frac  <= vx_out[DIV_OUT_WIDTH/2-1 -:OUT_WIDTH/2 + 1];
        vy_frac  <= vy_out[DIV_OUT_WIDTH/2-1 -:OUT_WIDTH/2 + 1];
        vx_error <= (vx_out[DIV_OUT_WIDTH-1] & ~vx_out[DIV_OUT_WIDTH/2 - 1] & |vx_out[0 +:DIV_OUT_WIDTH/2]);
        vy_error <= (vy_out[DIV_OUT_WIDTH-1] & ~vy_out[DIV_OUT_WIDTH/2 - 1] & |vy_out[0 +:DIV_OUT_WIDTH/2]);;
        if(vx_error)
            vx <= 0;
        else
            vx <= $signed({vx_int,{OUT_WIDTH/2{1'b0}}})+ $signed(vx_frac);
        if(vy_error)
            vy <= 0;
        else
            vy <= $signed({vy_int,{OUT_WIDTH/2{1'b0}}}) + $signed(vy_frac);
          
    end
    




endmodule
