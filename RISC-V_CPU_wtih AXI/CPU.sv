`include "../include/CPU_define.svh"
`include "EXE_Stage.sv"
`include "ID_Stage.sv"
`include "IF_Stage.sv"
`include "MEM_Stage.sv"
`include "WB_Stage.sv"
`include "Dynamic_Branch.sv"
`include "Branch_Ctrl.sv"
`include "ForwardingUnit.sv"
`include "Hazard_Ctrl.sv"
`include "CSR.sv"
`include "SRAM_wrapper.sv"
`include "comparator.sv"

module CPU (
    input clk,
    input rst,
    
    //Instruction Memory
    input        [`DATA_WIDTH -1:0]    IM_IF_instr,
    input                              IM_stall,
    output logic                       IM_WEB,
    output logic [`AXI_DATA_BITS -1:0] IM_addr,

    //Data Memory
    output logic                       DM_WEB,
    output logic [`DATA_WIDTH -1:0]    DM_BWEB,
    output logic                       DM_read_sel,
    output logic                       DM_write_sel,
    output logic [`AXI_ADDR_BITS -1:0] DM_addr,
    output logic [`AXI_DATA_BITS -1:0] DM_Din,
    input        [`AXI_DATA_BITS -1:0] DM_Dout,
    input                              DM_stall
);
 // ================  WIRES ================= // 
 wire   [`DATA_WIDTH -1:0]  IF_IM_pc;
//  wire   [`DATA_WIDTH -1:0]  IM_IF_instr;
// ============== 2025/10/15   ===============//
 wire                       wire_HAZ_IM_stall;
 wire                       wire_HAZ_DM_stall;
 wire                       wire_HAZ_Hazard_stall;
 wire                       wire_HAZ_ID_EXE_reg_write;
 wire                       wire_HAZ_EXE_MEM_reg_write;
 wire                       wire_HAZ_MEM_WB_reg_write;
 wire                       wire_HAZ_stall;
