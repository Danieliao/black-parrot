module fakebsg_stack #(parameter width_p=16
			    ,parameter els_p=8
			    ,parameter addr_width_lp=(els_p))
(
   input clk_i
  ,input reset_i

  ,input push_i
  ,input [width_p-1:0] w_data_i

  ,input pop_i
  ,output [width_p-1:0] r_data_o
);

  logic [15:0] mem [els_p-1:0];
  logic [addr_width_lp-1:0] tos_ptr;
  logic [width_p-1:0] temp_out;

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
			tos_ptr <= 0;
			mem[0] <= 0;
    end
	 else if (push_i && !pop_i) begin
			tos_ptr <= tos_ptr + 1;
    end
	 else if (pop_i && !push_i) begin
			tos_ptr <= tos_ptr - 1;
    end

	if (push_i && !pop_i) begin
			mem[tos_ptr] <= w_data_i;
	end
  end

  always_comb begin
		if(pop_i && push_i) begin
			temp_out = w_data_i;
		end
		else if (pop_i) begin
			temp_out = mem[tos_ptr - 1];
		end
		else
			temp_out = mem[0];
  end

  assign r_data_o = temp_out;
endmodule

