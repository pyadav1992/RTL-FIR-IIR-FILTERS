`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        San Diego State University
// Engineer:       Pratik Yadav
// 
// Create Date:     
// Design Name: 
// Module Name:    DFF 
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

module DFF #(parameter BW = 9,
			    parameter No_SOS = 4)
			  
			(input signed [BW-1:0]in,
			 input CLK,RESET,
			 output reg signed [BW-1:0] q_out);
		   
	
	reg [BW-1:0] temp [ 0:No_SOS-1];
	integer i;
	
	wire [4:0] iter_no;
	reg [4:0] value;
	
		always @(posedge CLK ) begin
			if (~RESET) begin
				for(i = 0; i < No_SOS; i = i+1) begin
				temp[i] <= 0;
				end	
			end
			else begin
				temp[value] <= in;
			end		
		end
	
		always @(iter_no) begin
				if(~RESET) begin
					q_out = 0;
				end
				else begin 
					q_out = temp[value];
				end
		end
		
		always @(posedge CLK) begin
			if (~RESET) begin
				value <= 0;
			end
			else begin
				if(iter_no == No_SOS) begin
					value <= 0;
					end
				else begin
					value <= iter_no;
					end
			end
		end
				
		assign iter_no = value+1;
	
endmodule 