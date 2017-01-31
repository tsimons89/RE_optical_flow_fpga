`timescale 1ns / 1ps

module vector_display_generator(
        input clk,
        input [CORD_WIDTH - 1:0]pixel_col_in,
        input [CORD_WIDTH - 1:0]pixel_row_in,
        input [CORD_WIDTH - 1:0]vec_x_cord_in,
        input [CORD_WIDTH - 1:0]vec_y_cord_in,
        input [RGB_WIDTH - 1:0]rgb_in,
        output [RGB_WIDTH - 1:0]rgb_out
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
    parameter VECTOR_BOX_WIDTH = 32;
    parameter RGB_WIDTH = 24;
    parameter LUT_WIDTH = VECTOR_BOX_WIDTH/2;
    parameter CORD_WIDTH = $clog2(VECTOR_BOX_WIDTH);
    parameter integer LUT [0 : LUT_WIDTH - 1] [LUT_WIDTH - 1:0] = '{'{00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00},
                                                                      '{01,01,01,01,02,02,02,02,03,03,04,05,05,08,15,30},
                                                                      '{02,02,02,03,03,03,04,04,05,05,05,08,08,15,23,30},
                                                                      '{03,03,04,04,04,05,05,05,06,08,08,11,15,20,23,30},
                                                                      '{04,04,05,05,05,06,06,08,08,11,11,15,20,23,26,30},
                                                                      '{05,05,06,06,07,08,08,10,11,12,15,19,20,23,26,30},
                                                                      '{06,06,07,08,08,09,10,11,12,15,18,20,23,26,27,30},
                                                                      '{07,08,08,09,10,11,11,13,15,18,20,21,23,26,27,30},
                                                                      '{08,09,09,10,11,12,13,15,17,19,20,23,25,26,28,30},
                                                                      '{09,10,10,11,12,13,15,17,19,20,21,23,25,26,28,30},
                                                                      '{10,11,11,12,13,15,17,18,20,21,23,24,26,27,28,30},
                                                                      '{11,12,13,14,15,17,18,19,20,22,23,25,26,27,28,30},
                                                                      '{12,13,14,15,16,18,19,20,21,23,24,25,26,27,29,30},
                                                                      '{13,14,15,16,17,19,20,21,22,23,24,25,26,28,29,30},
                                                                      '{14,15,16,17,18,19,20,21,23,24,25,26,27,28,29,30},
                                                                      '{15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30}};
    wire [CORD_WIDTH - 2:0] bitmap_col,bitmap_row,lut_row,lut_col;
    wire [CORD_WIDTH - 1:0] pix_x_cord,pix_y_cord,pixel_col,pixel_row,vec_x_cord,vec_y_cord;
    wire [5:0] bitmap_num;
    wire [9:0] bitmap_addr;
    wire [LUT_WIDTH - 1:0] bitmap_line;
    wire bitmap_pixel,pix_x_sign,pix_y_sign,vec_x_sign,vec_y_sign;
    wire correct_quarter,within_radius,within_range;
    wire [RGB_WIDTH - 1:0]out_color,vect_color;
    wire debug_center_pix = (pix_x_cord == 0 && pix_y_cord == 0 && within_range)?1:0; 
    
    assign vec_x_cord = ($signed(vec_x_cord_in) == -LUT_WIDTH)?-(LUT_WIDTH - 1):vec_x_cord_in;
    assign vec_y_cord = ($signed(vec_y_cord_in) == -LUT_WIDTH)?-(LUT_WIDTH - 1):vec_y_cord_in;
    assign pixel_col = (pixel_col_in == VECTOR_BOX_WIDTH - 1)?VECTOR_BOX_WIDTH - 2:pixel_col_in;
    assign pixel_row = (pixel_row_in == VECTOR_BOX_WIDTH - 1)?VECTOR_BOX_WIDTH - 2:pixel_row_in;
    assign pix_x_cord = pixel_col - (LUT_WIDTH - 1);
    assign pix_y_cord = pixel_row - (LUT_WIDTH - 1);
    assign pix_x_sign = pix_x_cord[CORD_WIDTH - 1];
    assign pix_y_sign = pix_y_cord[CORD_WIDTH - 1];
    assign vec_x_sign = vec_x_cord[CORD_WIDTH - 1];
    assign vec_y_sign = vec_y_cord[CORD_WIDTH - 1];    
    
    assign correct_quarter = ((pix_x_sign == vec_x_sign || pix_x_cord == 0) && (pix_y_sign == vec_y_sign || pix_y_cord == 0))?1:0;
    
    assign lut_col = (vec_x_sign)?-vec_x_cord:vec_x_cord;
    assign lut_row = (vec_y_sign)?-vec_y_cord:vec_y_cord;
    assign bitmap_col = (pix_x_sign)?-pix_x_cord:pix_x_cord;
    assign bitmap_row = (pix_y_sign)?-pix_y_cord:pix_y_cord;
    assign bitmap_num = LUT[lut_row][lut_col];
    assign bitmap_addr = {bitmap_num,bitmap_row};
    assign out_color = (lut_col == bitmap_col && lut_row == bitmap_row)?24'h00FF00:24'hFF0000;
    assign within_radius = (lut_col >= bitmap_col && lut_row >= bitmap_row)?1:0;
    assign within_range = ((pixel_col_in < VECTOR_BOX_WIDTH - 1)&&(pixel_row_in < VECTOR_BOX_WIDTH - 1))?1:0;
    vector_bitmaps bitmap (
       .clka(clk),    // input wire clka
       .ena(1'b1),      // input wire ena
       .addra(bitmap_addr),  // input wire [9 : 0] addra
       .douta(bitmap_line)  // output wire [15 : 0] douta
    );
    assign bitmap_pixel = bitmap_line[bitmap_col];
    
    assign rgb_out = (pix_x_cord == 0 && pix_y_cord == 0 && within_range)?24'h00FF00:
                     (bitmap_pixel && correct_quarter && within_radius && within_range)?24'hFF0000:rgb_in;
        
    
endmodule
