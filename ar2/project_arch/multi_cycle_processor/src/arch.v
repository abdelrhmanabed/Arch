//////////Simple RISC Pipeline Processor//////////

// odyshbayeh 1201462
// abdelrahman abed - 1193191
// yousef hatem - 1200252

//---------------------------------------Fetch-Stage----------------------------------------------//
module FetchStage(
  input Clk,
  input Reset,
  input [15:0] Baddi,
  input [15:0] Jaddi,
  input [15:0] Raddi,
  input [1:0] pcsori,
  input stall,
  input kill,
  input [31:0] cycle,
  output reg [15:0] pc,
  output reg [15:0] pcn,
  output [15:0] Instm
);

  // Instantiate instruction memory
  ST_InstMem instMem(
    .address(pc),
    .Inst(Instm),
    .stall(stall)
  );

  always @(posedge Clk or posedge Reset) begin
    if (Reset) begin
      pc <= 16'b0;
      pcn <= 16'b0;
    end else if (!stall) begin
      case (pcsori)
        2'b00: pcn <= pc + 16'd2; // Normal increment
        2'b01: pcn <= Baddi;      // Branch address
        2'b10: pcn <= Jaddi;      // Jump address
        2'b11: pcn <= Raddi;      // Return address
        default: pcn <= pc + 16'd2; // Default to normal increment
      endcase
      pc <= pcn;
      $display("CYCLE: %d, FETCH STAGE: pc=%h, pcn=%h, pcsori=%b", cycle, pc, pcn, pcsori);
    end
  end

endmodule

//---------------------------------------Instruction-Memory----------------------------------------------//
module ST_InstMem(
  input [15:0] address,
  output reg [15:0] Inst,
  input stall
);
  reg [7:0] Mem [0:4095]; // Byte-addressable memory, 4KB

  initial begin
    // Initialize memory with sample instructions in little-endian format
    {Mem[1], Mem[0]} = 16'b0001000000001010; // ADD R0, R0, #10
    {Mem[3], Mem[2]} = 16'b0000000101001100; // ADD R1, R1, R2
    {Mem[5], Mem[4]} = 16'b0000100111001110; // SUB R3, R3, R2
    {Mem[7], Mem[6]} = 16'b0001100101010000; // AND R4, R4, R1
    {Mem[9], Mem[8]} = 16'b0001100000010000; // OR  R5, R0, R1
    {Mem[11], Mem[10]} = 16'b0001000000010010; // XOR R6, R0, R2
  end

  always @(*) begin
    if (!stall) begin
      Inst = {Mem[address + 1], Mem[address]}; // Little-endian format
    end else begin
      Inst = 16'b0000000000000000;
    end
    $display("FETCH STAGE: Address=%h, Instruction=%b", address, Inst);
  end
endmodule

//---------------------------------------Register-File----------------------------------------------//
module ST_REG #(parameter WIDTH = 16) (
  input [WIDTH-1:0] IN,
  input EN,
  input Reset,
  output reg [WIDTH-1:0] OUT,
  input Clk
);
  initial begin
    OUT = 0;
  end
  
  always @(posedge Clk or posedge Reset) begin
    if (Reset) begin
      OUT <= 0;
    end else if (EN) begin
      OUT <= IN;
    end
  end
endmodule

//---------------------------------------PC-module "fetch next instruction"----------------------------------------------//
module ST_PLUS2(
  input [15:0] in,
  output reg [15:0] out,
  input stall
);
  
  always @(*) begin
    if (!stall) begin
      out = in + 2; // Increment by 2 for 16-bit instructions
    end else begin
      out = in;
    end
  end
endmodule

//---------------------------------------ALU-module----------------------------------------------//
module ALU(
  input Clk,
  input [15:0] Imm16i, SA16i, SBo2i, SBo1i, DataWriteMemoryIE,
  input [2:0] opi,
  input [1:0] AlusorBi,
  output reg zero, Cout, Neg, Overflow,
  output reg [15:0] ALUres, DataWriteMemoryOE,
  input [2:0] Rdi,
  output reg [2:0] Rdm,
  output reg memoryreado, memorywriteo, regwriteo, Datao,
  input memoryreadii, memorywriteii, regwriteii, Dataii,
  input [31:0] cycle
);

  reg [15:0] Imm16o, SA16o, SBo2, SBo1;
  reg [2:0] opo;
  reg [1:0] AlusorBo;
  reg [2:0] Rd;
  reg memoryreadi, memorywritei, regwritei, Datai;
  reg [15:0] val2;
  reg aa_completed;

  always @(posedge Clk) begin
    regwritei <= regwriteii;
    Datai <= Dataii;
    memorywritei <= memorywriteii;
    memoryreadi <= memoryreadii;
    DataWriteMemoryOE <= DataWriteMemoryIE;
    Rd <= Rdi;
    Imm16o <= Imm16i;
    SA16o <= SA16i;
    SBo2 <= SBo2i;
    SBo1 <= SBo1i;
    opo <= opi;
    AlusorBo <= AlusorBi;
    Rdm <= Rd;
    memoryreado <= memoryreadi;
    memorywriteo <= memorywritei;
    regwriteo <= regwritei;
    Datao <= Datai; 
  end
  
  always @(posedge Clk) begin  
    #2
    $display("CYCLE: %d, EXECUTION STAGE: OPcode=%b, DATA1=%b, DATA2=%b, RESULT=%b, Zero=%b, Cout=%b, Neg=%b, Overflow=%b, regwritei=%b", cycle, opo, SBo1, val2, ALUres, zero, Cout, Neg, Overflow, regwritei);
  end 
  
  always @(*) begin
    case (AlusorBo)
      2'b00: val2 = Imm16o;
      2'b01: val2 = SA16o;
      2'b10: val2 = SBo2;
      default: val2 = Imm16o;
    endcase
  end

  ST_ALU aa(opo, SBo1, val2, ALUres, zero, Cout, Neg, Overflow, aa_completed);	 
