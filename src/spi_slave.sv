//-----------------------------------------------------------------------------
// Title         : spi_slave
// Project       : Internship
//-----------------------------------------------------------------------------
// File          : spi_slave.sv
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
module spi_slave (/*AUTOARG*/
   // Outputs
   sdo,
   // Inputs
   clk, reset_n, sclk, sdi, csz
   ) ;
   input	clk; 		// Internal clk slave
   input	reset_n; 	// Intial reset
   input	sclk;  		// Master clk
   input	sdi; 		// Serial input from master
   input	csz; 		// Chip select
   output logic	sdo; 		// Serial output

   parameter	WAIT= 0;		// Wait for chip select
   parameter	RESET = 1;		// Power ON reset
   parameter	ADDRESS_FETCH = 2;	// Take 7bit Address
   parameter	MEM_OP = 3; 		// Decide the R/W
   parameter	MEM_WRITE = 4;		// Write the data bit by bit given by master to memory
   parameter	MEM_READ = 5;		// Read the data from memory and give to master bit by bit


   logic [3:0]	counter;	// Bit counter for ADD & DATA
   logic [15:0]	serial_buffer;	// Shift register for ADD & DATA
   logic [2:0]	state;		// Current state of FSM
   logic	mem_op_done;	// Flag to represent end memory opration
   logic	add_fetch_done; // Flag to represent end of address fetch
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [15:0]	data_out; // From smem of spi_mem.v
   // End of automatics
   
   /*AUTOREGINPUT*/
   // Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
   reg [6:0]	add; // To smem of spi_mem.v
   reg [15:0]	data_in; // To smem of spi_mem.v
   reg		rwb;			// To smem of spi_mem.v
   // End of automatics
   assign rstn = reset_n;
   
   spi_mem smem(/*AUTOINST*/
		// Outputs
		.data_out		(data_out[15:0]),
		// Inputs
		.clk			(clk),
		.add			(add[6:0]),
		.data_in		(data_in[15:0]),
		.rwb			(rwb),
		.rstn			(rstn));
   
   
   always_ff @(posedge clk or negedge reset_n) begin
      if(reset_n == 1'b0) begin
	 //Reset all the local vars
	 state <= WAIT;
	 sdo <= 1'b1;	 
	 /*AUTORESET*/
	 // Beginning of autoreset for uninitialized flops
	 add <= 7'h0;
	 add_fetch_done <= 1'h0;
	 counter <= 4'h0;
	 data_in <= 16'h0;
	 mem_op_done <= 1'h0;
	 rwb <= 1'h0;
	 serial_buffer <= 16'h0;
	 // End of automatics
      end else begin // if (reset_n == 1'b0)
	 
	 case(state)
	   WAIT: begin
	       counter <= 5'd0;
	       serial_buffer <= 16'd0;
	       rwb <= 0;
	       mem_op_done <= 1'b0;
	       sdo <= 1'b1;
	      
	      // Start the FSM only if chip was selected and was not here from final states
	      // Reset add_fetch_done only if there was a period when chip was unselected
	      
	      if((csz == 1'b0) & (add_fetch_done == 1'b0)) begin
		  state <= ADDRESS_FETCH;
	      end else begin
		  state <= WAIT;
		  add_fetch_done <= (csz) ? 1'b0 : 1'b1;
	      end
	   end // case: WAIT

	   
	   ADDRESS_FETCH: begin
	      if(add_fetch_done == 1'b1) begin
		 // Take the ADD from buffer and send to MEM
		 state <= MEM_OP;
		 add <= serial_buffer;		 
	      end else begin
 		 // Wait till the add_fetch_done is flagged from other always block
		 state <= ADDRESS_FETCH;		 
	      end
	   end
	   
	   // Send the R/W direcly to MEM to ensure data gets read prior to MEM_READ
	   MEM_OP: begin
	      rwb <= sdi;
	      serial_buffer <= data_out;

	      // mem_op_done will be flagged by other always block
	      // Meaning A0 bit or r/w has been read
	      if(mem_op_done) begin
		 if(rwb == 1'b1) begin
		    state <= MEM_READ;	    
		 end else begin
		    state <= MEM_WRITE;		    
		 end
	      end else begin
		 state <= MEM_OP;		 
	      end
	   end // case: MEM_OP


	   MEM_READ: begin
	      // Using mem_op_done to also have 16 count with 4-bit counter
	      if((counter == 4'b0) & (mem_op_done == 1'b0)) begin
		 // Go back to WAIT state
		 state <= WAIT;
		 counter <= 0;
		 mem_op_done <= 1'b1;		 
	      end else begin
		 state <= MEM_READ;
		 // Pushing the bits left and sending them to sdo at the same time
		 sdo <= serial_buffer[15];
		 mem_op_done <= (counter==4'd15) ? 1'b0 : 1'b1;		 
	      end
	   end // case: MEM_READ

	   
	   MEM_WRITE: begin
	      // Using mem_op_done to also have 16 count with 4-bit counter
	      if((counter == 4'd0) & (mem_op_done == 1'b0)) begin
		 // Go back to WAIT state
		 state <= WAIT;		 
		 data_in <= serial_buffer;
		 counter <= 0;
		 mem_op_done <= 1'b1;		 
	      end else begin
		 state <= MEM_WRITE;
		 mem_op_done <= (counter==4'd15) ? 1'b0 :1'b 1;
	      end
	   end // case: MEM_WRITE
	   
	 endcase // case (state)
      end 
   end 

   // Always block sync with sclk
   always_ff @(posedge sclk) begin
      case(state)

	// Take the MSBs and push them left to get the ADD
	ADDRESS_FETCH: begin
	    counter <= counter + 1;
	    serial_buffer <= {serial_buffer[14:0], sdi};
	    mem_op_done <= 1'b0;
	    add_fetch_done <= (counter == 6) ? 1'b1 : 1'b0;
	end

	// Count the last A0 bit and declare its done
	MEM_OP: begin
	   if (counter == 7) begin
	      mem_op_done <= 1'b1; 
	      counter <= 0;
	   end else begin
	      counter <= counter + 1'b1;      
	   end
	end

	// Shift the buffre read from memory as the sdo is begin assigned MSB by previos always block
	MEM_READ: begin
	   counter <= counter + 1'b1;	   
	   serial_buffer <= serial_buffer << 1'b1;	   
	end

	// Push the MSBs to right and add the sdi bit 
	MEM_WRITE: begin
	   counter <= counter + 1'b1;
	   serial_buffer <= {serial_buffer[14:0], sdi};	   
	end
	
      endcase 
      
   end // always_ff @ (posedge sclk)
      
endmodule // spi_slave
