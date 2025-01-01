module Clock (
	      input  CLK,
	      input RESET,
	      output clk,
	      output reset
);
   assign clk = CLK;
   assign reset = RESET;
endmodule
