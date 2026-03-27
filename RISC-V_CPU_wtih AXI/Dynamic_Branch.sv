module Dynamic_Branch (
    input clk, rst,
    input Mstall_IM,
    input [`DATA_WIDTH-1:0] pc,
    input [`DATA_WIDTH-1:0] imm,
    
    input Dy_B_branch_flag,
    input true_branch, // from EX stage

    output logic [1:0]             B_branch_count, // to CSR
    output logic                   by_Btype, // TO HAZARD
    output logic                   fix_signal, // to hazard
    output logic [`DATA_WIDTH-1:0] Btype_pc_imm,// TO IF stage

    output logic [`DATA_WIDTH-1:0] correct_pc, // to IF stage
    output logic [1:0] branch_sel_Dy,
   // 9/26 UPDATE ================
    output logic [1:0] branch_sel_Dy_reg,
    // 9/27 UPDATE ==============
    output logic                   correct_pc_BB_flag,
    // 9/28 UPDATE ==========
    output logic [1:0]             BB_counter,
    output logic [1:0]             branch_sel_Dy_t_nt_reg,
    output logic                   Dy_B_branch_flag_reg
);

localparam [1:0] pc_4 = 2'b00,
                 pc_imm = 2'b01,
                 correct_pc_sel = 2'b10;
                //  pc_imm_rs1 = 2'b10;
//============================================
localparam [1:0] N_Branch = 2'b00,
                 JAL_Branch = 2'b01, 
                 B_Branch = 2'b10,
                 J_Branch = 2'b11;

// ============== parameter ============== //
localparam [2:0] STRONG_TAKEN       = 3'b000,
                 WEAK_TAKEN         = 3'b001,
                 WEAK_NOT_TAKEN     = 3'b010,
                 STRONG_NOT_TAKEN   = 3'b011,
                 CORRECT            = 3'b100;
logic [2:0] curr_state, next_state;
logic  [1:0]branch_btype_reg; // store the type of branch instruction
// logic [1:0] branch_sel_Dy_reg;


