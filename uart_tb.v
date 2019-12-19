/**

    Uart_tb.v
    Tests uart_tx and uart_rx modules

    TODO add different baud rate tests
    TODO speed up tb
**/
`timescale 10ns / 10ns
//`define DEBUG

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
`define CLK_DELAY 32
`define CLK2_DELAY 5
`define CLK_CYCLE #`CLK_DELAY;#`CLK_DELAY;
`define CLK2_CYCLE #`CLK2_DELAY;#`CLK2_DELAY;
`define BAUD_DELAY #104166;
module uart_tb ();
	reg clk;
	reg[7:0] char,index;
	reg serial_data;
	reg[7:0] rx_data_t;
	reg rx_new_data_t;

	wire rst;
	wire rdy;
	wire rx_new_data;
	wire [7:0] rx_data;
	wire serial_out;

	reg clk2;
	reg serial_data2;
	reg[7:0] rx_data_t2;
	reg rx_new_data_t2;

	wire rdy2;
	wire rx_new_data2;
	wire [7:0] rx_data2;
	wire serial_out2;

	assign rst=0;

	uart_tx #(
	    .CLOCK_FREQ(16_000_000)
	) uart_tx1 ( //Parallel in, serial out shift register fitted with start and stop bit
		.clk_i(clk),
		.new_data(rx_new_data_t), //Keep transmitting until fifo is empty
		.dat_i(rx_data_t), //Input signal
		.rdy(rdy), //Ready for new data
		.dat_o(serial_out),  //Serial out
		.rst_i(rst)
	);
    uart_tx #(
        .CLOCK_FREQ(100_000_000)
    ) uart_tx2 (
        .clk_i(clk2),
        .new_data(rx_new_data_t2),
        .dat_i(rx_data_t2),
        .rdy(rdy2),
        .dat_o(serial_out2),
        .rst_i(rst)
    );
	uart_rx#(
	    .CLOCK_FREQ(16_000_000)
	) uart_rx1 (
		.clk_i(clk),
		.dat_i(serial_data),
		.dat_o(rx_data),
		.new_data(rx_new_data),
		.rst_i(rst)
	);
	initial begin
		clk=0;
        clk2=0;
		char=0;
		index=0;
		serial_data=0;
	end
	always #`CLK_DELAY clk=~clk;
	always #`CLK2_DELAY clk2=~clk2;

	initial begin
		$write("Testing uart.v...");
		`ifdef DEBUG $dumpfile("uart_tb.vcd"); `endif
		`ifdef DEBUG $dumpvars(0,clk,uart_rx1,uart_tx1,uart_tx2,char,index); `endif
		serial_data=1;
		for(char=8'h27;char<8'h32;char=char+1'b1) begin
			`CLK_CYCLE
			`BAUD_DELAY; //Wait for 1 bit length
			`BAUD_DELAY serial_data = 0;//Start bit
			for(index=8'h0;index<8;index=index+1'b1) begin
				#104167 serial_data = char[index];
			end
			`BAUD_DELAY serial_data = 1;//Stop bit
			`CLK_CYCLE;
			`assert(rx_data,char)
//			`assert(rx_data2,char)
			`ifdef DEBUG $write("%h/",char); `endif

		end

		for(char=8'h27;char<8'h30;char=char+1'b1) begin
			`ifdef DEBUG $write("%h/",char); `endif
			`CLK_CYCLE;
			rx_data_t=char;
			rx_data_t2=char;
			rx_new_data_t=1;
			rx_new_data_t2=1;
			`CLK2_CYCLE;
			rx_new_data_t2=0;
			`CLK_CYCLE rx_new_data_t=0;
			#104102;
			`assert(serial_out,0)
			`assert(serial_out2,0)
			for(index=8'h0;index<8;index=index+1) begin
				`BAUD_DELAY;
				`assert(serial_out,char[index])
				`assert(serial_out2,char[index])
			end
			#1041667;
		end
		$display("%m passed.");
		$finish;
	end

endmodule

