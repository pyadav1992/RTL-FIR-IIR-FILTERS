`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// Company:        San Diego State University
// Engineer:       Pratik Yadav
//
// Create Date:   21:19:30 03/17/2015
// Design Name:   FixedPoint_FIR_Filter_TM
// Module Name:   C:/Users/218/Desktop/xilinx/FixedPoint_Filter/tb_FixedPoint_FIR_Filter_TM.v
// Project Name:  FixedPoint_Filter
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: FixedPoint_FIR_Filter_TM
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  
// If not, see <https://www.gnu.org/licenses/>
////////////////////////////////////////////////////////////////////////////////

module tb_FIR2;

parameter No_Input = 50;
parameter N = 4;                    // filter order for the filter
parameter No_coeff = 8;             // number of coefficients available in the LUT  
parameter WI1 = 4;                  // Integer bitwidth for input signal samples 
parameter WF1 = 5;                  // Fractional bitwidth for input signal samples
parameter WIC = 4;                  // Integer bitwidth for input coefficients 
parameter WFC = 5;                  // Fractional bitwidth for input coefficients
	
	
	// Inputs
	reg [WI1+WF1-1:0] X;               //input samples 
	reg RESET;
	reg CLK;
	reg test;

	// Outputs
	wire  overflow;
	wire [(WI1+WIC+N)+(WF1+WFC)-1:0] Filt_Out;
	
	reg [WI1+WF1-1:0] X_array [0:No_Input-1];
	real X_real, in2_real;
	real Filt_Out_real;
	

	// Instantiate the Unit Under Test (UUT)
	FIR2 #(.N(N),
									.No_coeff(No_coeff),
									.WI1(WI1),
									.WF1(WF1),
									.WIC(WIC),
									.WFC(WFC))
									uut00 (.X(X), .RESET(RESET),	.CLK(CLK), .test(test), .Filt_Out(Filt_Out), .overflow(overflow));

	parameter ClockPeriod = 10;
	initial CLK =0;
	always #(ClockPeriod/2) CLK = ~CLK;

	//=====  Function Definition
	
		function real FixedToFloat;
					input [63:0] in;
					input integer WI;
					input integer WF;
					integer i;
					real retVal;
					
					begin
					retVal = 0;
					
					for (i = 0; i < WI+WF-1; i = i+1) begin
								if (in[i] == 1'b1) begin
										retVal = retVal + (2.0**(i-WF));
								end
					end
					FixedToFloat = retVal - (in[WI+WF-1] * (2.0**(WI-1)));
					end
		endfunction
	
		integer i;

initial begin 

	X = 0;
	test = 0;
	@(posedge CLK)RESET = 1;
		$readmemb("input1.txt",X_array);
			for(i=0; i<54; i=i+1) begin
					@(posedge CLK) RESET = 0; X = X_array[i]; test = 1;
					@(posedge CLK) test = 0;
					@(posedge CLK);
					@(posedge CLK);
					@(posedge CLK);
					@(posedge CLK);
					@(posedge CLK);
					$display(FixedToFloat(Filt_Out, WI1, WF1));
			end
  $finish;
end
      
	always @ X X_real = FixedToFloat(X, WI1, WF1); //convert in1 to real
	always @ Filt_Out Filt_Out_real = FixedToFloat(Filt_Out, (WI1+WIC+N), (WF1+WFC));//convert Out2 to real
		
endmodule