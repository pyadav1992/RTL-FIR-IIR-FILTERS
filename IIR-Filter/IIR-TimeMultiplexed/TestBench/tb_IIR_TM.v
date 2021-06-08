`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   00:03:23 04/22/2015
// Design Name:   IIR_TM
// Module Name:   C:/Users/Administrator/Desktop/IIR_TM/tb_IIR_TM.v
// Project Name:  SOS
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: IIR_TM
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_IIR_TM;

parameter No_SOS = 4;
parameter WIX = 3; //input sample integer bit width
parameter WFX = 7; //input sample fraction bit width
parameter WIC = 2; //input coefficient integer width
parameter WFC = 8;
parameter WIS = 5;
parameter WFS = 11;
parameter WIO =8;
parameter WFO =18;

  // Inputs
  reg [WIX+WFX-1:0] X;
  reg RESET;
  reg CLK;
  reg CE;
  integer i;
  // Outputs
  wire IIR_overflow;
  wire [WIO+WFO-1:0] Y;
  
  reg [WIX+WFX-1:0] rom [0:49];
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
    
    real X_real;
    real Y_real;
    
    always @ X X_real = FixedToFloat(X, WIX, WFX); //convert in1 to real
  
    always @ Y Y_real = FixedToFloat(Y, WIO, WFO);//convert Out2 to real    
    
  initial begin 
  $readmemb("filtercoeff.txt", tb_IIR_TM.uut00.filter_coeff);
  $readmemb ("scale.txt",tb_IIR_TM.uut00.scale_coeff);
  end

  // Instantiate the Unit Under Test (UUT)
  IIR_TM                        #(   .No_SOS(No_SOS),
                         .WIX(WIX),
                         .WFX(WFX),
                         .WIC(WIC),
                         .WFC(WFC),
                         .WIS(WIS),
                         .WFS(WFS),
                         .WIO(WIO), 
                         .WFO(WFO))
                          uut00 ( .X(X), 
                               .RESET(RESET), 
                               .CLK(CLK), 
                               .IIR_overflow(overflow), 
                               .Y(Y)  );
                               
  parameter ClockPeriod = 10;
  initial CLK =0;
  always #(ClockPeriod/2) CLK = ~CLK;


  initial begin
    // Initialize Inputs
    X = 0;
    RESET = 0;
    CE = 1;
  @(posedge CLK) RESET = 0;
  @(posedge CLK) RESET = 1;
  //@(posedge CLK);
    $readmemb("input.txt",rom);
      for(i=0; i<50; i=i+1) begin
          @(posedge CLK)RESET = 1; X = rom[i]; 
          @(posedge CLK);
          @(posedge CLK);
          @(posedge CLK);
          $display(FixedToFloat(Y, WIO,WFO));
      end
  end
      
endmodule