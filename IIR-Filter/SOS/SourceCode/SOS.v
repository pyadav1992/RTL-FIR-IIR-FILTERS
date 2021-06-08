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
module SOS  #(parameter N = 2,              // order  
                        WIX = 3,            // integer part bitwidth for input sample  
                        WFX = 7,            // fractional part bitwidth for input sample
                        WIC = 2,            // integer part bitwidth for Coefficient
                        WFC = 8,            // fractional part bitwidth for Coefficient
                        WIS = 5,            // integer part bitwidth for Scaling
                        WFS = 11,           // fractional part bitwidth for Scaling
                        WIO =WIX+WIS+WIC+N, // integer part bitwidth for addition output (user input)
                        WFO =WFX+WFS+WFC    // integer part bitwidth for addition outout (user input)
                       )
  (
    //input signed [(WIX+WFX+WIS+WFS-1):0] X,
    input signed [(WIX+WFX-1):0] X,
    input signed [(WIS+WFS-1):0] S,
    input CLK,
    input RESET,
    output   signed [(WIO+WFO-1):0] Y,
    output   reg SOS_overflow
   );
   
//-----------------------------------feedforward---------------------------------------//  
   wire signed [(WIX+WFX+WIC+WFC-1):0] wire_mult [0:N];           // multiplier wires
   wire signed [(WIX+WFX-1):0] wire_DFF [0:N];                    // DFF wires
   wire signed [(WIX+WFX+WIC+WFC+N-1):0] wire_Adders [0:(N-1)];   // Adder wires  
   
//--------------------------------------feedback---------------------------------------//  
   wire signed [(WIX+WIS+(2*WIC)+WFX+WFS+(2*WFC)-1):0] FB_wire_mult [0:(N+1)];     // feedback multiplier wires
   wire signed [(WIX+WIS+(2*WIC)+WFX+WFS+(2*WFC)-1):0] FB_wire_DFF [0:N];          // feedback DFF wires
   wire signed [(WIX+WIS+(2*WIC)+WFX+WFS+(2*WFC)-1):0] FB_wire_Adders [0:(N-1)];   // feedback Adder wires  
   
//-----------------------------------overflow------------------------------------------// 
   wire  [0:(N-1)] OF_add;
   wire  [0:N] OF_mult;
   wire  [0:(N-1)] FB_OF_add;
   wire  [0:N] FB_OF_mult;
   wire  OF_scale;  
   
   reg [(WIC+WFC-1):0] SOS_filter_coef [0 : 5];
//--------------------------- overflow---------------------------------------//
always @(*) begin
  if (|(OF_add) || |(OF_mult) || OF_scale) begin
             SOS_overflow <= 1'b1;
      end
  else 
         SOS_overflow <= 1'b0;
end

//-------------------------------------------------Feedforward Section--------------------------------------------// 
assign wire_DFF[0] = X;
 //---------------------------------------------------------DFF---------------------------------------------------//
DFF #(.BW(WIX+WFX)) D0 (.d(wire_DFF[0]),.CLK(CLK),.RESET(RESET),.q(wire_DFF[1]));
DFF #(.BW(WIX+WFX)) D1 (.d(wire_DFF[1]),.CLK(CLK),.RESET(RESET),.q(wire_DFF[2]));
//-------------------------------------------------------multiply--------------------------------------------------//
FixedPoint_Multiplier         #( .WI1(WIX),
                        .WF1(WFX),
                        .WI2(WIC),
                        .WF2(WFC),
                        .WIO(WIX+WIC),
                        .WFO(WFX+WFC)) 
                                mult0 
                                    (.in1(wire_DFF[0]),
                                    .in2(SOS_filter_coef[0]),
                                    .FixedPoint_Mul_Out(wire_mult[0]),
                                    .overFlow(OF_mult[0]));
        
FixedPoint_Multiplier         #( .WI1(WIX),
                        .WF1(WFX),
                        .WI2(WIC),
                        .WF2(WFC),
                        .WIO(WIX+WIC),
                        .WFO(WFX+WFC)) 
                                mult1 
                                      (.in1(wire_DFF[1]),
                                     .in2(SOS_filter_coef[1]),
                                     .FixedPoint_Mul_Out(wire_mult[1]),
                                     .overFlow(OF_mult[1]));
        
FixedPoint_Multiplier         #( .WI1(WIX),
                        .WF1(WFX),
                         .WI2(WIC),
                        .WF2(WFC),
                        .WIO(WIX+WIC),
                        .WFO(WFX+WFC)) 
                                mult2 (.in1(wire_DFF[2]),
                                     .in2(SOS_filter_coef[2]),
                                     .FixedPoint_Mul_Out(wire_mult[2]),
                                     .overFlow(OF_mult[2]));
