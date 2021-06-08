`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:        San Diego State University
// Engineer:       Pratik Yadav 
// 
// Create Date:    14:13:47 04/18/2015 
// Design Name: 
// Module Name:    IIR_Mcascaded 
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
module IIR_Mcascaded #(parameter WIX=3, 
                                 WFX=7,
                                 WIS=5,
                                 WFS=11,
                                 WIC=2,
                                 WFC=8,
                                 //WIO=WIX+WIS+WIC+N,
                                 //WFO=WFX+WFS+WFC,
                                 WIO = 8,
                                 WFO = 18,
                                 N=2)
     (
      //input signed [(WIX+WFX+WIS+WFS-1):0] X,
      input signed [(WIX+WFX-1):0] X,
      input CLK,
      input RESET,
      input CE,
      output  reg signed [(WIO+WFO-1):0] Y,
      output reg overflow
    );
   
reg signed  [(WIC+WFC-1):0] filter_coef [0: (((N/2)-1)*6)-1];     // memory to store FF filter Coefficients 
reg signed  [(WIS+WFS-1):0] Scale [0:(N/2)];                      // memory to store Scaling Factors
//wire signed [((WIX+WIS)+(WFX+WFS))-1 : 0] Scale_Wire[0 : (N/2)];  // 1st Scaling multiplier output
wire signed [(WIO+WFO)-1 : 0] Scale_Wire[0 : (N/2)];
wire CLK1;
wire OF_scale;
wire [0 : ((N/2)-1)] SOS_overflow ;

initial begin
  $readmemb ("filtercoeff.txt",filter_coef);
  $readmemb ("Scale.txt",Scale);
end

//--------------------------- overflow---------------------------------------//
always @(*) begin
  if ((|(SOS_overflow)) || OF_scale) begin
             overflow <= 1'b1;
      end
  else 
         overflow <= 1'b0;
end

assign CLK1 = CLK & CE;            

FixedPoint_Multiplier            #( .WI1(WIX),
                      .WF1(WFX),
                      .WI2(WIS),
                      .WF2(WFS),
                      .WIO(WIO),
                      .WFO(WFO)) 
                              mult_Scale1 (.in1(X),
                                       .in2(Scale[0]),
                                       .FixedPoint_Mul_Out(Scale_Wire[0]),
                                       .overFlow(OF_scale));
              
generate
  genvar i;
    for (i = 0; i <= (N/2)-1; i=i+1) begin: xi
      SOS #(//.WIX(WIX),
           //.WFX(WFX),
          .WIX(WIO),
           .WFX(WFO),
          .WIS(WIS),
          .WFS(WFS),
          .WIC(WIC),
          .WFC(WFC),
          .WIO(WIO),
          .WFO(WFO)) SOSi (.X(Scale_Wire[i]),
                        .S(Scale[i+1]),
                      .CLK(CLK1),
                      .RESET(RESET),
                      .Y(Scale_Wire[i+1]),
                      .SOS_overflow(SOS_overflow[i]));
    end
endgenerate 
  
  always @(*) begin
      if(~CE)
        Y <= 0;
         else begin       
        if (~RESET)
          Y <= 0;
        else
        Y <= Scale_Wire[(N/2)];
        end
    end           

endmodule
