`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:        San Diego State University
// Engineer:       Pratik Yadav  
// 
// Create Date:    11:55:36 03/16/2015 
// Design Name: 
// Module Name:    FIR1 
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
//////////////////////////////////////////////////////////////////////////////////
module FIR1  #(parameter WIX = 4,      // integer part bitwidth for input sample  
                         WFX = 5,      // fractional part bitwidth for input sample
                         WIC=4,        // integer part bitwidth for Coefficient
                         WFC=5,        // fractional part bitwidth for Coefficient
                         WIO =WIX+WIC, // integer part bitwidth for addition output (user input)
                         WFO =WFX+WFC, // integer part bitwidth for addition outout (user input)
                         N = 4         // order  
                       )
  (
    input signed [(WIX+WFX-1):0] X,
    input CLK,
    input RESET,
    output  reg signed [(WIO+WFO+N-1):0] Y,
    output   reg OF_add1,
    output   reg OF_mult1
   );
     
reg signed [(WIC+WFC-1):0] filter_coef [0:N];  // memory to store Coefficients 
wire signed [(WIO+WFO-1):0] wire_mult [0:N];  // multiplier wires
wire signed [(WIX+WFX-1):0] wire_DFF [0:N];   // DFF wires
wire signed [(WIO+WFO+N-1):0] wire_Adders [0:(N-1)];  // Adder wires
wire  [0:(N-1)] OF_add;
wire  [0:N] OF_mult; 
 

initial begin
  $readmemb ("coefficients.txt",filter_coef);
end

//--------------------------- overflow for adders---------------------------------------//
always @(*) begin
  if (|(OF_add)) begin
             OF_add1 <= 1'b1;
      end
  else 
        OF_add1 <= 1'b0;
end

//-----------------------------overflow for multiply------------------------------------//
always @(*) begin
  if (|(OF_mult)) begin
             OF_mult1 <= 1'b1;
      end
  else 
        OF_mult1 <= 1'b0;
end

 
assign wire_DFF[0] = X;

 //---------------------------------------------------------DFF---------------------------------------------------//
generate
  genvar i;
    for (i = 0; i <= N-1; i=i+1) begin: xi
      DFF di (.d(wire_DFF[i]),.CLK(CLK),.RESET(RESET),.q(wire_DFF[i+1]));
    end
endgenerate 

//-------------------------------------------------------multiply--------------------------------------------------//
generate
  genvar j;
    for (j = 0; j <= N; j=j+1) begin: xj
      FPmultiply #(.WIO(WIO), .WFO(WFO)) hj (.A(wire_DFF[j]),.B(filter_coef[j]),.multiply(wire_mult[j]),.overflow1(OF_mult[j]));
    end 
endgenerate 

//-------------------------------------------------------addition-------------------------------------------------//
FPadder  #(.WIO(WIO+N), .WFO(WFO)) addk (.A(wire_mult[0]),.B(wire_mult[1]),.out(wire_Adders[0]),.overflow(OF_add[0]));
generate
  genvar k;
    for (k = 1; k <= N-1; k=k+1) begin: xk
      FPadder  #(.WIO(WIO+N), .WFO(WFO)) addk (.A(wire_Adders[k-1]),.B(wire_mult[k+1]),.out(wire_Adders[k]),.overflow(OF_add[k]));
    end   
endgenerate

always @(posedge CLK) begin
if (RESET)begin
  Y <= 0;
  end
  else
  Y <= wire_Adders[N-1];
end

endmodule
