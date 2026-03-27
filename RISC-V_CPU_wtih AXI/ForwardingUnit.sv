module ForwardingUnit (
    
    input logic [4:0]   ID_rs1_addr,    //logic doesn't matter
    input logic [4:0]   ID_rs2_addr,
    input logic [4:0]   EXE_rd_addr,  // EXE/MEM REGISTER
    input logic [4:0]   MEM_rd_addr, //  MEM/WB  REGISTER 

    input wire          EXE_MEM_fwd_write,
    input wire          MEM_WB_fwd_write,
    // ======== FLOAT POINT =========   //

    input wire          EXE_MEM_fwd_FP_write,
    input wire          MEM_WB_fwd_FP_write,

    input wire          B_Branch_Fd,
    output reg  [1:0]   FWD_rs1_sel,
    output reg  [1:0]   FWD_rs2_sel,
// ============ FLOAT POINT ========== //
    output reg  [1:0]   FWD_rs1_FP_sel,
    output reg  [1:0]   FWD_rs2_FP_sel 



);

always_comb begin // RS1 select ， 要寫滿 ?
    if(EXE_MEM_fwd_write && EXE_rd_addr == ID_rs1_addr)begin // &&!B_Branch_Fd
        FWD_rs1_sel = 2'b01;
    end
    // else if(EXE_MEM_fwd_write && EXE_rd_addr == ID_rs1_addr && B_Branch_Fd)begin
    //     FWD_rs1_sel = 2'b00;
    // end
    else if(MEM_WB_fwd_write && MEM_rd_addr == ID_rs1_addr)begin
        FWD_rs1_sel = 2'b10;        
    end
    else begin
        FWD_rs1_sel = 2'b00;
    end
    
end

always_comb begin // RS2 select
    if(EXE_MEM_fwd_write && EXE_rd_addr == ID_rs2_addr )begin
        FWD_rs2_sel = 2'b01;
    end
    else if(MEM_WB_fwd_write && MEM_rd_addr == ID_rs2_addr)begin
        FWD_rs2_sel = 2'b10;

    end
    else begin
        FWD_rs2_sel = 2'b00;
    end
end

// =============== FLOAT POINT ===================== //
    always_comb begin
        if(EXE_MEM_fwd_FP_write && (EXE_rd_addr == ID_rs1_addr))begin
            FWD_rs1_FP_sel  =   2'b01;
        end
        else if(MEM_WB_fwd_FP_write && (MEM_rd_addr ==  ID_rs1_addr)) begin
            FWD_rs1_FP_sel  =   2'b10;
        end
        else begin
            FWD_rs1_FP_sel  =   2'b00;
        end
    end

    always_comb begin
        if (EXE_MEM_fwd_FP_write && (EXE_rd_addr    ==  ID_rs2_addr)) begin
            FWD_rs2_FP_sel  =   2'b01;
        end
        else if (MEM_WB_fwd_FP_write && (MEM_rd_addr    ==  ID_rs2_addr)) begin
            FWD_rs2_FP_sel  =   2'b10;
        end
        else begin
            FWD_rs2_FP_sel  =   2'b00;
        end
    end
endmodule