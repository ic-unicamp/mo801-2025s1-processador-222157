module store_mask(
  input [1:0] address,
  input [31:0] data_in,
  input [31:0] data_current,
  output [31:0] data_out,
  input [1:0] funct
);

reg [31:0] data_masked;
reg [31:0] data_shifted;
reg [31:0] data_current_masked;

//seleciona bits da entrada
always @(funct, data_in) begin
    case(funct)
        2'b00: //SB
            data_masked = data_in & 32'hFF;
        2'b01: //SH
            data_masked = data_in & 32'hFFFF;
        2'b10: //SW
            data_masked = data_in;
        default:
            data_masked = data_in;
    endcase
end

//desloca bits da entrada para a posição correta
always @(address, data_masked) begin
    case(address)
        2'b00: //dado alinhado com word
            data_shifted = data_masked;
        2'b01 : //dado deslocado 1 byte
            data_shifted = data_masked << 8;
        2'b10: //dado deslocado 2 bytes
            data_shifted = data_masked << 16;
        2'b11: //dado deslocado 3 bytes
            data_shifted = data_masked << 24;
        default:
            data_shifted = data_masked;
    endcase
end

//seleciona bits que não serão alterados do dado atual
always @(funct, address, data_current) begin
    case(funct)
        2'b00: //SB
            case(address)
                2'b00: //dado alinhado com word
                    data_current_masked = data_current & 32'hFFFFFF00;
                2'b01: //dado deslocado 1 byte
                    data_current_masked = data_current & 32'hFFFF00FF;
                2'b10: //dado deslocado 2 bytes
                    data_current_masked = data_current & 32'hFF00FFFF;
                2'b11: //dado deslocado 3 bytes
                    data_current_masked = data_current & 32'h00FFFFFF;
                default:
                    data_current_masked = 32'h0;
            endcase
        2'b01: //SH
            case(address)
                2'b00: //dado alinhado com word
                    data_current_masked = data_current & 32'hFFFF0000;
                2'b10: //dado deslocado 2 bytes
                    data_current_masked = data_current & 32'h0000FFFF;
                default:
                    data_current_masked = 32'h0;
            endcase
        2'b10: //SW
            data_current_masked = 32'h0;
        2'b11:
            data_current_masked = 32'h0;
        default:
            data_current_masked = 32'h0;
    endcase
end

//combina a entrada e o dado atual
assign data_out = data_current_masked | data_shifted;

endmodule