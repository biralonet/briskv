`include "soc.v"

module top(
           input        CLK,
           input        RESET,
           output [5:0] LEDS,
           input        RXD,
           output       TXD
);

   Briskv briskv(
	    .CLK(CLK),
	    .RESET(RESET),
	    .LEDS(LEDS),
	    .RXD(RXD),
	    .TXD(TXD));
   
endmodule
