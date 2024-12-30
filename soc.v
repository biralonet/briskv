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

   Clock #(
	   .BITS(21)
   ) clock (
	    .CLK(CLK),
	    .RESET(RESET),
	    .clk(clk),
	    .reset(reset));

   reg [5:0] MEM [0:5];
   initial begin
      MEM[0] = 6'b000001;
      MEM[1] = 6'b000010;
      MEM[2] = 6'b000100;
      MEM[3] = 6'b001000;
      MEM[4] = 6'b010000;
      MEM[5] = 6'b100000;
   end

   reg [2:0] PC = 0;
   reg [5:0] leds = 0;
   always @(posedge clk) begin
      leds <= MEM[PC];
      PC <= (reset || PC == 5) ? 0 : (PC + 1);
   end

   assign LEDS = ~leds;
   assign TXD = 1'b0;

endmodule
