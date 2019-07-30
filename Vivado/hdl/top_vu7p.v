module top_vu7p (
	
//-----------------------------------------------
  // clocks
  input p_clk_200a, n_clk_200a,                // 200 MHz system clock
  // ATCA timing and control
  //input p_atca_ttc_in, n_atca_ttc_in,        // GTH input, combined clock and data
  //output p_atca_tts_out, n_atca_tts_out,     // GTH output
  // legacy AMC13 signals
  input p_amc13_clk_40, n_amc13_clk_40,      // extracted 40 MHz experimental clock
  input p_amc13_cdr_data, n_amc13_cdr_data,  // extracted TTC data
  output p_amc13_tts_out, n_amc13_tts_out,   // encoded TTS 
  // 2 positions from 4 position DIP SWITCH
  input [3:2] dip_sw,                        // dip_sw[2] = position 2 of 4, no defined use yet
                                             // dip_sw[3] = position 3 of 4, no defined use yet
                                             // position 1 = boot mode , 0=MASTER_SPI, 1 = JTAG ONLY
                                             // position 4 = bit to TM4C  
  // tri-color LED
  output led_red, led_green, led_blue,       // assert to turn on
  // utility bits to/from TM4C
  input from_tm4c,                           // no defined use yet
  output to_tm4c,                            // no defined use yet
  // spare pairs from the VU7P, defined as inputs until an output is needed
  input [12:0] p_kv_spare, n_kv_spare,       // no defined use yet
  // test connector on bottom side of board, defined as inputs until an output is needed
  input [5:0] p_test_conn, n_test_conn,       // no defined use yet
  inout v_fpga_i2c_scl, // uncomment when using I2C DRP interface 
  inout v_fpga_i2c_sda // uncomment when using I2C DRP interface	
);

// add a differential clock buffer
wire clk_200;              // 200 MHz utility clock
IBUFDS clk_200_buf(.O(clk_200), .I(p_clk_200a), .IB(n_clk_200a) );

// add a free running counter to divide the clock
reg [27:0] divider;
always @(posedge clk_200) begin
  divider[27:0] <= divider[27:0] + 1;
end

assign led_red = divider[27];
assign led_green = divider[26];
assign led_blue = divider[25];

// create 6 differential buffers for inputs from the test connector 
genvar chan;
wire [5:0] test_conn_in;
generate
  for (chan=0; chan < 6; chan=chan+1)
    begin: gen_test_conn_buf
      IBUFDS test_conn_buf(.O(test_conn_in[chan]), .I(p_test_conn[chan]), .IB(n_test_conn[chan]) );
  end
endgenerate

// create 13 differential buffers for spare inputs from the VU7P 
wire [12:0] kv_spare_in;
generate
  for (chan=0; chan < 13; chan=chan+1)
    begin: gen_kv_spare_buf
      IBUFDS kv_spare_buf(.O(kv_spare_in[chan]), .I(p_kv_spare[chan]), .IB(n_kv_spare[chan]) );
  end
endgenerate

// loop amc13 input to output
wire amc13_clk_40;
wire amc13_cdr_data; 
reg amc13_tts_out;
IBUFDS amc13_clk_40_buf(.O(amc13_clk_40), .I(p_amc13_clk_40), .IB(n_amc13_clk_40) );
IBUFDS amc13_cdr_data_buf(.O(amc13_cdr_data), .I(p_amc13_cdr_data), .IB(n_amc13_cdr_data) );
OBUFDS amc13_tts_out_buf(.I(amc13_tts_out), .O(p_amc13_tts_out), .OB(n_amc13_tts_out) );
always @(posedge amc13_clk_40) begin
  amc13_tts_out <= amc13_cdr_data;
end
 
