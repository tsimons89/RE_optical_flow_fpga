`timescale 1ns / 1ps
module mem_control(
    input clk,
    input pixel_clk,
    input freeze,
    input [PIXEL_WIDTH -1:0] pixel_in,
    output [PIXEL_WIDTH*NUM_FRAMES - 1:0] pixels_out,
    input we,
    input rd,
    output [ADDR_WIDTH - 1:0] app_addr,
    output [2:0] app_cmd, // 001 read , 000 write
    output app_en,
    output [LINE_WIDTH - 1:0] app_wdf_data,
    output app_wdf_end, //current clock is the is the last of data input
    output app_wdf_wren,
    input  [LINE_WIDTH - 1:0] app_rd_data,
    input app_rd_data_valid,
    input app_rdy,
    input app_wdf_rdy,
    input frame_rst,
    output [ADDR_BANK_BITS - 1:0] wr_frame_num
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
    

    parameter ADDR_WIDTH = 29;
    parameter LINE_WIDTH = 256;
    parameter PIXEL_WIDTH = 8;
    parameter MEM_DATA_WIDTH = 32;
    parameter NUM_FIFO_LINES = 4;
    parameter ADDR_BANK_BITS = 4;
    parameter NUM_FRAMES = 7;
    parameter ADDR_PER_FIFO_LINE = LINE_WIDTH/MEM_DATA_WIDTH;
    parameter PIXEL_ADDR_BITS = 24;
    parameter ADDR_FILL_BITS = ADDR_WIDTH - (PIXEL_ADDR_BITS + ADDR_BANK_BITS); //Number of 0's to fill address
    
    wire [LINE_WIDTH - 1:0] w_line_out,r_line_in;
    wire w_rd,mem_wr,mem_rd;
    wire wr_cmd_sent,w_empty;
    wire rd_cmd_sent;
    wire [NUM_FRAMES -1:0] r_req;
    wire [NUM_FRAMES -1:0] r_we,rd_fifo_pend,r_incr_addr;
    reg w_req;
    reg new_frame;
    parameter RD_FIFO_NUM_BITS =  $clog2(NUM_FRAMES);
    wire [RD_FIFO_NUM_BITS - 1:0] rd_addr_num,rd_valid_num;
    
    reg [PIXEL_ADDR_BITS - 1:0] rd_px_addr;
    reg [PIXEL_ADDR_BITS - 1:0] wr_px_addr;
    reg [ADDR_BANK_BITS - 1:0] wr_frame_addr;
    wire [ADDR_BANK_BITS - 1:0] rd_frame_addr;
    wire [ADDR_WIDTH - 1:0] rd_addr;
    wire [ADDR_WIDTH - 1:0] wr_addr;
    wire [PIXEL_WIDTH*NUM_FRAMES - 1:0] unordered_pixels_out;
    
    assign wr_addr = {wr_frame_addr,{ADDR_FILL_BITS{1'b0}},wr_px_addr};
    assign rd_addr = {rd_frame_addr,{ADDR_FILL_BITS{1'b0}},rd_px_addr};
     
    initial wr_px_addr = 0;
    initial wr_frame_addr = 0;
    
    genvar i;
    generate
        for(i=0; i<NUM_FRAMES; i = i + 1) begin : gen_rd_fifos
            read_fifo #(
                .LINE_WIDTH(LINE_WIDTH),
                .WORD_WIDTH(PIXEL_WIDTH),
                .NUM_LINES(NUM_FIFO_LINES)) 
            r_fifo_inst(clk,frame_rst,pixel_clk,r_line_in,r_we[i],rd,,,unordered_pixels_out[PIXEL_WIDTH*i +: PIXEL_WIDTH]); 
        end
    endgenerate
    
    write_fifo #(
    .LINE_WIDTH(LINE_WIDTH),
    .WORD_WIDTH(PIXEL_WIDTH),
    .NUM_LINES(NUM_FIFO_LINES)) 
    w_fifo(clk,frame_rst,pixel_clk,pixel_in,we,w_rd,,w_empty,w_line_out);
    
    always @(posedge clk) begin
        if(frame_rst) begin
            wr_px_addr <= 0;
            new_frame <= 1;
        end
        else begin
            if(wr_cmd_sent) begin
                wr_px_addr <= wr_px_addr + (ADDR_PER_FIFO_LINE);
                new_frame <= 0;
            end
            else begin
                new_frame <= 0;
                wr_px_addr <= wr_px_addr;
            end
        end
    end
    
    always @(posedge clk) begin
        if(new_frame & ~freeze)
            if(wr_frame_addr >= (NUM_FRAMES-1))
                wr_frame_addr <= 0;
            else
                wr_frame_addr <= wr_frame_addr + 1;
         else
            wr_frame_addr <= wr_frame_addr;
    end
    
    always @(posedge clk)
        if(frame_rst)
            rd_px_addr <= 0;
        else
            if(rd_cmd_sent)
                rd_px_addr <= rd_px_addr + (ADDR_PER_FIFO_LINE);
            else
                rd_px_addr <= rd_px_addr;
    always @(posedge clk)
        w_req <= !w_empty;

                
    assign r_req = (rd_px_addr < wr_px_addr + (ADDR_PER_FIFO_LINE * NUM_FIFO_LINES))?1:0;
    assign rd_frame_addr = rd_addr_num;     
    assign app_wdf_end = mem_wr;
    assign app_wdf_wren = mem_wr;
    assign w_rd = wr_cmd_sent;
    assign r_incr_addr = {NUM_FRAMES{rd_cmd_sent}} & rd_fifo_pend;
    assign r_we = {NUM_FRAMES{mem_rd}} & (1 << rd_valid_num);
    assign app_wdf_data = w_line_out;
    assign r_line_in = app_rd_data;
    assign app_addr = (app_cmd)?rd_addr:wr_addr;
    assign wr_frame_num = wr_frame_addr;
    mem_sched #(
        .NUM_FRAMES(NUM_FRAMES))
        my_sched(clk,frame_rst,freeze,w_req,r_req,app_rdy,app_rd_data_valid,app_wdf_rdy,
                app_en,mem_wr,mem_rd,app_cmd,wr_cmd_sent,rd_cmd_sent,rd_addr_num,rd_valid_num);
     
    assign pixels_out = {unordered_pixels_out,unordered_pixels_out} >> (wr_frame_addr * PIXEL_WIDTH);
endmodule
