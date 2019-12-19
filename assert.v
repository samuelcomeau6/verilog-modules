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