`include "processor.v"
`include "memory.v"
`include "clock.v"

module Soc (
	    input	     CLK,
	    input	     RESET,
	    output reg [5:0] LEDS,
	    input	     RXD,
	    output	     TXD
);

   wire			 clk;
   wire			 reset;

   wire [31:0]		 mem_addr;
   wire [31:0]		 mem_rdata;
   wire			 mem_rstrb;
   wire [31:0]		 mem_wdata;
   wire [3:0]		 mem_wmask;

   wire [29:0]		 mem_wordaddr = mem_addr[31:2];
   wire			 is_io        = mem_addr[22];
   wire			 is_ram       = !is_io;
   wire			 mem_wstrb    = |mem_wmask;

   Memory memory(.clk(clk),
		 .mem_addr(mem_addr),
		 .mem_rdata(mem_rdata),
		 .mem_rstrb(is_ram & mem_rstrb),
		 .mem_wdata(mem_wdata),
		 .mem_wmask({4{is_ram}} & mem_wmask));

   Processor processor(.clk(clk),
		       .reset(reset),
		       .mem_addr(mem_addr),
		       .mem_rdata(mem_rdata),
		       .mem_rstrb(mem_rstrb),
		       .mem_wdata(mem_wdata),
		       .mem_wmask(mem_wmask));

   Clock clock(.CLK(CLK),
	       .RESET(RESET),
	       .clk(clk),
	       .reset(reset));

   localparam		 IO_LEDS_BIT = 0;
   always @(posedge clk) begin
      if (is_io & mem_wstrb & mem_wordaddr[IO_LEDS_BIT]) begin
`ifdef BENCH
	 LEDS <= mem_wdata;
`else
	 LEDS <= ~mem_wdata;
`endif
      end
   end

   assign TXD = 1'b0;

endmodule