logic [`DATA_WIDTH-1:0] correct_pc_4,correct_pc_b;
// logic [1:0] branch_sel_Dy_t_nt_reg;

logic [31:0]pc_reg;

always_ff @(posedge clk or posedge rst) begin
    if(rst)begin
        BB_counter <= 2'b0;
        pc_reg <= 32'b0; // 9/28 To avoid lw-use make BB_counter miscount
    end
    else if(Mstall_IM)begin
        BB_counter <= BB_counter;
        pc_reg <= pc_reg;
    end
    else if(Dy_B_branch_flag==1 && pc!=pc_reg)begin
        BB_counter <= BB_counter + 1;
        pc_reg <= pc;
    end
    else begin
        BB_counter <= 0;
        pc_reg <=0;
    end
end

assign Btype_pc_imm = pc + imm; // Btype address to IF 

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        Dy_B_branch_flag_reg <= 0;
        branch_sel_Dy_reg <= 0;
    end
    else if(Mstall_IM)begin
        Dy_B_branch_flag_reg<=Dy_B_branch_flag_reg; //Dy_B_branch_flag_reg
        branch_sel_Dy_reg <= branch_sel_Dy_reg;
    end
    else begin
        Dy_B_branch_flag_reg<=Dy_B_branch_flag;
        branch_sel_Dy_reg <= branch_sel_Dy;
    end
    
end

always_ff @(posedge clk or posedge rst) begin 
    if(rst)begin
        branch_sel_Dy_t_nt_reg <= 2'b0;
    end
    else if(Mstall_IM)
        branch_sel_Dy_t_nt_reg <= branch_sel_Dy_t_nt_reg;
    else begin
        branch_sel_Dy_t_nt_reg <= branch_sel_Dy;
        // if(branch_sel_Dy==2'b00 || branch_sel_Dy==2'b01)
        //    branch_sel_Dy_t_nt_reg <=branch_sel_Dy;
        // else 
        //      branch_sel_Dy_t_nt_reg <= 2'b0;
    end
end

// ========
always_comb begin
    if(Dy_B_branch_flag == 1 && Dy_B_branch_flag_reg == 1 )
        correct_pc_BB_flag = 1;
    else 
        correct_pc_BB_flag = 0;
end

always_ff @(posedge clk or posedge rst) begin 
    if(rst)begin
        correct_pc_b <= 0;
        correct_pc_4 <= 0;
    end
    // else if(Dy_B_branch_flag ==1 && branch_sel_Dy_reg==1)begin
    //     correct_pc_4 <= correct_pc_4;
    // end
    else if(Mstall_IM)begin
        correct_pc_b <= correct_pc_b; 
        correct_pc_4 <= correct_pc_4;
    end
    else if(Dy_B_branch_flag )begin // if btype run to ID stage remember pc+imm and pc
        correct_pc_b <= pc + imm; 
        correct_pc_4 <= pc + 8;
    end
    else begin
        correct_pc_b <= 0;
        correct_pc_4 <= 0;
    end
    
end
// assign correct_pc = (fix_signal&&true_branch) ? correct_pc_b : correct_pc_4;

always_comb begin // When btype run to exe stage chose the right pc
    if(branch_sel_Dy_reg[1] ==1 && true_branch == 0)begin
        correct_pc = correct_pc_4; 
   
    end
    else if(branch_sel_Dy_reg[1] == 0 && true_branch == 1)begin
        correct_pc = correct_pc_b;

    end
    else begin
        correct_pc = correct_pc_4;

    end

end



// ===================== to hazard for branch flush ===================== // 
    always_ff @(posedge clk or posedge rst)begin
        
        if(rst) by_Btype <= 0;
        else if(Mstall_IM)
            by_Btype <= by_Btype;
        else if(Dy_B_branch_flag)begin //2
            by_Btype <= 1;   
        end
        else begin //0,1,3
            by_Btype <=0;
        end

    end
// ===================== to hazard for branch flush ===================== // 

always_ff @(posedge clk or posedge rst ) begin
    if(rst) curr_state <= STRONG_TAKEN; // initial state not taken)
    else if(!Mstall_IM) curr_state <= next_state;
end
// ===================== to hazard for branch flush ===================== // 

//============== NEXT STATE LOGIC ============== //
// b branch 不能把 id exe flush掉，這樣會算不出zeroflag ??
 

always_comb begin
    next_state = curr_state;
    if( Dy_B_branch_flag_reg== 1'b1  && !Mstall_IM)begin

        case (curr_state)
            STRONG_TAKEN:begin
                if( true_branch==1 && branch_sel_Dy_reg==2'b01)begin
          
                    next_state = STRONG_TAKEN;
                end
                // else if(branch_sel_Dy_reg ==1 && true_branch == 0 && !Mstall_IM)begin
                //     next_state = CORRECT;
                // end
                // else if(branch_sel_Dy_reg == 0 && true_branch == 1 && !Mstall_IM)begin
                //     next_state = CORRECT;
                // end
                else begin
      
                    next_state = WEAK_TAKEN;
                end
            end
            WEAK_TAKEN:begin
                if( true_branch==1 && branch_sel_Dy_reg==2'b01)begin
                
                    next_state = STRONG_TAKEN;
                end
                // else if(branch_sel_Dy_reg ==1 && true_branch == 0 && !Mstall_IM)begin
                //     next_state = CORRECT;
                // end
                // else if(branch_sel_Dy_reg == 0 && true_branch == 1 && !Mstall_IM)begin
                //     next_state = CORRECT;
                // end
                else begin
                
                    next_state = WEAK_NOT_TAKEN;
                end
            end
            WEAK_NOT_TAKEN:begin
                if( true_branch==1&&branch_sel_Dy_reg==2'b00)begin

                    next_state = WEAK_TAKEN;
                end
                // else if(branch_sel_Dy_reg ==1 && true_branch == 0 && !Mstall_IM)begin
                //     next_state = CORRECT;
                // end
                // else if(branch_sel_Dy_reg == 0 && true_branch == 1 && !Mstall_IM)begin
                //     next_state = CORRECT;
                // end
                else begin
                
                    next_state = STRONG_NOT_TAKEN;
                end
            end
            STRONG_NOT_TAKEN:begin
                if( true_branch==1 &&branch_sel_Dy_reg==2'b00)begin

                    next_state = WEAK_NOT_TAKEN;
                end
                // else if(branch_sel_Dy_reg ==1 && true_branch == 0 && !Mstall_IM)begin
                //     next_state = CORRECT;
                // end
                // else if(branch_sel_Dy_reg == 0 && true_branch == 1 && !Mstall_IM)begin
                //     next_state = CORRECT;
                // end
                else begin            
                    next_state = STRONG_NOT_TAKEN;
                end
            end 

            // default: 
            endcase
    end 
    else if(curr_state == CORRECT)begin
        next_state = STRONG_TAKEN;
    end
    else begin
        next_state = curr_state;
    end

end
//============== NEXT STATE LOGIC ============== //

// ==================== CSR ======================= //
logic [1:0] csr_sel ;
assign csr_sel = {branch_sel_Dy_reg[0],true_branch};
always_comb begin
    // if(branch_sel_Dy_reg == 2'b01 && true_branch == 0) B_branch_count = 2'd0;
    // else if(branch_sel_Dy_reg == 2'b01 && true_branch == 1) B_branch_count = 2'd1;
    // else if(branch_sel_Dy_reg == 2'b00 && true_branch == 0) B_branch_count = 2'd1;
    // else if(branch_sel_Dy_reg == 2'b00 && true_branch == 1) B_branch_count = 2'd1;
    // else   
    if(branch_btype_reg == B_Branch)begin                                              
    //  case (csr_sel) //branch_btype_reg[1]
    //     2'b00:B_branch_count = 2'd0;
    //     2'b01:B_branch_count = 2'd0; // 1
    //     2'b10:B_branch_count = 2'd2; // 2
    //     2'b11:B_branch_count = 2'd1; // 3 
    //     // default: B_branch_count = 2'd3;
    // endcase 
        if(branch_sel_Dy_t_nt_reg == 2'b01 && true_branch == 0) B_branch_count = 2'd2; // jump but not jump
        else if(branch_sel_Dy_t_nt_reg == 2'b01 && true_branch == 1) B_branch_count = 2'd2;//jump and jump
        else if(branch_sel_Dy_t_nt_reg == 2'b00 && true_branch == 0) B_branch_count = 2'd2;// not jump and not jump
        else if(branch_sel_Dy_t_nt_reg == 2'b00 && true_branch == 1) B_branch_count = 2'd2;//not jump but jump
        else B_branch_count = 2'd2;
        //     if(branch_sel_Dy_t_nt_reg == 2'b01 ) B_branch_count = 2'd2; // jump but not jump
        // else if(branch_sel_Dy_t_nt_reg == 2'b01 ) B_branch_count = 2'd2;//jump and jump
        // else if(branch_sel_Dy_t_nt_reg == 2'b00 ) B_branch_count = 2'd2;// not jump and not jump
        // else if(branch_sel_Dy_t_nt_reg == 2'b00 ) B_branch_count = 2'd2;//not jump but jump
        // else B_branch_count = 2'd2;

    end
    else begin
        B_branch_count = 2'd3;
    end  
end
//=================== CSR ======================== //

// ================== UPDATE correct_pc & branch_btype_reg ================== //

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
            // correct_pc <= 32'b0;
            branch_btype_reg <= 2'b0;
    end
    else begin 
            // correct_pc <= pc + 4;
        if(Dy_B_branch_flag)
            branch_btype_reg <= B_Branch; // B_Branch = 2'b10
        else begin
            branch_btype_reg <= 2'b0;
        end
    end
end
//============== OUTPUT LOGIC ============== //
always_comb begin // B_branch
    branch_sel_Dy = pc_4;// for synthesize avoid latch
    if(Dy_B_branch_flag == 1'b1  && !Mstall_IM)begin //&& branch_sel_Dy_reg != 2'd2
        
        case (curr_state)
            STRONG_TAKEN:begin
                branch_sel_Dy = pc_imm; // pc_imm == 01
            end
            WEAK_TAKEN:begin
                branch_sel_Dy = pc_imm;
            end
            WEAK_NOT_TAKEN: begin
                branch_sel_Dy = pc_4; // pc_4 == 00
            end
            STRONG_NOT_TAKEN: begin
                branch_sel_Dy = pc_4;
            end
        endcase
    end
    else begin
        if(branch_sel_Dy_reg ==1 && true_branch == 0 && !Mstall_IM)begin
            branch_sel_Dy = correct_pc_sel;
        end
        else if(branch_sel_Dy_reg == 0 && true_branch == 1 && !Mstall_IM)begin
            branch_sel_Dy = correct_pc_sel;
        end
 
        else 
        branch_sel_Dy = pc_4;//(curr_state==STRONG_TAKEN ||curr_state == WEAK_TAKEN) ? pc_imm : pc_4; // j types & non-branch
            


    end
end


endmodule
// branch_sel_dy has three type below
// localparam [1:0] pc_4 = 2'b00,
//                  pc_imm = 2'b01,
//                  correct_pc_sel = 2'b10;
//                 //  pc_imm_rs1 = 2'b10;
// //============================================
// localparam [1:0] N_Branch = 2'b00,
//                  JAL_Branch = 2'b01, 
//                  B_Branch = 2'b10,
//                  J_Branch = 2'b11;

// // ============== parameter ============== //
// localparam [1:0] STRONG_TAKEN       = 2'b00,
//                  WEAK_TAKEN         = 2'b01,
//                  WEAK_NOT_TAKEN     = 2'b10,
//                  STRONG_NOT_TAKEN   = 2'b11;
// logic [1:0] curr_state, next_state;
// logic  [1:0]branch_btype_reg; // store the type of branch instruction
// // logic [1:0] branch_sel_Dy_reg;


// logic [`DATA_WIDTH-1:0] correct_pc_4,correct_pc_b;
// // logic [1:0] branch_sel_Dy_t_nt_reg;

