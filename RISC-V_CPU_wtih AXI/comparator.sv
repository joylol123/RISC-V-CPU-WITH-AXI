module comparator (
    input                   [`DATA_WIDTH-1:0]    instr_com,
    input                                        lw_use_com,
    input                                        Mstall_IM,
    output logic            [`OP_CODE-1:0]       com_opcode,
    output logic                              B_branch_flag
);


assign com_opcode = instr_com[6:0];
always_comb begin
    if(com_opcode == 7'b1100011 && lw_use_com != 1'b1 )begin//&& Mstall_IM != 1'b1
        B_branch_flag = 1'b1;

    end
    // else if(com_opcode == 7'b1100011 && Mstall_IM != 1'b1)
    //     B_branch_flag = 1'b1;
    else begin
        B_branch_flag = 1'b0;

    end
end




endmodule