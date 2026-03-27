`include "./IF_PC.sv"

module IF_Stage (
    input wire clk,rst,
    input IMstall_IF,
    input DMstall_IF,
    //From_BranchCtrl
    input wire [1:0] DY_IF_Branch_Ctrl,
    input wire [1:0] BC_IF_Branch_Ctrl,

    input wire [1:0] EXE_Branch_Ctrl,
    input wire [`DATA_WIDTH-1 : 0] pc_mux_imm_rs1, // WRITE BACK ????
    input wire [`DATA_WIDTH-1 : 0] pc_mux_imm,     // WRITE BACK ????
    input wire [`DATA_WIDTH-1 : 0] Btype_pc_imm_IF,   // From Dyamite_Branch
    // From Dyamite_Branch
    input wire [`DATA_WIDTH-1 : 0] correct_pc,     // From Dyamite_Branch
                        // From Dyamite_Branch
    
    //From_HazardCtrl
    input wire PC_write,

    output wire [`DATA_WIDTH-1 : 0] O_PC,
    output wire [`DATA_WIDTH-1 : 0] o_pc_IM,
    //instr_mux
    input logic                      instr_flush_sel,//From Hazard control block too ? 

    input logic [`DATA_WIDTH -1 : 0] IM_IF_instr, // From instruction memory???

    output logic [`DATA_WIDTH -1 : 0] IF_instr_out,
    // ========= 9/27 ============
    input logic                     correct_pc_BB_flag_Dy,
    input logic                     truebranch_IF
);

logic stall;
assign stall = IMstall_IF || DMstall_IF;
logic [1:0] EXE_Branch_Ctrl_reg;
logic [1:0] BC_IF_Branch_Ctrl_reg;
logic [31:0] correct_pc_BB;
wire [`DATA_WIDTH-1 : 0] PC_4; 
always_ff @(posedge clk or posedge  rst) begin
    if(rst) begin
        EXE_Branch_Ctrl_reg <= 2'b0;
        BC_IF_Branch_Ctrl_reg <= 2'b0;
        // ========== 9/27 ======= //
        correct_pc_BB <= 32'b0;
    end
    else if(!stall) begin
        EXE_Branch_Ctrl_reg <= EXE_Branch_Ctrl;
        BC_IF_Branch_Ctrl_reg <= BC_IF_Branch_Ctrl;
        correct_pc_BB <=  Btype_pc_imm_IF + 4;   // From Dyamite_Branch
    end
    else begin
        EXE_Branch_Ctrl_reg <= EXE_Branch_Ctrl_reg;
        BC_IF_Branch_Ctrl_reg <= BC_IF_Branch_Ctrl_reg;
        correct_pc_BB <=  correct_pc_BB;   // From Dyamite_Branch
;
    end
end



logic [`DATA_WIDTH-1 : 0]pc_B_J_mux_imm;
logic [`DATA_WIDTH-1 : 0]PC_B_in;

reg  [`DATA_WIDTH-1 : 0] PC_in;

logic[3:0] lead_branch_sel;
assign lead_branch_sel = {DY_IF_Branch_Ctrl,BC_IF_Branch_Ctrl}; // final control line 

assign PC_4 = O_PC + 32'd4;

assign o_pc_IM = O_PC; // to instruction memory
    localparam  [1:0]   N_Branch    =   2'b00,
                        JAL_Branch  =   2'b01, 
                        B_Branch    =   2'b10,
                        J_Branch    =   2'b11;

always_comb begin 
    if(correct_pc_BB_flag_Dy==1'b1 && truebranch_IF==1'b1 )// && IMstall_IF==1'b1 effect prog2
        PC_in = correct_pc_BB;
        
    else begin
    // // case (lead_branch_sel)
    // //     4'b0001:PC_in = pc_mux_imm;
    // //     4'b0010:PC_in = pc_mux_imm_rs1;
    // //     4'b0100: PC_in = Btype_pc_imm_IF; // from ID Dy chose b type
    // //     4'b1000: PC_in = correct_pc; // from ID Dy fix wrong pc
    // //     default: PC_in = PC_4;
    // // endcase
    if(lead_branch_sel == 4'b1000)begin
        PC_in = correct_pc;
    end
    else if(lead_branch_sel == 4'b0100)begin
        PC_in = Btype_pc_imm_IF;
    end
    else if(lead_branch_sel == 4'b0010)begin
        PC_in = pc_mux_imm_rs1;
    end
    else if(lead_branch_sel == 4'b0001)begin
        PC_in = pc_mux_imm;
    end
    else begin
        PC_in = PC_4;
    end
    end
end
// always_comb begin
//     unique if(BC_IF_Branch_Ctrl == 4'b0000 || DY_IF_Branch_Ctrl == 4'b0000) PC_in = PC_4;
//     else if(BC_IF_Branch_Ctrl == 4'b0010) PC_in = pc_mux_imm_rs1;
//     else if(DY_IF_Branch_Ctrl == 4'b0100) PC_in = Btype_pc_imm_IF;
//     else if(BC_IF_Branch_Ctrl == 4'b0001) PC_in = pc_mux_imm;
//     else if(DY_IF_Branch_Ctrl == 4'b1000) PC_in = correct_pc;
//     else                                  PC_in = PC_4;
// end
// always_comb begin // FINAL BIG MUX
//     if(EXE_Branch_Ctrl_reg == J_Branch || EXE_Branch_Ctrl_reg == JAL_Branch)begin
//         case (BC_IF_Branch_Ctrl_reg )
//             2'b01:PC_in = pc_mux_imm;
//             2'b10:PC_in = pc_mux_imm_rs1;
//             default: PC_in = PC_4;
//         endcase
//     end

// else begin
    
// end
//     case (DY_IF_Branch_Ctrl)

//         2'b01: PC_in = Btype_pc_imm_IF; // from ID Dy chose b type
//         2'b10: PC_in = correct_pc; // from ID Dy fix wrong pc
//         default: PC_in = PC_4;
//     endcase
// end
//================PC_ COUNTER==============//
IF_PC IF_PC_inst(.clk(clk),.rst(rst),.PC_write(PC_write),.I_PC(PC_in),.O_PC(O_PC));

//==============instr_flush_mux===============//
assign IF_instr_out = (instr_flush_sel) ? 32'd0 : IM_IF_instr; 

endmodule


