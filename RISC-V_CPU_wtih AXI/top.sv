`include "../include/AXI_define.svh"
`include "CPU_wrapper.sv"
`include "./AXI/AXI.sv"
`include "../include/CPU_define.svh"
module top (
    input clk,
    input rst
);
    
    //Master to Bus(Mx2B)
    //W channel - Addr
        logic  [`AXI_ID_BITS -1:0]     M0_2B_AWID  ; 
        logic  [`AXI_ADDR_BITS -1:0]   M0_2B_AWAddr ;
        logic  [`AXI_LEN_BITS -1:0]    M0_2B_AWLen  ;
        logic  [`AXI_SIZE_BITS -1:0]   M0_2B_AWSize ;
        logic  [1:0]                   M0_2B_AWBurst;
        logic                          M0_2B_AWValid;
        logic                          M0_2B_AWReady;

        logic  [`AXI_ID_BITS -1:0]     M1_2B_AWID   ;
        logic  [`AXI_ADDR_BITS -1:0]   M1_2B_AWAddr ;
        logic  [`AXI_LEN_BITS -1:0]    M1_2B_AWLen  ;
        logic  [`AXI_SIZE_BITS -1:0]   M1_2B_AWSize ;
        logic  [1:0]                   M1_2B_AWBurst;
        logic                          M1_2B_AWValid;
        logic                          M1_2B_AWReady;
    //W channel - data
        logic  [`AXI_DATA_BITS -1:0]   M0_2B_WData; 
        logic  [`AXI_STRB_BITS -1:0]   M0_2B_WStrb; 
        logic                          M0_2B_WLast; 
        logic                          M0_2B_WValid;
        logic                          M0_2B_WReady;

        logic  [`AXI_DATA_BITS -1:0]   M1_2B_WData; 
        logic  [`AXI_STRB_BITS -1:0]   M1_2B_WStrb; 
        logic                          M1_2B_WLast; 
        logic                          M1_2B_WValid;
        logic                          M1_2B_WReady;
    //W channel - Response
        logic  [`AXI_ID_BITS  -1:0]    M0_2B_BID;
        logic  [1:0]                   M0_2B_BResp;
        logic                          M0_2B_BValid;
        logic                          M0_2B_BReady;
        
        logic  [`AXI_ID_BITS  -1:0]    M1_2B_BID;
        logic  [1:0]                   M1_2B_BResp;
        logic                          M1_2B_BValid;
        logic                          M1_2B_BReady;  
    //R channel - Addr 
        logic  [`AXI_ID_BITS   -1:0]   M0_2B_ARID;
        logic  [`AXI_ADDR_BITS -1:0]   M0_2B_ARAddr;
        logic  [`AXI_LEN_BITS  -1:0]   M0_2B_ARLen;
        logic  [`AXI_SIZE_BITS -1:0]   M0_2B_ARSize;
        logic  [1:0]                   M0_2B_ARBurst;
        logic                          M0_2B_ARValid;
        logic                          M0_2B_ARReady;
        
        logic  [`AXI_ID_BITS   -1:0]   M1_2B_ARID;
        logic  [`AXI_ADDR_BITS -1:0]   M1_2B_ARAddr;
        logic  [`AXI_LEN_BITS  -1:0]   M1_2B_ARLen;
        logic  [`AXI_SIZE_BITS -1:0]   M1_2B_ARSize;
        logic  [1:0]                   M1_2B_ARBurst;
        logic                          M1_2B_ARValid;
        logic                          M1_2B_ARReady;    
    //R channel - data
        logic  [`AXI_ID_BITS   -1:0]   M0_2B_RID;  
        logic  [`AXI_DATA_BITS -1:0]   M0_2B_RData;
        logic  [1:0]                   M0_2B_RResp;
        logic                          M0_2B_RLast;
        logic                          M0_2B_RValid;
        logic                          M0_2B_RReady;

        logic  [`AXI_ID_BITS   -1:0]   M1_2B_RID;  
        logic  [`AXI_DATA_BITS -1:0]   M1_2B_RData;
        logic  [1:0]                   M1_2B_RResp;
        logic                          M1_2B_RLast;
        logic                          M1_2B_RValid;
        logic                          M1_2B_RReady;
    //Bus to Slave (B2Sx)
    //W channel - Addr
        logic  [`AXI_IDS_BITS -1:0]    B2_S0_AWID   ; 
        logic  [`AXI_ADDR_BITS -1:0]   B2_S0_AWAddr ;
        logic  [`AXI_LEN_BITS -1:0]    B2_S0_AWLen  ;
        logic  [`AXI_SIZE_BITS -1:0]   B2_S0_AWSize ;
        logic  [1:0]                   B2_S0_AWBurst;
        logic                          B2_S0_AWValid;
        logic                          B2_S0_AWReady;

        logic  [`AXI_IDS_BITS -1:0]    B2_S1_AWID   ;
        logic  [`AXI_ADDR_BITS -1:0]   B2_S1_AWAddr ;
        logic  [`AXI_LEN_BITS -1:0]    B2_S1_AWLen  ;
        logic  [`AXI_SIZE_BITS -1:0]   B2_S1_AWSize ;
        logic  [1:0]                   B2_S1_AWBurst;
        logic                          B2_S1_AWValid;
        logic                          B2_S1_AWReady;
    //W channel - data
        logic  [`AXI_DATA_BITS -1:0]   B2_S0_WData   ; 
        logic  [`AXI_STRB_BITS -1:0]   B2_S0_WStrb   ; 
        logic                          B2_S0_WLast   ; 
        logic                          B2_S0_WValid;
        logic                          B2_S0_WReady;

        logic  [`AXI_DATA_BITS -1:0]   B2_S1_WData   ; 
        logic  [`AXI_STRB_BITS -1:0]   B2_S1_WStrb   ; 
        logic                          B2_S1_WLast   ; 
        logic                          B2_S1_WValid;
        logic                          B2_S1_WReady;
    //W channel - Response
        logic  [`AXI_IDS_BITS  -1:0]   B2_S0_BID     ;
        logic  [1:0]                   B2_S0_BResp   ;
        logic                          B2_S0_BValid;
        logic                          B2_S0_BReady;
        
        logic  [`AXI_IDS_BITS  -1:0]   B2_S1_BID     ;
        logic  [1:0]                   B2_S1_BResp   ;
        logic                          B2_S1_BValid;
        logic                          B2_S1_BReady;  
    //R channel - Addr 
        logic  [`AXI_IDS_BITS   -1:0]  B2_S0_ARID    ;
        logic  [`AXI_ADDR_BITS -1:0]   B2_S0_ARAddr  ;
        logic  [`AXI_LEN_BITS  -1:0]   B2_S0_ARLen   ;
        logic  [`AXI_SIZE_BITS -1:0]   B2_S0_ARSize  ;
        logic  [1:0]                   B2_S0_ARBurst;
        logic                          B2_S0_ARValid;
        logic                          B2_S0_ARReady;
        
        logic  [`AXI_IDS_BITS   -1:0]  B2_S1_ARID    ;
        logic  [`AXI_ADDR_BITS -1:0]   B2_S1_ARAddr  ;
        logic  [`AXI_LEN_BITS  -1:0]   B2_S1_ARLen   ;
        logic  [`AXI_SIZE_BITS -1:0]   B2_S1_ARSize  ;
        logic  [1:0]                   B2_S1_ARBurst;
        logic                          B2_S1_ARValid;
        logic                          B2_S1_ARReady;    
    //R channel - data
        logic  [`AXI_IDS_BITS   -1:0]  B2_S0_RID     ;  
        logic  [`AXI_DATA_BITS -1:0]   B2_S0_RData   ;
        logic  [1:0]                   B2_S0_RResp   ;
        logic                          B2_S0_RLast   ;
        logic                          B2_S0_RValid;
        logic                          B2_S0_RReady;

        logic  [`AXI_IDS_BITS   -1:0]  B2_S1_RID     ;  
        logic  [`AXI_DATA_BITS -1:0]   B2_S1_RData   ;
        logic  [1:0]                   B2_S1_RResp   ;
        logic                          B2_S1_RLast   ;
        logic                          B2_S1_RValid;
        logic                          B2_S1_RReady;  
        
        //logic                          delay_rst; 
        
        //always_ff@(posedge clk or posedge rst)
          //if(rst)
            //delay_rst <= rst;
          //else
            //delay_rst <= rst;
