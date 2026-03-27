`include "SRAM_slave.sv"
`include "../include/AXI_define.svh"
`include "../include/CPU_define.svh"

module SRAM_wrapper (
    input ACLK,ARESETn,

    // AXI RADDR
    input   [`AXI_IDS_BITS-1:0]         ARID_S,
    input   [`AXI_ADDR_BITS-1:0]        ARADDR_S,
    input   [`AXI_LEN_BITS-1:0]         ARLEN_S,
    input   [`AXI_SIZE_BITS-1:0]        ARSIZE_S,
    input   [1:0]                       ARBURST_S,
    input                               ARVALID_S,
    output  logic                       ARREADY_S,

    // AXI RDATA
    output  logic [`AXI_DATA_BITS-1:0]  RDATA_S,
    output  logic [`AXI_IDS_BITS-1:0]   RID_S,
    output  logic [1:0]                 RRESP_S,
    output  logic                       RLAST_S,
    output  logic                       RVALID_S,
    input                               RREADY_S,

    // AXI WADDR
    input   [`AXI_IDS_BITS-1:0]         AWID_S,
    input   [`AXI_ADDR_BITS-1:0]        AWADDR_S,
    input   [`AXI_SIZE_BITS-1:0]        AWSIZE_S,
    input   [`AXI_LEN_BITS-1:0]         AWLEN_S,
    input   [1:0]                       AWBURST_S,
    input                               AWVALID_S,

    output  logic                       AWREADY_S,

    // AXI WDATA
    input   [`AXI_DATA_BITS-1:0]        WDATA_S,
    input   [`AXI_STRB_BITS-1:0]        WSTRB_S,
    input                               WVALID_S,
    input                               WLAST_S,
    output  logic                       WREADY_S,

    // AXI WRESP
    output   logic                           BVALID_S,
    output   logic[1:0]                       BRESP_S,
    output   logic[`AXI_IDS_BITS-1:0]          BID_S,
    input                                     BREADY_S
);
    
logic [1:0] curr_state;

localparam  ADDR = 2'd0,
            RDATA = 2'd1,
            WDATA = 2'd2,
            WRESP = 2'd3; 

logic [`AXI_DATA_BITS -1:0]   BWEB;
logic [`MEM_ADDR_LEN  -1:0]   A;
logic [`AXI_DATA_BITS -1:0]   DI;
logic [`AXI_DATA_BITS -1:0]   DO;
logic                         WEB;
logic                         CEB;

always_comb begin
    
    if(curr_state == RDATA || curr_state == WDATA)
        CEB = 1'b0; // active low
    else if(curr_state == ADDR)
        CEB = 1'b0;
    else 
        CEB = 1'b1;
end
SRAM_slave SRAM_slave_inst (
    .ACLK(ACLK),
    .ARESETn(ARESETn),
    // R_addr
    .AR_ID_sla(ARID_S),
    .AR_addr_sla(ARADDR_S),
    .AR_len_sla(ARLEN_S),
    .AR_size_sla(ARSIZE_S),
    .AR_burst_sla(ARBURST_S),
    .AR_valid_sla(ARVALID_S),
    .AR_ready_sla(ARREADY_S),
    // R_data
    .R_ID_sla(RID_S),
    .R_data_sla(RDATA_S),
    .R_resp_sla(RRESP_S),
    .R_last_sla(RLAST_S),
    .R_valid_sla(RVALID_S),
    .R_ready_sla(RREADY_S),
    // W_resp
    .B_resp_sla(BRESP_S),
    .B_ID_sla(BID_S),
    .B_valid_sla(BVALID_S),
    .B_ready_sla(BREADY_S),
    // W_data  
    .W_data_sla(WDATA_S),
    .W_last_sla(WLAST_S),
    .W_strb_sla(WSTRB_S),
    .W_valid_sla(WVALID_S),
    .W_ready_sla(WREADY_S),

    // W_addr  
    .AW_addr_sla(AWADDR_S),
    .AW_ID_sla(AWID_S),
    .AW_len_sla(AWLEN_S),
    .AW_valid_sla(AWVALID_S),
    .AW_ready_sla(AWREADY_S),
    .AW_size_sla(AWSIZE_S),
    .AW_burst_sla(AWBURST_S),

    // TO MEMOEY //////////////////////////////////
    .DO(DO),
    .DI(DI),
    .A(A),
    .BWEB(BWEB),
    .WEB(WEB),

    .curr_state(curr_state)

);

    //SRAM
    TS1N16ADFPCLLLVTA512X45M4SWSHOD i_SRAM (
      .SLP      (1'b0),
      .DSLP     (1'b0),
      .SD       (1'b0),
      .PUDELAY  (),
      .CLK      (ACLK),
      .CEB      (CEB),
      .WEB      (WEB),
      .A        (A),
      .D        (DI),
      .BWEB     (BWEB),
      .RTSEL    (2'b01),
      .WTSEL    (2'b01),
      .Q        (DO)
);

endmodule