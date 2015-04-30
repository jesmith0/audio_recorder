`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:40:47 04/10/2015 
// Design Name: 
// Module Name:    final_lab 
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
module final_lab(
	
	clock_100mhz, reset, leds,
	
	left_b_bounce, center_b_bounce, right_b_bounce, up_b_bounce, down_b_bounce,
	
	ac97_sdata_in, ac97_bit_clock, audio_reset_b, ac97_sdata_out, ac97_synch,
	
	lcd_data, lcd_com,
	
	hw_ram_rasn, hw_ram_casn, hw_ram_wen, hw_ram_ba, hw_ram_udqs_p, hw_ram_udqs_n,
	hw_ram_ldqs_p, hw_ram_ldqs_n, hw_ram_udm, hw_ram_ldm, hw_ram_ck, hw_ram_ckn,
	hw_ram_cke, hw_ram_odt, hw_ram_ad, hw_ram_dq, hw_rzq_pin, hw_zio_pin,
	
	pico_test, mem_full); // TEST OUTPUTS

	// INITIALS begin

	// GP in/outs
	input clock_100mhz;
	input reset;
	output reg [7:0] leds;
	
	// CONTROL ins
	input left_b_bounce;
	input center_b_bounce;
	input right_b_bounce;
	input up_b_bounce;
	input down_b_bounce;
	
	reg left_b;
	reg right_b;
	reg center_b;
	reg up_b;
	reg down_b;
	
	reg left_b_state;
	reg right_b_state;
	reg center_b_state;
	reg up_b_state;
	reg down_b_state;

	// AC97 in/outs
	input ac97_sdata_in;
	input ac97_bit_clock;
	output audio_reset_b;
	output ac97_sdata_out;
	output ac97_synch;

	reg [4:0] volume;
	reg [7:0] to_ac97_data;
	wire [7:0] from_ac97_data;

	// LCD in/outs/regs
	reg [7:0] out_port;
	output reg [3:0] lcd_data;
	output reg [2:0] lcd_com;
	wire [7:0] lcd_data_b;
	wire [2:0] lcd_com_b;
	wire lcd_done;
	
	// PICO in/outs/regs
	wire write_strobe;
	wire read_strobe;
	wire [7:0] port_id;
	wire [7:0] pico_out_port;
	wire interrupt_ack;
	reg interrupt;
	reg [7:0] pico_in_port;
	reg [7:0] pico_out_hold;
	reg [7:0] pico_port_hold;

	// RAM in/outs/regs
	reg [25:0] address;
	reg [7:0] data_in;
	wire [7:0] data_out;
	reg write_enable;
	reg read_request;
	reg read_ack;
	
	output hw_ram_rasn;
	output hw_ram_casn;
	output hw_ram_wen;
	output [2:0] hw_ram_ba;
	inout hw_ram_udqs_p;
	inout hw_ram_udqs_n;
	inout hw_ram_ldqs_p;
	inout hw_ram_ldqs_n;
	output hw_ram_udm;
	output hw_ram_ldm;
	output hw_ram_ck;
	output hw_ram_ckn;
	output hw_ram_cke;
	output hw_ram_odt;
	output [12:0] hw_ram_ad;
	inout [15:0] hw_ram_dq;
	inout	hw_rzq_pin;
	inout hw_zio_pin;

	initial begin
		leds = 7'b0000000;		// GP
		left_b_state = 1'b0;
		right_b_state = 1'b0;
		center_b_state = 1'b0;
		up_b_state = 1'b0;
		
		down_b_state = 1'b0;
		left_b = 1'b0;
		right_b = 1'b0;
		center_b = 1'b0;
		up_b = 1'b0;
		down_b = 1'b0;
		
		interrupt = 1'b0;			// PICO
		pico_in_port = 8'h00;
		pico_out_hold = 8'h00;
		pico_port_hold = 8'h00;
		
		to_ac97_data = 8'h00;	// AC97
		volume = 5'b00000;
	
		out_port = 8'h00;			// LCD
		lcd_data = 4'b0000;
		lcd_com = 3'b000;
	
		address = 26'h0000000;	// RAM
		data_in = 2'h00;
		write_enable = 1'b0;
		read_request = 1'b0;
		read_ack = 1'b0;	
	end
	
	// INITIALS end
	
	/***********************/
	
	// DECLARE MODULES begin
	
	// BUTTON DEBOUNCE MODULES
	debounce left_b_debouncer (.reset(~reset), .clk(sys_clk), .noisy(left_b_bounce), .clean(left_s));
	debounce center_b_debouncer (.reset(~reset), .clk(sys_clk), .noisy(center_b_bounce), .clean(center_s));
	debounce right_b_debouncer (.reset(~reset), .clk(sys_clk), .noisy(right_b_bounce), .clean(right_s));
	debounce up_b_debouncer (.reset(~reset), .clk(sys_clk), .noisy(up_b_bounce), .clean(up_s));
	debounce down_b_debouncer (.reset(~reset), .clk(sys_clk), .noisy(down_b_bounce), .clean(down_s));

	// AUDIO CODEC MODULE
	ac97audio ac97audio (

		.clock_100mhz(sys_clk), .reset(~reset), .volume(volume), .audio_in_data(from_ac97_data),
		.audio_out_data(to_ac97_data), .ready(ready), .audio_reset_b(audio_reset_b), .ac97_sdata_out(ac97_sdata_out),
		.ac97_sdata_in(ac97_sdata_in), .ac97_synch(ac97_synch), .ac97_bit_clock(ac97_bit_clock));

	// PICOBLAZE uCONTROLLER MODULE
	picoblaze picoblaze (

		.port_id(port_id), .read_strobe(read_strobe), .in_port(pico_in_port), .write_strobe(write_strobe),
		.out_port(pico_out_port), .interrupt(interrupt), .interrupt_ack(interrupt_ack), .reset(~reset),
		.clk(sys_clk));

	// LCD INTERFACE
	pmod_lcd pmod_lcd (

		.btnr(~reset), .CLK(sys_clk), .JA(lcd_data_b), .JB(lcd_com_b), .done(lcd_done));

	// RAM INTERFACE
	ram_interface_wrapper ram_interface_wrapper (
		
		.address(address), .data_in(data_in), .write_enable(write_enable), .read_request(read_request),
		.read_ack(read_ack), .data_out(data_out), .reset(~reset), .clk(clock_100mhz), .clkout(sys_clk),
		.sys_clk(sys_clk), .rdy(rdy), .rd_data_pres(rd_data_pres), .max_ram_address(max_ram_address),
		
		.hw_ram_rasn(hw_ram_rasn), .hw_ram_casn(hw_ram_casn), .hw_ram_wen(hw_ram_wen), .hw_ram_ba(hw_ram_ba),
		.hw_ram_udqs_p(hw_ram_udqs_p), .hw_ram_udqs_n(hw_ram_udqs_n), .hw_ram_ldqs_p(hw_ram_ldqs_p),
		.hw_ram_ldqs_n(hw_ram_ldqs_n), .hw_ram_udm(hw_ram_udm), .hw_ram_ldm(hw_ram_ldm), .hw_ram_ck(hw_ram_ck),
		.hw_ram_ckn(hw_ram_ckn), .hw_ram_cke(hw_ram_cke), .hw_ram_odt(hw_ram_odt), .hw_ram_ad(hw_ram_ad),
		.hw_ram_dq(hw_ram_dq), .hw_rzq_pin(hw_rzq_pin), .hw_zio_pin(hw_zio_pin));

	// DECLARE MODULES end
	
	/***********************/
	
	always @( posedge sys_clk ) begin
	
		if ((left_s) && (~left_b_state)) begin left_b <= 1'b1; left_b_state <= 1'b1; end
		else if ((~left_s) && (left_b_state)) left_b_state <= 1'b0;
		else left_b <= 1'b0;
		
		if ((right_s) && (~right_b_state)) begin right_b <= 1'b1; right_b_state <= 1'b1; end
		else if ((~right_s) && (right_b_state)) right_b_state <= 1'b0;
		else right_b <= 1'b0;
		
		if ((center_s) && (~center_b_state)) begin center_b <= 1'b1; center_b_state <= 1'b1; end
		else if ((~center_s) && (center_b_state)) center_b_state <= 1'b0;
		else center_b <= 1'b0;
		
		if ((up_s) && (~up_b_state)) begin up_b <= 1'b1; up_b_state <= 1'b1; end
		else if ((~up_s) && (up_b_state)) up_b_state <= 1'b0;
		else up_b <= 1'b0;
		
		if ((down_s) && (~down_b_state)) begin down_b <= 1'b1; down_b_state <= 1'b1; end
		else if ((~down_s) && (down_b_state)) down_b_state <= 1'b0;
		else down_b <= 1'b0;
		
	end

	/***********************/
	
	// PICOBLAZE CONTROL LOGIC begin
	
	parameter [7:0]	ram_com_port			= 8'h00,
							ram_start_addr_port1	= 8'h01,
							ram_start_addr_port2	= 8'h06,
							ram_start_addr_port3	= 8'h07,
							ram_start_addr_port4	= 8'h08,
							ram_stop_addr_port1	= 8'h02,
							ram_stop_addr_port2	= 8'h09,
							ram_stop_addr_port3	= 8'h0A,
							ram_stop_addr_port4	= 8'h0B,
							lcd_com_port			= 8'h03,
							lcd_data_port			= 8'h04,
							volume_port				= 8'h05,
							write_addr_port1		= 8'h0C,
							write_addr_port2		= 8'h0D,
							write_addr_port3		= 8'h0E,
							write_addr_port4		= 8'h0F,
							test_port				= 8'hFF;
	
	reg [7:0] ram_com = 8'h00;
	reg [25:0] ram_start_addr = 26'h0000000;
	reg [25:0] ram_stop_addr = 26'h0000000;
	reg [2:0] pico_lcd_com = 4'h0;
	reg [7:0] pico_lcd_data = 8'h00;
	output reg [7:0] pico_test = 8'h00;
	
	always @( posedge sys_clk ) begin

		if ((left_b || right_b || center_b || up_b || down_b || ram_op_done || mem_full) && (~interrupt) && lcd_done) begin
			interrupt <= 1'b1;
			if (left_b)					pico_in_port <= 8'h01;
			else if (right_b)			pico_in_port <= 8'h02;
			else if (center_b)		pico_in_port <= 8'h03;
			else if (up_b)				pico_in_port <= 8'h04;
			else if (down_b)			pico_in_port <= 8'h05;
			else if (mem_full)		pico_in_port <= 8'h06;
			else if (ram_op_done)	pico_in_port <= 8'h07;
		end
		else if (port_id == write_addr_port1) pico_in_port <= write_stop_addr[7:0];
		else if (port_id == write_addr_port2) pico_in_port <= write_stop_addr[15:8];
		else if (port_id == write_addr_port3) pico_in_port <= write_stop_addr[23:16];
		else if (port_id == write_addr_port4) pico_in_port <= write_stop_addr[25:24];
		
		if (interrupt_ack) interrupt <= 1'b0;
		if (read_strobe) pico_in_port <= 8'h00;

	end
	
	always @( posedge sys_clk ) begin
	
		if (write_strobe) begin
			pico_out_hold <= pico_out_port;
			pico_port_hold <= port_id;
			case (port_id)
				ram_com_port: 				ram_com <= pico_out_port;
				ram_start_addr_port1:	ram_start_addr[7:0] <= pico_out_port;
				ram_start_addr_port2:	ram_start_addr[15:8] <= pico_out_port;
				ram_start_addr_port3:	ram_start_addr[23:16] <= pico_out_port;
				ram_start_addr_port4:	ram_start_addr[25:24] <= pico_out_port;
				ram_stop_addr_port1:		ram_stop_addr[7:0] <= pico_out_port;
				ram_stop_addr_port2:		ram_stop_addr[15:8] <= pico_out_port;
				ram_stop_addr_port3:		ram_stop_addr[23:16] <= pico_out_port;
				ram_stop_addr_port4:		ram_stop_addr[25:24] <= pico_out_port;
				lcd_com_port: 				pico_lcd_com <= pico_out_port[2:0];
				lcd_data_port: 			pico_lcd_data <= pico_out_port;
				volume_port:				volume <= pico_out_port[4:0];
				test_port:					pico_test <= pico_out_port;
			endcase
		end
	
	end
	
	// PICOBLAZE CONTROL LOGIC end
	
	/***********************/

	// RAM CONTROL LOGIC begin
	
	parameter [9:0] 	ac97_delay = 10'b1100001101,
							half_ac97_delay = 10'b0110000110;
	
	reg [9:0] ac97_count = 10'b0000000000;
	reg delay_ack = 1'b0;
	
	reg [2:0] read_state = 3'b000;
	reg [2:0] write_state = 3'b000;
	
	reg [25:0] addr_start_p = 26'h0000000;
	reg [25:0] addr_stop_p = 26'h0000000;
	reg [25:0] write_stop_addr = 26'h0000000;
	
	reg ram_op_done = 0;
	output reg mem_full = 1'b0;

	always @( posedge sys_clk ) begin
	
		if (ram_com[7:0] == 8'h80) begin ram_op_done <= 0; mem_full <= 1'b0; end		// RAM inactive, bypass if statement
	
		else if (ram_com[7:0] == 8'h40) begin		// load RAM data, reset
			addr_start_p <= ram_start_addr;
			addr_stop_p <= ram_stop_addr;
			
			ram_op_done <= 0;						// reset everything!
			mem_full <= 0;
			write_state <= 3'b000;
			read_state <= 3'b000;
			ac97_count <= 10'b0000000000;
			delay_ack <= 1'b0;
			address <= 26'h0000000;
			data_in <= 8'h00;
			write_enable <= 1'b0;
			read_request <= 1'b0;
			read_ack <= 1'b0;
		end
		
		else if (ram_com[7:0] == 8'h20) write_stop_addr <= addr_start_p;	// latch write stop address
		
		else if ((	ram_com[7:0] == 8'h01 || ram_com[7:0] == 8'h02 || ram_com[7:0] == 8'h04 ||
						ram_com[7:0] == 8'h08 || ram_com[7:0] == 8'h10	) &&
						rdy && ~ram_op_done && ~mem_full)										begin	// HW ready, op NOT done
					
			if ((ac97_count == ac97_delay) || ((ac97_count == half_ac97_delay) &&  (ram_com[7:0] == 8'h10))) begin
				ac97_count <= 10'b0000000000;
				delay_ack <= 1'b1;
			end
			else ac97_count <= ac97_count + 1;
	
			if (delay_ack ||  ram_com[7:0] == 8'h04 ||  ram_com[7:0] == 8'h08) begin	// bypass delay if delete op
				
				if (ram_com[7:0] == 8'h02 || ram_com[7:0] == 8'h04 ||  ram_com[7:0] == 8'h08) begin // write or delete op
					if (write_state == 3'b000) begin
						address <= addr_start_p;
						write_state <= 3'b001;
					end
					if (write_state == 3'b001) begin
						if (ram_com[7:0] == 8'h02) data_in <= from_ac97_data;	// load date from ac97 if write
						else	data_in <= 8'h00;											// load 00 if delete
						write_state <= 3'b010;
					end
					else if (write_state == 3'b010) begin
						write_enable <= 1'b1;
						write_state <= 3'b011;
					end
					else if (write_state == 3'b011) begin
						write_enable <= 1'b0;
						addr_start_p <= addr_start_p + 1;
						delay_ack <= 1'b0;
						write_state <= 3'b000;
					end
				end
				
				else if (ram_com[7:0] == 8'h01 || ram_com[7:0] == 8'h10) begin	// read or FF op
					if (read_state == 3'b000) begin
						address <= addr_start_p;
						read_state <= 3'b001;
					end
					else if (read_state == 3'b001) begin
						read_request <= 1'b1;
						read_state <= 3'b010;
					end
					else if (read_state == 3'b010) begin
						read_request <= 1'b0;
						read_state <= 3'b011;
					end
					else if (read_state == 3'b011) begin
						if (rd_data_pres) read_state <= 3'b100;
					end
					else if (read_state == 3'b100) begin
						to_ac97_data <= data_out;
						read_state <= 3'b101;
					end
					else if (read_state == 3'b101) begin
						read_ack <= 1'b1;
						read_state <= 3'b110;
					end
					else if (read_state == 3'b110) begin
						read_ack <= 1'b0;
						addr_start_p <= addr_start_p + 1;
						delay_ack <= 1'b0;
						read_state <= 3'b000;
					end
				end
				
				// checks if start point has reached stop point (read, addr controlled delete, delete all, or FF)
				if ((addr_start_p == addr_stop_p) && (ram_com[7:0] == 8'h01 || ram_com[7:0] == 8'h04 || ram_com[7:0] == 8'h08 || ram_com[7:0] == 8'h10)) begin
					ram_op_done <= 1;
				end
				else if ((addr_start_p == 26'h1FFFFF0) && (ram_com[7:0] == 8'h02)) begin 	// if max addr during write op
					mem_full <= 1'b1;																			// avoids overwriting
				end
				
			end
		end
		
	end
	
	// RAM CONTROL LOGIC end
	
	/***********************/

	// LCD CONTROL LOGIC begin
	
	parameter [5:0] 	d1 = 5'b00011, d2 = 6'b000101,
							d3 = 6'b001110, d4 = 6'b110100,
							d5 = 6'b110110, d6 = 6'b111111;
	
	reg [29:0] lcd_delay = 0;
	
	always @( posedge sys_clk ) begin

		if (lcd_delay == d1)	begin
			if (~lcd_done) begin
				lcd_data <= lcd_data_b[7:4];
				lcd_com[1:0] <= lcd_com_b[1:0];
			end
			else begin
				lcd_data <= pico_lcd_data[7:4];
				lcd_com[1:0] <= pico_lcd_com[1:0];
			end
		end
		else if (lcd_delay == d2) lcd_com[2] <= 1'b1;				// assert enable after 40ns (2 cycles)
		else if (lcd_delay == d3) lcd_com[2] <= 1'b0;				// de-assert enable after 230ns (9 cycles)
		else if (lcd_delay == d4) begin
			if (~lcd_done) lcd_data <= lcd_data_b[3:0]; 				// after 1us, setup lsb[yte] (38 cycles)
			else lcd_data <= pico_lcd_data[3:0];
		end
		else if (lcd_delay == d5) lcd_com[2] <= 1'b1;				// assert enable after 40ns (2 cycles)
		else if (lcd_delay == d6) lcd_com[2] <= 1'b0;				// de-assert enable after 230ns (9 cycles)
		
		if (~lcd_done && ~lcd_com_b[2]) lcd_delay <= 0;		// reset count when pmod_lcd lowers enable
		else if (lcd_done && ~pico_lcd_com[2]) lcd_delay <= 0;
		else lcd_delay <= lcd_delay + 1;							// increment delay counter
			
	end
	
	// LCD CONTROL LOGIC end

endmodule
