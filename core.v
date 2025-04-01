module core( // modulo de um core
  input clk, // clock
  input resetn, // reset que ativa em zero
  output reg [31:0] address, // endereço de saída
  output [31:0] data_out, // dado de saída
  input [31:0] data_in, // dado de entrada
  output we // write enable
);

wire reg_en;
reg [31:0] instr;
wire [31:0] rd1;
wire [31:0] rd2;

reg [31:0] srcA;
reg [31:0] srcB;
wire [31:0] alu_result;
wire zero;
wire [9:0]  alu_control;

reg [31:0] alu_out;
reg zero_out;
reg [31:0] result;

reg [31:0] imm_ext;

wire instr_en;
wire adr_sel;
wire [1:0] srcA_sel;
wire [1:0] srcB_sel;
wire [2:0] imm_sel;
wire [1:0] result_sel;
wire mask_en;
wire mask_sel;

reg [31:0] pc_out;
reg [31:0] old_pc;

reg [31:0] data_in_stored;
wire [31:0] data_in_ext;
reg [31:0] data_current;
wire [31:0] data_masked;

store_mask smsk_inst(
  .data_in(rd2),
  .address(result[1:0]),
  .data_current(data_current),
  .data_out(data_masked),
  .funct(instr[13:12])
);

load_extend ext_inst(
  .data_in(data_in),
  .address(address[1:0]),
  .data_out(data_in_ext),
  .funct(instr[14:12])
);

alu alu_inst(
  .srcA(srcA),
  .srcB(srcB),
  .result(alu_result),
  .funct(alu_control),
  .zero(zero)
);

regfile reg_inst(
  .clk(clk), // clock
  .we(reg_en), // write enable
  .rs1(instr[19:15]), // endereço do registrador fonte 1
  .rs2(instr[24:20]), // endereço do registrador fonte 2
  .rd(instr[11:7]), // endereço do registrador destino
  .wd(result), // write data
  .rd1(rd1), // saída de dado 1
  .rd2(rd2) // saída de dado 2
);

control_unit ctrl_inst(
  .clk(clk),
  .resetn(resetn),
  .zero(zero_out),
  .less(alu_out[0]),
  .opcode(instr[6:0]),
  .funct3(instr[14:12]),
  .funct7(instr[31:25]),
  .alu_control(alu_control),
  .pc_en(pc_en),
  .mem_en(we),
  .reg_en(reg_en),
  .instr_en(instr_en),
  .mask_en(mask_en),
  .adr_sel(adr_sel),
  .imm_sel(imm_sel),
  .srcA_sel(srcA_sel),
  .srcB_sel(srcB_sel),
  .result_sel(result_sel),
  .mask_sel(mask_sel)
);

// mux selecting address
always @(adr_sel, pc_out, result) begin
  if(adr_sel == 1'b0) begin
    address = pc_out;
  end else begin
    address = result;
  end;
end

// mux selecting ALU input A
always @(srcA_sel, pc_out, old_pc) begin
  case(srcA_sel)
    2'b00:
      srcA = pc_out;
    2'b01:
      srcA = old_pc;
    2'b10:
      srcA = rd1;
    2'b11:
      srcA = 32'd0;
    default:
      result = rd1;
  endcase
end

// mux selecting ALU input B
always @(srcB_sel, imm_ext) begin
  case(srcB_sel)
    2'b00:
      srcB = rd2;
    2'b01:
      srcB = imm_ext;
    2'b10:
      srcB = 32'd4;
    default:
      result = rd2;
  endcase
end

// mux selecting result
always @(result_sel, alu_result, alu_out, data_in_stored) begin
  case(result_sel)
    2'b00:
      result = alu_result;
    2'b01:
      result = data_in_stored;
    2'b10:
      result = alu_out;
    default:
      result = alu_out;
  endcase
end

// Extend
always @(imm_sel, instr[31:7]) begin
  case(imm_sel)
    3'b000:
      imm_ext = {{21{instr[31]}}, instr[30:20]};
    3'b001:
      imm_ext = {{21{instr[31]}}, instr[30:25], instr[11:7]};
    3'b010:
      imm_ext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
    3'b011:
      imm_ext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
    3'b100:
      imm_ext = {{13{instr[31]}}, instr[30:12]};
    3'b101:
      imm_ext = {instr[31:12], 12'd0};
    default
      imm_ext = 32'd0;
  endcase
end

// mux selecting data out
assign data_out = mask_sel ? data_masked : rd2;

// storing data_in for store_mask module
always @(posedge clk) begin
  if(mask_en == 1'b1) begin
    data_current = data_in;
  end
end

// storing data_in
always @(posedge clk) begin
  data_in_stored = data_in_ext;
end

// storing alu outputs
always @(posedge clk) begin
  alu_out = alu_result;
  zero_out = zero;
end

// storing instr and pc_out
always @(posedge clk) begin
  if(instr_en == 1'b1) begin
    old_pc = pc_out;
    instr = data_in;
  end
end

// PC register
always @(posedge clk) begin
  if (resetn == 1'b0) begin
    pc_out = 32'h00000000;
  end else if(pc_en == 1'b1) begin
    pc_out = result;
  end
end

endmodule
