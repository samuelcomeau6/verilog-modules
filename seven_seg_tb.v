`timescale 1ns / 1ns
`define assert(signal, value) \
	if(signal != value) begin \
		$display(" ",$realtime,":ASSERTION FAILED in %m: signal != value");\
		$display("          %m:signal = ",signal);\
		$display("          %m:value = ",value);\
		$stop;\
	end \
	if(^signal === 1'bX) begin \
		$display(" ",$realtime,":SIGNAL UNASSIGNED AT ASSERTION in %m: signal != value");\
		$display("          %m:signal = ",signal);\
		$display("          %m:value = ",value);\
		$stop;\
	end
module seven_seg_tb();
    reg[3:0] in;
    wire[6:0] seg;
    seven_seg seven_seg(.in(in),.seg(seg));
    initial begin
        $write("Testing seven_seg.v ...");
        in=8'd0;
        #10 `assert(seg,7'b0111111);
        in=8'd1;
        #10 `assert(seg,7'b0000110);
        in=8'd2;
        #10 `assert(seg,7'b1011011);
        in=8'd3;
        #10 `assert(seg,7'b1001111);
        in=8'd4;
        #10 `assert(seg,7'b1100110);
        in=8'd5;
        #10 `assert(seg,7'b1101101);
        in=8'd6;
        #10 `assert(seg,7'b1111101);
        in=8'd7;
        #10 `assert(seg,7'b0000111);
        in=8'd8;
        #10 `assert(seg,7'b1111111);
        in=8'd9;
        #10 `assert(seg,7'b1101111);
        $display("Test passed!");
        $finish;
    end
endmodule
