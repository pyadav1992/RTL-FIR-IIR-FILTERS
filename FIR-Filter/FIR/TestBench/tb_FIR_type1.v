`timescale 1ns / 1ps
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

module tb_FIR_type1;

parameter WIX = 4,            // integer part bitwidth for integer 1  
          WFX = 5,            // fractional part bitwidth for integer 1
          WIC=4,
          WFC=5,
          WIO =WIX+WIC,  // integer part bitwidth for addition output (user input)
          WFO =WFX+WFC,  // integer part bitwidth for addition outout (user input)
          N = 4;
                       

  // Inputs
  reg [(WIX+WFX-1):0] X;
  reg CLK;
  reg RESET;

  // Outputs
  wire [(WIO+WFO+N-1):0] Y;
  wire OF_add;
  wire OF_mult;

  real in1_real,in2_real,out_real;
  real floatout;

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
  FIR1 #(.WIX(WIX),.WFX(WFX),.WIC(WIC),. WFC( WFC),.WIO(WIO),.WFO(WFO),.N(N)) uut (
    .X(X), 
    .CLK(CLK), 
    .RESET(RESET), 
    .Y(Y), 
    .OF_add1(OF_add1), 
    .OF_mult1(OF_mult1)
  );

parameter clockperiod = 20;
initial CLK = 0;
always #(clockperiod/2) CLK = ~ CLK;

parameter data_width = 9;
parameter addr_width = 50;

reg [(data_width-1):0] rom [addr_width-1:0];
initial begin
  $readmemb ("input1.txt",rom);
end

integer i;
  initial begin
  
      X = 0;
     RESET = 1;
    @(posedge CLK) RESET = 0;
   
      for (i = 0; i <= 49 ; i = i + 1 )begin
     @(posedge CLK)  X = rom[i];
     $display (fixedToFloat(Y,WIO,WFO));
     end    
      $finish;
  end
  always @ X in1_real = fixedToFloat(X,WIX,WFX);
  always @ Y out_real = fixedToFloat(Y,WIO,WFO);   
endmodule