CPU_wrapper CPU_wrapper_inst(
    .ACLK(clk),.ARESETn(!rst),

    //M0 ======

   //RDATA
    .RDATA_M0(M0_2B_RData),
    .RID_M0(M0_2B_RID),
    .RRESP_M0(M0_2B_RResp),
    .RLAST_M0(M0_2B_RLast),
    .RVALID_M0(M0_2B_RValid),
    .RREADY_M0(M0_2B_RReady),

    //RADDR
    .ARBURST_M0(M0_2B_ARBurst),
    .ARADDR_M0(M0_2B_ARAddr),
    .ARID_M0(M0_2B_ARID),
    .ARSIZE_M0(M0_2B_ARSize),
    .ARLEN_M0(M0_2B_ARLen),
    .ARVALID_M0(M0_2B_ARValid),
    .ARREADY_M0(M0_2B_ARReady),
    //WADDR
    .AWBURST_M0(M0_2B_AWBurst),
    .AWADDR_M0(M0_2B_AWAddr),
    .AWID_M0(M0_2B_AWID),
    .AWSIZE_M0(M0_2B_AWSize),
    .AWLEN_M0(M0_2B_AWLen),
    .AWVALID_M0(M0_2B_AWValid),
    .AWREADY_M0(M0_2B_AWReady),

    //WDATA
    .WDATA_M0(M0_2B_WData),
    .WSTRB_M0(M0_2B_WStrb),
    .WVALID_M0(M0_2B_WValid),
    .WLAST_M0(M0_2B_WLast),
    .WREADY_M0(M0_2B_WReady),

    //WRESP
    .BVALID_M0(M0_2B_BValid),
    .BRESP_M0(M0_2B_BResp),
    .BID_M0(M0_2B_BID),
    .BREADY_M0(M0_2B_BReady),

    //M1==============

    .RDATA_M1(M1_2B_RData),
    .RID_M1(M1_2B_RID),
    .RRESP_M1(M1_2B_RResp),
    .RLAST_M1(M1_2B_RLast),
    .RVALID_M1(M1_2B_RValid),
    .RREADY_M1(M1_2B_RReady),
    //RADDR
    .ARBURST_M1(M1_2B_ARBurst),
    .ARADDR_M1(M1_2B_ARAddr),
    .ARID_M1(M1_2B_ARID),
    .ARSIZE_M1(M1_2B_ARSize),
    .ARLEN_M1(M1_2B_ARLen),
    .ARVALID_M1(M1_2B_ARValid),
    .ARREADY_M1(M1_2B_ARReady),
    //WADDR
    .AWBURST_M1(M1_2B_AWBurst),
    .AWADDR_M1(M1_2B_AWAddr),
    .AWID_M1(M1_2B_AWID),
    .AWSIZE_M1(M1_2B_AWSize),
    .AWLEN_M1(M1_2B_AWLen),
    .AWVALID_M1(M1_2B_AWValid),
    .AWREADY_M1(M1_2B_AWReady),
    //WDATA
    .WDATA_M1(M1_2B_WData),
    .WSTRB_M1(M1_2B_WStrb),
    .WVALID_M1(M1_2B_WValid),
    .WLAST_M1(M1_2B_WLast),
    .WREADY_M1(M1_2B_WReady),
    //WRESP
    .BVALID_M1(M1_2B_BValid),
    .BRESP_M1(M1_2B_BResp),
    .BID_M1(M1_2B_BID),
    .BREADY_M1(M1_2B_BReady)
);

