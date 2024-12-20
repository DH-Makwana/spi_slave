//-----------------------------------------------------------------------------
// Title         : spi_tb
// Project       : Internship
//-----------------------------------------------------------------------------
// File          : spi_tb.sv
// Author        : Dell  <infi@Dell>
// Created       : 17.12.2024
// Last modified : 17.12.2024
//-----------------------------------------------------------------------------
// Description :
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2024 by Infineon This model is the confidential and
// proprietary property of Infineon and the possession or use of this
// file requires a written license from Infineon.
//------------------------------------------------------------------------------
// Modification history :
// 17.12.2024 : created
//-----------------------------------------------------------------------------


module spi_tb (/*AUTOARG*/);
   /*AUTOREGINPUT*/
   // Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
   logic		clk;			// To spiSlave of spi_slave.v
   logic		csz;			// To spiSlave of spi_slave.v
   logic		reset_n;		// To spiSlave of spi_slave.v
   logic		sclk;			// To spiSlave of spi_slave.v
   logic		sdi;			// To spiSlave of spi_slave.v
   // End of automatics
   /*AUTOLOGIC*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   logic		sdo;			// From spiSlave of spi_slave.v
   // End of automatics
   spi_slave spiSlave(/*AUTOINST*/
		      // Outputs
		      .sdo		(sdo),
		      // Inputs
		      .clk		(clk),
		      .reset_n		(reset_n),
		      .sclk		(sclk),
		      .sdi		(sdi),
		      .csz		(csz));

   initial begin
      $dumpfile("spi_tb.vcd");
      $dumpvars;
   end
      
endmodule
