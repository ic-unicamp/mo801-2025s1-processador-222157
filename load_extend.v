module load_extend(
  input [1:0] address,
  input [31:0] data_in,
  output reg [31:0] data_out,
  input [2:0] funct
);

reg [31:0] data_shift;

//realinha os bits para começar na posição zero
always @(address, data_in) begin
    case(address)
        2'b00: //dado alinhado com word
            data_shift = data_in;
        2'b01: //dado deslocado 1 byte
            data_shift = data_in >> 8;
        2'b10: //dado deslocado 2 bytes
            data_shift = data_in >> 16;
        2'b11: //dado deslocado 3 bytes
            data_shift = data_in >> 24;
        default:
            data_shift = data_in;
    endcase
end

//seleciona os bits de interesse e extende bits de sinais (ou zeros p/ unsigned)
always @(funct, data_shift) begin
    case(funct)
        3'b000: //LB
            data_out = {{24{data_shift[7]}}, data_shift[7:0]};
        3'b001: //LH
            data_out = {{16{data_shift[15]}}, data_shift[15:0]};
        3'b010: //LW
            data_out = data_shift;
        3'b100: //LBU
            data_out = {24'd0, data_shift[7:0]};
        3'b101: //LHU
            data_out = {16'd0, data_shift[15:0]};
        default:
            data_out = data_shift;
    endcase
end

endmodule