AXI AXI_inst(

	.ACLK(clk),
	.ARESETn(!rst),

	//SLAVE INTERFACE FOR MASTERS
	
	//WRITE ADDRESS
	.AWID_M1(M1_2B_AWID),
	.AWADDR_M1(M1_2B_AWAddr),
	.AWLEN_M1(M1_2B_AWLen),
	.AWSIZE_M1(M1_2B_AWSize),
	.AWBURST_M1(M1_2B_AWBurst),
	.AWVALID_M1(M1_2B_AWValid),
	.AWREADY_M1(M1_2B_AWReady),

	//WRITE DATA
	.WDATA_M1(M1_2B_WData),
	.WSTRB_M1(M1_2B_WStrb),
	.WLAST_M1(M1_2B_WLast),
	.WVALID_M1(M1_2B_WValid),
	.WREADY_M1(M1_2B_WReady),

	//WRITE RESPONSE
	.BID_M1(M1_2B_BID),
	.BRESP_M1(M1_2B_BResp),
	.BVALID_M1(M1_2B_BValid),
	.BREADY_M1(M1_2B_BReady),

	//READ ADDRESS0
	.ARID_M0(M0_2B_ARID),
	.ARADDR_M0(M0_2B_ARAddr),
	.ARLEN_M0(M0_2B_ARLen),
	.ARSIZE_M0(M0_2B_ARSize),
	.ARBURST_M0(M0_2B_ARBurst),
	.ARVALID_M0(M0_2B_ARValid),
	.ARREADY_M0(M0_2B_ARReady),

	//READ DATA0
	.RID_M0(M0_2B_RID),
	.RDATA_M0(M0_2B_RData),
	.RRESP_M0(M0_2B_RResp),
	.RLAST_M0(M0_2B_RLast),
	.RVALID_M0(M0_2B_RValid),
	.RREADY_M0(M0_2B_RReady),

	//READ ADDRESS1
	.ARID_M1(M1_2B_ARID),
	.ARADDR_M1(M1_2B_ARAddr),
	.ARLEN_M1(M1_2B_ARLen),
	.ARSIZE_M1(M1_2B_ARSize),
	.ARBURST_M1(M1_2B_ARBurst),
	.ARVALID_M1(M1_2B_ARValid),
	.ARREADY_M1(M1_2B_ARReady),

	//READ DATA1
	.RID_M1(M1_2B_RID),
	.RDATA_M1(M1_2B_RData),
	.RRESP_M1(M1_2B_RResp),
	.RLAST_M1(M1_2B_RLast),
	.RVALID_M1(M1_2B_RValid),
	.RREADY_M1(M1_2B_RReady),

	//MASTER INTERFACE FOR SLAVES
	//WRITE ADDRESS0
	.AWID_S0(B2_S0_AWID),
	.AWADDR_S0(B2_S0_AWAddr),
	.AWLEN_S0(B2_S0_AWLen),
	.AWSIZE_S0(B2_S0_AWSize),
	.AWBURST_S0(B2_S0_AWBurst),
	.AWVALID_S0(B2_S0_AWValid),
	.AWREADY_S0(B2_S0_AWReady),

	//WRITE DATA0
	.WDATA_S0(B2_S0_WData),
	.WSTRB_S0(B2_S0_WStrb),
	.WLAST_S0(B2_S0_WLast),
	.WVALID_S0(B2_S0_WValid),
	.WREADY_S0(B2_S0_WReady),

	//WRITE RESPONSE0
	.BID_S0(B2_S0_BID),
	.BRESP_S0(B2_S0_BResp),
	.BVALID_S0(B2_S0_BValid),
	.BREADY_S0(B2_S0_BReady),

	//WRITE ADDRESS1
	.AWID_S1(B2_S1_AWID),
	.AWADDR_S1(B2_S1_AWAddr),
	.AWLEN_S1(B2_S1_AWLen),
	.AWSIZE_S1(B2_S1_AWSize),
	.AWBURST_S1(B2_S1_AWBurst),
	.AWVALID_S1(B2_S1_AWValid),
	.AWREADY_S1(B2_S1_AWReady),

	//WRITE DATA1
	.WDATA_S1(B2_S1_WData),
	.WSTRB_S1(B2_S1_WStrb),
	.WLAST_S1(B2_S1_WLast),
	.WVALID_S1(B2_S1_WValid),
	.WREADY_S1(B2_S1_WReady),

	//WRITE RESPONSE1
	.BID_S1(B2_S1_BID),
	.BRESP_S1(B2_S1_BResp),
	.BVALID_S1(B2_S1_BValid),
	.BREADY_S1(B2_S1_BReady),

	//READ ADDRESS0
	.ARID_S0(B2_S0_ARID),
	.ARADDR_S0(B2_S0_ARAddr),
	.ARLEN_S0(B2_S0_ARLen),
	.ARSIZE_S0(B2_S0_ARSize),
	.ARBURST_S0(B2_S0_ARBurst),
	.ARVALID_S0(B2_S0_ARValid),
	.ARREADY_S0(B2_S0_ARReady),

	//READ DATA0
	.RID_S0(B2_S0_RID),
	.RDATA_S0(B2_S0_RData),
	.RRESP_S0(B2_S0_RResp),
	.RLAST_S0(B2_S0_RLast),
	.RVALID_S0(B2_S0_RValid),
	.RREADY_S0(B2_S0_RReady),

	//READ ADDRESS1
	.ARID_S1(B2_S1_ARID),
	.ARADDR_S1(B2_S1_ARAddr),
	.ARLEN_S1(B2_S1_ARLen),
	.ARSIZE_S1(B2_S1_ARSize),
	.ARBURST_S1(B2_S1_ARBurst),
	.ARVALID_S1(B2_S1_ARValid),
	.ARREADY_S1(B2_S1_ARReady),

	//READ DATA1
	.RID_S1(B2_S1_RID),
	.RDATA_S1(B2_S1_RData),
	.RRESP_S1(B2_S1_RResp),
	.RLAST_S1(B2_S1_RLast),
	.RVALID_S1(B2_S1_RValid),
	.RREADY_S1(B2_S1_RReady)
    );


