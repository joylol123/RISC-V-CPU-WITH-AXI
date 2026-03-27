`include "./ID_RegFile.sv"
`include "./ID_FP_RegFile.sv"
`include "./ID_ImmGe.sv"
`include "./ControlUnit.sv"
module ID_Stage (
    input clk,rst,
    input wire[`DATA_WIDTH -1:0] in_pc,

    input wire [`DATA_WIDTH - 1:0] instr,

    input wire [4:0]               reg_rd_addr,
    input wire [`DATA_WIDTH - 1:0] reg_rd_data,

    input wire                     reg_write,// from forwarding unit??
    input wire                     reg_FP_write,

    output wire [`DATA_WIDTH -1:0] rs1_data,
    output wire [`DATA_WIDTH -1:0] rs2_data,

    output wire [`DATA_WIDTH -1:0] rs1_FP_data,
    output wire [`DATA_WIDTH -1:0] rs2_FP_data,

    output wire [`FUNCTION_3 -1:0] funct3,
    output wire [`FUNCTION_7 -1:0] funct7,
    output wire [4:0]              rs1_addr,
    output wire [4:0]              rs2_addr,
    output wire [4:0]              rd_addr,
    output wire [`DATA_WIDTH -1:0] imm_o,

    //======================= Control Signal ==============//
    output  wire [2:0]  ALU_Ctrl_op,
    output  wire        ALU_rs2_sel,
    output  wire        EXE_pc_sel,

    output  wire [1:0]  branch_signal,
    output  wire [1:0]  MEM_rd_sel,
    output  wire        MEM_Din_sel,
    output  wire        MEM_DM_read,
    output  wire        MEM_DM_write,
    output  wire        reg_file_write,
    output  wire        reg_file_FP_write,

    output  wire        WB_data_sel,    
    output  wire [`OP_CODE -1:0] opcode,
    output wire [`DATA_WIDTH -1:0] out_pc


);
    


// ========== Split the instr =============//

// wire [`OP_CODE -1:0] opcode;
wire [4:0]           regf_rs1_addr;
wire [4:0]           regf_rs2_addr;
wire [2:0]           ImmGe;

// ========== Data Path ===================//

assign opcode           =   instr[6:0];

assign regf_rs1_addr    =   instr[19:15]; // to register file
assign regf_rs2_addr    =   instr[24:20];

assign out_pc            =   in_pc;
assign funct3           =   instr[14:12];
assign funct7           =   instr[31:25];
assign rs1_addr         =   instr[19:15];
assign rs2_addr         =   instr[24:20];
assign rd_addr          =   instr[11:7];

// ========= Control Unit ==============//

ControlUnit ControlUnit_inst(
    .opcode(opcode),
    .Imm_type(ImmGe),
    .ALU_Ctrl_op(ALU_Ctrl_op),
    .ALU_rs2_sel(ALU_rs2_sel),
    .EXE_pc_sel(EXE_pc_sel),
    .branch_signal(branch_signal),
    .MEM_rd_sel(MEM_rd_sel),
    .Din_sel(MEM_Din_sel), // before Din_sel 
    .DM_read(MEM_DM_read), // before DM_read
    .DM_write(MEM_DM_write), // before DM_write
    .reg_file_write(reg_file_write),

    .reg_file_FP_write(reg_file_FP_write),
    .WB_data_sel(WB_data_sel)
);
// =========== ID_ImmGe =======//

ID_ImmGe ID_ImmGe_inst(
    .Imm_type(ImmGe),
    .Instr_in(instr),
    .Imm_out(imm_o)
);

//========= Register File =======//

ID_RegFile ID_RegFile_inst(
    .clk(~clk), // why invert ?? 
    .rst(rst),
    .reg_write(reg_write),
    
    .rs1_addr(regf_rs1_addr),
    .rs2_addr(regf_rs2_addr),
    .rd_addr(reg_rd_addr),
    .rd_data(reg_rd_data),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data)
);

ID_FP_RegFile ID_FP_RegFile_inst(
    .clk(~clk),
    .rst(rst),
    .reg_write(reg_FP_write),
    
    .rs1_addr(regf_rs1_addr),
    .rs2_addr(regf_rs2_addr),

    .rd_addr(reg_rd_addr),
    .rd_data(reg_rd_data),

    .rs1_FP_data(rs1_FP_data),
    .rs2_FP_data(rs2_FP_data)
);
endmodule