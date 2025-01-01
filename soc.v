`include "processor.v"
`include "memory.v"
`include "clock.v"

module Soc (
	    input	 CLK,
	    input	 RESET,
	    output [5:0] LEDS,
	    input	 RXD,
	    output	 TXD
);

   wire			 clk;
   wire			 reset;
   Memory memory(.clk(clk),
		 .mem_addr(mem_addr),
		 .mem_rdata(mem_rdata),
		 .mem_rstrb(mem_rstrb));

   wire [31:0]		 mem_addr;
   wire [31:0]		 mem_rdata;
   wire			 mem_rstrb;
   wire [31:0]		 x10;
   Processor processor(.clk(clk),
		       .reset(reset),
		       .mem_addr(mem_addr),
		       .mem_rdata(mem_rdata),
		       .mem_rstrb(mem_rstrb),
		       .x10(x10));
`ifdef BENCH
   assign LEDS = x10[5:0];
`else
   assign LEDS = ~x10[5:0];
`endif

   Clock clock(.CLK(CLK),
	       .RESET(RESET),
	       .clk(clk),
	       .reset(reset));

   assign TXD = 1'b0;

endmodule
