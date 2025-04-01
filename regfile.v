module regfile( // modulo do arquivo de registradores
    input clk, // clock
    input we, // write enable
    input [4:0] rs1, // endereço do registrador fonte 1
    input [4:0] rs2, // endereço do registrador fonte 2
    input [4:0] rd, // endereço do registrador destino
    input [31:0] wd, // write data
    output reg [31:0] rd1, // saída de dado 1
    output reg [31:0] rd2 // saída de dado 2
);

reg [31:0] registers [31:1]; // 32 registradores

always @(posedge clk) begin
    if(we == 1 && rd != 0) begin
        registers[rd] = wd;
    end
    rd1 = (rs1 == 0) ? 32'b0 : registers[rs1];
    rd2 = (rs2 == 0) ? 32'b0 : registers[rs2];
end

endmodule