SRAM_wrapper IM1(
    .ACLK(clk),.ARESETn(!rst),

    // AXI RADDR
    .ARID_S(B2_S0_ARID),
    .ARADDR_S(B2_S0_ARAddr),
    .ARLEN_S(B2_S0_ARLen),
    .ARSIZE_S(B2_S0_ARSize),
    .ARBURST_S(B2_S0_ARBurst),
    .ARVALID_S(B2_S0_ARValid),
    .ARREADY_S(B2_S0_ARReady),

    // AXI RDATA
    .RDATA_S(B2_S0_RData),
    .RID_S(B2_S0_RID),
    .RRESP_S(B2_S0_RResp),
    .RLAST_S(B2_S0_RLast),
    .RVALID_S(B2_S0_RValid),
    .RREADY_S(B2_S0_RReady),

    // AXI WADDR
    .AWID_S(B2_S0_AWID),
    .AWADDR_S(B2_S0_AWAddr),
    .AWSIZE_S(B2_S0_AWSize),
    .AWLEN_S(B2_S0_AWLen),
    .AWBURST_S(B2_S0_AWBurst),
    .AWVALID_S(B2_S0_AWValid),
    .AWREADY_S(B2_S0_AWReady),

    // AXI WDATA
    .WDATA_S(B2_S0_WData),
    .WSTRB_S(B2_S0_WStrb),
    .WVALID_S(B2_S0_WValid),
    .WLAST_S(B2_S0_WLast),
    .WREADY_S(B2_S0_WReady),

    // AXI WRESP
    .BVALID_S(B2_S0_BValid),
    .BRESP_S(B2_S0_BResp),
    .BID_S(B2_S0_BID),
    .BREADY_S(B2_S0_BReady)
);

