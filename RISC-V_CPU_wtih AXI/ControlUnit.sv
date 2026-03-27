module ControlUnit (
    input logic [6:0] opcode,

    output logic [2:0] Imm_type, // to immge module

    //Control Signal

    output logic [2:0] ALU_Ctrl_op, // to EXE_ALU_CTRL module ，yes，
    output logic ALU_rs2_sel,
    output logic EXE_pc_sel,

    output logic [1:0] branch_signal,
    output logic [1:0] MEM_rd_sel,
    output logic       Din_sel,
    output logic       DM_read,
    output logic       DM_write,
    output logic       reg_file_write,
    output logic       reg_file_FP_write,

    output logic       WB_data_sel
);
// PARAMETERS
    //Type
    localparam [2:0] R_type     =   3'b000,
                     I_type     =   3'b001,
                     ADD_type   =   3'b010,
                     I_JAL_type =   3'b011,
                     B_type     =   3'b100,
                     U_LUI_type =   3'b101,
                     F_type     =   3'b110,
                     CSR_type   =   3'b111;

    //Imm
    localparam [2:0] Imm_I      =   3'b000,
                     Imm_S      =   3'b001,
                     Imm_B      =   3'b010,
                     Imm_U      =   3'b011,
                     Imm_J      =   3'b100;

    //branch_type
    localparam [1:0] N_Branch   =   2'b00,
                     JAL_Branch =   2'b01,
                     B_Branch   =   2'b10,
                     J_Branch   =   2'b11;

    //branch_type end
    

    always_comb begin 
        case (opcode)
            // R - Type
            7'b0110011:begin
                ALU_Ctrl_op     =   R_type;
                Imm_type        =   Imm_I; // dont't care R-type doesn't need imm

                ALU_rs2_sel     =   1'b1; // 1: sel rs2(default)    ,   0: Imm
                EXE_pc_sel      =   1'b0; // 1: pc+imm              ,   0: pc + 4 or don't care
                MEM_rd_sel      =   2'd0; // 2: fp_alu, 1: pc, 0:from_alu(rd)   select memory address ??  

                //  float point ??
                Din_sel         =   1'b0; // 1: fp                  ,   0: int
                DM_read         =   1'b0;
                DM_write        =   1'b0;
                // end

                WB_data_sel     =   1'b0;
                reg_file_write  =   1'b1;

                reg_file_FP_write   =   1'b0; //1: use      , 0: not use
                branch_signal   =   N_Branch;

            
            end 

            //  I - Type _ 1 => LW / LB / LH / LHU / LBU 

            7'b0000011:begin
                ALU_Ctrl_op     =   ADD_type;
                Imm_type        =   Imm_I;

                ALU_rs2_sel     =   1'b0;// 1: sel rs2(default)    ,   0: Imm
                EXE_pc_sel      =   1'b0;// 1: pc+imm              ,   0: pc + 4 or don't care
                MEM_rd_sel      =   2'd0;// 2: fp_alu, 1: pc, 0:from_alu(rd) 

                
                Din_sel         =   1'b0; // 1: fp                 , 0: int
                // Memory control  ?? 
                DM_read         =   1'b1;
                DM_write        =   1'b0;

                WB_data_sel     =   1'b1;   // why 1??

                reg_file_write  =   1'b1;
                reg_file_FP_write  =    1'b0; // 1: use             ,0: not use

                branch_signal      =  N_Branch;
            end




            // I - type _ 2

            7'b0010011:begin
                ALU_Ctrl_op     =   I_type;
                Imm_type        =   Imm_I;

                ALU_rs2_sel     =   1'b0;
                EXE_pc_sel      =   1'b0;
                MEM_rd_sel      =   2'd0; // 2: fp_alu, 1: pc, 0:from_alu(rd)   select memory address ?? 
                Din_sel         =   1'b0; //1: fp    ,0: int
                DM_read         =   1'b0;
                DM_write        =   1'b0;

                WB_data_sel     =   1'b0;
                reg_file_write  =   1'b1;
                reg_file_FP_write   =   1'b0;
                branch_signal       =   N_Branch;
            end
            // F - Type 
            7'b1010011:begin
                ALU_Ctrl_op =   F_type;
                Imm_type    =   Imm_I;

                ALU_rs2_sel =   1'b0;
                EXE_pc_sel  =   1'b0;
                MEM_rd_sel  =   2'd2; // 2: fp_alu, 1: pc, 0:from_alu(rd) 

                Din_sel     =   1'b0; // 1:fp   ,0:int
                DM_read     =   1'b0;
                DM_write    =   1'b0;

                WB_data_sel =   1'b0;
                reg_file_write  =   1'b0;
                reg_file_FP_write = 1'b1; // 1: use , 0: don't use
                branch_signal   =   N_Branch;
            end
            // END

            // F-type - FLW
            7'b0000111:begin
                ALU_Ctrl_op =   ADD_type;
                Imm_type    =   Imm_I;

                ALU_rs2_sel =   1'b0; // 1: rs2 , 0: imm 
                EXE_pc_sel  =   1'b0;
                MEM_rd_sel  =   2'd0; // 10/3 update

                Din_sel     =   1'b0; // write in memory ??? 
                DM_read     =   1'b1;
                DM_write    =   1'b0;

                WB_data_sel =   1'b1;   // why ?
                reg_file_write  =   1'b0;
                reg_file_FP_write   =   1'b1; // 1: use ,0: not use

                branch_signal       =   N_Branch;


            end
            // F - Type FSW
            7'b0100111:begin
                ALU_Ctrl_op =   ADD_type;
                Imm_type    =   Imm_S;

                ALU_rs2_sel =   1'b0;
                EXE_pc_sel  =   1'b0;
                MEM_rd_sel  =   2'd0; // don't care ? 

                Din_sel     =   1'b1; // 1: fp  ,   0: int
                DM_read     =   1'b0;
                DM_write    =   1'b1;

                WB_data_sel =   1'b1; // from data memory ?? store word need write back?
                reg_file_write  =   1'b0;
                reg_file_FP_write   =   1'b0; // 0 : don't use
                branch_signal       =   N_Branch;


            end
            // FSW end

            // I - Type - JALR

            7'b1100111: begin
                ALU_Ctrl_op     =   I_JAL_type;
                Imm_type        =   Imm_I;

                ALU_rs2_sel     =   1'b0; // 1: sel rs2(default)    ,   0: Imm
                EXE_pc_sel      =   1'b0;// 1: pc+imm              ,   0: pc + 4 or don't care
                MEM_rd_sel      =   2'd1;// 2: fp_alu, 1: pc, 0:from_alu(rd)                       //before 2'd0

                Din_sel         =   1'b0; //1: FP                  ,    0:int
                DM_read         =   1'b0;
                DM_write        =   1'b0;

                WB_data_sel     =   1'b0;
                reg_file_write  =   1'b1;
                reg_file_FP_write   =   1'b0; // 1: use            , 0: not use
                branch_signal       =   JAL_Branch; // should notice !!!

            end 

            //S - Type
            7'b0100011:begin
                ALU_Ctrl_op     =   ADD_type;
                Imm_type        =   Imm_S;

                ALU_rs2_sel     =   1'b0;
                EXE_pc_sel      =   1'b0;
                MEM_rd_sel      =   2'd0;

                Din_sel         =   1'b0;   //  1: fp               ,0: int
                DM_read         =   1'b0;
                DM_write        =   1'b1; // NOTICED !!

                WB_data_sel     =   1'b0;
                reg_file_write  =   1'b0;
                reg_file_FP_write   =   1'b0;
                branch_signal   =   N_Branch;

            end



            //B-TYPE
            7'b1100011:begin
                ALU_Ctrl_op     =   B_type;
                Imm_type        =   Imm_B;

                ALU_rs2_sel     =   1'b1;
                EXE_pc_sel      =   1'b0;
                MEM_rd_sel      =   2'd1;

                Din_sel         =   1'b0; // 1: FP                  , 0: int
                DM_read         =   1'b0;
                DM_write        =   1'b0;

                WB_data_sel     =   1'b0;
                reg_file_write  =   1'b0;
                reg_file_FP_write   =   1'b0; // 1 : use            , 0: not use
                branch_signal       =   B_Branch; // NOTICED !!

            end

            // U - TYPE -   AUIPC
        7'b0010111:begin
            ALU_Ctrl_op     =   ADD_type;
            Imm_type        =   Imm_U;

            ALU_rs2_sel     =   1'b0;
            EXE_pc_sel      =   1'b1;
            MEM_rd_sel      =   2'd1;

            Din_sel         =   1'b0;
            DM_read         =   1'b0;
            DM_write        =   1'b0;

            WB_data_sel     =   1'b0;
            reg_file_write  =   1'b1;
            reg_file_FP_write   =   1'b0;

            branch_signal   =   N_Branch;
        end
            // U - TYPE - LUI
        7'b0110111:begin
            ALU_Ctrl_op     =   U_LUI_type;
            Imm_type        =   Imm_U;

            ALU_rs2_sel     =   1'b0;
            EXE_pc_sel      =   1'b0;
            MEM_rd_sel      =   2'd0; // 

            Din_sel         =   1'b0; // 1: FP                          ,0: int
            DM_read         =   1'b0;
            DM_write        =   1'b0;

            WB_data_sel     =   1'b0;
            reg_file_write  =   1'b1;
            reg_file_FP_write   =   1'b0;

            branch_signal   =   N_Branch;
        end
            //J - TYPE
        7'b1101111:begin
            ALU_Ctrl_op     =   ADD_type;
            Imm_type        =   Imm_J;

            ALU_rs2_sel     =   1'b0;
            EXE_pc_sel      =   1'b0;
            MEM_rd_sel      =   2'd1;   

            Din_sel         =   1'b0;
            DM_read         =   1'b0;
            DM_write        =   1'b0;

            WB_data_sel     =   1'b0;
            reg_file_write  =   1'b1;
            reg_file_FP_write   =   1'b0;
            branch_signal   =   J_Branch;
        end
            // CSR 
        7'b1110011:begin
            ALU_Ctrl_op =   CSR_type;
            Imm_type    =   Imm_I;

            ALU_rs2_sel =   1'b0;
            EXE_pc_sel  =   1'b0;
            MEM_rd_sel  =   2'b11; // csr data

            Din_sel     =   1'b0;
            DM_read     =   1'b0;
            DM_write    =   1'b0;

            WB_data_sel =   1'b0;
            reg_file_write  =   1'b1;
            reg_file_FP_write   =   1'b0;

            branch_signal  =   N_Branch;

        end
            // CSR END


            default: begin // don't care 
                ALU_Ctrl_op     =   1'b0;
                Imm_type        =   Imm_I;

                ALU_rs2_sel     =   1'b0;
                EXE_pc_sel      =   1'b0;
                MEM_rd_sel      =   2'd0;

                Din_sel         =   1'b0;
                DM_read         =   1'b0;
                DM_write        =   1'b0;

                WB_data_sel     =   1'b0;
                reg_file_write  =   1'b0;
                reg_file_FP_write   =   1'b0;
                branch_signal   =   N_Branch;
            end  


        endcase
    end

endmodule