///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///
/// Top-Level Verilog Module
///
/// Only include pins the design is actually using.  Make sure that the pin is
/// given the correct direction: input vs. output vs. inout
///
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
module seven_seg (
    input[3:0] in,
    output[6:0] seg
);
    //Assign seg[n] to  A-G
    assign seg[0] = (~in[3]&~in[2]&in[1])|(~in[2]&~in[1]&~in[0])|(~in[3]&in[2]&in[0])|(~in[3]&in[2]&in[1]&~in[0])|(in[3]&~in[2]&~in[1]&in[0]);
    assign seg[1] = (~in[3]&~in[2])|(~in[3]&in[2]&~in[1]&~in[0])|(~in[3]&in[2]&in[1]&in[0])|(in[3]&~in[2]&~in[1]);
    assign seg[2] = (~in[3]&~in[2]&~in[1]&~in[0])|(~in[3]&~in[2]&in[0])|(~in[3]&in[2])|(in[3]&~in[2]&~in[1]);
    assign seg[3] = (~in[3]&~in[2]&~in[1]&~in[0]) | (~in[3]&~in[2]&in[1]) | (~in[3]&in[2]&~in[1]&in[0]) | (~in[3]&in[2]&in[1]&~in[0]) | (in[3]&~in[2]&~in[1]);
    assign seg[4] = (~in[3]&~in[2]&~in[0])|(~in[3]&in[2]&in[1]&~in[0])|(in[3]&~in[2]&~in[1]&~in[0]);
    assign seg[5] = (~in[3]&~in[1]&~in[0])|(~in[3]&in[2]&~in[1])|(~in[3]&in[2]&in[1]&~in[0])|(in[3]&~in[2]&~in[1]);
    assign seg[6] = (~in[3]&~in[2]&in[1])|(~in[3]&in[2]&~in[1])|(~in[3]&in[2]&in[1]&~in[0])|(in[3]&~in[2]&~in[1]);
endmodule
