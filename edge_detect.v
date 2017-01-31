`timescale 1ns / 1ps

module pos_edge_detect(
    input clk,
    input signal_in,
    output edge_out
    );
    reg [2:0] sync_chain;
    initial sync_chain = 3'b111;
    always @(posedge clk) 
        sync_chain <= {sync_chain[1:0],signal_in};

    assign edge_out = ~sync_chain[2] & sync_chain[1];
endmodule
