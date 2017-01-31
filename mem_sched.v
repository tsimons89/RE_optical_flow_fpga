`timescale 1ns / 1ps

module mem_sched(
    input clk,
    input rst,
    input freeze,
    input w_req,
    input r_req,
    input mem_app_rdy,
    input mem_rd_rdy,
    input mem_wr_rdy,
    output reg app_en,
    output reg mem_wr,
    output reg mem_rd,
    output reg [2:0] cmd,
    output reg wr_cmd_sent,
    output reg rd_cmd_sent, 
    output reg [RD_FIFO_NUM_BITS - 1:0] rd_addr_num,
    output reg [RD_FIFO_NUM_BITS - 1:0] rd_valid_num
    );
    
    
    parameter NUM_STATE_BITS = 3;
    parameter IDLE = 3'd0, SCH_WR = 3'd1, DDR_WR = 3'd2, SCH_RD = 3'd3, DDR_RD = 3'd4,BEGIN = 3'd5,READ = 3'b001,WRITE = 3'b000;
    parameter NUM_FRAMES = 4;
    
    function integer clogb2;
        input [31:0] value;
        begin
            value = value - 1;
            for (clogb2 = 0; value > 0; clogb2 = clogb2 + 1) begin
                value = value >> 1;
            end
        end
    endfunction    
    parameter RD_FIFO_NUM_BITS =  $clog2(NUM_FRAMES);
    reg [RD_FIFO_NUM_BITS - 1:0] rd_addr_num_next,rd_valid_num_next;
    reg [NUM_STATE_BITS - 1:0] state;
    reg [NUM_STATE_BITS - 1:0] next_state;
    initial state = IDLE;
    initial cmd = WRITE;
    
    always @(posedge clk)
        state <= next_state;
        
    always @(posedge clk)
        rd_addr_num <= rd_addr_num_next;
    always @(posedge clk)
        rd_valid_num <= rd_valid_num_next;
    
    always @(*) begin
        cmd <= WRITE;
        mem_wr <= 0;
        wr_cmd_sent <= 0;
        rd_cmd_sent <= 0;
        app_en <= 0;
        next_state <= state;
        rd_addr_num_next <= rd_addr_num;
        if(rst)
            next_state <= IDLE;
        else begin
            case(state)
                IDLE:begin
                    rd_addr_num_next <= 0;
                    if(w_req) begin
                        next_state <= SCH_WR;
                    end
                    else if(r_req) begin
                        cmd <= READ;
                        next_state <= SCH_RD;
                    end
                end
                SCH_WR:begin
                    cmd <= WRITE;
                    if(!freeze)
                        app_en <= 1;
                    if(mem_wr_rdy & mem_app_rdy) begin
                        if(!freeze)
                            mem_wr <= 1;
                        wr_cmd_sent <= 1;
                       next_state <= DDR_WR;
                    end
                end
                DDR_WR: begin
                   cmd <= WRITE;
                   next_state <= IDLE;
                end
                SCH_RD:begin
                    app_en <= 1;
                    cmd <= READ;
                    if(mem_app_rdy)
                        if(rd_addr_num >= (NUM_FRAMES - 1)) begin
                            next_state <= IDLE;
                            rd_addr_num_next <= 0;
                            rd_cmd_sent <= 1;
                        end
                        else
                            rd_addr_num_next <= rd_addr_num + 1;
                end
            endcase
        end
    end
    always @(*) begin
        mem_rd <= 0;
        rd_valid_num_next <= rd_valid_num;
        if(rst)
            rd_valid_num_next <= 0;
        else begin
            if(mem_rd_rdy) begin
               mem_rd <= 1;
               if(rd_valid_num >= (NUM_FRAMES - 1))
                    rd_valid_num_next <= 0;
                else
                    rd_valid_num_next <= rd_valid_num + 1;
            end
        end
    end
    
    
endmodule