endmodule

//---------------------------------------ALU-operations----------------------------------------------//
module ST_ALU(
  input [2:0] opi,
  input [15:0] SBo1, SBo2,
  output reg [15:0] ALUres,
  output reg zero, Cout, Neg, Overflow,
  output reg aa_completed
);
  
  always @(*) begin
    case (opi)
      3'b000: ALUres = SBo1 & SBo2;  // AND
      3'b001: {Cout, ALUres} = SBo1 + SBo2;  // ADD
      3'b010: {Cout, ALUres} = SBo1 - SBo2;  // SUB
      3'b011: {Cout, ALUres} = SBo1 + SBo2;  // ADDI
      3'b100: ALUres = SBo1 & SBo2;  // ANDI
      3'b101: ALUres = SBo1 << SBo2; // SLL
      3'b110: ALUres = SBo1 >> SBo2; // SRL
      default: ALUres = SBo1;
    endcase

    // Set flags
    zero = (ALUres == 0);
    Neg = ALUres[15];
    Overflow = ((opi == 3'b001 || opi == 3'b010 || opi == 3'b011) && ((SBo1[15] == SBo2[15]) && (ALUres[15] != SBo1[15])));
    aa_completed = 1;
  end
endmodule

//---------------------------------------Data-Memory----------------------------------------------//
module ST_DataMem(
  input [15:0] address,
  input [15:0] DataIn,
  input R, W, Clk,
  output reg [15:0] DataOut,
  input [31:0] cycle
);
  reg [7:0] Mem [0:4095]; // Byte-addressable memory, 4KB
  integer i;
  
  initial begin
    for (i = 0; i < 4096; i = i + 1) begin
      Mem[i] = 8'd20; // Initialize memory with some values
    end
  end
   
  always @(posedge Clk) begin	
    if (W == 1) begin
      {Mem[address + 1], Mem[address]} = DataIn; // Write operation, little-endian
      $display("CYCLE: %d, MEMORY STAGE: Write In Memory Address=%b, DataIn=%b", cycle, address, DataIn);
    end else if (R == 1) begin
      DataOut = {Mem[address + 1], Mem[address]}; // Read operation, little-endian
      $display("CYCLE: %d, MEMORY STAGE: Read From Memory, Address=%b, DataOut=%b", cycle, address, DataOut);
    end else begin 
      DataOut = 16'b0000000000000000;
      $display("CYCLE: %d, MEMORY STAGE: NOT Write or Read From Memory", cycle);
    end	 
  end
endmodule

//---------------------------------------Decode-Stage----------------------------------------------//
module DecodeStage(
  input [15:0] regfilei [7:0],
  input Clk,
  input Ex_RWi,
  input Mem_RWi,
  input WR_RWi,
  input EX_MemRi,
  input zero,
  input Neg,
  input [15:0] Insti,
  input [15:0] PcPlus2i,
  input [15:0] ALUresi,
  input [15:0] Mresi,
  input [15:0] WRresi,
  input [2:0] Rdo1i,
  input [2:0] Rdo2i,
  input [2:0] Rdo3i,
  output reg [15:0] Badd,
  output reg [15:0] Jadd,
  output reg [15:0] Radd,
  output reg [15:0] DataWriteMemory,
  output reg [1:0] pcsor,
  output reg kill,
  input stall,
  output reg [1:0] spsor,
  output reg [15:0] SBi1,
  output reg [15:0] SBi2,
  output reg [15:0] SA16,
  output reg [1:0] Alusoro,
  output reg [2:0] op,
  output reg [2:0] Rd,
  output reg [15:0] Imm16,
  output reg RWo,
  output reg Rsor,
  output reg MemRo,
  output reg MemWo,
  output reg DWDo,
  output reg RWB4,
  input [31:0] cycle
);
  reg [15:0] Insto;
  reg Ex_RWo, Mem_RWo, WR_RWo, EX_MemRo;
  reg [15:0] PcPlus2, ALUres, Mres, WRres; 
  reg [2:0] Rdo1, Rdo2, Rdo3;
  wire Cout, Overflow, pop, Kill;
  wire [15:0] next_pc;

  always @(posedge Clk) begin
    Insto <= Insti;
    Ex_RWo <= Ex_RWi;
    Mem_RWo <= Mem_RWi;
    WR_RWo <= WR_RWi;
    EX_MemRo <= EX_MemRi;
    PcPlus2 <= PcPlus2i;
    ALUres <= ALUresi;
    WRres <= WRresi;
    Rdo1 <= Rdo1i;
    Rdo2 <= Rdo2i;
    Rdo3 <= Rdo3i;     
  end

  wire [3:0] func;
  wire [2:0] Rs1, Rs2;
  wire [4:0] Imm;
  wire [11:0] JImm;
  wire stop, EXT1, push;
  wire [1:0] Alusor;
  wire RW, MemR, DWD, MemW;
  assign func = Insto[15:12];
  assign Rs1 = Insto[11:9];
  assign Rd = Insto[8:6];
  assign Rs2 = Insto[5:3];
  assign Imm = Insto[4:0];
  assign JImm = Insto[11:0];
  assign stop = Insto[0];

  ST_MainControl MC(func, RW, Rsor, Alusor, MemR, MemW, DWD, EXT1);
  ST_AluControl AC(func, op);
  ST_SPControl SC(func, stop, spsor, push, pop);
  ST_PCControl PRC(func, Rd, zero, Cout, Overflow, Neg, PcPlus2, Imm, pcsor, Kill, next_pc);

  integer i;
  always @(posedge Clk) begin  
    #6  
    $display("CYCLE: %d, DECODE STAGE: Insto=%b, func=%b, Rs1=%b, Rd=%b, Rs2=%b, Imm=%b, JImm=%b, stop=%b", cycle, Insto, func, Rs1, Rd, Rs2, Imm, JImm, stop);
  end

  wire [15:0] regfileo [7:0];
  wire [2:0] S2;    
  ST_Mux2x1x3bit m3(Rs2, Rd, Rsor, S2); 
  reg [15:0] So1, So2;

  always @(negedge Clk) begin
    #3
    So2 = regfilei[S2];
    So1 = regfilei[Rs1];    
    DataWriteMemory <= regfilei[Rd];
  end

  wire [15:0] JImm16;
  ST_EX1 E1(Imm16, Imm, EXT1);
  ST_EX2 E2(SA16, Rs2);
  ST_EX3 E3(JImm16, JImm);

  ST_ADDER AD1(Imm16, PcPlus2i, Badd);
  ST_ADDER AD2(JImm16, PcPlus2i, Jadd);

  wire [15:0] spin, spout, spp1, spm1; 
  wire [1:0] Forward1, Forward2;
  ST_Stack ST(spout, PcPlus2i, push, pop, Clk, Radd);
  ST_Forwarding FR(func, Rs1, S2, Rdo1i, Rdo2i, Rdo3i, Ex_RWi, Mem_RWi, WR_RWi, Forward1, Forward2, cycle);
  ST_DATAHAZERD DH(EX_MemRi, MemWo, Rs1, Rs2, Rd, Forward1, Forward2, stall, cycle);

  ST_Mux4x1 #(16) m5(So1, ALUresi, Mresi, WRresi, Forward1, SBi1);
  ST_Mux4x1 #(16) m6(So2, ALUresi, Mresi, WRresi, Forward2, SBi2);  
  ST_Mux2x1Stall m7(RW, Alusor, MemR, MemW, DWD, stall, RWo, Alusoro, MemRo, MemWo, DWDo);  
endmodule

//---------------------------------------Main-Control-Stage----------------------------------------------//
module ST_MainControl(
  input [3:0] func,
  output reg RW,
  output reg Rsor,
  output reg [1:0] Alusor,
  output reg MemR,
  output reg MemW,
  output reg DWD,
  output reg EXT1
);
  always @(*) begin
    RW = 1'b0;
    Rsor = 1'b0;
    Alusor = 2'b00;
    MemR = 1'b0;
    MemW = 1'b0;
    DWD = 1'b0;
    EXT1 = 1'b0;
    case (func)
      4'b0000: begin // AND
        RW = 1'b1;
        Rsor = 1'b0;
        Alusor = 2'b10;
      end
      4'b0001: begin // ADD
        RW = 1'b1;
        Rsor = 1'b0;
        Alusor = 2'b10;
      end
      4'b0010: begin // SUB
        RW = 1'b1;
        Rsor = 1'b0;
        Alusor = 2'b10;
      end
      4'b0011: begin // ADDI
        RW = 1'b1;
        Rsor = 1'bx;
        Alusor = 2'b00;
        EXT1 = 1'b0;
      end
      4'b0100: begin // ANDI
        RW = 1'b1;
        Rsor = 1'bx;
        Alusor = 2'b00;
        EXT1 = 1'b1;
      end
      4'b0101: begin // LW
        RW = 1'b1;
        Rsor = 1'bx;
        Alusor = 2'b00;
        MemR = 1'b1;
        DWD = 1'b1;
        EXT1 = 1'b1;
      end
      4'b0110: begin // LBu
        RW = 1'b1;
        Rsor = 1'bx;
        Alusor = 2'b00;
        MemR = 1'b1;
        DWD = 1'b1;
        EXT1 = 1'b1;
      end
      4'b0111: begin // SW
        RW = 1'b0;
        Rsor = 1'b1;
        Alusor = 2'b00;
        MemW = 1'b1;
        EXT1 = 1'b1;
      end
      4'b1000: begin // BGT
        RW = 1'b0;
        Rsor = 1'b1;
        Alusor = 2'b10;
        EXT1 = 1'b1;
      end
      4'b1001: begin // BLT
        RW = 1'b0;
        Rsor = 1'b1;
        Alusor = 2'b10;
        EXT1 = 1'b1;
      end
      4'b1010: begin // BEQ
        RW = 1'b0;
        Rsor = 1'b1;
        Alusor = 2'b10;
        EXT1 = 1'b1;
      end
      4'b1011: begin // BNE
        RW = 1'b0;
        Rsor = 1'b1;
        Alusor = 2'b10;
        EXT1 = 1'b1;
      end
      4'b1100: begin // JMP
        RW = 1'b0;
        Rsor = 1'bx;
      end
      4'b1101: begin // CALL
        RW = 1'b0;
        Rsor = 1'bx;
      end
      4'b1110: begin // RET
        RW = 1'b0;
        Rsor = 1'bx;
      end
      default: begin
        RW = 1'b0;
        Rsor = 1'b0;
        Alusor = 2'b00;
      end
    endcase
  end
endmodule

//---------------------------------------ALU-control-module----------------------------------------------//
module ST_AluControl(input [3:0] func, output reg [2:0] op);
  always @(*) begin
    case (func)
      4'b0000: op = 3'b000; // AND
      4'b0001: op = 3'b001; // ADD
      4'b0010: op = 3'b010; // SUB
      4'b0011: op = 3'b011; // ADDI
      4'b0100: op = 3'b100; // ANDI
      4'b0101: op = 3'b101; // LW
      4'b0110: op = 3'b110; // LBu
      4'b0111: op = 3'b110; // SW
      4'b1000: op = 3'b111; // BGT
      4'b1001: op = 3'b111; // BLT
      4'b1010: op = 3'b111; // BEQ
      4'b1011: op = 3'b111; // BNE
      default: op = 3'b000; // Default
    endcase
  end
endmodule

//---------------------------------------Sign-extension-module----------------------------------------------//
module ST_EX1(output reg [15:0] out, input [4:0] in, input ExtendSign);
  always @(*) begin
    if (ExtendSign == 0) begin
      out <= {11'b00000000000, in};
    end else begin
      if (in[4] == 1) begin
        out <= {11'b11111111111, in};
      end else begin
        out <= {11'b00000000000, in};
      end
    end
  end
endmodule

module ST_EX2(output reg [15:0] out, input [2:0] in);
  always @(*) begin
    out <= {13'b0000000000000, in};
  end
endmodule

module ST_EX3(output reg [15:0] out, input [11:0] in);
  always @(*) begin
    if (in[11] == 1) begin
      out <= {4'b1111, in};
    end else begin
      out <= {4'b0000, in};
    end
  end
endmodule

//---------------------------------------MUXes-Module----------------------------------------------//
module ST_Mux2x1x3bit(input [2:0] in1, in2, input sel, output reg [2:0] out);
  always @(*) begin
    case (sel)
      1'b0: out <= in1;
      1'b1: out <= in2;
      default: out <= in1;
    endcase
  end
endmodule

module ST_Mux4x1 #(parameter WIDTH = 16) (input [WIDTH-1:0] in1, in2, in3, in4, input [1:0] sel, output reg [WIDTH-1:0] out);
  always @(*) begin
    case (sel)
      2'b00: out = in1;
      2'b01: out = in2;
      2'b10: out = in3;
      2'b11: out = in4;
      default: out = in1;
    endcase
  end
endmodule

module ST_Mux2x1 #(parameter WIDTH = 16) (input [WIDTH-1:0] in1, in2, input sel, output reg [WIDTH-1:0] out);
  always @(*) begin
    case (sel)
      1'b0: out <= in1;
      1'b1: out <= in2;
      default: out <= in1;
    endcase
  end
endmodule

//---------------------------------------Stack-module----------------------------------------------//
module ST_Stack(
  input [15:0] address,
  input [15:0] DataIn,
  input push,
  input pop,
  input Clk,
  output reg [15:0] DataOut
);
  reg [15:0] Mem [255:0];
  reg [15:0] stack_address;

  initial begin
    stack_address = 0; // Initialize stack_address to zero
  end

  always @(posedge Clk) begin 
    if (push) begin
      Mem[stack_address] = DataIn;
      stack_address = stack_address + 2; // Increment stack_address by 2 on push 
    end else if (pop) begin
      stack_address = stack_address - 2; // Decrement stack_address by 2 on pop
    end
    DataOut = Mem[stack_address];
  end
endmodule

//---------------------------------------SP-Control-Module----------------------------------------------//
module ST_SPControl(
  input [3:0] func,
  input stop,
  output reg [1:0] spsor,
  output reg push,
  output reg pop
);
  always @(*) begin
    spsor = 2'b00;
    push = 0;
    pop = 0;
    case (func)
      4'b1101: begin // CALL
        spsor = 2'b10;
        push = 1;
      end
      4'b1110: begin // RET
        spsor = 2'b11;
        pop = 1;
      end
    endcase
  end
endmodule

//---------------------------------------PC-Control-Module----------------------------------------------//
module ST_PCControl(
  input [3:0] func,
  input [2:0] Rd,
  input zero, Neg, Cout, Overflow,
  input [15:0] pc, 
  input [4:0] offset,
  output reg [1:0] pcsor,
  output reg Kill,
  output reg [15:0] next_pc
);
  
  always @(*) begin
    Kill = 0;
    next_pc = pc + 2; // Default next PC value (increment by 2)
    case (func)
      4'b1000: begin // BGT
        if (!Neg && !zero) begin
          next_pc = pc + (offset << 1);
          pcsor = 2'b01;
          Kill = 1;
        end else begin
          pcsor = 2'b00;
        end
      end
      4'b1001: begin // BLT
        if (Neg) begin
          next_pc = pc + (offset << 1);
          pcsor = 2'b01;
          Kill = 1;
        end else begin
          pcsor = 2'b00;
        end
      end
      4'b1010: begin // BEQ
        if (zero) begin
          next_pc = pc + (offset << 1);
          pcsor = 2'b01;
          Kill = 1;
        end else begin
          pcsor = 2'b00;
        end
      end
      4'b1011: begin // BNE
        if (!zero) begin
          next_pc = pc + (offset << 1);
          pcsor = 2'b01;
          Kill = 1;
        end else begin
          pcsor = 2'b00;
        end
      end
      4'b1100: begin // JMP
        next_pc = {pc[15:10], offset} << 1;
        pcsor = 2'b10;
        Kill = 1;
      end
      4'b1101: begin // CALL
        next_pc = {pc[15:10], offset} << 1;
        pcsor = 2'b10;
        Kill = 1;
      end
      4'b1110: begin // RET
        next_pc = offset; // Assuming the return address is provided in offset
        pcsor = 2'b11;
        Kill = 1;
      end
      default: begin
        pcsor = 2'b00;
      end
    endcase
  end
endmodule

//---------------------------------------Hazard-Module----------------------------------------------//
module ST_DATAHAZERD(
  input EX_MemR, MemWrite,
  input [2:0] Rs1, Rs2, Rd,
  input [1:0] For1, For2,
  output reg Stall,
  input [31:0] cycle
);
  always @(*) begin
    // Data hazard
    if (EX_MemR == 1 && ((For1 == 1 && Rd == Rs1) || (For2 == 1 && Rd == Rs2))) begin
      Stall = 1;
      $display("CYCLE: %d, DATA HAZARD DETECTED - Stall!", cycle);
    end
    // Structural hazard (if MemWrite to the same address)
    else if (MemWrite == 1 && (Rd == Rs1 || Rd == Rs2)) begin
      Stall = 1;
      $display("CYCLE: %d, STRUCTURAL HAZARD DETECTED - Stall!", cycle);
    end else begin
      Stall = 0;
      $display("CYCLE: %d, NO HAZARD - No Stall", cycle);
    end
  end
endmodule

//---------------------------------------Pipeline Registers----------------------------------------------//
module FetchToDecodeReg(
  input Clk, Reset, stall,
  input [15:0] pc_in, Inst_in,
  output reg [15:0] pc_out, Inst_out
);
  always @(posedge Clk or posedge Reset) begin
    if (Reset) begin
      pc_out <= 0;
      Inst_out <= 0;
    end else if (!stall) begin
      pc_out <= pc_in;
      Inst_out <= Inst_in;
      $display("FETCH TO DECODE: Time=%0t, pc_in=%h, Inst_in=%h, pc_out=%h, Inst_out=%h", $time, pc_in, Inst_in, pc_out, Inst_out);
    end
  end
endmodule

module DecodeToExecuteReg(
  input Clk, Reset, stall,
  input [15:0] pc_in, Data1_in, Data2_in, Imm_in,
  input [2:0] Rd_in,
  input [2:0] func_in,
  output reg [15:0] pc_out, Data1_out, Data2_out, Imm_out,
  output reg [2:0] Rd_out,
  output reg [2:0] func_out
);
  always @(posedge Clk or posedge Reset) begin
    if (Reset) begin
      pc_out <= 0;
      Data1_out <= 0;
      Data2_out <= 0;
      Imm_out <= 0;
      Rd_out <= 0;
      func_out <= 0;
    end else if (!stall) begin
      pc_out <= pc_in;
      Data1_out <= Data1_in;
      Data2_out <= Data2_in;
      Imm_out <= Imm_in;
      Rd_out <= Rd_in;
      func_out <= func_in;
      $display("DECODE TO EXECUTE: Time=%0t, pc_in=%h, Data1_in=%h, Data2_in=%h, Imm_in=%h, Rd_in=%h, func_in=%h, pc_out=%h, Data1_out=%h, Data2_out=%h, Imm_out=%h, Rd_out=%h, func_out=%h", $time, pc_in, Data1_in, Data2_in, Imm_in, Rd_in, func_in, pc_out, Data1_out, Data2_out, Imm_out, Rd_out, func_out);
    end
  end
endmodule

module ExecuteToMemoryReg(
  input Clk, Reset, stall,
  input [15:0] pc_in, Alu_in, Data2_in, Imm_in,
  input [2:0] Rd_in,
  input [2:0] func_in,
  output reg [15:0] pc_out, Alu_out, Data2_out, Imm_out,
  output reg [2:0] Rd_out,
  output reg [2:0] func_out
);
  always @(posedge Clk or posedge Reset) begin
    if (Reset) begin
      pc_out <= 0;
      Alu_out <= 0;
      Data2_out <= 0;
      Imm_out <= 0;
      Rd_out <= 0;
      func_out <= 0;
    end else if (!stall) begin
      pc_out <= pc_in;
      Alu_out <= Alu_in;
      Data2_out <= Data2_in;
      Imm_out <= Imm_in;
      Rd_out <= Rd_in;
      func_out <= func_in;
      $display("EXECUTE TO MEMORY: Time=%0t, pc_in=%h, Alu_in=%h, Data2_in=%h, Imm_in=%h, Rd_in=%h, func_in=%h, pc_out=%h, Alu_out=%h, Data2_out=%h, Imm_out=%h, Rd_out=%h, func_out=%h", $time, pc_in, Alu_in, Data2_in, Imm_in, Rd_in, func_in, pc_out, Alu_out, Data2_out, Imm_out, Rd_out, func_out);
    end
  end
endmodule

module MemoryToWriteBackReg(
  input Clk, Reset, stall,
  input [15:0] pc_in, MemData_in, Alu_in, 
  input [2:0] Rd_in,
  input [2:0] func_in,
  output reg [15:0] pc_out, MemData_out, Alu_out,
  output reg [2:0] Rd_out,
  output reg [2:0] func_out
);
  always @(posedge Clk or posedge Reset) begin
    if (Reset) begin
      pc_out <= 0;
      MemData_out <= 0;
      Alu_out <= 0;
      Rd_out <= 0;
      func_out <= 0;
    end else if (!stall) begin
      pc_out <= pc_in;
      MemData_out <= MemData_in;
      Alu_out <= Alu_in;
      Rd_out <= Rd_in;
      func_out <= func_in;
      $display("MEMORY TO WRITEBACK: Time=%0t, pc_in=%h, MemData_in=%h, Alu_in=%h, Rd_in=%h, func_in=%h, pc_out=%h, MemData_out=%h, Alu_out=%h, Rd_out=%h, func_out=%h", $time, pc_in, MemData_in, Alu_in, Rd_in, func_in, pc_out, MemData_out, Alu_out, Rd_out, func_out);
    end
  end
endmodule

//--------------------------------------WriteBackStage---------------------------------------------//
module WriteBackStage(
  input [15:0] regfilei [7:0],
  input Clk, DWDB3i, regWB3i,
  input [15:0] ResBo, DaOuM, 
  input [2:0] RDi,
  output reg [15:0] Mres,
  output reg [2:0] RDo,
  output reg regWB3o,
  output [15:0] regfileo [7:0],
  input [31:0] cycle
);

  wire [15:0] s1, s2;
  ST_Mux2x1 #(16) m9(ResBo, DaOuM, DWDB3i, Mres);
  ST_regFile mq(
    .regfilei(regfilei),
    .Clk(Clk),
    .WE(regWB3i),
    .A1(RDi),
    .A2(3'b000),
    .WD(Mres),
    .WE3(regWB3i),
    .RD1(s1),
    .RD2(s2),
    .regfileo(regfileo)
  );

  always @(posedge Clk) begin
    RDo = RDi;
    regWB3o = regWB3i;
    $display("CYCLE: %d, WRITEBACK STAGE: Register=%d, Data=%h, Write Enable=%b", cycle, RDo, Mres, regWB3i);
    $display("Register file state: R0=%h, R1=%h, R2=%h, R3=%h, R4=%h, R5=%h, R6=%h, R7=%h", 
              regfileo[0], regfileo[1], regfileo[2], regfileo[3], regfileo[4], regfileo[5], regfileo[6], regfileo[7]);
  end
endmodule

//---------------------------------------Adder-Module----------------------------------------------//
module ST_ADDER(
  input [15:0] a,
  input [15:0] b,
  output reg [15:0] sum
);
  always @(*) begin											 
    sum = a + b;
    $display("ADDER: A=%h, B=%h, Sum=%h", a, b, sum);
  end
endmodule

//---------------------------------------regFile-Module----------------------------------------------//
module ST_regFile(
  input [15:0] regfilei [7:0],
  input Clk,
  input WE,
  input [2:0] A1,
  input [2:0] A2,
  input [15:0] WD,
  input WE3,
  output reg [15:0] RD1,
  output reg [15:0] RD2,
  output reg [15:0] regfileo [7:0]
);
  reg [15:0] Regs [7:0];

  always @(posedge Clk) begin
    if (WE3) begin
      Regs[A1] <= WD;
      $display("REGFILE WRITE: Time=%0t, Writing %h to Register %d", $time, WD, A1);
    end
    RD1 <= Regs[A1];
    RD2 <= Regs[A2];
    $display("REGFILE READ: Time=%0t, Read Data1=%h from Register %d, Read Data2=%h from Register %d", $time, RD1, A1, RD2, A2);
  end

  always @(*) begin
    integer i;
    for (i = 0; i < 8; i = i + 1) begin
      regfileo[i] = Regs[i];
    end
  end
endmodule

//-------------------------------forwarding-module-------------------------//
module ST_Forwarding(
  input [3:0] func,
  input [2:0] Rs1,
  input [2:0] Rs2,
  input [2:0] Ex_Rd,
  input [2:0] Mem_Rd,
  input [2:0] WB_Rd,
  input Ex_WB,
  input Mem_WB,
  input WB_WB,
  output reg [1:0] ForwardA,
  output reg [1:0] ForwardB,
  input [31:0] cycle
);
  always @(*) begin
    // ForwardA logic
    if (Ex_WB && (Ex_Rd != 0) && (Ex_Rd == Rs1)) begin
      ForwardA = 2'b10;
    end else if (Mem_WB && (Mem_Rd != 0) && (Mem_Rd == Rs1)) begin
      ForwardA = 2'b01;
    end else begin
      ForwardA = 2'b00;
    end

    // ForwardB logic
    if (Ex_WB && (Ex_Rd != 0) && (Ex_Rd == Rs2)) begin
      ForwardB = 2'b10;
    end else if (Mem_WB && (Mem_Rd != 0) && (Mem_Rd == Rs2)) begin
      ForwardB = 2'b01;
    end else begin
      ForwardB = 2'b00;
    end

    $display("CYCLE: %d, FORWARDING: ForwardA=%b, ForwardB=%b", cycle, ForwardA, ForwardB);
  end
endmodule

//---------------------------------------Mux2x1Stall-Module----------------------------------------------//
module ST_Mux2x1Stall(
  input RW,
  input [1:0] Alusor,
  input MemR,
  input MemW,
  input DWD,
  input stall,
  output reg RWo,
  output reg [1:0] Alusoro,
  output reg MemRo,
  output reg MemWo,
  output reg DWDo
);
  always @(*) begin
    if (stall) begin
      RWo = 0;
      Alusoro = 2'b00;
      MemRo = 0;
      MemWo = 0;
      DWDo = 0;
    end else begin
      RWo = RW;
      Alusoro = Alusor;
      MemRo = MemR;
      MemWo = MemW;
      DWDo = DWD;
    end
    $display("MUX 2x1 STALL: RW=%b, Alusor=%b, MemR=%b, MemW=%b, DWD=%b, Stall=%b, RWo=%b, Alusoro=%b, MemRo=%b, MemWo=%b, DWDo=%b", RW, Alusor, MemR, MemW, DWD, stall, RWo, Alusoro, MemRo, MemWo, DWDo);
  end
endmodule

//---------------------------------------Test Bench----------------------------------------------//
module testbench();
  reg Clk, Reset;
  wire [15:0] pc, pcn, Instm;
  reg stall, kill;
  reg [1:0] pcsori;
  reg [15:0] Baddi, Jaddi, Raddi;
  reg [31:0] cycle;

  // Simplified regfile for initial debugging
  reg [15:0] regfilei [7:0];

  FetchStage fetchStage(
    .Clk(Clk),
    .Reset(Reset),
    .pc(pc),
    .pcn(pcn),
    .Baddi(Baddi),
    .Jaddi(Jaddi),
    .Raddi(Raddi),
    .stall(stall),
    .kill(kill),
    .Instm(Instm),
    .pcsori(pcsori),
    .cycle(cycle)
  );

  // Temporary signals for other stages
  wire [15:0] decode_pc, decode_inst;
  wire decode_stall;

  FetchToDecodeReg fetchToDecodeReg(
    .Clk(Clk),
    .Reset(Reset),
    .stall(stall),
    .pc_in(pc),
    .Inst_in(Instm),
    .pc_out(decode_pc),
    .Inst_out(decode_inst)
  );

  DecodeStage decodeStage(
    .regfilei(regfilei),
    .Clk(Clk),
    .Ex_RWi(1'b0),
    .Mem_RWi(1'b0),
    .WR_RWi(1'b0),
    .EX_MemRi(1'b0),
    .zero(1'b0),
    .Neg(1'b0),
    .Insti(decode_inst),
    .PcPlus2i(16'b0),
    .ALUresi(16'b0),
    .Mresi(16'b0),
    .WRresi(16'b0),
    .Rdo1i(3'b0),
    .Rdo2i(3'b0),
    .Rdo3i(3'b0),
    .Badd(),
    .Jadd(),
    .Radd(),
    .DataWriteMemory(),
    .pcsor(),
    .kill(),
    .stall(decode_stall),
    .spsor(),
    .SBi1(),
    .SBi2(),
    .SA16(),
    .Alusoro(),
    .op(),
    .Rd(),
    .Imm16(),
    .RWo(),
    .Rsor(),
    .MemRo(),
    .MemWo(),
    .DWDo(),
    .RWB4(),
    .cycle(cycle)
  );

  wire [15:0] execute_pc, execute_data1, execute_data2, execute_imm, execute_alu_out;
  wire [2:0] execute_rd, execute_func;
  wire execute_stall;

  DecodeToExecuteReg decodeToExecuteReg(
    .Clk(Clk),
    .Reset(Reset),
    .stall(stall),
    .pc_in(decode_pc),
    .Data1_in(decodeStage.SBi1),
    .Data2_in(decodeStage.SBi2),
    .Imm_in(decodeStage.Imm16),
    .Rd_in(decodeStage.Rd),
    .func_in(decodeStage.op),
    .pc_out(execute_pc),
    .Data1_out(execute_data1),
    .Data2_out(execute_data2),
    .Imm_out(execute_imm),
    .Rd_out(execute_rd),
    .func_out(execute_func)
  );

  ALU executeStage(
    .Clk(Clk),
    .Imm16i(execute_imm),
    .SA16i(16'b0),
    .SBo2i(execute_data2),
    .SBo1i(execute_data1),
    .DataWriteMemoryIE(decodeStage.DataWriteMemory),
    .opi(execute_func),
    .AlusorBi(decodeStage.Alusoro),
    .zero(),
    .Cout(),
    .Neg(),
    .Overflow(),
    .ALUres(execute_alu_out),
    .DataWriteMemoryOE(),
    .Rdi(execute_rd),
    .Rdm(),
    .memoryreado(),
    .memorywriteo(),
    .regwriteo(),
    .Datao(),
    .memoryreadii(1'b0),
    .memorywriteii(1'b0),
    .regwriteii(decodeStage.RWo),
    .Dataii(1'b0),
    .cycle(cycle)
  );

  wire [15:0] memory_pc, memory_alu_out, memory_data2, memory_imm, memory_data_out;
  wire [2:0] memory_rd, memory_func;
  wire memory_stall;

  ExecuteToMemoryReg executeToMemoryReg(
    .Clk(Clk),
    .Reset(Reset),
    .stall(stall),
    .pc_in(execute_pc),
    .Alu_in(execute_alu_out),
    .Data2_in(execute_data2),
    .Imm_in(execute_imm),
    .Rd_in(execute_rd),
    .func_in(execute_func),
    .pc_out(memory_pc),
    .Alu_out(memory_alu_out),
    .Data2_out(memory_data2),
    .Imm_out(memory_imm),
    .Rd_out(memory_rd),
    .func_out(memory_func)
  );

  ST_DataMem memoryStage(
    .address(memory_alu_out),
    .DataIn(memory_data2),
    .R(memory_func == 3'b101),
    .W(memory_func == 3'b110),
    .Clk(Clk),
    .DataOut(memory_data_out),
    .cycle(cycle)
  );

  reg [15:0] writeback_pc, writeback_mem_data, writeback_alu_out;
  reg [2:0] writeback_rd, writeback_func;
  wire writeback_stall;

  MemoryToWriteBackReg memoryToWriteBackReg(
    .Clk(Clk),
    .Reset(Reset),
    .stall(stall),
    .pc_in(memory_pc),
    .MemData_in(memory_data_out),
    .Alu_in(memory_alu_out),
    .Rd_in(memory_rd),
    .func_in(memory_func),
    .pc_out(writeback_pc),      // 16 bits
    .MemData_out(writeback_mem_data), // 16 bits
    .Alu_out(writeback_alu_out), // 16 bits
    .Rd_out(writeback_rd),      // 3 bits
    .func_out(writeback_func)   // 3 bits
  );

  WriteBackStage writebackStage(
    .regfilei(regfilei),
    .Clk(Clk),
    .DWDB3i(writeback_func == 3'b101),
    .regWB3i(decodeStage.RWB4),
    .ResBo(writeback_alu_out), // 16 bits
    .DaOuM(writeback_mem_data), // 16 bits
    .RDi(writeback_rd),         // 3 bits
    .Mres(),
    .RDo(),
    .regWB3o(),
    .regfileo(),
    .cycle(cycle)
  );

  task print_registers;
    integer i;
    begin
      $display("Register file contents at cycle %d:", cycle);
      for (i = 0; i < 8; i = i + 1) begin
        $display("R%d: %h", i, regfilei[i]);
      end
    end
  endtask

  initial begin
    // Initialize test
    Clk = 0;
    Reset = 1;
    Baddi = 0;
    Jaddi = 0;
    Raddi = 0;
    pcsori = 2'b00;
    cycle = 0;
    stall = 0;
    kill = 0;

    // Initialize regfile with some values
    regfilei[0] = 16'h0001;
    regfilei[1] = 16'h0002;
    regfilei[2] = 16'h0003;
    regfilei[3] = 16'h0004;
    regfilei[4] = 16'h0005;
    regfilei[5] = 16'h0006;
    regfilei[6] = 16'h0007;
    regfilei[7] = 16'h0008;

    #10;
    Reset = 0;

    // Sample instructions to test forwarding and hazards
    // These tests will reflect the sample instructions from ST_InstMem
    // ADD R0, R1, R2 -> Forward result of ADD to next instruction
    // ADD R3, R0, R2 -> Forward result of first ADD to this instruction
    // SUB R4, R3, R1 -> Forward result of second ADD to this instruction
    #10 pcsori = 2'b00; // Normal increment to fetch first instruction
    #20 pcsori = 2'b00; // Continue to next instruction
    #20 pcsori = 2'b00; // Continue to next instruction
    #20 pcsori = 2'b00; // Continue to next instruction

    // Print registers at key points
    //print_registers;

    // End simulation after a few cycles
    #100;
    //print_registers; // Print registers at the end of simulation
    $finish;
  end

  // Clock generation
  always #5 Clk = ~Clk;

  // Cycle counter
  always @(posedge Clk) begin
    cycle <= cycle + 1;
  end

  // Additional print statements for debugging
  always @(posedge Clk) begin
    $display("Cycle: %d, PC: %h, Instruction: %h", cycle, pc, Instm);
  end

endmodule
