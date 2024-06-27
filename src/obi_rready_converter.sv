module obi_rready_converter #(
                              parameter type obi_a_chan_t = logic,
                              parameter type obi_r_chan_t = logic,
                              parameter int unsigned DEPTH = 1
                              )
  (
   input logic  clk_i,
   input logic  rst_ni,
   input logic  test_mode_i,
   input        obi_a_chan_t sbr_a_chan_i,
   input logic  req_i,
   input logic  rready_i,
   output       obi_r_chan_t sbr_r_chan_o,
   output logic gnt_o,
   output logic rvalid_o,
   output       obi_a_chan_t mgr_a_chan_o,
   output logic req_o,
   output logic rready_o, // this will be always 1
   input        obi_r_chan_t mgr_r_chan_i,
   input logic  gnt_i,
   input logic  rvalid_i
   );



  logic fifo_ready, credit_left;
  stream_fifo #(
                .FALL_THROUGH(1'b1),
                .DEPTH(DEPTH),
                .T(obi_r_chan_t)
                )
  response_fifo_i
    (
     .clk_i,
     .rst_ni,
     .flush_i(1'b0),
     .testmode_i(test_mode_i),
     .usage_o(),
     .data_i(mgr_r_chan_i),
     .valid_i(rvalid_i),
     .ready_o(fifo_ready),
     .data_o(sbr_r_chan_o),
     .valid_o(rvalid_o),
     .ready_i(rready_i)
     );

  credit_counter #(
                   .NumCredits(DEPTH),
                   .InitCreditEmpty(1'b0)
                   )
  credit_cntr_i (
                 .clk_i,
                 .rst_ni,
                 .credit_o(),
                 .credit_give_i(rvalid_o & rready_i),
                 .credit_take_i(req_o & gnt_i),
                 .credit_init_i(1'b0),
                 .credit_left_o(credit_left),
                 .credit_crit_o(),
                 .credit_full_o()
                 );

  assign rready_o = 1'b1; // We are always ready for responses, because we don't send more requests than we
                          // can absorb in the fifo
  assign req_o = req_i & (credit_left | (rready_i & rvalid_o)); // only transmit requests if we have credits left or free a
                                                   // space in the FIFO
  assign gnt_o = gnt_i & (credit_left | (rready_i & rvalid_o)); // only grant requests if we have credits left or free a
                                                   // space in the FIFO
  assign mgr_a_chan_o = sbr_a_chan_i;
  
endmodule : obi_rready_converter
