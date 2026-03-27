`include "CPU.sv"
`include "Master.sv"
module CPU_wrapper (
    input ACLK,ARESETn,

    //M0 ======

   //RDATA
    input [`AXI_DATA_BITS -1:0]         RDATA_M0,
    input [`AXI_ID_BITS   -1:0]         RID_M0,
    input [1:0]                         RRESP_M0,
    input                               RLAST_M0,
    input                               RVALID_M0,
    output logic                        RREADY_M0,

    //RADDR
    output logic [1:0]                  ARBURST_M0,
    output logic [`AXI_ADDR_BITS -1:0]  ARADDR_M0,
    output logic [`AXI_ID_BITS   -1:0]  ARID_M0,
    output logic [`AXI_SIZE_BITS -1:0]  ARSIZE_M0,
    output logic [`AXI_LEN_BITS  -1:0]  ARLEN_M0,
    output logic                        ARVALID_M0,
    input                               ARREADY_M0,
    //WADDR
    output logic [1:0]                  AWBURST_M0,
    output logic [`AXI_ADDR_BITS -1:0]  AWADDR_M0,
    output logic [`AXI_ID_BITS   -1:0]  AWID_M0,
    output logic [`AXI_SIZE_BITS -1:0]  AWSIZE_M0,
    output logic [`AXI_LEN_BITS  -1:0]  AWLEN_M0,
    output logic                        AWVALID_M0,
    input                               AWREADY_M0,

    //WDATA
    output logic [`AXI_DATA_BITS -1:0]  WDATA_M0,
    output logic [`AXI_STRB_BITS -1:0]  WSTRB_M0,
    output logic                        WVALID_M0,
    output logic                        WLAST_M0,
    input                               WREADY_M0,

    //WRESP
    input                               BVALID_M0,
    input [1:0]                         BRESP_M0,
    input [`AXI_ID_BITS -1:0]           BID_M0,
    output                              BREADY_M0,

    //M1==============

    input [`AXI_DATA_BITS -1:0]         RDATA_M1,
    input [`AXI_ID_BITS   -1:0]         RID_M1,
    input [1:0]                         RRESP_M1,
    input                               RLAST_M1,
    input                               RVALID_M1,
    output logic                        RREADY_M1,
    //RADDR
    output logic [1:0]                  ARBURST_M1,
    output logic [`AXI_ADDR_BITS -1:0]  ARADDR_M1,
    output logic [`AXI_ID_BITS   -1:0]  ARID_M1,
    output logic [`AXI_SIZE_BITS -1:0]  ARSIZE_M1,
    output logic [`AXI_LEN_BITS  -1:0]  ARLEN_M1,
    output logic                        ARVALID_M1,
    input                               ARREADY_M1,
    //WADDR
    output logic [1:0]                  AWBURST_M1,
    output logic [`AXI_ADDR_BITS -1:0]  AWADDR_M1,
    output logic [`AXI_ID_BITS   -1:0]  AWID_M1,
    output logic [`AXI_SIZE_BITS -1:0]  AWSIZE_M1,
    output logic [`AXI_LEN_BITS  -1:0]  AWLEN_M1,
    output logic                        AWVALID_M1,
    input                               AWREADY_M1,
    //WDATA
    output logic [`AXI_DATA_BITS -1:0]  WDATA_M1,
    output logic [`AXI_STRB_BITS -1:0]  WSTRB_M1,
    output logic                        WVALID_M1,
    output logic                        WLAST_M1,
    input                               WREADY_M1,
    //WRESP
    input                               BVALID_M1,
    input [1:0]                         BRESP_M1,
    input [`AXI_ID_BITS -1:0]           BID_M1,
    output                              BREADY_M1
);
// ================== WIRES ======================//
    logic [`DATA_WIDTH -1:0]    W_IM_IF_instr;
    logic                       W_IM_stall;
    logic                       W_IM_WEB;
    logic [`AXI_DATA_BITS -1:0] W_IM_addr;

    //Data Memory
    logic                       W_DM_WEB;
    logic [`DATA_WIDTH -1:0]    W_DM_BWEB;
    logic                       W_DM_read_sel;
    logic                       W_DM_write_sel;
    logic [`AXI_ADDR_BITS -1:0] W_DM_addr;
    logic [`AXI_DATA_BITS -1:0] W_DM_Din;
    logic [`AXI_DATA_BITS -1:0] W_DM_Dout;
    logic                       W_DM_stall;

    logic                       delay_ARESETn,delay_ARESETn_cpu;
    logic                       lock_DM;
    //always_ff @(posedge ACLK or negedge ARESETn) begin
      //  if(!ARESETn)
        //    delay_ARESETn <= ARESETn;
        //else
          //  delay_ARESETn <= ARESETn;
    //end
    
    always_ff@(posedge ACLK)begin
      if(!ARESETn)
        delay_ARESETn <= 1'b0;
      else
        delay_ARESETn <= 1'b1;
    end

    always_ff@(posedge ACLK)begin
      if(ARESETn)
        delay_ARESETn_cpu <= 1'b1;
      else
        delay_ARESETn_cpu <= 1'b0;
    end