// munge together 'dip_sw', 'from_tm4c', 'test_conn' and 'kv_spare' to a single output
assign to_tm4c =  from_tm4c & dip_sw[2] & dip_sw[3] & test_conn_in[0] & test_conn_in[1] & test_conn_in[2] & test_conn_in[3] & test_conn_in[4] & test_conn_in[5] & 
     kv_spare_in[0] & kv_spare_in[1] & kv_spare_in[2] & kv_spare_in[3] & kv_spare_in[4] & kv_spare_in[5] & kv_spare_in[6] & kv_spare_in[7] &
     kv_spare_in[8] & kv_spare_in[9] & kv_spare_in[10] & kv_spare_in[11] & kv_spare_in[12];

// I2C interface for SYSMON
wire i2c_sclk_in;
wire i2c_sclk_ts;
wire i2c_sda_in;
wire i2c_sda_ts;

/// sysmone1

//  SYSMONE1   : In order to incorporate this function into the design,
//   Verilog   : the following instance declaration needs to be placed
//  instance   : in the body of the design code.  The instance name
// declaration : (SYSMONE1_inst) and/or the port declarations within the
//    code     : parenthesis may be changed to properly reference and
//             : connect this function to the design.  All inputs
//             : and outputs must be connected.

//  <-----Cut code below this line---->

   // SYSMONE1: Xilinx Analog-to-Digital Converter and System Monitor
   //           Virtex UltraScale+
   // Xilinx HDL Language Template, version 2018.2

   SYSMONE1 #(
      // INIT_40 - INIT_44: SYSMON configuration registers
      .INIT_40(16'h0000),
      .INIT_41(16'h0000),
      .INIT_42(16'h0000),
      .INIT_43(16'hC680), // enable I2C, I2C address 0x23, OR enable
      .INIT_44(16'h0000),
      .INIT_45(16'h0000),              // Analog Bus Register
      // INIT_46 - INIT_4F: Sequence Registers
      .INIT_46(16'h0000),
      .INIT_47(16'h0000),
      .INIT_48(16'h0000),
      .INIT_49(16'h0000),
      .INIT_4A(16'h0000),
      .INIT_4B(16'h0000),
      .INIT_4C(16'h0000),
      .INIT_4D(16'h0000),
      .INIT_4E(16'h0000),
      .INIT_4F(16'h0000),
      // INIT_50 - INIT_5F: Alarm Limit Registers
      .INIT_50(16'h0000),
      .INIT_51(16'h0000),
      .INIT_52(16'h0000),
      .INIT_53(16'h0000),
      .INIT_54(16'h0000),
      .INIT_55(16'h0000),
      .INIT_56(16'h0000),
      .INIT_57(16'h0000),
      .INIT_58(16'h0000),
      .INIT_59(16'h0000),
      .INIT_5A(16'h0000),
      .INIT_5B(16'h0000),
      .INIT_5C(16'h0000),
      .INIT_5D(16'h0000),
      .INIT_5E(16'h0000),
      .INIT_5F(16'h0000),
      // INIT_60 - INIT_6F: User Supply Alarms
      .INIT_60(16'h0000),
      .INIT_61(16'h0000),
      .INIT_62(16'h0000),
      .INIT_63(16'h0000),
      .INIT_64(16'h0000),
      .INIT_65(16'h0000),
      .INIT_66(16'h0000),
      .INIT_67(16'h0000),
      .INIT_68(16'h0000),
      .INIT_69(16'h0000),
      .INIT_6A(16'h0000),
      .INIT_6B(16'h0000),
      .INIT_6C(16'h0000),
      .INIT_6D(16'h0000),
      .INIT_6E(16'h0000),
      .INIT_6F(16'h0000),
      // Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion on
      // specific pins
      .IS_CONVSTCLK_INVERTED(1'b0),    // Optional inversion for CONVSTCLK, 0-1
      .IS_DCLK_INVERTED(1'b0),         // Optional inversion for DCLK, 0-1
      // Simulation attributes: Set for proper simulation behavior
      .SIM_MONITOR_FILE("design.txt"), // Analog simulation data file name
      // User Voltage Monitor: SYSMON User voltage monitor
      .SYSMON_VUSER0_BANK(0),          // Specify IO Bank for User0
      .SYSMON_VUSER0_MONITOR("NONE"),  // Specify Voltage for User0
      .SYSMON_VUSER1_BANK(0),          // Specify IO Bank for User1
      .SYSMON_VUSER1_MONITOR("NONE"),  // Specify Voltage for User1
      .SYSMON_VUSER2_BANK(0),          // Specify IO Bank for User2
      .SYSMON_VUSER2_MONITOR("NONE"),  // Specify Voltage for User2
      .SYSMON_VUSER3_MONITOR("NONE")   // Specify Voltage for User3
   )
   SYSMONE1_inst (
      // ALARMS outputs: ALM, OT
      .ALM(),                   // 16-bit output: Output alarm for temp, Vccint, Vccaux and Vccbram
      .OT(),                     // 1-bit output: Over-Temperature alarm
      // Dynamic Reconfiguration Port (DRP) outputs: Dynamic Reconfiguration Ports
      .DO(),                     // 16-bit output: DRP output data bus
      .DRDY(),                 // 1-bit output: DRP data ready
      // I2C Interface outputs: Ports used with the I2C DRP interface
      .I2C_SCLK_TS(i2c_sclk_ts),   // 1-bit output: I2C_SCLK output port
      .I2C_SDA_TS(i2c_sda_ts),     // 1-bit output: I2C_SDA_TS output port
      // STATUS outputs: SYSMON status ports
      .BUSY(),                 // 1-bit output: System Monitor busy output
      .CHANNEL(),           // 6-bit output: Channel selection outputs
      .EOC(),                   // 1-bit output: End of Conversion
      .EOS(),                   // 1-bit output: End of Sequence
      .JTAGBUSY(),         // 1-bit output: JTAG DRP transaction in progress output
      .JTAGLOCKED(),     // 1-bit output: JTAG requested DRP port lock
      .JTAGMODIFIED(), // 1-bit output: JTAG Write to the DRP has occurred
      .MUXADDR(),           // 5-bit output: External MUX channel decode
      // Auxiliary Analog-Input Pairs inputs: VAUXP[15:0], VAUXN[15:0]
      .VAUXN(),               // 16-bit input: N-side auxiliary analog input
      .VAUXP(),               // 16-bit input: P-side auxiliary analog input
      // CONTROL and CLOCK inputs: Reset, conversion start and clock inputs
      .CONVST(1'b0),             // 1-bit input: Convert start input
      .CONVSTCLK(amc13_clk_40),       // 1-bit input: Convert start input
      .RESET(1'b0),               // 1-bit input: Active-High reset
      // Dedicated Analog Input Pair inputs: VP/VN
      .VN(),                     // 1-bit input: N-side analog input
      .VP(),                     // 1-bit input: P-side analog input
      // Dynamic Reconfiguration Port (DRP) inputs: Dynamic Reconfiguration Ports
      .DADDR(),               // 8-bit input: DRP address bus
      .DCLK(),                 // 1-bit input: DRP clock
      .DEN(),                   // 1-bit input: DRP enable signal
      .DI(),                     // 16-bit input: DRP input data bus
      .DWE(),                   // 1-bit input: DRP write enable
      // I2C Interface inputs: Ports used with the I2C DRP interface
      .I2C_SCLK(i2c_sclk_in),         // 1-bit input: I2C_SCLK input port
      .I2C_SDA(i2c_sda_in)            // 1-bit input: I2C_SDA input port
   );

   // End of SYSMONE1_inst instantiation
   // for bidirectional I2C lines					
   IOBUF I2C_SCLK_inst (
    .O(i2c_sclk_in),     // Buffer output
    .IO(v_fpga_i2c_scl),   // Buffer inout port (connect directly to top-level port)
    .I(1'b0),     // Buffer input
    .T(i2c_sclk_ts)      // 3-state enable input, high=input, low=output
   );
   IOBUF I2C_SDA_inst (
    .O(i2c_sda_in),     // Buffer output
    .IO(v_fpga_i2c_sda),   // Buffer inout port (connect directly to top-level port)
    .I(1'b0),     // Buffer input
    .T(i2c_sda_ts)      // 3-state enable input, high=input, low=output
   );

endmodule
