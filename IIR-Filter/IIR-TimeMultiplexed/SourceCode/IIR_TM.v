`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:        San Diego State University
// Engineer:       Pratik Yadav 
// 
// Create Date:    11:55:36 03/16/2015 
// Design Name: 
// Module Name:    IIR_TM 
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
module IIR_TM  #(parameter        N = 2, 							 
                                  No_SOS = 4,         //Total number of SOS
                                  WIX = 3, 						// integer part bitwidth for input sample  
                                  WFX = 7, 						// fractional part bitwidth for input sample
                                  WIC = 2,            // integer part bitwidth for Coefficient
                                  WFC = 8,            // fractional part bitwidth for Coefficient
                                  WIS = 5,            // integer part bitwidth for Scaling
                                  WFS = 11,           // fractional part bitwidth for Scaling
                                  WIO =WIX+WIS+WIC+N, // integer part bitwidth for addition output (user input)
                                  WFO =WFX+WFS+WFC    // integer part bitwidth for addition outout (user input)
											 )
	(
	  input signed [(WIX+WFX-1):0] X,
	  input CLK,
	  input RESET,
	  input CE,
	  output reg signed [(WIO+WFO-1):0] Y,
     output reg IIR_overflow
	 );
	 
	wire CLK_en;
   assign CLK_en = CLK & CE;	
//-----------------------------------bitwidth------------------------------------------//
	localparam int_W = WIX+WIS;
	localparam frac_W = WFX+WFS;
//-----------------------------------filter Coefficients-------------------------------//
	 reg signed [(WIC+WFC-1):0]   SOS_filter_coef0,
											SOS_filter_coef1,
											SOS_filter_coef2,
											SOS_filter_coef3,
											SOS_filter_coef4,
											SOS_filter_coef5;
											
   reg signed[(WIC+WFC-1):0] filter_coeff	[0 : 23];									
//-----------------------------------Scaling coefficients------------------------------//
   reg signed [(WIS+WFS-1):0] S;
	 reg signed [(WIS+WFS-1) : 0] scale_coeff [0:No_SOS]; // scaling coefficients
	 wire signed [(int_W+frac_W-1) : 0] Scale_wire1;
	 wire signed [(int_W+frac_W-1) : 0] Scale_wire2;
//-----------------------------------feedforward---------------------------------------//	  
	 wire signed [(int_W+frac_W+WIC+WFC-1):0] wire_mult [0:N];// multiplier wires
	 wire signed [(int_W+frac_W-1):0] wire_DFF [0:N];   			// DFF wires
    wire signed [(int_W+frac_W+WIC+WFC+N-1):0] wire_Adders [0:(N-1)];	// Adder wires  
//--------------------------------------feedback---------------------------------------//	 
	 wire signed [(WIX+WIS+(2*WIC)+WFX+WFS+(2*WFC)-1):0] FB_wire_mult [0:N];  	  // feedback multiplier wires
	 wire signed [(WIX+WIS+(2*WIC)+WFX+WFS+(2*WFC)-1):0] FB_wire_DFF [0:N-1];		  // feedback DFF wires
    wire signed [(WIX+WIS+(2*WIC)+WFX+WFS+(2*WFC)-1):0] FB_wire_Adders [0:(N-1)]; // feedback Adder wires	 
	 reg signed  [(int_W+frac_W-1) : 0] temp_in;

//--------------------------- overflow---------------------------------------//
	 wire  [0:(N-1)] OF_add;
	 wire  [0:N] OF_mult;
   wire  [0:(N-1)] FB_OF_add;
	 wire  [0:N] FB_OF_mult;
   wire  OF_Scale1,OF_Scale2;	
	 
always @(*) begin
	if (|(OF_add) || |(OF_mult) || OF_Scale1 || OF_Scale2) begin
             IIR_overflow <= 1'b1;
			end
	else 
		   	 IIR_overflow <= 1'b0;
end

//-------------------------------------------------input Scaling Multiplier---------------------------------------//
FixedPoint_Multiplier  			  #( .WI1(WIX),
											  .WF1(WFX),
											  .WI2(WIS),
											  .WF2(WFS),
											  .WIO(int_W),
											  .WFO(frac_W)) 
																mult_Scale1 
																		(.in1(X),
																		 .in2(scale_coeff[0]),
																		 .FixedPoint_Mul_Out(Scale_wire1),
																		 .overFlow(OF_Scale1));

//-------------------------------------------------Feedforward Section--------------------------------------------// 
assign wire_DFF[0] = Scale_wire1;
 //---------------------------------------------------------DFF---------------------------------------------------//
DFF #(.BW(int_W+frac_W),.No_SOS(No_SOS)) D0 (.in(temp_in),.CLK(CLK_en),.RESET(RESET),.q_out(wire_DFF[1]));
DFF #(.BW(int_W+frac_W),.No_SOS(No_SOS)) D1 (.in(wire_DFF[1]),.CLK(CLK_en),.RESET(RESET),.q_out(wire_DFF[2]));
//-------------------------------------------------------multiply--------------------------------------------------//
FixedPoint_Multiplier  			  #( .WI1(int_W),
											  .WF1(frac_W),
											  .WI2(WIC),
											  .WF2(WFC),
											  .WIO(int_W+WIC),
											  .WFO(frac_W+WFC)) 
																mult0 
																		(.in1(temp_in),
																		 .in2(SOS_filter_coef0),
																		 .FixedPoint_Mul_Out(wire_mult[0]),
																		 .overFlow(OF_mult[0]));
				
FixedPoint_Multiplier  			  #( .WI1(int_W),
											  .WF1(frac_W),
											  .WI2(WIC),
											  .WF2(WFC),
											  .WIO(int_W+WIC),
											  .WFO(frac_W+WFC)) 
																mult1 
																      (.in1(wire_DFF[1]),
																		 .in2(SOS_filter_coef1),
																		 .FixedPoint_Mul_Out(wire_mult[1]),
																		 .overFlow(OF_mult[1]));
				
FixedPoint_Multiplier  			  #( .WI1(int_W),
											  .WF1(frac_W),
										     .WI2(WIC),
											  .WF2(WFC),
											  .WIO(int_W+WIC),
											  .WFO(frac_W+WFC)) 
																mult2 (.in1(wire_DFF[2]),
																		 .in2(SOS_filter_coef2),
																		 .FixedPoint_Mul_Out(wire_mult[2]),
																		 .overFlow(OF_mult[2]));
//-------------------------------------------------------addition-------------------------------------------------//
FPadder  			 #( .WI1(int_W+WIC),
							 .WF1(frac_W+WFC),
							 .WI2(int_W+WIC),
							 .WF2(frac_W+WFC),
							 .WIO(int_W+WIC+N),
							 .WFO(frac_W+WFC)) 
												add0 (.A(wire_mult[1]),
														.B(wire_mult[2]),
														.out(wire_Adders[0]),
														.overflow(OF_add[0]));

FPadder  			 #( .WI1(int_W+WIC),
							 .WF1(frac_W+WFC),
							 .WI2(int_W+WIC+N),
							 .WF2(frac_W+WFC),
							 .WIO(int_W+WIC+N),
							 .WFO(frac_W+WFC))
												add1 (.A(wire_mult[0]),
														.B(wire_Adders[0]),
														.out(wire_Adders[1]),
														.overflow(OF_add[1]));

//------------------------------------------------Feedback Section-------------------------------------------------//
FPadder  			#( .WI1(int_W+WIC+N),
						   .WF1(frac_W+WFC),
							.WI2(WIX+WIS+(2*WIC)),
							.WF2(WFX+WFS+(2*WFC)),
							.WIO(WIX+WIS+(2*WIC)),
							.WFO(WFX+WFS+(2*WFC))) 
														FB_add1 (.A(wire_Adders[1]),
																	.B(FB_wire_Adders[0]),
																	.out(FB_wire_Adders[1]),
																	.overflow(FB_OF_add[1]));

FixedPoint_Multiplier  			#( .WI1(WIX+WIS+(2*WIC)),
											.WF1(WFX+WFS+(2*WFC)),
											.WI2(WIC),
											.WF2(WFC),
											.WIO(WIX+WIS+(2*WIC)),
											.WFO(WFX+WFS+(2*WFC))) 
																		FB_mult0 
																					(	.in1(FB_wire_Adders[1]),
																						.in2(SOS_filter_coef3),
																						.FixedPoint_Mul_Out(FB_wire_mult[2]),
																						.overFlow(FB_OF_mult[0]));

DFF #(.BW(WIX+WIS+(2*WIC)+WFX+WFS+(2*WFC)),
		.No_SOS(No_SOS)) 
							 FB_D0 
									(.in(FB_wire_mult[2]),
									 .CLK(CLK_en),.RESET(RESET),
									 .q_out(FB_wire_DFF[1]));

//---------------------------------------------------------DFF---------------------------------------------------//
DFF #(.BW(WIX+WIS+(2*WIC)+WFX+WFS+(2*WFC)),
	   .No_SOS(No_SOS)) 
							 FB_D1 
									(.in(FB_wire_DFF[1]),
									 .CLK(CLK_en),.RESET(RESET),
									 .q_out(FB_wire_DFF[0]));

//-------------------------------------------------------multiply--------------------------------------------------//
FixedPoint_Multiplier  			#( .WI1(WIX+WIS+(2*WIC)),
											.WF1(WFX+WFS+(2*WFC)),
											.WI2(WIC),
											.WF2(WFC),
											.WIO(WIX+WIS+(2*WIC)),
											.WFO(WFX+WFS+(2*WFC))) FB_mult1 
																					(.in1(FB_wire_DFF[1]),
																					 .in2(SOS_filter_coef4),
																					 .FixedPoint_Mul_Out(FB_wire_mult[1]),
																					 .overFlow(FB_OF_mult[1]));
							  
FixedPoint_Multiplier  			#( .WI1(WIX+WIS+(2*WIC)),
											.WF1(WFX+WFS+(2*WFC)),
											.WI2(WIC),
											.WF2(WFC),
											.WIO(WIX+WIS+(2*WIC)),
											.WFO(WFX+WFS+(2*WFC))) 
																		FB_mult2 
																					(.in1(FB_wire_DFF[0]),
																					 .in2(SOS_filter_coef5),
																					 .FixedPoint_Mul_Out(FB_wire_mult[0]),
																					 .overFlow(FB_OF_mult[2]));
//-------------------------------------------------------addition-------------------------------------------------//
FPadder  			#( .WI1(WIX+WIS+(2*WIC)),
							.WF1(WFX+WFS+(2*WFC)),
							.WI2(WIX+WIS+(2*WIC)),
							.WF2(WFX+WFS+(2*WFC)),
							.WIO(WIX+WIS+(2*WIC)), 
							.WFO(WFX+WFS+(2*WFC))) 
														  FB_add0 (.A(FB_wire_mult[0]),
																	  .B(FB_wire_mult[1]),
																	  .out(FB_wire_Adders[0]),
																	  .overflow(FB_OF_add[0]));
//------------------------------------------------------Scaling Multiplier----------------------------------------//
FixedPoint_Multiplier  			#( .WI1(WIX+WIS+(2*WIC)),
											.WF1(WFX+WFS+(2*WFC)),
											.WI2(WIS),
											.WF2(WFS),
											.WIO(WIO),
											.WFO(WFO))
														  mult_Scale2 
																		(.in1(FB_wire_mult[2]),
																		 .in2(S),
																		 .FixedPoint_Mul_Out(Scale_wire2),
																		 .overFlow(OF_Scale2));
																		 
																		 
//----------------------------------------------------Finite State Machine to time Multiplex SOS--------------------------//

reg signed [(int_W+frac_W-1) : 0] iter_out;
wire [4:0] iter_no;
integer i = 0;

always @(posedge CLK_en)begin
	if(~RESET)begin
		i <= 0;
		temp_in <= 0;
	end
	else begin
		if(iter_no == No_SOS)begin
			i <= 0;
		end
		else begin
			i <= iter_no;
		end
	end	
end

assign iter_no = i + 1;

always @(posedge CLK_en)begin
	if(~RESET)begin
		temp_in <= 0;
		Y	<=	0;
	end
	else begin
		if(iter_no == No_SOS)begin
				Y <= Scale_wire2;
		end
	end
end

always @(iter_no) begin
	temp_in <= 0;
	if (iter_no == 1)begin
	temp_in <= Scale_wire1;
	
	SOS_filter_coef0 <= filter_coeff[(i*6)];
	SOS_filter_coef1 <= filter_coeff[(i*6)+1];
  SOS_filter_coef2 <= filter_coeff[(i*6)+2];
  SOS_filter_coef3 <= filter_coeff[(i*6)+3];
  SOS_filter_coef4 <= filter_coeff[(i*6)+4];
  SOS_filter_coef5 <= filter_coeff[(i*6)+5];
  S <= scale_coeff[i+1];	
	end
	else begin
	iter_out = Scale_wire2;
	temp_in  <= iter_out;
	
	SOS_filter_coef0 <= filter_coeff[(i*6)];
	SOS_filter_coef1 <= filter_coeff[(i*6)+1];
  SOS_filter_coef2 <= filter_coeff[(i*6)+2];
  SOS_filter_coef3 <= filter_coeff[(i*6)+3];
  SOS_filter_coef4 <= filter_coeff[(i*6)+4];
  SOS_filter_coef5 <= filter_coeff[(i*6)+5];
  S <= scale_coeff[i+1];
	end
end
endmodule
