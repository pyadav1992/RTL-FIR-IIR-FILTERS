`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company:        San Diego State University
// Engineer:       Pratik Yadav
// 
// Create Date:    20:24:39 03/16/2015 
// Design Name: 
// Module Name:    FixedPoint_FIR_Filter_TM 
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
module FIR2 #(parameter N = 4,  // filter order for the filter
                        No_coeff = 8,                    // number of coefficients available in the LUT  
                        WI1 = 4,                         // Integer bitwidth for input signal samples 
                        WF1 = 5,                         // Fractional bitwidth for input signal samples
                        WIC = 4,                         // Integer bitwidth for input coefficients 
                        WFC = 5)                         // Fractional bitwidth for input coefficients
                       (input signed [WI1+WF1-1:0] X,    // input samples
                        input RESET ,CLK, test,          //test is used for validating input at state S0 of FSM
                        output   overflow,               // Combined overflow of adder and mltiplier
                        output reg signed [(WI1+WIC+N)+(WF1+WFC)-1:0] Filt_Out);  // filtered output
                     
                     
                     
                     
reg signed [WIC+WFC-1:0] coeff;                                 // choose a coeffiect out of coefficient LUT to multiply with input sample
reg signed [WIC+WFC-1:0] Filter_coeff [0:No_coeff-1];           // RAM for filter coefficients
reg signed [WI1+WF1-1:0] delay_wire [0:N+1];                    // the input samples are sent for multiplication in FIFO format  
reg signed [WI1+WF1-1:0] delay;                                 // choose input sample from FIFO stack for multiplication 

wire signed [(WIC+WI1)+ (WFC+WF1)-1:0] Mult_Out;                // multiplication output    
wire signed [(WI1+WIC+N)+(WF1+WFC)-1:0] Add_Out;                // addition output  

wire  overflow_Mul;                          // multiplication overflow
wire  overflow_Add;                          // addition overflow

reg state;                                    // state defined to generate FSM
reg s0 = 1'b0, s1 = 1'b1;                     // 2 states  :  S0 for resetting all registre values to zero 
                                               //             S1 for performing convolution and finding filtered output       

integer i = 0;
integer j = 0;
reg signed [(WI1+WIC+N)+(WF1+WFC)-1:0] Add_reg ;


initial begin
$readmemb("coefficients.txt",Filter_coeff);
end

assign overflow  =  (overflow_Mul || overflow_Add);

  FPmultiply          #(.WI1(WIC),
                   .WF1(WFC),
                     .WI2(WI1),
                     .WF2(WF1),
                     .WIO(WIC+WI1),
                     .WFO(WFC+WF1))
                    Multiplier00 ( .A(coeff), .B(delay), .overflow1(overflow_Mul), .multiply(Mult_Out));
                    
  FPadder           #(.WI1(WIC+WI1),
                 .WF1(WFC+WF1),
                   .WI2(WI1+WIC+N),
                   .WF2(WFC+WF1),
                   .WIO(WI1+WIC+N),
                   .WFO(WFC+WF1)) 
                    Adder00 (.A(Mult_Out), .B(Add_reg), .overflow(overflow_Add), .out(Add_Out));
              
  always @(posedge CLK) begin
    
      if (RESET) begin
        state <= s0;
        delay <= 0 ;
        Add_reg <=0;
        coeff <= 0;
        Filt_Out <= 0;
        $readmemb("reset.txt",delay_wire);
      end
      
      else begin
      
      case(state)
      
        s0:begin
           delay_wire[0] <= X;
          coeff <= 0;
          Add_reg <=0;
          delay <= 0 ;
          if(test)
            state <= s1;
          else
            state <= s0;
          end
          
        s1:begin  
              Add_reg <=  Add_Out;
            coeff <= Filter_coeff[i];
            delay <= delay_wire[i];

          if ( i <= N) begin
            state <= s1;
            i = i+1;
          end
          
          else begin
            Filt_Out <= Add_Out;
            state<= s0;
            i=0;
            for(j = 0; j<N+1; j=j+1) begin
              delay_wire [j+1] <= delay_wire[j];
            end
            
            end
          end
      endcase
    end
  end
  
endmodule
