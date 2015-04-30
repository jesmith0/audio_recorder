`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineers: Dan Pederson, 2004
//				  Barron Barnett, 2004
//				  Jacob Beck, 2006
//				  Tudor Ciuleanu, 2007
//				  Josh Sackos, 2012
// 
// Create Date:    13:03:39 06/26/2012 
// Module Name:    PmodCLP 
// Project Name:   PmodCLP_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.1
// Description: Displays "Hello from Digilent" text on the PmodCLP LCD screen.
//
// Revision: 6
// Revision 0.01 - File Created
// Revision History:								    
//		 05/27/2004(DanP):  created
//		 07/01/2004(BarronB): (optimized) and added writeDone as output
//		 08/12/2004(BarronB): fixed timing issue on the D2SB
//		 12/07/2006(JacobB): Revised code to be implemented on a Nexys Board
//						Changed "Hello from Digilent" to be on one line"
//						Added a Shift Left command so that the message
//						"Hello from Diligent" is shifted left by 1 repeatedly
//						Changed the delay of character writes
//		 11/21/2007(TudorC): Revised code to work with the CLP module.
//						Removed the write state machine and other unnecessary signals
//						Added backlight toggling
//		 08/17/2011(MichelleY): remove the backlight toggling
//									modify to be compatible with Nexys2 master UCF
//		 06/26/2012(JoshS): Converted VHDL to Verilog
//////////////////////////////////////////////////////////////////////////////////


// ==============================================================================
// 										  Define Module
// ==============================================================================
module pmod_lcd(
    btnr,
    CLK,
    JA,
	 JB,
	 done
    );

	// ===========================================================================
	// 										Port Declarations
	// ===========================================================================
    input btnr;								// use BTNR as reset input
    input CLK;									// 100 MHz clock input

   //lcd input signals
   //signal on connector JA
    output [7:0] JA;							//output bus, used for data transfer (DB)
   // signal on connector JB
   //JB[4]register selection pin  (RS)
   //JB[5]selects between read/write modes (RW)
   //JB[6]enable signal for starting the data read/write (E)
    output [6:4] JB;
	 output reg done;


	// ===========================================================================
	// 							  Parameters, Regsiters, and Wires
	// ===========================================================================
	wire [7:0] JA;
	wire [6:4] JB;

   //LCD control state machine
	parameter [3:0] stFunctionSet = 0,						// Initialization states
						 stDisplayCtrlSet = 1,
						 stDisplayClear = 2,
						 stPowerOn_Delay = 3,					// Delay states
						 stFunctionSet_Delay = 4,
						 stDisplayCtrlSet_Delay = 5,
						 stDisplayClear_Delay = 6,
						 stInitDne = 7,							// Display characters and perform standard operations
						 stActWr = 8,
						 stCharDelay = 9;							// Write delay for operations	
	
	/* These constants are used to initialize the LCD pannel.

		--  FunctionSet:
								Bit 0 and 1 are arbitrary
								Bit 2:  Displays font type(0=5x8, 1=5x11)
								Bit 3:  Numbers of display lines (0=1, 1=2)
								Bit 4:  Data length (0=4 bit, 1=8 bit)
								Bit 5-7 are set
		--  DisplayCtrlSet:
								Bit 0:  Blinking cursor control (0=off, 1=on)
								Bit 1:  Cursor (0=off, 1=on)
								Bit 2:  Display (0=off, 1=on)
								Bit 3-7 are set
		--  DisplayClear:
								Bit 1-7 are set	*/
		
	reg [5:0] clkCount = 6'b000000;
	reg [20:0] count = 21'b000000000000000000000;	// 21 bit count variable for timing delays
	wire delayOK;													// High when count has reached the right delay time
	reg oneUSClk;													// Signal is treated as a 1 MHz clock	
	reg [3:0] stCur = stPowerOn_Delay;						// LCD control state machine
	reg [3:0] stNext;
	wire writeDone;											// Command set finish

	parameter [9:0] LCD_CMDS[0:23] = {

						{2'b00, 8'h2C},		// 0, Function Set
						{2'b00, 8'h0C},		// 1, Display ON, Cursor OFF, Blink OFF
						{2'b00, 8'h01},		// 2, Clear Display
						{2'b00, 8'h02},		// 3, Return Home

						{2'b10, 8'h20},		// 4, space
						{2'b10, 8'h20},		// 5, space
						{2'b10, 8'h20},		// 6, space
						{2'b10, 8'h20},		// 7, space
						{2'b10, 8'h57},		// 8, W
						{2'b10, 8'h45},		// 9, E
						{2'b10, 8'h4C},		// 10, L
						{2'b10, 8'h43},		// 11, C
						{2'b10, 8'h4F},		// 12, o
						{2'b10, 8'h4D},		// 13, m
						{2'b10, 8'h45},		// 14, E
						{2'b10, 8'h21},		// 15, !
						
						{2'b10, 8'h69},		// 16, i
						{2'b10, 8'h67},		// 17, g
						{2'b10, 8'h69},		// 18, i
						{2'b10, 8'h6C},		// 19, l
						{2'b10, 8'h65},		// 20, e
						{2'b10, 8'h6E},		// 21, n
						{2'b10, 8'h74},		// 22, t
						{2'b00, 8'h18}			// 23, Shift left
	};

	reg [4:0] lcd_cmd_ptr;

	// ===========================================================================
	// 										Implementation
	// ===========================================================================

	// This process counts to 100, and then resets.  It is used to divide the clock signal.
	// This makes oneUSClock peak aprox. once every 1microsecond
	always @(posedge CLK) begin

			if(clkCount == 6'b111111) begin
					clkCount <= 6'b000000;
					oneUSClk <= ~oneUSClk;
			end
			else begin
					clkCount <= clkCount + 1'b1;
			end

	end


	// This process increments the count variable unless delayOK = 1.
	always @(posedge oneUSClk) begin
	
			if(delayOK == 1'b1) begin
					count <= 21'b000000000000000000000;
			end
			else begin
					count <= count + 1'b1;
			end
	
	end


	// Determines when count has gotten to the right number, depending on the state.
	assign delayOK = (
				((stCur == stPowerOn_Delay) && (count == 21'b000000010110111000111)) ||				// 2000000	 	-> 20 ms
				((stCur == stFunctionSet_Delay) && (count == 21'b000000000000000011000)) ||		// 4000 			-> 40 us
				((stCur == stDisplayCtrlSet_Delay) && (count == 21'b000000000000000011000)) ||	// 4000 			-> 40 us
				((stCur == stDisplayClear_Delay) && (count == 21'b000000000001110101010)) ||		// 160000 		-> 1.6 ms
				((stCur == stCharDelay) && (count == 21'b000000011110111110100))						// 260000		-> 2.6 ms - Max Delay for character writes and shifts
	) ? 1'b1 : 1'b0;
	/*
	assign delayOK = (
				((stCur == stPowerOn_Delay) && (count == 21'b111101000010010000000)) ||				// 2000000	 	-> 20 ms
				((stCur == stFunctionSet_Delay) && (count == 21'b000000000111110100000)) ||		// 4000 			-> 40 us
				((stCur == stDisplayCtrlSet_Delay) && (count == 21'b000000000111110100000)) ||	// 4000 			-> 40 us
				((stCur == stDisplayClear_Delay) && (count == 21'b000100111000100000000)) ||		// 160000 		-> 1.6 ms
				((stCur == stCharDelay) && (count == 21'b000111111011110100000))						// 260000		-> 2.6 ms - Max Delay for character writes and shifts
	) ? 1'b1 : 1'b0;
	*/

	// writeDone goes high when all commands have been run	
	assign writeDone = (lcd_cmd_ptr == 5'd16) ? 1'b1 : 1'b0;
	
	always @(writeDone) begin
		done <= writeDone;
	end
	
	// Increments the pointer so the statemachine goes through the commands
	always @(posedge oneUSClk) begin
			if((stNext == stInitDne || stNext == stDisplayCtrlSet || stNext == stDisplayClear) && writeDone == 1'b0) begin
					lcd_cmd_ptr <= lcd_cmd_ptr + 1'b1;
			end
			else if(stCur == stPowerOn_Delay || stNext == stPowerOn_Delay) begin
					lcd_cmd_ptr <= 5'b00000;
			end
			else begin
					lcd_cmd_ptr <= lcd_cmd_ptr;
			end
	end
	
	
	// This process runs the LCD state machine
	always @(posedge oneUSClk) begin
			if(btnr == 1'b1) begin
					stCur <= stPowerOn_Delay;
			end
			else begin
					stCur <= stNext;
			end
	end
	

	// This process generates the sequence of outputs needed to initialize and write to the LCD screen
	always @(stCur or delayOK or writeDone or lcd_cmd_ptr) begin
			case (stCur)
				// Delays the state machine for 20ms which is needed for proper startup.
				stPowerOn_Delay : begin
						if(delayOK == 1'b1) begin
							stNext <= stFunctionSet;
						end
						else begin
							stNext <= stPowerOn_Delay;
						end
				end
					
				// This issues the function set to the LCD as follows 
				// 8 bit data length, 1 lines, font is 5x8.
				stFunctionSet : begin
						stNext <= stFunctionSet_Delay;
				end
				
				// Gives the proper delay of 37us between the function set and
				// the display control set.
				stFunctionSet_Delay : begin
						if(delayOK == 1'b1) begin
							stNext <= stDisplayCtrlSet;
						end
						else begin
							stNext <= stFunctionSet_Delay;
						end
				end
				
				// Issuse the display control set as follows
				// Display ON,  Cursor OFF, Blinking Cursor OFF.
				stDisplayCtrlSet : begin
						stNext <= stDisplayCtrlSet_Delay;
				end

				// Gives the proper delay of 37us between the display control set
				// and the Display Clear command. 
				stDisplayCtrlSet_Delay : begin
						if(delayOK == 1'b1) begin
							stNext <= stDisplayClear;
						end
						else begin
							stNext <= stDisplayCtrlSet_Delay;
						end
				end
				
				// Issues the display clear command.
				stDisplayClear	: begin
						stNext <= stDisplayClear_Delay;
				end

				// Gives the proper delay of 1.52ms between the clear command
				// and the state where you are clear to do normal operations.
				stDisplayClear_Delay : begin
						if(delayOK == 1'b1) begin
							stNext <= stInitDne;
						end
						else begin
							stNext <= stDisplayClear_Delay;
						end
				end
				
				// State for normal operations for displaying characters, changing the
				// Cursor position etc.
				stInitDne : begin		
						stNext <= stActWr;
				end

				// stActWr
				stActWr : begin
						stNext <= stCharDelay;
				end
					
				// Provides a max delay between instructions.
				stCharDelay : begin
						if(delayOK == 1'b1) begin
							stNext <= stInitDne;
						end
						else begin
							stNext <= stCharDelay;
						end
				end

				default : stNext <= stPowerOn_Delay;

			endcase
	end
		
		
	// Assign outputs
	assign JB[4] = LCD_CMDS[lcd_cmd_ptr][9];
	assign JB[5] = LCD_CMDS[lcd_cmd_ptr][8];
	assign JA = LCD_CMDS[lcd_cmd_ptr][7:0];
	assign JB[6] = (stCur == stFunctionSet || stCur == stDisplayCtrlSet || stCur == stDisplayClear || stCur == stActWr) ? 1'b1 : 1'b0;

endmodule
