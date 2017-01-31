`timescale 1ns / 1ps

module top(
    //Clock
    input sys_clk_p,
    input sys_clk_n,
    //HDIM
    input TMDS_Clk_p,
    input TMDS_Clk_n,
    input [2:0] TMDS_Data_p,
    input [2:0] TMDS_Data_n,
    inout sda_io,
    inout scl_io,
    output hpa,
    //Memory
    inout [31:0] ddr3_dq,
    inout [3:0] ddr3_dqs_n,
    inout [3:0] ddr3_dqs_p,    
    output [14:0] ddr3_addr,
    output [2:0] ddr3_ba,
    output ddr3_ras_n,
    output ddr3_cas_n,
    output ddr3_we_n,
    output ddr3_reset_n,
    output [0:0] ddr3_ck_p,
    output [0:0] ddr3_ck_n,
    output [0:0] ddr3_cke,
    output [0:0] ddr3_cs_n,
    output [3:0] ddr3_dm,
    output [0:0] ddr3_odt,
    //VGA
    output [4:0] vga_pRed,
    output [4:0] vga_pBlue,
    output [5:0] vga_pGreen,
    output vga_pHSync,
    output vga_pVSync,
    //For testing
    input [3:0] sw
);
    parameter NUM_FRAMES = 7;
    parameter NUM_DERIVATIVE_FRAMES = 3;
    parameter OF_CALC_WIDTH = 12;
    parameter PIXEL_WIDTH = 8;
    parameter CORD_WIDTH = 11;
    parameter SYNC_INV = 1;

    wire [28:0] app_addr;
    wire [2:0] app_cmd;
    wire app_en;
    wire app_rdy;
    wire [255:0] app_rd_data;
    wire app_rd_data_end;
    wire app_rd_data_valid;
    wire [255:0] app_wdf_data;
    wire app_wdf_end;
    wire [31:0] app_wdf_mask;
    wire app_wdf_rdy;
    wire app_sr_active;
    wire app_ref_ack;
    wire app_zq_ack;
    wire app_wdf_wren,init_calib_complete;
    wire sys_rst;
    wire clk;
    wire [23:0] vid_pData;
    wire [23:0] rgb_pData;
    reg [23:0] rgb_pData_reg;
    wire vid_pVDE;
    wire vid_pHSync,HS_out;
    wire vid_pVSync,VS_out;
    wire [3:0] cur_frame;
    wire PixelClk;
    wire [PIXEL_WIDTH - 1:0] pixel_in,display_frame_pixel;
    wire clk_out400;
    wire clk_out200;
    wire [PIXEL_WIDTH*NUM_FRAMES - 1:0] pixels_out;
    wire we,rd;
    wire pixel_valid;
    wire timing_HS,timing_VS,timing_pix_clk,timing_blank,timing_valid,vga_valid;
    wire freeze_frame;
    wire frame_rst;
    wire pix_en;
    wire [2:0] desiplay_frame_select;
    reg [PIXEL_WIDTH - 1:0] display_frame_pixel_reg;
    wire vid_pHSync_in,vid_pVSync_in;
    
    wire [OF_CALC_WIDTH - 1:0] vx,vy;
    (* mark_debug = "ture"*)reg  [OF_CALC_WIDTH - 1:0] vx_reg,vy_reg;
    wire [CORD_WIDTH - 1:0] pixel_x,pixel_y;
      mig_7series_0 u_mig_7series_0 (
  
      // Memory interface ports
      .ddr3_addr                      (ddr3_addr),  // output [14:0]    ddr3_addr
      .ddr3_ba                        (ddr3_ba),  // output [2:0]    ddr3_ba
      .ddr3_cas_n                     (ddr3_cas_n),  // output      ddr3_cas_n
      .ddr3_ck_n                      (ddr3_ck_n),  // output [0:0]    ddr3_ck_n
      .ddr3_ck_p                      (ddr3_ck_p),  // output [0:0]    ddr3_ck_p
      .ddr3_cke                       (ddr3_cke),  // output [0:0]    ddr3_cke
      .ddr3_ras_n                     (ddr3_ras_n),  // output      ddr3_ras_n
      .ddr3_reset_n                   (ddr3_reset_n),  // output      ddr3_reset_n
      .ddr3_we_n                      (ddr3_we_n),  // output      ddr3_we_n
      .ddr3_dq                        (ddr3_dq),  // inout [31:0]    ddr3_dq
      .ddr3_dqs_n                     (ddr3_dqs_n),  // inout [3:0]    ddr3_dqs_n
      .ddr3_dqs_p                     (ddr3_dqs_p),  // inout [3:0]    ddr3_dqs_p
      .init_calib_complete            (init_calib_complete),  // output      init_calib_complete
        
    .ddr3_cs_n                      (ddr3_cs_n),  // output [0:0]    ddr3_cs_n
      .ddr3_dm                        (ddr3_dm),  // output [3:0]    ddr3_dm
      .ddr3_odt                       (ddr3_odt),  // output [0:0]    ddr3_odt
      // Application interface ports
      .app_addr                       (app_addr),  // input [28:0]    app_addr
      .app_cmd                        (app_cmd),  // input [2:0]    app_cmd
      .app_en                         (app_en),  // input        app_en
      .app_wdf_data                   (app_wdf_data),  // input [255:0]    app_wdf_data
      .app_wdf_end                    (app_wdf_end),  // input        app_wdf_end
      .app_wdf_wren                   (app_wdf_wren),  // input        app_wdf_wren
      .app_rd_data                    (app_rd_data),  // output [255:0]    app_rd_data
      .app_rd_data_end                (app_rd_data_end),  // output      app_rd_data_end
      .app_rd_data_valid              (app_rd_data_valid),  // output      app_rd_data_valid
      .app_rdy                        (app_rdy),  // output      app_rdy
      .app_wdf_rdy                    (app_wdf_rdy),  // output      app_wdf_rdy
      .app_sr_req                     (1'b0),  // input      app_sr_req
      .app_ref_req                    (1'b0),  // input      app_ref_req
      .app_zq_req                     (1'b0),  // input      app_zq_req
      .app_sr_active                  (),  // output      app_sr_active
      .app_ref_ack                    (),  // output      app_ref_ack
      .app_zq_ack                     (),  // output      app_zq_ack
      .ui_clk                         (clk),  // output      ui_clk 100MHz
      .ui_clk_sync_rst                (),  // output      ui_clk_sync_rst
      .app_wdf_mask                   (0),  // input [31:0]    app_wdf_mask
      // System Clock Ports
      .sys_clk_p                      (sys_clk_p),  // input        sys_clk_p
      .sys_clk_n                      (sys_clk_n),  // input        sys_clk_n
      .sys_rst                        (sys_rst) // input sys_rst
      );
            
    mem_control my_mem_control(clk,PixelClk,freeze_frame,pixel_in,pixels_out,we,rd,app_addr,app_cmd,app_en,app_wdf_data,
        app_wdf_end,app_wdf_wren,app_rd_data,app_rd_data_valid,app_rdy,app_wdf_rdy,frame_rst,cur_frame);

    pos_edge_detect v_sync_edge(clk,vid_pVSync,frame_rst);

    rgb2gray my_rgb2gray(vid_pData,pixel_in);    
    dvi2rgb_0 my_dvi2rgb(
        .TMDS_Clk_p(TMDS_Clk_p),        // input wire TMDS_Clk_p
        .TMDS_Clk_n(TMDS_Clk_n),        // input wire TMDS_Clk_n
        .TMDS_Data_p(TMDS_Data_p),      // input wire [2 : 0] TMDS_Data_p
        .TMDS_Data_n(TMDS_Data_n),      // input wire [2 : 0] TMDS_Data_n
        .RefClk(clk_out200),                // input wire RefClk
        .aRst(1'b0),                    // input wire aRst
        .vid_pData(vid_pData),          // output wire [23 : 0] vid_pData
        .vid_pVDE(vid_pVDE),            // output wire vid_pVDE
        .vid_pHSync(vid_pHSync_in),        // output wire vid_pHSync
        .vid_pVSync(vid_pVSync_in),        // output wire vid_pVSync
        .PixelClk(PixelClk),            // output wire PixelClk
        .aPixelClkLckd(),  // output wire aPixelClkLckd
        .DDC_SDA_I(DDC_SDA_I),          // input wire DDC_SDA_I
        .DDC_SDA_O(DDC_SDA_O),          // output wire DDC_SDA_O
        .DDC_SDA_T(DDC_SDA_T),          // output wire DDC_SDA_T
        .DDC_SCL_I(DDC_SCL_I),          // input wire DDC_SCL_I
        .DDC_SCL_O(DDC_SCL_O),          // output wire DDC_SCL_O
        .DDC_SCL_T(DDC_SCL_T),          // output wire DDC_SCL_T
        .debug(),                  // output wire debug
        .pRst(1'b0)                    // input wire pRst
      );

    rgb2vga_0 my_rgb2vga (
      .rgb_pData(rgb_pData_reg),    // input wire [23 : 0] rgb_pData
      .rgb_pVDE(vid_pVDE),      // input wire rgb_pVDE
      .rgb_pHSync(vid_pHSync),  // input wire rgb_pHSync
      .rgb_pVSync(vid_pVSync),  // input wire rgb_pVSync
      .PixelClk(PixelClk),      // input wire PixelClk
      .vga_pRed(vga_pRed),      // output wire [4 : 0] vga_pRed
      .vga_pGreen(vga_pGreen),  // output wire [5 : 0] vga_pGreen
      .vga_pBlue(vga_pBlue),    // output wire [4 : 0] vga_pBlue
      .vga_pHSync(vga_pHSync),  // output wire vga_pHSync
      .vga_pVSync(vga_pVSync)  // output wire vga_pVSync
    );
    
//    clk_wiz_1 my_clk_wiz
//    (
//        .clk_in1(clk),      
//        .clk_out1(clk_out400),
//        .clk_out2(clk_out200)
//    );
    
      clk_wiz_0 my_clk_wiz
     (
     // Clock in ports
      .clk_in1(clk),      // input clk_in1
      // Clock out ports
      .clk_out1(clk_out200));    // output clk_out1
      

    IOBUF IOBUF_SDA (
        .O(DDC_SDA_I),     // Buffer output
        .IO(sda_io),   // Buffer inout port (connect directly to top-level port)
        .I(DDC_SDA_O),     // Buffer input
        .T(DDC_SDA_T)      // 3-state enable input, high=input, low=output
    );
    
    IOBUF IOBUF_SCL (
        .O(DDC_SCL_I),     // Buffer output
        .IO(scl_io),   // Buffer inout port (connect directly to top-level port)
        .I(DDC_SCL_O),     // Buffer input
        .T(DDC_SCL_T)      // 3-state enable input, high=input, low=output
    );
    
    
    optical_flow_calc my_OF_calc(PixelClk,vid_pVDE,pixels_out,vx,vy);
    pixel_cord_gen my_cord_gen(PixelClk,vid_pVDE,vid_pHSync,vid_pVSync,pixel_x,pixel_y);
    optical_flow_display my_display(PixelClk,display_frame_pixel_reg,vx_reg,vy_reg,vid_pVDE,vid_pHSync,vid_pVSync,rgb_pData,pixel_x,pixel_y);   
    
        
    assign sys_rst = 1;
    assign pix_en = PixelClk & vid_pVDE;
    assign hpa = 1;  
    assign freeze_frame = sw[3];
    assign we = vid_pVDE;
    assign rd = vid_pVDE;
    assign desiplay_frame_select = (sw[2:0] == 7)?6:sw[2:0];
    assign display_frame_pixel = pixels_out[PIXEL_WIDTH * desiplay_frame_select +: PIXEL_WIDTH];
    
    always @(posedge PixelClk) begin
        vx_reg <= vx;
        vy_reg <= vy;
        rgb_pData_reg <= rgb_pData;
        display_frame_pixel_reg <= display_frame_pixel;
    end
                    
    assign vid_pHSync = (SYNC_INV)? ~vid_pHSync_in:vid_pHSync_in;
    assign vid_pVSync = (SYNC_INV)? ~vid_pVSync_in:vid_pVSync_in;

  
endmodule
