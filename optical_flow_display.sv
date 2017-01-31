`timescale 1ns / 1ps

module optical_flow_display(
        input clk,
        input [GRAY_WIDTH - 1:0] gray_in,
        input [OF_CALC_WIDTH - 1:0] vx,
        input [OF_CALC_WIDTH - 1:0] vy,
        input pix_valid,
        input HS,
        input VS,
        output [RGB_WIDTH - 1:0]rgb_out,
        input [X_CORD_WIDTH - 1:0] x_cord,
        input [Y_CORD_WIDTH - 1:0] y_cord
    );
    parameter RGB_WIDTH = 24;
    parameter GRAY_WIDTH = RGB_WIDTH/3;
    parameter FRAME_WIDTH = 1280;
    parameter FRAME_HEIGHT = 1040;
    parameter VEC_BOX_WIDTH = 32;
    parameter VEC_REG_COLS = FRAME_WIDTH/VEC_BOX_WIDTH;
    parameter VEC_REG_ROWS = FRAME_HEIGHT/VEC_BOX_WIDTH;
    parameter OF_CALC_WIDTH = 12;
    parameter VEC_CORD_WIDTH = 5;
    parameter VEC_CORD_MIN = {1'b1,{VEC_CORD_WIDTH-1{1'b0}}};
    parameter VEC_CORD_MAX = {1'b0,{VEC_CORD_WIDTH-1{1'b1}}};
    parameter OF_CALC_TRUNC_WIDTH = ((OF_CALC_WIDTH - 1) - VEC_CORD_HIGH_INDEX)+VEC_CORD_WIDTH;
    parameter VEC_CORD_HIGH_INDEX = 8;
    parameter X_CORD_WIDTH = 11;
    parameter Y_CORD_WIDTH = 11;
    parameter Y_OFFSET = 10;//13
    parameter X_OFFSET = 212;//200
    wire [X_CORD_WIDTH - 1:0] x_cord_offset;
    wire [Y_CORD_WIDTH - 1:0] y_cord_offset;
    wire [VEC_CORD_WIDTH - 1:0] vec_x_cord,vec_y_cord;
    reg [VEC_CORD_WIDTH - 1:0] vec_x_cord_reg [0:VEC_REG_ROWS-1][0:VEC_REG_COLS-1];
    reg [VEC_CORD_WIDTH - 1:0] vec_y_cord_reg [0:VEC_REG_ROWS-1][0:VEC_REG_COLS-1];
    wire [OF_CALC_TRUNC_WIDTH - 1:0]vx_trunc;
    wire [OF_CALC_TRUNC_WIDTH - 1:0]vy_trunc;
    wire [X_CORD_WIDTH-VEC_CORD_WIDTH-1:0]cur_reg_col_in,cur_reg_row_in,cur_reg_col_out,cur_reg_row_out;
    assign vx_trunc = vx[OF_CALC_WIDTH - 1 -: OF_CALC_TRUNC_WIDTH];
    assign vy_trunc = vy[OF_CALC_WIDTH - 1 -: OF_CALC_TRUNC_WIDTH];
//    pixel_cord_gen #(
//        .X_CORD_WIDTH(X_CORD_WIDTH),
//        .Y_CORD_WIDTH(Y_CORD_WIDTH))
//    y_cord_gen(clk,pix_valid,HS,VS,x_cord,y_cord);
    
    assign vec_x_cord = ($signed(vx_trunc) > $signed(VEC_CORD_MAX))?VEC_CORD_MAX:
                        ($signed(vx_trunc) < $signed(VEC_CORD_MIN))?VEC_CORD_MIN:vx_trunc;
    assign vec_y_cord = ($signed(vy_trunc) > $signed(VEC_CORD_MAX))?VEC_CORD_MAX:
                        ($signed(vy_trunc) < $signed(VEC_CORD_MIN))?VEC_CORD_MIN:vy_trunc;
                        
    assign x_cord_offset = ($signed(x_cord - X_OFFSET) < 0)? $signed(x_cord - X_OFFSET) + FRAME_WIDTH:$signed(x_cord - X_OFFSET); 
    assign y_cord_offset = ($signed(y_cord - Y_OFFSET) < 0)? $signed(y_cord - Y_OFFSET) + FRAME_HEIGHT:$signed(y_cord - Y_OFFSET); 
    assign cur_reg_col_in = x_cord_offset[X_CORD_WIDTH - 1:VEC_CORD_WIDTH];
    assign cur_reg_row_in = y_cord_offset[Y_CORD_WIDTH - 1:VEC_CORD_WIDTH];
    
    
    assign cur_reg_col_out = x_cord[X_CORD_WIDTH - 1:VEC_CORD_WIDTH];
    assign cur_reg_row_out = y_cord[Y_CORD_WIDTH - 1:VEC_CORD_WIDTH];
    
    always @(posedge clk) begin
        if(x_cord[0+:VEC_CORD_WIDTH] == 0 && y_cord[0+:VEC_CORD_WIDTH] == 0) begin
            vec_x_cord_reg[cur_reg_row_in][cur_reg_col_in] <= vec_x_cord;
            vec_y_cord_reg[cur_reg_row_in][cur_reg_col_in] <= vec_y_cord;
        end 
    end
    
    vector_display_generator #(
        .VECTOR_BOX_WIDTH(VEC_BOX_WIDTH),
        .RGB_WIDTH(RGB_WIDTH))
    my_vec_gen(clk,x_cord[0+:VEC_CORD_WIDTH],y_cord[0+:VEC_CORD_WIDTH],vec_x_cord_reg[cur_reg_row_out][cur_reg_col_out],vec_y_cord_reg[cur_reg_row_out][cur_reg_col_out],{3{gray_in}},rgb_out);
//    vector_display_generator #(
//        .VECTOR_BOX_WIDTH(VEC_BOX_WIDTH),
//        .RGB_WIDTH(RGB_WIDTH))
//    my_vec_gen(clk,x_cord[0+:VEC_CORD_WIDTH],y_cord[0+:VEC_CORD_WIDTH],10,0,{3{gray_in}},rgb_out);
endmodule
