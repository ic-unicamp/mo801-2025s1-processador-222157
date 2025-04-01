module control_unit( // modulo do arquivo de registradores
    input clk, // clock
    input resetn, // reset
    input zero, // zero
    input less, // zero
    input [6:0] opcode, // opcode
    input [2:0] funct3, // funct3
    input [6:0] funct7, // funct7
    output reg [9:0] alu_control, // bits de seleção da alu
    output reg pc_en, // enables de registradores
    output reg mem_en,
    output reg reg_en,
    output reg instr_en,
    output reg mask_en,
    output reg adr_sel, // bits de seleção dos mux
    output reg [2:0] imm_sel,
    output reg [1:0] srcA_sel,
    output reg [1:0] srcB_sel,
    output reg [1:0] result_sel,
    output reg mask_sel
);

reg [3:0] state, next_state;
parameter [3:0]
    FETCH = 4'd0,
    DECODE = 4'd1,
    R_EXECUTE = 4'd2,
    WRITE_BACK = 4'd3,
    I_EXECUTE = 4'd4,
    MEM_EXECUTE = 4'd5,
    MEM_READ = 4'd6,
    LOAD_WRITE_BACK = 4'd7,
    MEM_WRITE = 4'd8,
    COMPARE = 4'd9,
    DECIDE = 4'd10,
    LINK = 4'd11,
    JUMP = 4'd12,
    U_EXECUTE = 4'd13,
    MASK_EXECUTE = 4'd14;
parameter [6:0]
    rtype = 7'b0110011,
    itype = 7'b0010011,
    load = 7'b0000011,
    store = 7'b0100011,
    btype = 7'b1100011,
    jal = 7'b1101111,
    lui = 7'b0110111,
    auipc = 7'b0010111,
    jalr = 7'b1100111,
    ebreak = 7'b1110011;


always @(state, opcode, funct3, funct7, zero, less) begin
    //default values
    pc_en = 1'b0;
    mem_en = 1'b0;
    reg_en = 1'b0;
    instr_en = 1'b0;
    mask_en = 1'b0;
    adr_sel = 1'b0;
    imm_sel = 3'b000;
    srcA_sel = 2'b01;
    srcB_sel = 2'b10;
    result_sel = 2'b10;
    mask_sel = 1'b0;
    alu_control = 10'b0000000000;
    case(state)
        FETCH: begin
            instr_en = 1'b1;
            srcA_sel = 2'b00;
            srcB_sel = 2'b10;
            alu_control = 10'b0000000000;
            result_sel = 2'b00;
            pc_en = 1'b1;
            next_state = DECODE;
        end
        DECODE:
            case(opcode)
                rtype:
                    next_state = R_EXECUTE;
                itype:
                    next_state = I_EXECUTE;
                store, load:
                    next_state = MEM_EXECUTE;
                btype:
                    next_state = COMPARE;
                jal, jalr:
                    next_state = LINK;
                lui, auipc:
                    next_state = U_EXECUTE;
                ebreak:
                    $finish;
                default:
                    next_state = FETCH;
            endcase
        R_EXECUTE: begin
            srcA_sel = 2'b10;
            srcB_sel = 2'b00;
            alu_control = {funct7, funct3};
            next_state = WRITE_BACK;
        end
        WRITE_BACK: begin
            reg_en = 1'b1;
            result_sel = 2'b10;
            next_state = FETCH;
        end
        I_EXECUTE: begin
            srcA_sel = 2'b10;
            srcB_sel = 2'b01;
            alu_control = (funct3 == 3'b101) ? {funct7, funct3} : {7'd0, funct3};
            imm_sel = 3'b000;
            next_state = WRITE_BACK;
        end
        MEM_EXECUTE: begin
            srcA_sel = 2'b10;
            srcB_sel = 2'b01;
            alu_control = 10'b0000000000;
            if(opcode == load) begin
                imm_sel = 3'b000;
                next_state = MEM_READ;
            end else if(funct3 == 3'b010) begin
                imm_sel = 3'b001;
                next_state = MEM_WRITE;
            end else begin
                imm_sel = 3'b001;
                next_state = MASK_EXECUTE;
            end
        end
        MEM_READ: begin
            result_sel = 2'b10;
            adr_sel = 1'b1;
            next_state = LOAD_WRITE_BACK;
        end
        LOAD_WRITE_BACK: begin
            result_sel = 2'b01;
            reg_en = 1'b1;
            next_state = FETCH;
        end
        MEM_WRITE: begin
            result_sel = 2'b10;
            adr_sel = 1'b1;
            mem_en = 1'b1;
            if(funct3 != 3'b010)
                mask_sel = 1'b1;
            next_state = FETCH;
        end
        COMPARE: begin
            srcA_sel = 2'b10;
            srcB_sel = 2'b00;
                case(funct3)
                    3'b000, 3'b001:
                        alu_control = 10'b0100000000;
                    3'b100, 3'b101:
                        alu_control = 10'b0000000010;
                    3'b110, 3'b111:
                        alu_control = 10'b0000000011;
                    default:
                        alu_control = 10'b0000000000;
                endcase
            next_state = DECIDE;
        end
        DECIDE: begin
            srcA_sel = 2'b01;
            srcB_sel = 2'b01;
            imm_sel = 3'b010;
            alu_control = 10'b0000000000;
            result_sel = 2'b00;
            case(funct3)
                3'b000:
                    pc_en = zero;
                3'b001:
                    pc_en = ~zero;
                3'b100, 3'b110:
                    pc_en = less;
                3'b101, 3'b111:
                    pc_en = ~less;
                default:
                    pc_en = 1'b0;
            endcase
            next_state = FETCH;
        end
        LINK: begin
            srcA_sel = 2'b01;
            srcB_sel = 2'b10;
            alu_control = 10'b0000000000;
            result_sel = 2'b00;
            reg_en = 1'b1;
            next_state = JUMP;
        end
        JUMP: begin
            srcA_sel = (opcode == jal) ? 2'b01 : 2'b10;
            srcB_sel = 2'b01;
            imm_sel = (opcode == jal) ? 3'b011: 3'b000;
            alu_control = (opcode == jal) ? 10'b0000000000 : 10'b1000000000;
            result_sel = 2'b00;
            pc_en = 1'b1;
            next_state = FETCH;
        end
        U_EXECUTE: begin
            srcA_sel = (opcode == lui) ? 2'b11 : 2'b01;
            srcB_sel = 2'b01;
            imm_sel = 3'b101;
            alu_control = 10'b0000000000;
            next_state = WRITE_BACK;
        end
        MASK_EXECUTE: begin
            srcA_sel = 2'b10;
            srcB_sel = 2'b01;
            alu_control = 10'b0000000000;
            imm_sel = 3'b001;
            result_sel = 2'b10;
            adr_sel = 1'b1;
            mask_en = 1'b1;
            next_state = MEM_WRITE;
        end
        default:
            next_state = FETCH;
    endcase
end

always @(negedge resetn, posedge clk) begin
    if (resetn == 1'b0) state <= FETCH;
    else state <= next_state;
end

endmodule