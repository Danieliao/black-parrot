/*
 * bp_fe_ras.v
 *
 *
 * Return Address Stack (RAS) stores the addresses that JAL and JALR instructions
 * are linked back to. When a JAL or JALR instruction is called, it pushes the
 * return address onto the stack (either r or the pc+4). When a JALR instruction with r0 as destination
 * is called, the return address at the top of the stack is pushed as the branch
 * target. This implementations uses the bsg_mem_1rw_sync_synth RAM design.
 */
module bp_fe_ras
 import bp_common_pkg::*;
 import bp_common_aviary_pkg::*;
 import bp_common_rv64_pkg::*;
 import bp_fe_pkg::*;
 #(parameter vaddr_width_p = "inv"
   , parameter ras_tag_width_p = "inv"
   , parameter ras_idx_width_p = "inv"

   // From RISC-V specifications
   , localparam eaddr_width_lp = rv64_eaddr_width_gp
   , localparam instr_scan_width = rv64_instr_width_gp
   , localparam instr_scan_width_lp = `bp_fe_instr_scan_width(vaddr_width_p)
   )
   ( input                              clk_i
   , input                              reset_i

   , input  [1:0]			state_i 
   , input  [vaddr_width_p-1:0]         pc_i
   , input  [instr_scan_width-1:0]   instr_i
   , output [vaddr_width_p-1:0]        j_tgt_o
   , output                             j_tgt_v_o
   );

rv64_instr_s       instr_cast_i;
logic [vaddr_width_p-1:0] retaddr;
logic [vaddr_width_p-1:0] stack_o;
logic push, pop, pop_d, push_d, onepush;

assign instr_cast_i = instr_i;
assign j_tgt_o = stack_o;
assign j_tgt_v_o = (pop & ~pop_d);
assign onepush = (push & ~push_d);

logic rd_link, rs_link;
always_comb begin
  retaddr = pc_i;
  push = 1'b0;
  pop = 1'b0;
  rd_link = 1'b0;
  rs_link = 1'b0;
  if(state_i == 2'b01) begin
  unique casez (instr_i[6:0])
    `RV64_JAL_OP   :  begin
    //e_rvi_jal: begin
      rd_link = (instr_i[11:7] == 5'b00001 || instr_i[11:7] == 5'b00101);
      //if(rd_link)
        push = 1;
    end
    `RV64_JALR_OP  :  begin
    //e_rvi_jalr: begin
      rd_link = (instr_i[11:7] == 5'b00001 || instr_i[11:7] == 5'b00101);
      rs_link = (instr_i[19:15] == 5'b00001 || instr_i[19:15] == 5'b00101);
      unique case ({rd_link,rs_link})
      2'b01: pop = 1'b1;
      2'b10: push = 1'b1;
      2'b11: begin
        if(instr_i[19:15] == instr_i[11:7])
          push = 1'b1;
        else begin
          push = 1'b1;
          pop = 1'b1;
        end
      end
      default: begin
        push = 1'b0;
        pop = 1'b0;
      end
      endcase
    end
    default: begin
      push = 1'b0;
      pop = 1'b0;
    end
    endcase
end
end

always_ff @(posedge clk_i)
  begin
    pop_d <= pop;
    push_d <= push;
  end

fakebsg_stack
  #(.width_p(vaddr_width_p)
   ,.els_p(16))
  ras_interface
   (
    .clk_i(clk_i)
   ,.reset_i(reset_i)

   ,.push_i(onepush)
   ,.w_data_i(retaddr)

   ,.pop_i((pop & ~pop_d))
   ,.r_data_o(stack_o)
   );

endmodule