// logic [31:0]pc_reg;

// always_ff @(posedge clk or posedge rst) begin
//     if(rst)begin
//         BB_counter <= 2'b0;
//         pc_reg <= 32'b0; // 9/28 To avoid lw-use make BB_counter miscount
//     end
//     else if(Dy_B_branch_flag==1 && pc!=pc_reg)begin
//         BB_counter <= BB_counter + 1;
//         pc_reg <= pc;
//     end
//     else begin
//         BB_counter <= 0;
//         pc_reg <=0;
//     end
// end

// assign Btype_pc_imm = pc + imm; // Btype address to IF 

// always_ff @(posedge clk or posedge rst) begin
//     if(rst) begin
//         Dy_B_branch_flag_reg <= 0;
//         branch_sel_Dy_reg <= 0;
//     end

//     else begin
//         Dy_B_branch_flag_reg<=Dy_B_branch_flag;
//         branch_sel_Dy_reg <= branch_sel_Dy;
//     end
    
// end

// always_ff @(posedge clk or posedge rst) begin 
//     if(rst)begin
//         branch_sel_Dy_t_nt_reg <= 2'b0;
//     end

//     else begin
//         branch_sel_Dy_t_nt_reg <= branch_sel_Dy;
//         // if(branch_sel_Dy==2'b00 || branch_sel_Dy==2'b01)
//         //    branch_sel_Dy_t_nt_reg <=branch_sel_Dy;
//         // else 
//         //      branch_sel_Dy_t_nt_reg <= 2'b0;
//     end
// end