//-------------------------------------------------------addition-------------------------------------------------//
FPadder        #( .WI1(WIX+WIC),
               .WF1(WFX+WFC),
               .WI2(WIX+WIC),
               .WF2(WFX+WFC),
               .WIO(WIX+WIC+N),
               .WFO(WFX+WFC)) 
                        add0 (.A(wire_mult[1]),
                            .B(wire_mult[2]),
                            .out(wire_Adders[0]),
                            .overflow(OF_add[0]));

FPadder        #( .WI1(WIX+WIC),
               .WF1(WFX+WFC),
               .WI2(WIX+WIC+N),
               .WF2(WFX+WFC),
               .WIO(WIX+WIC+N),
               .WFO(WFX+WFC))
                        add1 (.A(wire_mult[0]),
                            .B(wire_Adders[0]),
                            .out(wire_Adders[1]),
                            .overflow(OF_add[1]));

//------------------------------------------------Feedback Section-------------------------------------------------//
FPadder       #( .WI1(WIX+WIC+N),
               .WF1(WFX+WFC),
              .WI2(WIX+WIS+(2*WIC)),
              .WF2(WFX+WFS+(2*WFC)),
              .WIO(WIX+WIS+(2*WIC)),
              .WFO(WFX+WFS+(2*WFC))) 
                            FB_add1 (.A(wire_Adders[1]),
                                  .B(FB_wire_Adders[0]),
                                  .out(FB_wire_Adders[1]),
                                  .overflow(FB_OF_add[1]));

FixedPoint_Multiplier       #( .WI1(WIX+WIS+(2*WIC)),
                      .WF1(WFX+WFS+(2*WFC)),
                      .WI2(WIC),
                      .WF2(WFC),
                      .WIO(WIX+WIS+(2*WIC)),
                      .WFO(WFX+WFS+(2*WFC))) 
                                    FB_mult0 
                                          ( .in1(FB_wire_Adders[1]),
                                            .in2(SOS_filter_coef[3]),
                                            .FixedPoint_Mul_Out(FB_wire_mult[2]),
                                            .overFlow(FB_OF_mult[0]));

DFF #(.BW(WIX+WIS+(2*WIC)+WFX+WFS+(2*WFC))) FB_D0 (.d(FB_wire_mult[2]),.CLK(CLK),.RESET(RESET),.q(FB_wire_DFF[1]));

//---------------------------------------------------------DFF---------------------------------------------------//
DFF #(.BW(WIX+WIS+(2*WIC)+WFX+WFS+(2*WFC))) FB_D1 (.d(FB_wire_DFF[1]),.CLK(CLK),.RESET(RESET),.q(FB_wire_DFF[0]));

//-------------------------------------------------------multiply--------------------------------------------------//
FixedPoint_Multiplier       #( .WI1(WIX+WIS+(2*WIC)),
                      .WF1(WFX+WFS+(2*WFC)),
                      .WI2(WIC),
                      .WF2(WFC),
                      .WIO(WIX+WIS+(2*WIC)),
                      .WFO(WFX+WFS+(2*WFC))) FB_mult1 
                                          (.in1(FB_wire_DFF[1]),
                                           .in2(SOS_filter_coef[4]),
                                           .FixedPoint_Mul_Out(FB_wire_mult[1]),
                                           .overFlow(FB_OF_mult[1]));
                
FixedPoint_Multiplier       #( .WI1(WIX+WIS+(2*WIC)),
                      .WF1(WFX+WFS+(2*WFC)),
                      .WI2(WIC),
                      .WF2(WFC),
                      .WIO(WIX+WIS+(2*WIC)),
                      .WFO(WFX+WFS+(2*WFC))) 
                                    FB_mult2 
                                          (.in1(FB_wire_DFF[0]),
                                           .in2(SOS_filter_coef[5]),
                                           .FixedPoint_Mul_Out(FB_wire_mult[0]),
                                           .overFlow(FB_OF_mult[2]));
//-------------------------------------------------------addition-------------------------------------------------//
FPadder       #( .WI1(WIX+WIS+(2*WIC)),
              .WF1(WFX+WFS+(2*WFC)),
              .WI2(WIX+WIS+(2*WIC)),
              .WF2(WFX+WFS+(2*WFC)),
              .WIO(WIX+WIS+(2*WIC)), 
              .WFO(WFX+WFS+(2*WFC))) FB_add0 (.A(FB_wire_mult[0]),
                                    .B(FB_wire_mult[1]),
                                    .out(FB_wire_Adders[0]),
                                    .overflow(FB_OF_add[0]));
//------------------------------------------------------Scaling Multiplier----------------------------------------//
FixedPoint_Multiplier       #( .WI1(WIX+WIS+(2*WIC)),
                      .WF1(WFX+WFS+(2*WFC)),
                      .WI2(WIS),
                      .WF2(WFS),
                      .WIO(WIO),
                      .WFO(WFO)) mult_Scale 
                                    (.in1(FB_wire_mult[2]),
                                     .in2(S),.FixedPoint_Mul_Out(Y),
                                     .overFlow(OF_scale));

endmodule