// ============== 2025/10/15   ===============//
// ============== LATEST WIRES =============== //
 wire   [`DATA_WIDTH -1:0]  Dy_IF_imm;
 wire                       Dy_Haz_fix_signal;
 wire   [`DATA_WIDTH -1:0]  Dy_IF_Btype_imm;

 wire   [`DATA_WIDTH -1:0]  Dy_IF_correct_pc;

 wire   [1:0]               Dy_IF_branch_sel;

 wire                       Dy_Haz_by_Btype;
 wire   [1:0]                   Dy_CSR_Bbranch;
 wire                       com_Dy_B_branch_flag;
 wire   [1:0]               EXE_IF_branch_sel;
 wire   [1:0]               Dy_Haz_branch_sel_Dy_reg;
 wire   [`OP_CODE -1:0]     wire_opcode_ID;
 wire                       correct_pc_BB_flag_Dy_IF;
 wire   [1:0]               BB_counter_Dy_Haz;
 wire                       lw_sue_Haz_com;
 wire   [`OP_CODE-1:0]      opcode_com_csr;
// ============== LATEST WIRES =============== //
 wire   [1:0]               BC_IF_branch_sel;
 wire   [`DATA_WIDTH -1:0]  EXE_IF_ALU_o; // jalr ?
 wire   [`DATA_WIDTH -1:0]  EXE_IF_pc_imm; // branch & jal
 wire                       HAZ_IF_pc_w;
 wire                       HAZ_IF_instr_flush;
 wire                       wire_HAZ_IF_ID_reg_write;

 wire                       wire_ctrl_sig_flush; // when hazard occur reset all the ctrl line ??
 wire                       wire_HAZ_CSR_lw_use;

 wire   [1:0]               FWD_EXE_rs1_sel;
 wire   [1:0]               FWD_EXE_rs2_sel;
 wire   [1:0]               FWD_EXE_rs1_FP_sel;
 wire   [1:0]               FWD_EXE_rs2_FP_sel;
 wire   [1:0]               wire_branch_sel_Dy_t_nt;
 wire                       wire_branch_flag;
// ================================================ //

 wire                       EXE_Bctrl_zeroflag;
 wire                       MEM_DM_CS;
 wire   [`DATA_WIDTH -1:0]  DM_write_enable;
 // =============== STATE REGISTER ==================== //
  // ================== IF_ID Register ============//
 reg    [`DATA_WIDTH -1:0]  IF_ID_pc;
 reg    [`DATA_WIDTH -1:0]  IF_ID_instr;
 wire   [`DATA_WIDTH -1:0]  wire_IF_ID_pc;
 wire   [`DATA_WIDTH -1:0]  wire_IF_ID_instr;

 // ============= ID_EXE Register ============= //
 reg    [`DATA_WIDTH -1:0]  ID_EXE_rs1;
 reg    [`DATA_WIDTH -1:0]  ID_EXE_rs2;
 reg    [`DATA_WIDTH -1:0]  ID_EXE_rs1_FP;
 reg    [`DATA_WIDTH -1:0]  ID_EXE_rs2_FP;
 reg    [`DATA_WIDTH -1:0]  ID_EXE_pc_in; 

 reg    [`FUNCTION_3 -1:0]  ID_EXE_function3; // before `FUNCTION_7
 reg    [`FUNCTION_7 -1:0]  ID_EXE_function7; // before `FUNCTION_3
 reg    [4:0]               ID_EXE_rs1_addr;
 reg    [4:0]               ID_EXE_rs2_addr;
 reg    [4:0]               ID_EXE_rd_addr;
 reg    [`DATA_WIDTH -1:0]  ID_EXE_imm;

 reg    [6:0]               ID_EXE_opcode;

 wire   [`DATA_WIDTH -1:0]  wire_ID_EXE_pc_in;
 wire   [`DATA_WIDTH -1:0]  wire_ID_EXE_rs1;
 wire   [`DATA_WIDTH -1:0]  wire_ID_EXE_rs2;
 wire   [`DATA_WIDTH -1:0]  wire_ID_EXE_rs1_FP;
 wire   [`DATA_WIDTH -1:0]  wire_ID_EXE_rs2_FP;

 wire   [`FUNCTION_3 -1:0]  wire_ID_EXE_function3;
 wire   [`FUNCTION_7 -1:0]  wire_ID_EXE_function7;
 wire   [4:0]               wire_ID_EXE_rs1_addr;
 wire   [4:0]               wire_ID_EXE_rs2_addr;
 wire   [4:0]               wire_ID_EXE_rd_addr;
 wire   [`DATA_WIDTH -1:0]  wire_ID_EXE_imm;
// =============== CONTROL SIG REGISTER =============== //
 reg    [2:0]               ID_EXE_ALU_Ctrl_op;
 reg                        ID_EXE_pc_mux;
 reg                        ID_EXE_ALU_rs2_sel;
 reg    [1:0]               ID_EXE_branch_signal;
 reg    [1:0]               ID_EXE_rd_sel; // before ID_EXE_MEM_rd_sel 
 reg                        ID_EXE_Din_sel;
 reg                        ID_EXE_DM_read;
 reg                        ID_EXE_DM_write;
 reg                        ID_EXE_reg_file_write;
 reg                        ID_EXE_reg_file_FP_write;
 reg                        ID_EXE_WB_data_sel;

 wire    [2:0]              wire_ID_EXE_ALU_Ctrl_op;
 wire                       wire_ID_EXE_pc_mux;
 wire                       wire_ID_EXE_ALU_rs2_sel;
 wire    [1:0]              wire_ID_EXE_branch_signal;
 wire    [1:0]              wire_ID_EXE_rd_sel; // before wire_ID_EXE_MEM_rd_sel
 wire                       wire_ID_EXE_Din_sel;
 wire                       wire_ID_EXE_DM_read;
 wire                       wire_ID_EXE_DM_write;
 wire                       wire_ID_EXE_reg_file_write;
 wire                       wire_ID_EXE_reg_file_FP_write;
 wire                       wire_ID_EXE_WB_data_sel;

// ================ EXE_MEM REGISTER ================ // 
reg     [`DATA_WIDTH -1:0]  EXE_MEM_rs2_data;
reg     [`DATA_WIDTH -1:0]  EXE_MEM_rs2_FP_data;
reg     [`DATA_WIDTH -1:0]  EXE_MEM_ALU_o;
reg     [`DATA_WIDTH -1:0]  EXE_MEM_ALU_FP_o;
reg     [`DATA_WIDTH -1:0]  EXE_MEM_PC;
reg     [`FUNCTION_3 -1:0]  EXE_MEM_function_3;
reg     [4:0]  EXE_MEM_rd_addr;
reg     [`DATA_WIDTH -1:0]  EXE_MEM_csr_rd; // ???

wire     [`DATA_WIDTH -1:0]  wire_EXE_MEM_rs2_data;
wire     [`DATA_WIDTH -1:0]  wire_EXE_MEM_rs2_FP_data;
wire     [`DATA_WIDTH -1:0]  wire_EXE_MEM_ALU_o;
wire     [`DATA_WIDTH -1:0]  wire_EXE_MEM_ALU_FP_o;
wire     [`DATA_WIDTH -1:0]  wire_EXE_MEM_PC;
wire     [`FUNCTION_3 -1:0]  wire_EXE_MEM_function_3;
wire     [4:0]  wire_EXE_MEM_rd_addr;
wire     [`DATA_WIDTH -1:0]  wire_EXE_MEM_csr_rd; // ???

wire     [`DATA_WIDTH -1:0]  MEM_DM_Din; // ??? from sram wrapper

// ================== CONTROL SIG REGISTER ============ //
//reg                         EXE_MEM_DM_read_sel;  
reg                         EXE_MEM_DM_write_sel; 
reg     [1:0]               EXE_MEM_rd_sel;
reg                         EXE_MEM_Din_sel;
reg                         EXE_MEM_DM_read;
reg                         EXE_MEM_DM_write;
reg                         EXE_MEM_data_sel;
reg                         EXE_MEM_reg_file_write;
reg                         EXE_MEM_reg_file_FP_write;

// wire                         wire_EXE_MEM_DM_read_sel; 
wire                         wire_EXE_MEM_DM_write_sel; 
wire     [1:0]               wire_EXE_MEM_rd_sel;
wire                         wire_EXE_MEM_Din_sel;
wire                         wire_EXE_MEM_DM_read;
wire                         wire_EXE_MEM_DM_write;
wire                         wire_EXE_MEM_data_sel;
wire                         wire_EXE_MEM_reg_file_write;
wire                         wire_EXE_MEM_reg_file_FP_write;

// ================= MEM_WB Register ====================== //
reg     [`DATA_WIDTH -1:0]  MEM_WB_rd_dir; //for write back
reg     [`DATA_WIDTH -1:0]  MEM_WB_rd_DM; // for data memory ??
reg     [4:0]               MEM_WB_rd_addr;

wire    [`DATA_WIDTH -1:0]  DM_MEM_Dout;
wire                        SRAM_web; // ???????

wire     [`DATA_WIDTH -1:0]  wire_MEM_WB_rd_dir; //for write back
wire     [`DATA_WIDTH -1:0]  wire_MEM_WB_rd_DM; // for data memory ??
wire     [4:0]               wire_MEM_WB_rd_addr;

// ================== CONTROL SIG REGISTER ================= //
reg                          MEM_WB_data_sel;
reg                          MEM_WB_reg_file_write;
reg                          MEM_WB_reg_file_FP_write;

wire                          wire_MEM_WB_data_sel;
wire                          wire_MEM_WB_reg_file_write;
wire                          wire_MEM_WB_reg_file_FP_write;

reg                           lw_use_delay;

always_ff @(posedge clk or posedge rst)  begin 
    if(rst)
        lw_use_delay<=1'b0;
    else if(wire_HAZ_CSR_lw_use)
        lw_use_delay <= wire_HAZ_CSR_lw_use;
    else    
        lw_use_delay<=1'b0;
end
// ================ WB wire /reg ============= //
wire    [`DATA_WIDTH -1:0]  WB_rd_data;

// =============== IF_ Stage =============== //
    IF_Stage IF_Stage_inst(
        .clk(clk),.rst(rst),
        .DY_IF_Branch_Ctrl(Dy_IF_branch_sel),// from dynamic branch
        .BC_IF_Branch_Ctrl(EXE_IF_branch_sel),// fror exe branch
        // =========== LASTEST ========== //
        .Btype_pc_imm_IF(Dy_IF_Btype_imm), // from dynamic branch
        
        .correct_pc(Dy_IF_correct_pc),// from dynamic branch
        .EXE_Branch_Ctrl(ID_EXE_branch_signal),


        // =========== LASTEST ========== //
        .pc_mux_imm_rs1(EXE_IF_ALU_o),
        .pc_mux_imm(EXE_IF_pc_imm), //before EXE_IF_pc_imm
        .PC_write(HAZ_IF_pc_w),
        .O_PC(wire_IF_ID_pc),
        .o_pc_IM(IF_IM_pc), // SRAM wrapper instr memory ???
        .instr_flush_sel(HAZ_IF_instr_flush),
        .IM_IF_instr(IM_IF_instr), // input
        .IF_instr_out(wire_IF_ID_instr),
        .correct_pc_BB_flag_Dy(correct_pc_BB_flag_Dy_IF),
        .truebranch_IF(EXE_Bctrl_zeroflag),
        .IMstall_IF(IM_stall),
        .DMstall_IF(DM_stall)
        );

// IM

assign IM_WEB = 1'b1; // keep reading
assign IM_addr = IF_IM_pc;
// SRAM_wrapper IM1(
//     .CLK(~clk),.RST(rst),
//     .CEB(1'b0), // active low
//     .WEB(1'b1), // read : active high
//     //.OE(1'b1),
//     .BWEB(32'hffff_ffff), // active low
//     //.WEB(4'b1111),
//     .A(IF_IM_pc[15:2]),
//     .DI(32'b0), // no data in
//     .DO(IM_IF_instr)
// );
// =============== ID_Stage ================= //
    ID_Stage ID_Stage_inst(
        .clk(clk),.rst(rst),
        .instr(IF_ID_instr),
        .reg_rd_addr(MEM_WB_rd_addr),
        .reg_rd_data(WB_rd_data),
        .reg_write(MEM_WB_reg_file_write),
        .reg_FP_write(MEM_WB_reg_file_FP_write),
//      Output              //  
        .rs1_data(wire_ID_EXE_rs1),
        .rs2_data(wire_ID_EXE_rs2),
        .rs1_FP_data(wire_ID_EXE_rs1_FP),
        .rs2_FP_data(wire_ID_EXE_rs2_FP),

        .funct3(wire_ID_EXE_function3),
        .funct7(wire_ID_EXE_function7 ),
        .rs1_addr(wire_ID_EXE_rs1_addr),
        .rs2_addr(wire_ID_EXE_rs2_addr),
        .rd_addr(wire_ID_EXE_rd_addr),
        .imm_o(wire_ID_EXE_imm),

//     Control Signal   //
        .opcode(wire_opcode_ID),
        .ALU_Ctrl_op(wire_ID_EXE_ALU_Ctrl_op),
        .ALU_rs2_sel(wire_ID_EXE_ALU_rs2_sel),
        .EXE_pc_sel(wire_ID_EXE_pc_mux),
        .branch_signal(wire_ID_EXE_branch_signal),
        .MEM_rd_sel(wire_ID_EXE_rd_sel),// before wire_ID_EXE_MEM_rd_sel
        .MEM_Din_sel(wire_ID_EXE_Din_sel),
        .MEM_DM_read(wire_ID_EXE_DM_read),
        .MEM_DM_write(wire_ID_EXE_DM_write),
        .reg_file_write(wire_ID_EXE_reg_file_write),
        .reg_file_FP_write(wire_ID_EXE_reg_file_FP_write),

        .WB_data_sel(wire_ID_EXE_WB_data_sel),
        .in_pc(IF_ID_pc), // before IF_ID_pc_in
        .out_pc(wire_ID_EXE_pc_in)
    );

//  ======================  EXE STAGE ===================== //
EXE_Stage EXE_Stage(
//========= Control Signal ====== //
            .ALU_op(ID_EXE_ALU_Ctrl_op),
    
            .pc_mux_sel(ID_EXE_pc_mux),
            .ALU_rs2_sel(ID_EXE_ALU_rs2_sel),

            .ID_EXE_rd_sel(ID_EXE_rd_sel), //??
            .EXE_MEM_rd_sel(wire_EXE_MEM_rd_sel),

            .ID_EXE_Din(ID_EXE_Din_sel), // control line
            .EXE_MEM_Din(wire_EXE_MEM_Din_sel),

            .ID_EXE_DM_read(ID_EXE_DM_read),
            .EXE_MEM_DM_read(wire_EXE_MEM_DM_read),

            .ID_EXE_DM_write(ID_EXE_DM_write),
            .EXE_MEM_DM_write(wire_EXE_MEM_DM_write),

            .ID_EXE_WB_data_sel(ID_EXE_WB_data_sel),
            .EXE_MEM_WB_data_sel(wire_EXE_MEM_data_sel),

            .ID_EXE_reg_file_write(ID_EXE_reg_file_write),
            .EXE_MEM_reg_file_write(wire_EXE_MEM_reg_file_write),

            .ID_EXE_reg_file_FP_write(ID_EXE_reg_file_FP_write),
            .EXE_MEM_reg_file_FP_write(wire_EXE_MEM_reg_file_FP_write),


            .EXE_imm(ID_EXE_imm),
    
    
           .ForwardA_sel(FWD_EXE_rs1_sel),
           .ForwardB_sel(FWD_EXE_rs2_sel),
           .ForwardA_FP_sel(FWD_EXE_rs1_FP_sel),
           .ForwardB_FP_sel(FWD_EXE_rs2_FP_sel),

// ============ DATA PATH =============== //

            .PC_EXE_in(ID_EXE_pc_in), //before ID_EXE_pc_in
            .EXE_rs1(ID_EXE_rs1),
            .EXE_rs2(ID_EXE_rs2),
            .WB_rd_data(WB_rd_data),
            .MEM_rd_data(wire_MEM_WB_rd_dir), // what does focus mean ??? From mem stage forwaring
            .EXE_rs1_FP(ID_EXE_rs1_FP),
            .EXE_rs2_FP(ID_EXE_rs2_FP),
            .EXE_function_3(ID_EXE_function3),
            .EXE_function_7(ID_EXE_function7),
            .ID_EXE_rd_addr(ID_EXE_rd_addr),

            .EXE_PC_imm(EXE_IF_pc_imm), // back to IF stage

            .pc_sel_o(wire_EXE_MEM_PC),
            .zeroflag(EXE_Bctrl_zeroflag), //back to BranchCtrl module
            .ALU_o(wire_EXE_MEM_ALU_o),
            .ALU_FP_out(wire_EXE_MEM_ALU_FP_o),
            .ALU_o_2_immrs1(EXE_IF_ALU_o), // back to IF stage

            .Mux3_ALU(wire_EXE_MEM_rs2_data),
            .Mux_rs2_FP(wire_EXE_MEM_rs2_FP_data),

            .EXE_MEM_function_3(wire_EXE_MEM_function_3),
            .EXE_MEM_rd_addr(wire_EXE_MEM_rd_addr)
);

// ================== MEM Stage ==================== //
MEM_Stage MEM_Stage_inst(
    .clk(clk),.rst(rst),

// ============ Ctrl signal ============== //

    .MEM_rd_sel(EXE_MEM_rd_sel),
    .MEM_Din_sel(EXE_MEM_Din_sel),
    .MEM_DMread_sel(EXE_MEM_DM_read), // before_sel
    .MEM_DMwrite_sel(EXE_MEM_DM_write), // before EXE_MEM_DM_write_sel
    .EXE_MEM_WB_data_sel(EXE_MEM_data_sel), // before : EXE_MEM_WB_data_sel
    .EXE_MEM_reg_file_write(EXE_MEM_reg_file_write),
    .EXE_MEM_reg_file_FP_write(EXE_MEM_reg_file_FP_write),

    .MEM_WB_reg_file_write(wire_MEM_WB_reg_file_write),
    .MEM_WB_reg_file_FP_write(wire_MEM_WB_reg_file_FP_write),
    .MEM_WB_data_sel(wire_MEM_WB_data_sel),

// ================ MEM I / O =====================//
    
    .MEM_pc(EXE_MEM_PC),
    .MEM_ALU(EXE_MEM_ALU_o),
    .MEM_ALU_FP(EXE_MEM_ALU_FP_o),
    .MEM_csr(EXE_MEM_csr_rd),
    .EXE_MEM_rd_addr(EXE_MEM_rd_addr),
    .MEM_WB_rd_addr(wire_MEM_WB_rd_addr), //next register

// =================== DATA ========================//
    .EXE_funct3(EXE_MEM_function_3),
    .EXE_rs2_data(EXE_MEM_rs2_data),
    .EXE_rs2_FP_data(EXE_MEM_rs2_FP_data),
    .MEM_rd_data(wire_MEM_WB_rd_dir), // write back to exe stage
// =================== DM ========================== // 
    .chip_select(MEM_DM_CS),
    .SRAM_web(SRAM_web),
// =================== SW ================= //
    .w_eb(DM_write_enable),
    .DM_in(MEM_DM_Din),
// =================== LW ========================= //
    .DM_out(DM_MEM_Dout), // input port from sram wrapper Data memory 
    .DM_out_2_reg(wire_MEM_WB_rd_DM)
);
// DM
assign DM_WEB  = SRAM_web;
assign DM_BWEB = DM_write_enable;
assign DM_read_sel = EXE_MEM_DM_read;
assign DM_write_sel = EXE_MEM_DM_write;//from MEM Stage
assign DM_addr      = EXE_MEM_ALU_o;
assign DM_Din       = MEM_DM_Din;
assign DM_MEM_Dout  = DM_Dout;
// SRAM_wrapper DM1(
//     .CLK(~clk), .RST(rst),
//     .CEB(MEM_DM_CS),// active low
//     .WEB(SRAM_web),
//     .BWEB(DM_write_enable),
//     //.OE(EXE_MEM_DM_read),
    
//     .A(EXE_MEM_ALU_o[15:2]), // sw instr =>   
//     .DI(MEM_DM_Din),
//     .DO(DM_MEM_Dout) //before DM_out

// );                   // ??????????

// ================ WB_STAGE ================ //
WB_Stage WB_Stage_inst(
    .data_sel(MEM_WB_data_sel), // control line
    .WB_rd_dir(MEM_WB_rd_dir),
    .WB_rd_DM(MEM_WB_rd_DM),
    .WB_rd_data(WB_rd_data) // write back to EXE stage & ID stage
);

// =============== DY Branch Control ============== //
Dynamic_Branch Dynamic_Branch_inst(
    .clk(clk),.rst(rst),
    .pc(IF_ID_pc),.imm(wire_ID_EXE_imm),
    .true_branch(EXE_Bctrl_zeroflag),
    .Dy_B_branch_flag(com_Dy_B_branch_flag),
    .Mstall_IM(IM_stall),
    //======= OUTUPT =======//
    
    .by_Btype(Dy_Haz_by_Btype), // to hazard
    .fix_signal(Dy_Haz_fix_signal), // to hazard
    .Btype_pc_imm(Dy_IF_Btype_imm),
    .correct_pc(Dy_IF_correct_pc),
    .B_branch_count(Dy_CSR_Bbranch),
    .branch_sel_Dy(Dy_IF_branch_sel),
    .branch_sel_Dy_reg(Dy_Haz_branch_sel_Dy_reg),
    .correct_pc_BB_flag(correct_pc_BB_flag_Dy_IF),
    .BB_counter(BB_counter_Dy_Haz),
    .branch_sel_Dy_t_nt_reg(wire_branch_sel_Dy_t_nt),
    .Dy_B_branch_flag_reg(wire_branch_flag)
);
       
// ============== EXE BRANCH CONTROL ==================//
Branch_Ctrl Branch_Ctrl_inst(
    .zeroflag(EXE_Bctrl_zeroflag),
    .branch_signal(ID_EXE_branch_signal), // From Control Unit
    .branch_sel(EXE_IF_branch_sel) // output to IF Stage mux // before BC_IF_branch_sel
);
// ============== comparator =================== //

comparator comparator_inst(
    .instr_com(IF_ID_instr),.B_branch_flag(com_Dy_B_branch_flag),.Mstall_IM(IM_stall),
    .lw_use_com(wire_HAZ_CSR_lw_use),.com_opcode(opcode_com_csr)
);
// ============= Hazard Control =============== //
 
logic   w_fix_dy_pc;


Hazard_Ctrl Hazard_Ctrl_inst(
    .branch_sel(EXE_IF_branch_sel), // little weird ?? before BC_IF_branch_sel From branch ctrl module
    .EXE_read(ID_EXE_DM_read), // detect lw use
    .Dy_by_Btype(Dy_Haz_by_Btype), // from dynamic branch
    .ID_rs1_addr(wire_ID_EXE_rs1_addr),
    .ID_rs2_addr(wire_ID_EXE_rs2_addr), // before wire_ID_EXE_rs2
    .EXE_rd_addr(wire_EXE_MEM_rd_addr),
    // ============ LASTEST ============ //
    .fix_signal_dynamic(Dy_Haz_fix_signal), // from dynamic branch
    .true_branch_Haz(EXE_Bctrl_zeroflag),
    .branch_sel_Dy_reg_Haz(Dy_Haz_branch_sel_Dy_reg),
    .B_branch_flag_Haz(com_Dy_B_branch_flag),
    .correct_pc_BB_flag_haz(correct_pc_BB_flag_Dy_IF),
    
    // ============ LASTEST ============ //
    .pc_write(HAZ_IF_pc_w), // to IF stage
    .instr_flush(HAZ_IF_instr_flush), // to IF stage
    .IF_ID_reg_write(wire_HAZ_IF_ID_reg_write), // flush the IF_ID register
    .ctrl_sig_flush(wire_ctrl_sig_flush), // Reset the branch state?
    .fix_dy_pc     (w_fix_dy_pc),
    .BB_counter_Haz(BB_counter_Dy_Haz),

    .lw_use(wire_HAZ_CSR_lw_use), // to CSR module
    // 2025/10/15
    .IM_stall(IM_stall),// before wire_HAZ_IM_stall
    .DM_stall(DM_stall),//before wire_HAZ_DM_stall
    .Hazard_stall(wire_HAZ_stall),
    .ID_EXE_reg_write(wire_HAZ_ID_EXE_reg_write),
    .EXE_MEM_reg_write(wire_HAZ_EXE_MEM_reg_write),
    .MEM_WB_reg_write(wire_HAZ_MEM_WB_reg_write)
    // 2025/10/15
);

// ================ Forwarding Unit ====================== //
ForwardingUnit ForwardingUnit_inst(
    .ID_rs1_addr(ID_EXE_rs1_addr),   
    .ID_rs2_addr(ID_EXE_rs2_addr),
    .EXE_rd_addr(EXE_MEM_rd_addr), // why does't it use wire_EXE_MEM_rd_addr?? cause it is the where forwarding occurs?
    .MEM_rd_addr(MEM_WB_rd_addr),

    .EXE_MEM_fwd_write(EXE_MEM_reg_file_write), // before EXE_MEM_reg_file_write
    .MEM_WB_fwd_write(MEM_WB_reg_file_write), // before MEM_WB_fwd_write

    .EXE_MEM_fwd_FP_write(EXE_MEM_reg_file_FP_write),// before EXE_MEM_fwd_FP_write 
    .MEM_WB_fwd_FP_write(MEM_WB_reg_file_FP_write), // before MEM_WB_fwd_FP_write

    .FWD_rs1_sel(FWD_EXE_rs1_sel),
    .FWD_rs2_sel(FWD_EXE_rs2_sel), 

    .FWD_rs1_FP_sel(FWD_EXE_rs1_FP_sel),
    .FWD_rs2_FP_sel(FWD_EXE_rs2_FP_sel) ,
    .B_Branch_Fd(com_Dy_B_branch_flag)
);

// ================ CSR ======================= //
CSR CSR_inst(
    .clk(clk),.rst(rst),
        
    .CSR_op(ID_EXE_opcode),// From control unit
    .function_3(ID_EXE_function3),
    .rs1       (ID_EXE_rs1),
    .imm_csr   (ID_EXE_imm),

    .lw_use    (wire_HAZ_CSR_lw_use),
    .branch_b    (Dy_CSR_Bbranch),//before BC_IF_branch_sel // count btype branch
    // .branch_j  (EXE_Dy_branch_sel),
    .csr_rd_data(wire_EXE_MEM_csr_rd),
    .branch_sel_Dy_t_nt_csr(wire_branch_sel_Dy_t_nt),
    .true_branch_csr(EXE_Bctrl_zeroflag),
    .branch_signal_csr(ID_EXE_branch_signal),
    .BB_counter_csr(BB_counter_Dy_Haz),
    .branch_flag_csr(com_Dy_B_branch_flag),
    .branch_flag_reg_csr(wire_branch_flag),
    .opcode_csr(opcode_com_csr),
    .IM_stall_csr(IM_stall),
    .DM_stall_csr(DM_stall)
);

// ============== REGISTER =============== //
    //=========== IF/ID ============= //

always_ff @(posedge clk) begin 
    if(rst)begin
        IF_ID_pc    <=  0;
        IF_ID_instr <=  0;
    end
    else begin
        if(wire_HAZ_IF_ID_reg_write)begin // pc write ??
            IF_ID_pc    <=  (HAZ_IF_instr_flush) ? 32'b0 : wire_IF_ID_pc; // 
            IF_ID_instr <=  (HAZ_IF_instr_flush) ? 32'b0 : wire_IF_ID_instr;
        end
    end
    
end

    // ========== ID/EXE ============ //

always_ff @(posedge clk) begin
    if(rst)begin
        ID_EXE_rs1          <=  0;
        ID_EXE_rs2          <=  0;
        ID_EXE_rs1_FP       <=  0;
        ID_EXE_rs2_FP       <=  0;
        ID_EXE_pc_in        <=  0;

        ID_EXE_function3    <=  0;
        ID_EXE_function7    <=  0;
        ID_EXE_rs1_addr     <=  0;
        ID_EXE_rs2_addr     <=  0;
        ID_EXE_rd_addr      <=  0;
        ID_EXE_imm          <=  0;
    // ========= 9/27 =========//
        ID_EXE_opcode       <= 0;
    // =========9/27 ==========//
    // ======== CONTROL ====== //
        ID_EXE_ALU_Ctrl_op          <=  0;
        ID_EXE_pc_mux               <=  0;
        ID_EXE_ALU_rs2_sel          <=  0;
        ID_EXE_branch_signal        <=  0;
        ID_EXE_rd_sel               <=  0;
   
        ID_EXE_Din_sel              <=  0;
        ID_EXE_DM_read              <=  0;
        ID_EXE_DM_write             <=  0;
        ID_EXE_reg_file_write       <=  0;
        ID_EXE_reg_file_FP_write    <=  0;
        ID_EXE_WB_data_sel          <=  0;
    end

    else if(wire_HAZ_ID_EXE_reg_write)begin
        // ID_EXE_rs1、ID_EXE_rs2 will effect prog1
        ID_EXE_rs1          <= (wire_ctrl_sig_flush) ? 0 : wire_ID_EXE_rs1;//wire_ID_EXE_rs1; //(wire_ctrl_sig_flush) ? 0 : wire_ID_EXE_rs1;

        ID_EXE_rs2          <= (wire_ctrl_sig_flush &  !EXE_Bctrl_zeroflag) ? 0 : wire_ID_EXE_rs2; //(wire_ctrl_sig_flush &  !EXE_Bctrl_zeroflag) ? 0 : 
        ID_EXE_rs1_FP       <=  wire_ID_EXE_rs1_FP;
        ID_EXE_rs2_FP       <=  wire_ID_EXE_rs2_FP;
        ID_EXE_pc_in        <=  (w_fix_dy_pc) ? 0 : wire_ID_EXE_pc_in;

        ID_EXE_function3    <=  wire_ID_EXE_function3;
        ID_EXE_function7    <=  wire_ID_EXE_function7;
        ID_EXE_rs1_addr     <=  wire_ID_EXE_rs1_addr;
        ID_EXE_rs2_addr     <=  wire_ID_EXE_rs2_addr;
        ID_EXE_rd_addr      <=  wire_ID_EXE_rd_addr;
        ID_EXE_imm          <=  wire_ID_EXE_imm;

    // ======== CONTROL ====== //
        ID_EXE_opcode               <=  wire_opcode_ID;
        ID_EXE_ALU_Ctrl_op          <=  wire_ID_EXE_ALU_Ctrl_op;
        ID_EXE_pc_mux               <=  wire_ID_EXE_pc_mux;
        ID_EXE_ALU_rs2_sel          <=  wire_ID_EXE_ALU_rs2_sel;
        ID_EXE_branch_signal        <=  (wire_ctrl_sig_flush) ? 1'b0 : wire_ID_EXE_branch_signal; // branch signal from control unit
        ID_EXE_rd_sel               <=  wire_ID_EXE_rd_sel;
        
        ID_EXE_Din_sel              <=  wire_ID_EXE_Din_sel;
        ID_EXE_DM_read              <=  (wire_ctrl_sig_flush) ? 1'b0 : wire_ID_EXE_DM_read; //
        ID_EXE_DM_write             <=  (wire_ctrl_sig_flush) ? 1'b0 : wire_ID_EXE_DM_write; //
        ID_EXE_reg_file_write       <=  (wire_ctrl_sig_flush) ? 1'b0 : wire_ID_EXE_reg_file_write; //
        ID_EXE_reg_file_FP_write    <=  (wire_ctrl_sig_flush) ? 1'b0: wire_ID_EXE_reg_file_FP_write; //
        ID_EXE_WB_data_sel          <=  wire_ID_EXE_WB_data_sel;
    end
end

// =========== EXE/MEM ======== //

always_ff @(posedge clk) begin

    if(rst)begin
        EXE_MEM_rs2_data            <=  0;
        EXE_MEM_rs2_FP_data         <=  0;
        EXE_MEM_ALU_o               <=  0;
        EXE_MEM_ALU_FP_o            <=  0;
        EXE_MEM_PC                  <=  0;
        EXE_MEM_function_3          <=  0;
        EXE_MEM_rd_addr             <=  0;
        EXE_MEM_csr_rd              <=  0; // ???

    // ========= CONTROL ========== //
        // EXE_MEM_DM_read_sel         <=  0;  
        EXE_MEM_DM_write_sel        <=  0; 
        EXE_MEM_rd_sel              <=  0;
        EXE_MEM_Din_sel             <=  0;
        EXE_MEM_DM_read             <=  0;
        EXE_MEM_DM_write            <=  0;
        EXE_MEM_data_sel            <=  0;
        EXE_MEM_reg_file_write      <=  0;
        EXE_MEM_reg_file_FP_write   <=  0;

end

    else if(wire_HAZ_EXE_MEM_reg_write)begin
        EXE_MEM_rs2_data            <=  wire_EXE_MEM_rs2_data;
        EXE_MEM_rs2_FP_data         <=  wire_EXE_MEM_rs2_FP_data;
        EXE_MEM_ALU_o               <=  wire_EXE_MEM_ALU_o;
        EXE_MEM_ALU_FP_o            <=  wire_EXE_MEM_ALU_FP_o;
        EXE_MEM_PC                  <=  wire_EXE_MEM_PC;
        EXE_MEM_function_3          <=  wire_EXE_MEM_function_3;
        EXE_MEM_rd_addr             <=  wire_EXE_MEM_rd_addr;
        EXE_MEM_csr_rd              <=  wire_EXE_MEM_csr_rd; // ???

    // ========= CONTROL ========== //
    //    EXE_MEM_DM_read_sel         <=  wire_EXE_MEM_DM_read_sel; 
    //   EXE_MEM_DM_write_sel        <=  wire_EXE_MEM_DM_write_sel; 
        EXE_MEM_rd_sel              <=  wire_EXE_MEM_rd_sel;
        EXE_MEM_Din_sel             <=  wire_EXE_MEM_Din_sel;
        EXE_MEM_DM_read             <=  wire_EXE_MEM_DM_read;
        EXE_MEM_DM_write            <=  wire_EXE_MEM_DM_write;
        EXE_MEM_data_sel            <=  wire_EXE_MEM_data_sel;
        EXE_MEM_reg_file_write      <=  wire_EXE_MEM_reg_file_write;
        EXE_MEM_reg_file_FP_write   <=  wire_EXE_MEM_reg_file_FP_write;
    end

end

//  =============== MEM /WB ================= //

always_ff @(posedge clk) begin

    if(rst)begin
        MEM_WB_rd_dir               <=  0; //for write back
        MEM_WB_rd_DM                <=  0; // for data memory ??
        MEM_WB_rd_addr              <=  0;

        // ========== CONTROL =========== //
        MEM_WB_data_sel             <=  0;
        MEM_WB_reg_file_write       <=  0;
        MEM_WB_reg_file_FP_write    <=  0;
    end
    
    else if(wire_HAZ_MEM_WB_reg_write)begin
        MEM_WB_rd_dir               <=  wire_MEM_WB_rd_dir; //for write back
        MEM_WB_rd_DM                <=  wire_MEM_WB_rd_DM; // for data memory ??
        MEM_WB_rd_addr              <=  wire_MEM_WB_rd_addr;

        // ========== CONTROL =========== //
        MEM_WB_data_sel             <=  wire_MEM_WB_data_sel;
        MEM_WB_reg_file_write       <=  wire_MEM_WB_reg_file_write;
        MEM_WB_reg_file_FP_write    <=  wire_MEM_WB_reg_file_FP_write;
    end
end
endmodule