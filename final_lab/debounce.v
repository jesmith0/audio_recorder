`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:57:00 04/23/2015 
// Design Name: 
// Module Name:    debounce 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module debounce (reset, clk, noisy, clean);

   input reset, clk, noisy;
   output clean;

   parameter NDELAY = 243750; // was 650000 for 100MHz clock
   parameter NBITS = 18;

   reg [NBITS-1:0] count;
   reg xnew, clean;

	always @(posedge clk)
		if (reset) begin xnew <= noisy; clean <= noisy; count <= 0; end
		else if (noisy != xnew) begin xnew <= noisy; count <= 0; end
		else if (count == NDELAY) clean <= xnew;
		else count <= count+1;

endmodule
