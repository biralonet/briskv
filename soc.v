`include "clock.v"

module Briskv (
	    input	 CLK,
	    input	 RESET,
	    output [5:0] LEDS,
	    input	 RXD,
	    output	 TXD
);

   wire			 clk;
   wire			 reset;

   reg [5:0]		 count = 0;

   always @(posedge clk) begin
      count <= count + 1;
   end

   Clock #(
	   .BITS(21)
   ) clock (
	    .CLK(CLK),
	    .RESET(RESET),
	    .clk(clk),
	    .reset(reset));

   assign LEDS = ~count;
   assign TXD = 1'b0;

endmodule
