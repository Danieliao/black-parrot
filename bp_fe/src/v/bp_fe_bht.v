/*
 * bp_fe_bht.v
 * 
 * Branch History Table (BHT) records the information of the branch history, i.e.
 * branch taken or not taken. 
 * Each entry consists of 2 bit saturation counter. If the counter value is in
 * the positive regime, the BHT predicts "taken"; if the counter value is in the
 * negative regime, the BHT predicts "not taken". The implementation of BHT is
 * native to this design.
*/
module bp_fe_bht
 import bp_fe_pkg::*; 
 #(parameter bht_idx_width_p = "inv"

   , localparam local_bht_els_lp   = 2**bht_idx_width_p
   , localparam local_bht_length   = 4 //set to even number
   , localparam global_bht_idx_width_p = 9
   , localparam global_bht_els_lp  = 2**global_bht_idx_width_p
   , localparam saturation_size_lp = 2
   )
  (input                         clk_i
   , input                       reset_i
    
   , input                       w_v_i
   , input [bht_idx_width_p-1:0] idx_w_i
   , input                       correct_i
 
   , input                       r_v_i   
   , input [bht_idx_width_p-1:0] idx_r_i
   , output                      predict_o
   );



//logic [els_lp-1:0][saturation_size_lp-1:0] global_bht;
logic [local_bht_els_lp-1:0][local_bht_length-1:0] local_bht;
logic [global_bht_els_lp-1:0][saturation_size_lp-1:0] global_bht;

logic [global_bht_idx_width_p-1:0] global_bht_index;
assign global_bht_index = {idx_w_i[global_bht_idx_width_p-local_bht_length-1:0], local_bht[idx_w_i]};

logic [saturation_size_lp-1:0] global_bht_r;


always_ff @(posedge clk_i)
  begin 
    if (reset_i)
      local_bht <= '{default:4'b0000};
      //global_bht_r <= 2'b0;
    else if (w_v_i)
      local_bht[idx_w_i] <= {global_bht_r, local_bht[idx_w_i][local_bht_length-1:local_bht_length-1-saturation_size_lp]};
end

assign predict_o = r_v_i ? global_bht_r[1] : 1'b0;

always_ff @(posedge clk_i) 
  if (reset_i) 
    begin
      global_bht <= '{default:2'b01};
      global_bht_r <= 2'b01;
    end
  else if (w_v_i) 
    begin
      //2-bit saturating counter(high_bit:prediction direction,low_bit:strong/weak prediction)
      case ({correct_i, global_bht[global_bht_index][1], global_bht[global_bht_index][0]})
        //wrong prediction
        3'b000: global_bht_r <= {global_bht[global_bht_index][1]^global_bht[global_bht_index][0], 1'b1};//2'b01
        3'b001: global_bht_r <= {global_bht[global_bht_index][1]^global_bht[global_bht_index][0], 1'b1};//2'b11
        3'b010: global_bht_r <= {global_bht[global_bht_index][1]^global_bht[global_bht_index][0], 1'b1};//2'b11
        3'b011: global_bht_r <= {global_bht[global_bht_index][1]^global_bht[global_bht_index][0], 1'b1};//2'b01
        //correct prediction
        3'b100: global_bht_r <= global_bht[global_bht_index];//2'b00
        3'b101: global_bht_r <= {global_bht[global_bht_index][1], ~global_bht[global_bht_index][0]};//2'b00
        3'b110: global_bht_r <= global_bht[global_bht_index];//2'b10
        3'b111: global_bht_r <= {global_bht[global_bht_index][1], ~global_bht[global_bht_index][0]};//2'b10
      endcase

    global_bht[global_bht_index] <= global_bht_r;
    end
  
endmodule