SRAM_wrapper DM1(
    .ACLK(clk),.ARESETn(!rst),

    // AXI RADDR
    .ARID_S(B2_S1_ARID),
    .ARADDR_S(B2_S1_ARAddr),
    .ARLEN_S(B2_S1_ARLen),
    .ARSIZE_S(B2_S1_ARSize),
    .ARBURST_S(B2_S1_ARBurst),
    .ARVALID_S(B2_S1_ARValid),
    .ARREADY_S(B2_S1_ARReady),

    // AXI RDATA
    .RDATA_S(B2_S1_RData),
    .RID_S(B2_S1_RID),
    .RRESP_S(B2_S1_RResp),
    .RLAST_S(B2_S1_RLast),
    .RVALID_S(B2_S1_RValid),
    .RREADY_S(B2_S1_RReady),

    // AXI WADDR
    .AWID_S(B2_S1_AWID),
    .AWADDR_S(B2_S1_AWAddr),
    .AWSIZE_S(B2_S1_AWSize),
    .AWLEN_S(B2_S1_AWLen),
    .AWBURST_S(B2_S1_AWBurst),
    .AWVALID_S(B2_S1_AWValid),
    .AWREADY_S(B2_S1_AWReady),

    // AXI WDATA
    .WDATA_S(B2_S1_WData),
    .WSTRB_S(B2_S1_WStrb),
    .WVALID_S(B2_S1_WValid),
    .WLAST_S(B2_S1_WLast),
    .WREADY_S(B2_S1_WReady),

    // AXI WRESP
    .BVALID_S(B2_S1_BValid),
    .BRESP_S(B2_S1_BResp),
    .BID_S(B2_S1_BID),
    .BREADY_S(B2_S1_BReady)
);

endmodule