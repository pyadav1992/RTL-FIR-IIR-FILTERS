`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:        San Diego State University
// Engineer:       Pratik Yadav 
// 
// Create Date:    17:35:09 04/09/2015 
// Design Name: 
// Module Name:    increment 
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
module increment(
    input c,
    output c1
    );
  
   assign c1 = c + 1;
endmodule