// // ========
// always_comb begin
//     if(Dy_B_branch_flag == 1 && Dy_B_branch_flag_reg == 1)
//         correct_pc_BB_flag = 1;
//     else 
//         correct_pc_BB_flag = 0;
// end

// always_ff @(posedge clk or posedge rst) begin 
//     if(rst)begin
//         correct_pc_b <= 0;
//         correct_pc_4 <= 0;
//     end
//     // else if(Dy_B_branch_flag ==1 && branch_sel_Dy_reg==1)begin
//     //     correct_pc_4 <= correct_pc_4;
//     // end
//     else if(Dy_B_branch_flag )begin // if btype run to ID stage remember pc+imm and pc
//         correct_pc_b <= pc + imm; 
//         correct_pc_4 <= pc + 8;
//     end
//     else begin
//         correct_pc_b <= 0;
//         correct_pc_4 <= 0;
//     end
    
// end
// // assign correct_pc = (fix_signal&&true_branch) ? correct_pc_b : correct_pc_4;

// always_comb begin // When btype run to exe stage chose the right pc
//     if(branch_sel_Dy_reg[1] ==1 && true_branch == 0)begin
//         correct_pc = correct_pc_4; 
   
//     end
//     else if(branch_sel_Dy_reg[1] == 0 && true_branch == 1)begin
//         correct_pc = correct_pc_b;

