module CSR (
    input clk, rst,
    input   logic   [`FUNCTION_7 -1:0]     CSR_op,
    input   logic   [`FUNCTION_3 -1:0]  function_3,
    input   logic   [`DATA_WIDTH -1:0]  rs1,
    input   logic   [`DATA_WIDTH -1:0]  imm_csr,
    input   logic   [1:0]               branch_signal_csr,
    input   logic                       lw_use,
    input   logic   [1:0]               branch_b,
    input   logic   [1:0]               branch_sel_Dy_t_nt_csr,
    input   logic                       true_branch_csr,
    input   logic   [1:0]                  BB_counter_csr,
    input   logic                       branch_flag_csr,
    input   logic                       branch_flag_reg_csr,
    input   logic   [`OP_CODE-1:0]      opcode_csr,
    input                               IM_stall_csr,
    input                               DM_stall_csr,
    output  logic   [`DATA_WIDTH -1:0]  csr_rd_data    
);
    logic                         stall;
    assign  stall = IM_stall_csr || DM_stall_csr;
    reg     [`CSR_REG_WIDTH -1:0] count_instret;
    reg     [`CSR_REG_WIDTH -1:0] count_cycle;

    //  ================= count instra ================= //

    localparam [1:0] N_Branch   =   2'b00,
                     JAL_Branch =   2'b01,
                     B_Branch   =   2'b10,
                     J_Branch   =   2'b11;

    wire a_1, a_2, a_3, a_4, a_5;
    logic [1:0] count_delay;
    assign a_1 = branch_signal_csr == J_Branch || branch_signal_csr == JAL_Branch;
    assign a_2 = branch_signal_csr == B_Branch && branch_sel_Dy_t_nt_csr == 2'b00 && true_branch_csr == 1'b1;
    assign a_3 = branch_signal_csr == B_Branch && branch_sel_Dy_t_nt_csr == 2'b00 && true_branch_csr == 1'b0;
    assign a_4 = branch_signal_csr == B_Branch && branch_sel_Dy_t_nt_csr == 2'b01 && true_branch_csr == 1'b0 && branch_flag_reg_csr==1'b1;
    assign a_5 = branch_signal_csr == B_Branch && branch_sel_Dy_t_nt_csr == 2'b01 && true_branch_csr == 1'b1;

always_ff @(posedge clk or posedge rst) begin 
    if(rst)begin
        count_delay <= 2'b0;
    end
    else begin
        if(count_delay == 2'd2 || stall)begin
            count_delay <= count_delay;
        end
        else begin
            count_delay <= count_delay + 2'b1;
        end
    end
end

always_ff @(posedge clk or posedge rst) begin
    if(rst)begin
        count_cycle     <=  0;
        count_instret   <=  0;
    end
    else begin
        count_cycle     <=  count_cycle + 1;

        if(count_delay >= 2 && !stall)begin
            if(lw_use)
                count_instret   <=  count_instret;
            // else if(CSR_op == 7'b1101111 || CSR_op == 7'b1100111)begin
            //     count_instret   <=  count_instret -1;
            // end
            // else if(stall)
            //     count_instret <= count_instret;
            else if(a_1)begin
                count_instret   <=  count_instret-1;
            end
            // else if(branch_signal_csr == N_Branch)begin
            //     count_instret <= count_instret + 1;
            // end
             else if(a_2)begin // not taken, B_Branch==2,
                 count_instret <= count_instret-1;
             end
             
             else if(a_3)begin  
                 count_instret <= count_instret+1;
             end
            // else if(branch_signal_csr == B_Branch && branch_sel_Dy_t_nt_csr == 2'b00 && true_branch_csr == 0 && BB_counter_csr==2'd1)begin
            //      count_instret <= count_instret;
            //  end
            //  else if(branch_signal_csr == B_Branch && branch_sel_Dy_t_nt_csr == 2'b01 && true_branch_csr == 0 )begin//&&BB_counter_csr==2'd0 //&&branch_flag_csr==1&&branch_flag_reg_csr==1
            //      count_instret <= count_instret;
            //  end

            // else if(a_4&&branch_flag_csr==0&&branch_flag_reg_csr==1)begin//&&branch_flag_csr==0&&branch_flag_reg_csr==1 BB_counter_csr==1
            //      count_instret <= count_instret;
            //  end

            else if(a_4 && BB_counter_csr==1'b1)begin//&&branch_flag_csr==0&&branch_flag_reg_csr==1 BB_counter_csr==1
                 if( opcode_csr == 7'b1100111) count_instret <= count_instret+1;
                 else count_instret <= count_instret;
             end

            // else if(branch_signal_csr == B_Branch&& branch_sel_Dy_t_nt_csr == 2'b01 && true_branch_csr == 0 && BB_counter_csr==2'd1 &&branch_flag_reg_csr==1&&branch_flag_csr==0)begin//&&branch_flag_csr==0&&branch_flag_reg_csr==1
            //      count_instret <= count_instret+1'b1;
            //  end
             else if(a_5)begin
                 count_instret <= count_instret;
            end
            // else if(branch_signal_csr == B_Branch && branch_sel_Dy_t_nt_csr == 2'b10 && true_branch_csr == 0)begin
            //      count_instret <= count_instret;
            // end
            else begin
                count_instret <= count_instret + 1'b1;



            end
        end
    end 
end

    always_comb begin
        if( | rs1 )
            csr_rd_data = imm_csr;
        else begin
            case (imm_csr[11:0]) // count instr & cycle
                12'hc82:    csr_rd_data =   count_instret[63:32];
                12'hc02:    csr_rd_data =   count_instret[31:0];
                12'hc80:    csr_rd_data =   count_cycle[63:32];
                12'hc00:    csr_rd_data =   count_cycle[31:0]; 
                default:    csr_rd_data =   32'b0;
            endcase
        end
    end
endmodule

// ==================== rd ============================ //

