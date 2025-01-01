`include "soc.v"

module top(
           input        CLK,
           input        RESET,
           output [5:0] LEDS,
           input        RXD,
           output       TXD
);

   Soc soc(.CLK(CLK),
	   .RESET(RESET),
	   .LEDS(LEDS),
	   .RXD(RXD),
	   .TXD(TXD));

endmodule
