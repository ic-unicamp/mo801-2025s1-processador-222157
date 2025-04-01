module alu( // modulo de um alu
    input [31:0] srcA, // source A
    input [31:0] srcB, // source B
    output reg [31:0] result, // resultado da operação
    input [9:0] funct, // função escolhida
    output reg zero // resultado = 0
);

always @(funct, srcA, srcB) begin
    case(funct)
        // ADD
        10'b0000000000:
            result = srcA + srcB;

        // ADD & ~1 // Usado para JALR
        10'b1000000000:
            result = (srcA + srcB) & -32'd2;

        // SUB
        10'b0100000000:
            result = srcA - srcB;

        // SLL
        10'b0000000001:
            result = srcA << srcB[4:0];

        // SLT
        10'b0000000010:
            result = ((srcA[31] == 1 && srcB[31] == 0) || ((srcA[31] == srcB[31]) && (srcA[30:0] < srcB[30:0]))) ? 32'b1 : 32'b0;

        // SLTU
        10'b0000000011:
            result = (srcA < srcB) ? 32'b1 : 32'b0;

        // XOR
        10'b0000000100:
            result = srcA ^ srcB;

        // SRL
        10'b0000000101:
            result = srcA >> srcB[4:0];

        // SRA
        10'b0100000101:
            result = ((srcA ^ {32{srcA[31]}}) >> srcB[4:0]) ^ {32{srcA[31]}};

        // OR
        10'b0000000110:
            result = srcA | srcB;

        // AND
        10'b0000000111:
            result = srcA & srcB;

        // Default
        default: result = 32'b0;
    endcase
    zero = result == 32'b0;
end

endmodule
