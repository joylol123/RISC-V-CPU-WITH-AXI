module Branch_Ctrl (
    input   logic           zeroflag,
    input   logic   [1:0]   branch_signal,
    output  logic   [1:0]   branch_sel
);


// ============== parameter ============== //

    localparam  [1:0]   N_Branch    =   2'b00,
                        JAL_Branch  =   2'b01, 
                        B_Branch    =   2'b10,
                        J_Branch    =   2'b11;

    localparam  [3:0]   pc_4        =   2'b00,
                        pc_imm      =   2'b01,
                        pc_imm_rs1  =   2'b10;
// ======================================= //
always_comb begin
    case (branch_signal)
        N_Branch        :   branch_sel  =   pc_4; 

        JAL_Branch      :   branch_sel  =   pc_imm_rs1; // jalr

        // B_Branch        :   begin
        //     if(zeroflag)
        //         branch_sel  =   pc_imm;
        //     else
        //         branch_sel  =   pc_4; 
        // end

        J_Branch        :   branch_sel  =   pc_imm;

        default         :   branch_sel  =   pc_4;     // B type too
    endcase
end
    
endmodule