CPU CPU_inst(
    .clk(ACLK),
    .rst(!delay_ARESETn_cpu),
    
    //Instruction Memory
    .IM_IF_instr(W_IM_IF_instr),
    .IM_stall(W_IM_stall),
    .IM_WEB(W_IM_WEB),
    .IM_addr(W_IM_addr),

    //Data Memory
    .DM_WEB(W_DM_WEB),
    .DM_BWEB(W_DM_BWEB),
    .DM_read_sel(W_DM_read_sel),
    .DM_write_sel(W_DM_write_sel),
    .DM_addr(W_DM_addr),
    .DM_Din(W_DM_Din),
    .DM_Dout(W_DM_Dout),
    .DM_stall(W_DM_stall)
);

always_ff @(posedge ACLK) begin
  if(~ARESETn)begin
    lock_DM <= 1'b0;
  end
  else begin
    lock_DM <=(~W_IM_stall) ? 1'b0 : (W_IM_stall & ~ W_DM_stall) ? 1'b1 : lock_DM;
  end
end
Master M1_DM(
    .ACLK(ACLK),.ARESETn(delay_ARESETn),
    //RDATA
    .M_R_data(RDATA_M1),
    .M_R_ID(RID_M1),
    .M_R_resp(RRESP_M1),
    .M_R_last(RLAST_M1),
    .M_R_valid(RVALID_M1),
    .M_R_ready(RREADY_M1),

    //RADDR
    .M_AR_burst(ARBURST_M1),
    .M_AR_addr(ARADDR_M1),
    .M_AR_ID(ARID_M1),
    .M_AR_size(ARSIZE_M1),
    .M_AR_len(ARLEN_M1),
    .M_AR_valid(ARVALID_M1),
    .M_AR_ready(ARREADY_M1),
    //WADDR
    .M_AW_burst(AWBURST_M1),
    .M_AW_addr(AWADDR_M1),
    .M_AW_ID(AWID_M1),
    .M_AW_size(AWSIZE_M1),
    .M_AW_len(AWLEN_M1),
    .M_AW_valid(AWVALID_M1),
    .M_AW_ready(AWREADY_M1),

    //WDATA
    .M_W_data(WDATA_M1),
    .M_W_strb(WSTRB_M1),
    .M_W_valid(WVALID_M1),
    .M_W_last(WLAST_M1),
    .M_W_ready(WREADY_M1),

    //WRESP
    .M_B_valid(BVALID_M1),
    .M_B_resp(BRESP_M1),
    .M_B_ID(BID_M1),
    .M_B_ready(BREADY_M1),

    // CPU
    .M_web(W_DM_WEB),
    .M_DM_read_sel(W_DM_read_sel & ~lock_DM),
    .M_DM_write_sel(W_DM_write_sel & ~lock_DM),
    .M_Memory_BWEB(W_DM_BWEB),
    .M_Memory_addr(W_DM_addr), 
    .M_Memory_Din(W_DM_Din),
    .M_Memory_Dout(W_DM_Dout),
    .M_stall(W_DM_stall)

);

Master M0_IM(
    .ACLK(ACLK),.ARESETn(delay_ARESETn),
    //RDATA
    .M_R_data(RDATA_M0),
    .M_R_ID(RID_M0),
    .M_R_resp(RRESP_M0),
    .M_R_last(RLAST_M0),
    .M_R_valid(RVALID_M0),
    .M_R_ready(RREADY_M0),

    //RADDR
    .M_AR_burst(ARBURST_M0),
    .M_AR_addr(ARADDR_M0),
    .M_AR_ID(ARID_M0),
    .M_AR_size(ARSIZE_M0),
    .M_AR_len(ARLEN_M0),
    .M_AR_valid(ARVALID_M0),
    .M_AR_ready(ARREADY_M0),
    //WADDR
    .M_AW_burst(AWBURST_M0),
    .M_AW_addr(AWADDR_M0),
    .M_AW_ID(AWID_M0),
    .M_AW_size(AWSIZE_M0),
    .M_AW_len(AWLEN_M0),
    .M_AW_valid(AWVALID_M0),
    .M_AW_ready(AWREADY_M0),

    //WDATA
    .M_W_data(WDATA_M0),
    .M_W_strb(WSTRB_M0),
    .M_W_valid(WVALID_M0),
    .M_W_last(WLAST_M0),
    .M_W_ready(WREADY_M0),

    //WRESP
    .M_B_valid(BVALID_M0),
    .M_B_resp(BRESP_M0),
    .M_B_ID(BID_M0),
    .M_B_ready(BREADY_M0),

    // CPU
    .M_web(W_IM_WEB),
    .M_DM_read_sel(1'b1),
    .M_DM_write_sel(1'b0),
    .M_Memory_BWEB(32'hffff_ffff),
    .M_Memory_addr(W_IM_addr), 
    .M_Memory_Din(32'b0),
    .M_Memory_Dout(W_IM_IF_instr),
    .M_stall(W_IM_stall)

);
endmodule