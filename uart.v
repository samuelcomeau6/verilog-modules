`define CLOG2(x) \
   (x <= 2) ? 1 : \
   (x <= 4) ? 2 : \
   (x <= 8) ? 3 : \
   (x <= 16) ? 4 : \
   (x <= 32) ? 5 : \
   (x <= 64) ? 6 : \
   (x <= 128) ? 7 : \
   (x <= 256) ? 8 : \
   (x <= 512) ? 9 : \
   (x <= 1024) ? 10 : \
   (x <= 2048) ? 11 : \
   (x <= 4096) ? 12 : \
   (x <= 8192) ? 13 : \
   (x <= 16384) ? 14 : \
   (x <= 32768) ? 15 : \
   (x <= 65536) ? 16 : \
   -1
module uart_tx #(
	parameter CLOCK_FREQ=100_000_000, //FPGA's clock freq B2 boards = 16MHz
	parameter BAUD=9600, //Default baudrate
	parameter START_BITS=1, //Start bits(initial 0)
	parameter STOP_BITS=1, //Stop bits (ending high)
	parameter PARITY=0, //Parity, not yet implemented
	parameter WIDTH=8 //Data width
)(
	input clk_i, //FPGA clock
	input rst_i,
	input new_data, //New data strobe, must be high for at least one clk_i
	input [WIDTH-1:0] dat_i, //Input data to be sent
	output rdy, //High when module is not busy
	output dat_o //serial out
);
	//Definitions
	localparam SIZE=WIDTH+START_BITS+STOP_BITS; //Combined width with start,stop and parity
	localparam MAX_ADDR=`CLOG2(SIZE)+1;
	localparam DIV=CLOCK_FREQ/BAUD+1; //Divider constant
	localparam MAX_COUNT=`CLOG2(DIV); //Size of the divider register

	reg [MAX_COUNT:0] divider; //Clock divider
	reg [SIZE-1:0] byte_d,byte_q=8'd0; //Byte output
	reg [MAX_ADDR-1:0] shift_d,shift_q=0; //Shift counter
	reg rdy_d,rdy_q=1;
	reg [1:0] state_d,state_q=0; //FSM register

	localparam READY=2'd0;
	localparam LOAD=2'd1;
	localparam SHIFT=2'd2;

	//Assignments
	assign rdy=rdy_q;
	assign dat_o=byte_q[0]|rdy;

	//Combinatorial Logic
	always @* begin
		state_d=state_q;
		shift_d=0;
		byte_d=byte_q;
		rdy_d=rdy_q;
		case(state_q)
			READY: begin
				rdy_d=1;
				if(new_data) begin
					rdy_d=0;
					state_d=LOAD;
				end else state_d=READY;
			end
			LOAD: begin
				rdy_d=0;
				byte_d={{STOP_BITS{1'b1}},dat_i,{START_BITS{1'b0}}};
				state_d=SHIFT;
			end
			SHIFT: begin
				shift_d=shift_q+1;
				byte_d=byte_q>>1;
				if(shift_q>=SIZE-1) state_d=READY;
				else state_d=SHIFT;
			end
			default:begin
				state_d=READY;
			end
		endcase
	end

	//Sequential Logic
	always @(posedge clk_i) begin
		if(rst_i) begin
			divider<=0;
			state_q<=READY;
			rdy_q<=1;
			byte_q<=0;
			shift_q<=0;
		end
		else begin
			rdy_q<=rdy_d;
			state_q<=state_d;
			divider<=divider+1;
			if(state_q==LOAD) begin //only do once per transmission
			    byte_q<=byte_d;
				divider<=0;
				shift_q<=0;
			end
			if(divider>=DIV) begin //Shift
				divider<=0;
				byte_q<=byte_d;
				shift_q<=shift_d;
			end
		end
	end
endmodule

module uart_rx #(
	parameter CLOCK_FREQ=100_000_000, //FPGA's clock freq B2 boards = 16MHz
	parameter BAUD=9600, //Default baudrate
	parameter START_BITS=1,
	parameter STOP_BITS=1,
	parameter PARITY=0, //TODO Not yet implemented
	parameter WIDTH=8 //Data width

)(
	input clk_i,
	input rst_i,
	input dat_i, //Serial in
	output [WIDTH-1:0] dat_o,
	output new_data  //High for one full clock cycle when new data is available
);
	localparam DIV=CLOCK_FREQ/BAUD;//Divider constant
	localparam HDIV=DIV/2; //Half a division
  	localparam MAX_COUNT=`CLOG2(DIV); //Size of the divider register
	localparam MAX_ADDR=`CLOG2(WIDTH);

  	localparam READY=2'd0;
	localparam SYNC=2'd1;
	localparam READ=2'd2;
	localparam STOP=2'd3;

	reg new_data_d, new_data_q=0;
	reg data_in_r_d, data_in_r_q=1; //Must be one on start
	reg [1:0] state_d, state_q=0;
	reg [MAX_COUNT:0] ctr_d, ctr_q=0;
	reg [MAX_ADDR:0] bit_ctr_d, bit_ctr_q=0;
	reg [WIDTH-1:0] data_d, data_q;

	assign dat_o=data_q[WIDTH-1:0];
	assign new_data=new_data_q;

	always @* begin
	    state_d=state_q;
	    new_data_d=new_data_q;
	    bit_ctr_d=bit_ctr_q;
	    data_d=data_q;
	    ctr_d=ctr_q;
	    data_in_r_d=dat_i;
		case (state_q)
			READY: begin
				bit_ctr_d=0;
				ctr_d=0;
				new_data_d=0;
				if (data_in_r_q==0) begin //Start processing when input goes low
					state_d=SYNC;
				end
			end
			SYNC: begin //Count a half division to center data on pulse
				ctr_d=ctr_q + 1;
				if (ctr_q==HDIV) begin
					ctr_d=0;
					state_d=READ;
				end
			end
			READ: begin //Record data
				ctr_d=ctr_q + 1;
				if (ctr_q==DIV) begin
					if(bit_ctr_q<WIDTH) data_d={data_in_r_q, data_q[(WIDTH-1):1]};
					bit_ctr_d=bit_ctr_q + 1;
					ctr_d=0;
					if (bit_ctr_q==WIDTH) begin
						state_d=STOP;
						new_data_d=1;
					end
				end
			end
			STOP: begin //Line must go high before another byte is read
				if (data_in_r_q==1) begin
					state_d=READY;
				end
			end
			default: begin
				state_d=READY;
			end
		endcase
	end

    //Combinational Logic
	always @(posedge clk_i) begin
		if(rst_i) begin
			ctr_q<=0;
			bit_ctr_q<=0;
			data_q<=0;
			new_data_q<=0;
			data_in_r_q<=1;
			state_q<=READY;
		end else begin
			ctr_q<=ctr_d;
			bit_ctr_q<=bit_ctr_d;
			data_q<=data_d;
			new_data_q<=new_data_d;
			data_in_r_q<=data_in_r_d;
			state_q<=state_d;
		end
	end
endmodule
