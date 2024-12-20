//-----------------------------------------------------------------------------
// Title         : spi_mem
// Project       : Internship
//-----------------------------------------------------------------------------
// File          : spi_mem.sv
// Author        : Dell  <infi@Dell>
// Created       : 18.12.2024
// Last modified : 18.12.2024
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2024 by Infineon This model is the confidential and
// proprietary property of Infineon and the possession or use of this
// file requires a written license from Infineon.
//------------------------------------------------------------------------------
// Modification history :
// 18.12.2024 : created
//-----------------------------------------------------------------------------


module spi_mem (/*AUTOARG*/
   // Outputs
   data_out,
   // Inputs
   clk, add, data_in, rwb, rstn
   ) ;
   input clk;
   input [6:0] add;
   input [15:0]	data_in;
   output reg [15:0] data_out;   
   input	rwb;
   input	rstn;

   logic [127:0]	[15:0]mem;
      
   always @(posedge clk) begin
      if(rstn == 1'b0) begin
	 data_out = 16'd0;
      end else begin
	 if(rwb == 1'b1) begin
	    data_out <= mem[add];	    
	 end else begin
	    mem[add] <= data_in;	    
	 end	 
      end      
   end
     
endmodule // spi_mem