//     end
//     else begin
//         correct_pc = correct_pc_4;

//     end

// end



// // ===================== to hazard for branch flush ===================== // 
//     always_ff @(posedge clk or posedge rst)begin
        
//         if(rst) by_Btype <= 0;
//         else if(Dy_B_branch_flag)begin //2
//             by_Btype <= 1;   
//         end
//         else begin //0,1,3
//             by_Btype <=0;
//         end

//     end
// // ===================== to hazard for branch flush ===================== // 

// always_ff @(posedge clk or posedge rst ) begin
//     if(rst) curr_state <= STRONG_TAKEN; // initial state not taken)
//     else if(!Mstall_IM) curr_state <= next_state;
// end
// // ===================== to hazard for branch flush ===================== // 

// //============== NEXT STATE LOGIC ============== //
// // b branch 不能把 id exe flush掉，這樣會算不出zeroflag ??
 

// always_comb begin
//     if( Dy_B_branch_flag_reg== 1'b1  && !Mstall_IM)begin
//         case (curr_state)
//             STRONG_TAKEN:begin
//                 if( true_branch==1 && branch_sel_Dy_reg==2'b01)begin
          
//                     next_state = STRONG_TAKEN;
//                 end
//                 else begin
      
//                     next_state = WEAK_TAKEN;
//                 end
//             end
//             WEAK_TAKEN:begin
//                 if( true_branch==1 && branch_sel_Dy_reg==2'b01)begin
                
//                     next_state = STRONG_TAKEN;
//                 end
//                 else begin
                
//                     next_state = WEAK_NOT_TAKEN;
//                 end
//             end
//             WEAK_NOT_TAKEN:begin
//                 if( true_branch==1&&branch_sel_Dy_reg==2'b00)begin

//                     next_state = WEAK_TAKEN;
//                 end
//                 else begin
                
//                     next_state = STRONG_NOT_TAKEN;
//                 end
//             end
//             STRONG_NOT_TAKEN:begin
//                 if( true_branch==1 &&branch_sel_Dy_reg==2'b00)begin

//                     next_state = WEAK_NOT_TAKEN;
//                 end
//                 else begin
                
//                     next_state = STRONG_NOT_TAKEN;
//                 end
//             end 
//             // default: 
//             endcase
//     end 
//     else begin
//         next_state = curr_state;
//     end

// end
// //============== NEXT STATE LOGIC ============== //

