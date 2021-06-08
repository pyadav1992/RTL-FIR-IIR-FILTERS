`timescale 1ns / 1ns

////////////////////////////////////////////////////////////////////////////////
// Company:        San Diego State University
// Engineer:       Pratik Yadav 
//
// Create Date:   16:43:50 03/16/2015
// Design Name:   FIR1
// Module Name:   C:/Users/Administrator/Desktop/fixedpoint/FPmultiply/FIR_type1/tb_FIR_type1.v
// Project Name:  FIR_type1
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: FIR1
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

module tb_IIR_Mcascaded ;
parameter             WIX=3, 
                      WFX=7,
											WIS=5,
											WFS=11,
											WIC=2,
											WFC=8,
											WIO=14,
											WFO=24,
											N=8;
 

	// Inputs
	//reg [(WIX+WFX+WIS+WFS-1):0] X;
	reg [(WIX+WFX-1):0] X;
	reg CLK;
	reg RESET;
   reg CE;
	
	// Outputs
	wire [(WIO+WFO-1):0] Y;
	wire overflow;
	real in1_real,out_real;

function real fixedToFloat;
	          input [63:0] in;
				 input integer WI;
				 input integer WF;
				 integer idx;
				 real retVal;
				 begin
				 retVal = 0;
				 for (idx = 0; idx<WI+WF-1;idx = idx+1)begin
						if(in[idx] == 1'b1)begin
						  retVal = retVal + (2.0**(idx-WF));
						end
				 end
				 fixedToFloat = retVal -(in[WI+WF-1]*(2.0**(WI-1)));
				 end
endfunction
	// Instantiate the Unit Under Test (UUT)
	IIR_Mcascaded #(.WIX(WIX),.WFX(WFX),.WIC(WIC),. WFC( WFC),.WIS(WIS),.WFS(WFS),.WIO(WIO),.WFO(WFO),.N(N)) uut1 (
		.X(X), 
		 .CE(CE),
		.CLK(CLK), 
		.RESET(RESET), 
		.Y(Y), 
		.overflow(overflow)
	);

parameter clockperiod = 20;
initial CLK = 0;
always #(clockperiod/2) CLK = ~ CLK;

parameter data_width = 10;
parameter addr_width = 50;

reg [(data_width-1):0] rom [addr_width-1:0];
reg [(WIC+WFC)-1 : 0 ] filter_coef [0 : 23];
integer j = 0; 

initial begin
	$readmemb ("input.txt",rom);
	$readmemb ("filtercoeff.txt",filter_coef);
	
for (j = 0; j <= 5; j = j + 1) 
      begin
		tb_IIR_Mcascaded.uut1.xi[0].SOSi.SOS_filter_coef[j] = filter_coef[j];
		end
		
for (j = 0; j <= 5; j = j + 1) 
      begin
		tb_IIR_Mcascaded.uut1.xi[1].SOSi.SOS_filter_coef[j] = filter_coef[(j+6)];
		end
for (j = 0; j <= 5; j = j + 1) 
      begin
		tb_IIR_Mcascaded.uut1.xi[2].SOSi.SOS_filter_coef[j] = filter_coef[(j+12)];
		end
for (j = 0; j <= 5; j = j + 1) 
      begin
		tb_IIR_Mcascaded.uut1.xi[3].SOSi.SOS_filter_coef[j] = filter_coef[(j+18)];
		end
end


integer i;
	initial begin
	    X = 0;
		 RESET = 0;
		 CE = 0;
		@(posedge CLK) RESET = 0; CE = 0;
		@(posedge CLK) RESET = 0; CE = 0;
    @(posedge CLK) RESET = 0; CE = 1;
		@(posedge CLK) RESET = 0; CE = 1;
		@(posedge CLK) RESET = 0; CE = 1;
		@(posedge CLK) RESET = 1;
	    for (i = 0; i <= 49 ; i = i + 1 )begin
        @(posedge CLK)  X = rom[i];
        $display (fixedToFloat(Y,WIO,WFO));
        //$display (fixedToFloat(X,WIX,WFX));
		 end 		
	  @(posedge CLK);
		@(posedge CLK);
		@(posedge CLK);
		$finish;
	end
	always @ X in1_real = fixedToFloat(X,WIX,WFX);
	always @ Y out_real = fixedToFloat(Y,WIO,WFO); 

endmodule