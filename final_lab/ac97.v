`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:54:36 04/03/2011 
// Design Name: 
// Module Name:    ac97 
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
//
//////////////////////////////////////////////////////////////////////////////////
module ac97 (ready,
             command_address, command_data, command_valid,
             left_data, left_valid,
             right_data, right_valid,
             left_in_data, right_in_data,
             ac97_sdata_out, ac97_sdata_in, ac97_synch, ac97_bit_clock);

   output ready;
   input [7:0] command_address;
   input [15:0] command_data;
   input command_valid;
   input [19:0] left_data, right_data;
   input left_valid, right_valid;
   output [19:0] left_in_data, right_in_data;

   input ac97_sdata_in;
   input ac97_bit_clock;
   output ac97_sdata_out;
   output ac97_synch;

   reg ready;

   reg ac97_sdata_out;
   reg ac97_synch;

   reg [7:0] bit_count;

   reg [19:0] l_cmd_addr;
   reg [19:0] l_cmd_data;
   reg [19:0] l_left_data, l_right_data;
   reg l_cmd_v, l_left_v, l_right_v;
   reg [19:0] left_in_data, right_in_data;

   initial begin
      ready <= 1'b0;
      // synthesis attribute init of ready is "0";
      ac97_sdata_out <= 1'b0;
      // synthesis attribute init of ac97_sdata_out is "0";
      ac97_synch <= 1'b0;
      // synthesis attribute init of ac97_synch is "0";

      bit_count <= 8'h00;
      // synthesis attribute init of bit_count is "0000";
      l_cmd_v <= 1'b0;
      // synthesis attribute init of l_cmd_v is "0";
      l_left_v <= 1'b0;
      // synthesis attribute init of l_left_v is "0";
      l_right_v <= 1'b0;
      // synthesis attribute init of l_right_v is "0";

      left_in_data <= 20'h00000;
      // synthesis attribute init of left_in_data is "00000";
      right_in_data <= 20'h00000;
      // synthesis attribute init of right_in_data is "00000";
   end

   always @(posedge ac97_bit_clock) begin
      // Generate the sync signal 
		if (bit_count == 255) ac97_synch <= 1'b1; 	// EDITED (ref. top of page 21)
		if (bit_count == 15) ac97_synch <= 1'b0; 	// (ref. top of page 27)
		
      // Generate the ready signal
      if (bit_count == 128) // EDITED (ref. toggle ready bit)
        ready <= 1'b1;
      if (bit_count == 2)
        ready <= 1'b0;

      // Latch user data at the end of each frame. This ensures that the
      // first frame after reset will be empty.
      if (bit_count == 255) // EDITED (changed "bit_count == 0") (ref. NO CERTAIN, could be 255)
        begin
           l_cmd_addr <= {command_address, 12'h000};
           l_cmd_data <= {command_data, 4'h0};
           l_cmd_v <= command_valid;
           l_left_data <= left_data;
           l_left_v <= left_valid;
           l_right_data <= right_data;
           l_right_v <= right_valid;
        end

      if ((bit_count >= 0) && (bit_count <= 15)) // EDITED (ref. tag frame is 16 bits wide)
        // Slot 0: Tags
        case (bit_count[3:0])						// (ref. pg. 30) (MSB of frame is received first)
          4'h0: ac97_sdata_out <= 1'b1;      // Frame valid // EDITED
          4'h1: ac97_sdata_out <= l_cmd_v;   // Command address valid // EDITED
          4'h2: ac97_sdata_out <= l_cmd_v;   // Command data valid // EDITED
          4'h3: ac97_sdata_out <= l_left_v;  // Left data valid // EDITED
			 4'h4: ac97_sdata_out <= l_right_v; // Right data valid // EDITED
          default: ac97_sdata_out <= 1'b0;
        endcase

      else if ((bit_count >= 16) && (bit_count <= 35)) // EDITED (changed "bit_count >= 16") (ref. 20 bits per slot)
        // Slot 1: Command address (8-bits, left justified)
        ac97_sdata_out <= l_cmd_v ? l_cmd_addr[35-bit_count] : 1'b0; // EDITED (changed "l_cmd_addr[35-bit_count]")

      else if ((bit_count >= 36) && (bit_count <= 55)) // EDITED (changed "bit_count <= 55") (ref. 20 bits per slot)
        // Slot 2: Command data (16-bits, left justified)
        ac97_sdata_out <= l_cmd_v ? l_cmd_data[55-bit_count] : 1'b0; // EDITED (changed "l_cmd_data[55-bit_count")

      else if ((bit_count >= 56) && (bit_count <= 75)) // EDITED (changed "bit_count >= 56") (ref. 20 bits per slot)
        begin
           // Slot 3: Left channel
           ac97_sdata_out <= l_left_v ? l_left_data[19] : 1'b0;
           l_left_data <= { l_left_data[18:0], l_left_data[19] };
        end
      else if ((bit_count >= 76) && (bit_count <= 95)) // EDITED (changed "bit_count <= 95") (ref. 20 bits per slot)
			  // Slot 4: Right channel
           ac97_sdata_out <= l_right_v ? l_right_data[95-bit_count] : 1'b0; // EDITED (changed "l_right_data[95-bit_count]")
      else
        ac97_sdata_out <= 1'b0;

      bit_count <= bit_count+1;

   end // always @ (posedge ac97_bit_clock)

   always @(negedge ac97_bit_clock) begin
      if ((bit_count >= 57) && (bit_count <= 76)) // EDITED (changed "bit_count >= 57") (ref. 20 bits per slot)
        // Slot 3: Left channel
		  //left_in_data <= { left_in_data[18:0], ac97_sdata_in };
        left_in_data[76-bit_count] <= ac97_sdata_in; // maybe: { left_in_data[18:0], ac97_sdata_in }
      else if ((bit_count >= 77) && (bit_count <= 96)) // EDITED (changed "bit_count <= 96") (ref. 20 bits per slot)
        // Slot 4: Right channel
        //right_in_data <= { right_in_data[18:0], ac97_sdata_in };
		  right_in_data[96-bit_count] <= ac97_sdata_in; // maybe: { right_in_data[18:0], ac97_sdata_in }
   end

endmodule