// // ==================== CSR ======================= //
// logic [1:0] csr_sel ;
// assign csr_sel = {branch_sel_Dy_reg[0],true_branch};
// always_comb begin
//     // if(branch_sel_Dy_reg == 2'b01 && true_branch == 0) B_branch_count = 2'd0;
//     // else if(branch_sel_Dy_reg == 2'b01 && true_branch == 1) B_branch_count = 2'd1;
//     // else if(branch_sel_Dy_reg == 2'b00 && true_branch == 0) B_branch_count = 2'd1;
//     // else if(branch_sel_Dy_reg == 2'b00 && true_branch == 1) B_branch_count = 2'd1;
//     // else   
//     if(branch_btype_reg == B_Branch)begin                                              
//     //  case (csr_sel) //branch_btype_reg[1]
//     //     2'b00:B_branch_count = 2'd0;
//     //     2'b01:B_branch_count = 2'd0; // 1
//     //     2'b10:B_branch_count = 2'd2; // 2
//     //     2'b11:B_branch_count = 2'd1; // 3 
//     //     // default: B_branch_count = 2'd3;
//     // endcase 
//         if(branch_sel_Dy_t_nt_reg == 2'b01 && true_branch == 0) B_branch_count = 2'd2; // jump but not jump
//         else if(branch_sel_Dy_t_nt_reg == 2'b01 && true_branch == 1) B_branch_count = 2'd2;//jump and jump
//         else if(branch_sel_Dy_t_nt_reg == 2'b00 && true_branch == 0) B_branch_count = 2'd2;// not jump and not jump
//         else if(branch_sel_Dy_t_nt_reg == 2'b00 && true_branch == 1) B_branch_count = 2'd2;//not jump but jump
//         else B_branch_count = 2'd2;
//         //     if(branch_sel_Dy_t_nt_reg == 2'b01 ) B_branch_count = 2'd2; // jump but not jump
//         // else if(branch_sel_Dy_t_nt_reg == 2'b01 ) B_branch_count = 2'd2;//jump and jump
//         // else if(branch_sel_Dy_t_nt_reg == 2'b00 ) B_branch_count = 2'd2;// not jump and not jump
//         // else if(branch_sel_Dy_t_nt_reg == 2'b00 ) B_branch_count = 2'd2;//not jump but jump
//         // else B_branch_count = 2'd2;

//     end
//     else begin
//         B_branch_count = 2'd3;
//     end  
// end
// //=================== CSR ======================== //

// // ================== UPDATE correct_pc & branch_btype_reg ================== //

// always_ff @(posedge clk or posedge rst) begin
//     if(rst) begin
//             // correct_pc <= 32'b0;
//             branch_btype_reg <= 2'b0;
//     end
//     else begin 
//             // correct_pc <= pc + 4;
//         if(Dy_B_branch_flag)
//             branch_btype_reg <= B_Branch; // B_Branch = 2'b10
//         else begin
//             branch_btype_reg <= 2'b0;
//         end
//     end
// end
// //============== OUTPUT LOGIC ============== //
// always_comb begin // B_branch
//     if(Dy_B_branch_flag == 1'b1  && !Mstall_IM)begin //&& branch_sel_Dy_reg != 2'd2
//         case (curr_state)
//             STRONG_TAKEN:begin
//                 branch_sel_Dy = pc_imm; // pc_imm == 01
//             end
//             WEAK_TAKEN:begin
//                 branch_sel_Dy = pc_imm;
//             end
//             WEAK_NOT_TAKEN: begin
//                 branch_sel_Dy = pc_4; // pc_4 == 00
//             end
//             STRONG_NOT_TAKEN: begin
//                 branch_sel_Dy = pc_4;
//             end
//         endcase
//     end
//     else begin

//         if(branch_sel_Dy_reg ==1 && true_branch == 0 && !Mstall_IM)begin
//             branch_sel_Dy = correct_pc_sel;
//         end
//         else if(branch_sel_Dy_reg == 0 && true_branch == 1 && !Mstall_IM)begin
//             branch_sel_Dy = correct_pc_sel;
//         end
//         else begin
//             branch_sel_Dy = pc_4; // j types & non-branch
//         end
//     end
// end





// endmodule