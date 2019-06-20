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
  input [5:0] p_test_conn, n_test_conn       // no defined use yet
	
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

endmodule
