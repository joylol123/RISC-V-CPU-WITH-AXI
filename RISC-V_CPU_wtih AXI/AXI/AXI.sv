//////////////////////////////////////////////////////////////////////
//          ██╗       ██████╗   ██╗  ██╗    ██████╗            		//
//          ██║       ██╔══█║   ██║  ██║    ██╔══█║            		//
//          ██║       ██████║   ███████║    ██████║            		//
//          ██║       ██╔═══╝   ██╔══██║    ██╔═══╝            		//
//          ███████╗  ██║  	    ██║  ██║    ██║  	           		//
//          ╚══════╝  ╚═╝  	    ╚═╝  ╚═╝    ╚═╝  	           		//
//                                                             		//
// 	2024 Advanced VLSI System Design, advisor: Lih-Yih, Chiou		//
//                                                             		//
//////////////////////////////////////////////////////////////////////
//                                                             		//
// 	Autor: 			TZUNG-JIN, TSAI (Leo)				  	   		//
//	Filename:		 AXI.sv			                            	//
//	Description:	Top module of AXI	 							//
// 	Version:		1.0	    								   		//
//////////////////////////////////////////////////////////////////////
// `include "../../include/AXI_define.svh"
// `include "../../include/CPU_define.svh"
// `include "../../src/AXI/Arbiter.sv"
// `include "../../src/AXI/Decoder.sv"
// `include "../../src/AXI/DefaultSlave.sv"
// `include "../../src/AXI/ReadAddress.sv"
// `include "../../src/AXI/ReadData.sv"
// `include "../../src/AXI/WriteAddress.sv"
// `include "../../src/AXI/WriteData.sv"
// `include "../../src/AXI/WriteResponse.sv"
`include "../include/AXI_define.svh"
`include "../include/CPU_define.svh"
`include "../src/AXI/Arbiter.sv"
`include "../src/AXI/Decoder.sv"
`include "../src/AXI/DefaultSlave.sv"
`include "../src/AXI/ReadAddress.sv"
`include "../src/AXI/ReadData.sv"
`include "../src/AXI/WriteAddress.sv"
`include "../src/AXI/WriteData.sv"
`include "../src/AXI/WriteResponse.sv"
module AXI(

	input ACLK,
	input ARESETn,

	//SLAVE INTERFACE FOR MASTERS
	
	//WRITE ADDRESS
	input [`AXI_ID_BITS-1:0] AWID_M1,
	input [`AXI_ADDR_BITS-1:0] AWADDR_M1,
	input [`AXI_LEN_BITS-1:0] AWLEN_M1,
	input [`AXI_SIZE_BITS-1:0] AWSIZE_M1,
	input [1:0] AWBURST_M1,
	input AWVALID_M1,
	output logic AWREADY_M1,
	
	//WRITE DATA
	input [`AXI_DATA_BITS-1:0] WDATA_M1,
	input [`AXI_STRB_BITS-1:0] WSTRB_M1,
	input WLAST_M1,
	input WVALID_M1,
	output logic WREADY_M1,
	
	//WRITE RESPONSE
	output logic [`AXI_ID_BITS-1:0] BID_M1,
	output logic [1:0] BRESP_M1,
	output logic BVALID_M1,
	input BREADY_M1,

	//READ ADDRESS0
	input [`AXI_ID_BITS-1:0] ARID_M0,
	input [`AXI_ADDR_BITS-1:0] ARADDR_M0,
	input [`AXI_LEN_BITS-1:0] ARLEN_M0,
	input [`AXI_SIZE_BITS-1:0] ARSIZE_M0,
	input [1:0] ARBURST_M0,
	input ARVALID_M0,
	output logic ARREADY_M0,
	
	//READ DATA0
	output logic [`AXI_ID_BITS-1:0] RID_M0,
	output logic [`AXI_DATA_BITS-1:0] RDATA_M0,
	output logic [1:0] RRESP_M0,
	output logic RLAST_M0,
	output logic RVALID_M0,
	input RREADY_M0,
	
	//READ ADDRESS1
	input [`AXI_ID_BITS-1:0] ARID_M1,
	input [`AXI_ADDR_BITS-1:0] ARADDR_M1,
	input [`AXI_LEN_BITS-1:0] ARLEN_M1,
	input [`AXI_SIZE_BITS-1:0] ARSIZE_M1,
	input [1:0] ARBURST_M1,
	input ARVALID_M1,
	output logic ARREADY_M1,
	
	//READ DATA1
	output logic [`AXI_ID_BITS-1:0] RID_M1,
	output logic [`AXI_DATA_BITS-1:0] RDATA_M1,
	output logic [1:0] RRESP_M1,
	output logic RLAST_M1,
	output logic RVALID_M1,
	input RREADY_M1,

	//MASTER INTERFACE FOR SLAVES
	//WRITE ADDRESS0
	output logic [`AXI_IDS_BITS-1:0] AWID_S0,
	output logic [`AXI_ADDR_BITS-1:0] AWADDR_S0,
	output logic [`AXI_LEN_BITS-1:0] AWLEN_S0,
	output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S0,
	output logic [1:0] AWBURST_S0,
	output logic AWVALID_S0,
	input AWREADY_S0,
	
	//WRITE DATA0
	output logic [`AXI_DATA_BITS-1:0] WDATA_S0,
	output logic [`AXI_STRB_BITS-1:0] WSTRB_S0,
	output logic WLAST_S0,
	output logic WVALID_S0,
	input WREADY_S0,
	
	//WRITE RESPONSE0
	input [`AXI_IDS_BITS-1:0] BID_S0,
	input [1:0] BRESP_S0,
	input BVALID_S0,
	output logic BREADY_S0,
	
	//WRITE ADDRESS1
	output logic [`AXI_IDS_BITS-1:0] AWID_S1,
	output logic [`AXI_ADDR_BITS-1:0] AWADDR_S1,
	output logic [`AXI_LEN_BITS-1:0] AWLEN_S1,
	output logic [`AXI_SIZE_BITS-1:0] AWSIZE_S1,
	output logic [1:0] AWBURST_S1,
	output logic AWVALID_S1,
	input AWREADY_S1,
	
	//WRITE DATA1
	output logic [`AXI_DATA_BITS-1:0] WDATA_S1,
	output logic [`AXI_STRB_BITS-1:0] WSTRB_S1,
	output logic WLAST_S1,
	output logic WVALID_S1,
	input WREADY_S1,
	
	//WRITE RESPONSE1
	input [`AXI_IDS_BITS-1:0] BID_S1,
	input [1:0] BRESP_S1,
	input BVALID_S1,
	output logic BREADY_S1,
	
	//READ ADDRESS0
	output logic [`AXI_IDS_BITS-1:0] ARID_S0,
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_S0,
	output logic [`AXI_LEN_BITS-1:0] ARLEN_S0,
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S0,
	output logic [1:0] ARBURST_S0,
	output logic ARVALID_S0,
	input ARREADY_S0,
	
	//READ DATA0
	input [`AXI_IDS_BITS-1:0] RID_S0,
	input [`AXI_DATA_BITS-1:0] RDATA_S0,
	input [1:0] RRESP_S0,
	input RLAST_S0,
	input RVALID_S0,
	output logic RREADY_S0,
	
	//READ ADDRESS1
	output logic [`AXI_IDS_BITS-1:0] ARID_S1,
	output logic [`AXI_ADDR_BITS-1:0] ARADDR_S1,
	output logic [`AXI_LEN_BITS-1:0] ARLEN_S1,
	output logic [`AXI_SIZE_BITS-1:0] ARSIZE_S1,
	output logic [1:0] ARBURST_S1,
	output logic ARVALID_S1,
	input ARREADY_S1,
	
	//READ DATA1
	input [`AXI_IDS_BITS-1:0] RID_S1,
	input [`AXI_DATA_BITS-1:0] RDATA_S1,
	input [1:0] RRESP_S1,
	input RLAST_S1,
	input RVALID_S1,
	output logic RREADY_S1
	
);
    //---------- you should put your design here ----------//
logic [`AXI_IDS_BITS-1:0] ARID_DEFAULT;
	logic [`AXI_ADDR_BITS-1:0] ARADDR_DEFAULT;
	logic [`AXI_LEN_BITS-1:0] ARLEN_DEFAULT;
	logic [`AXI_SIZE_BITS-1:0] ARSIZE_DEFAULT;
	logic [1:0] ARBURST_DEFAULT;
	logic ARVALID_DEFAULT;
	logic ARREADY_DEFAULT;
	//READ DATA DEFAULT
	logic [`AXI_IDS_BITS-1:0] RID_DEFAULT;
	logic [`AXI_DATA_BITS-1:0] RDATA_DEFAULT;
	logic [1:0] RRESP_DEFAULT;
	logic RLAST_DEFAULT;
	logic RVALID_DEFAULT;
	logic RREADY_DEFAULT;
	//WRITE ADDRESS DEFAULT
	logic [`AXI_IDS_BITS-1:0] AWID_DEFAULT;
	logic [`AXI_ADDR_BITS-1:0] AWADDR_DEFAULT;
	logic [`AXI_LEN_BITS-1:0] AWLEN_DEFAULT;
	logic [`AXI_SIZE_BITS-1:0] AWSIZE_DEFAULT;
	logic [1:0] AWBURST_DEFAULT;
	logic AWVALID_DEFAULT;
	logic AWREADY_DEFAULT;
	//WRITE DATA DEFAULT
	logic [`AXI_DATA_BITS-1:0] WDATA_DEFAULT;
	logic [`AXI_STRB_BITS-1:0] WSTRB_DEFAULT;
	logic WLAST_DEFAULT;
	logic WVALID_DEFAULT;
	logic WREADY_DEFAULT;
	//WRITE RESPONSE DEFAULT
	logic [`AXI_IDS_BITS-1:0] BID_DEFAULT;
	logic [1:0] BRESP_DEFAULT;
	logic BVALID_DEFAULT;
	logic BREADY_DEFAULT;
logic delay_ARESETn;
always_ff@(posedge ACLK)begin
  if(!ARESETn)
    delay_ARESETn <= 1'b0;
  else
    delay_ARESETn <= 1'b1;
end
	DefaultSlave uDefaultSlave(
		.clk			(ACLK		),
		.rst			(delay_ARESETn	),

		.ARID_DEFAULT	(ARID_DEFAULT),
		.ARADDR_DEFAULT	(ARADDR_DEFAULT),
		.ARLEN_DEFAULT	(ARLEN_DEFAULT),
		.ARSIZE_DEFAULT	(ARSIZE_DEFAULT),
		.ARBURST_DEFAULT(ARBURST_DEFAULT),
		.ARVALID_DEFAULT(ARVALID_DEFAULT),
		.ARREADY_DEFAULT(ARREADY_DEFAULT),

		.RID_DEFAULT	(RID_DEFAULT),
		.RDATA_DEFAULT	(RDATA_DEFAULT),
		.RRESP_DEFAULT	(RRESP_DEFAULT),
		.RLAST_DEFAULT	(RLAST_DEFAULT),
		.RVALID_DEFAULT	(RVALID_DEFAULT),
		.RREADY_DEFAULT	(RREADY_DEFAULT),

		.AWID_DEFAULT	(AWID_DEFAULT),
		.AWADDR_DEFAULT	(AWADDR_DEFAULT),
		.AWLEN_DEFAULT	(AWLEN_DEFAULT),
		.AWSIZE_DEFAULT	(AWSIZE_DEFAULT),
		.AWBURST_DEFAULT(AWBURST_DEFAULT),
		.AWVALID_DEFAULT(AWVALID_DEFAULT),
		.AWREADY_DEFAULT(AWREADY_DEFAULT),

		.WDATA_DEFAULT	(WDATA_DEFAULT),
		.WSTRB_DEFAULT	(WSTRB_DEFAULT),
		.WLAST_DEFAULT	(WLAST_DEFAULT),
		.WVALID_DEFAULT	(WVALID_DEFAULT),
		.WREADY_DEFAULT	(WREADY_DEFAULT),

		.BID_DEFAULT	(BID_DEFAULT),
		.BRESP_DEFAULT	(BRESP_DEFAULT),
		.BVALID_DEFAULT	(BVALID_DEFAULT),
		.BREADY_DEFAULT	(BREADY_DEFAULT)
	);

	ReadAddress uReadAddress(
		.clk			(ACLK		),
		.rst			(delay_ARESETn	),

		.ARID_M0		(ARID_M0	),
		.ARADDR_M0		(ARADDR_M0	),
		.ARLEN_M0		(ARLEN_M0	),
		.ARSIZE_M0		(ARSIZE_M0	),
		.ARBURST_M0		(ARBURST_M0	),
		.ARVALID_M0		(ARVALID_M0	),
		.ARREADY_M0		(ARREADY_M0	),

		.ARID_M1		(ARID_M1	),
		.ARADDR_M1		(ARADDR_M1	),
		.ARLEN_M1		(ARLEN_M1	),
		.ARSIZE_M1		(ARSIZE_M1	),
		.ARBURST_M1		(ARBURST_M1	),
		.ARVALID_M1		(ARVALID_M1	),
		.ARREADY_M1		(ARREADY_M1	),

		.ARID_S0		(ARID_S0	),
		.ARADDR_S0		(ARADDR_S0	),
		.ARLEN_S0		(ARLEN_S0	),
		.ARSIZE_S0		(ARSIZE_S0	),
		.ARBURST_S0		(ARBURST_S0	),
		.ARVALID_S0		(ARVALID_S0	),
		.ARREADY_S0		(ARREADY_S0	),

		.ARID_S1		(ARID_S1	),
		.ARADDR_S1		(ARADDR_S1	),
		.ARLEN_S1		(ARLEN_S1	),
		.ARSIZE_S1		(ARSIZE_S1	),
		.ARBURST_S1		(ARBURST_S1	),
		.ARVALID_S1		(ARVALID_S1	),
		.ARREADY_S1		(ARREADY_S1	),

		.ARID_S2		(ARID_DEFAULT),
		.ARADDR_S2		(ARADDR_DEFAULT),
		.ARLEN_S2		(ARLEN_DEFAULT),
		.ARSIZE_S2		(ARSIZE_DEFAULT),
		.ARBURST_S2		(ARBURST_DEFAULT),
		.ARVALID_S2		(ARVALID_DEFAULT),
		.ARREADY_S2		(ARREADY_DEFAULT)
	);

	ReadData uReadData(
		.clk			(ACLK		),
		.rst			(delay_ARESETn	),

		.RID_M0			(RID_M0		),
		.RDATA_M0		(RDATA_M0	),
		.RRESP_M0		(RRESP_M0	),
		.RLAST_M0		(RLAST_M0	),
		.RVALID_M0		(RVALID_M0	),
		.RREADY_M0		(RREADY_M0	),

		.RID_M1			(RID_M1		),
		.RDATA_M1		(RDATA_M1	),
		.RRESP_M1		(RRESP_M1	),
		.RLAST_M1		(RLAST_M1	),
		.RVALID_M1		(RVALID_M1	),
		.RREADY_M1		(RREADY_M1	),

		.RID_S0			(RID_S0		),
		.RDATA_S0		(RDATA_S0	),
		.RRESP_S0		(RRESP_S0	),
		.RLAST_S0		(RLAST_S0	),
		.RVALID_S0		(RVALID_S0	),
		.RREADY_S0		(RREADY_S0	),

		.RID_S1			(RID_S1		),
		.RDATA_S1		(RDATA_S1	),
		.RRESP_S1		(RRESP_S1	),
		.RLAST_S1		(RLAST_S1	),
		.RVALID_S1		(RVALID_S1	),
		.RREADY_S1		(RREADY_S1	),

		.RID_S2			(RID_DEFAULT),
		.RDATA_S2		(RDATA_DEFAULT),
		.RRESP_S2		(RRESP_DEFAULT),
		.RLAST_S2		(RLAST_DEFAULT),
		.RVALID_S2		(RVALID_DEFAULT),
		.RREADY_S2		(RREADY_DEFAULT)
	);
	
	WriteAddress uWriteAddress(
		.clk			(ACLK		),
		.rst			(delay_ARESETn	),

		.AWID_M1		(AWID_M1	),
		.AWADDR_M1		(AWADDR_M1	),
		.AWLEN_M1		(AWLEN_M1	),
		.AWSIZE_M1		(AWSIZE_M1	),
		.AWBURST_M1		(AWBURST_M1	),
		.AWVALID_M1		(AWVALID_M1	),
		.AWREADY_M1		(AWREADY_M1	),

		.AWID_S0		(AWID_S0	),
		.AWADDR_S0		(AWADDR_S0	),
		.AWLEN_S0		(AWLEN_S0	),
		.AWSIZE_S0		(AWSIZE_S0	),
		.AWBURST_S0		(AWBURST_S0	),
		.AWVALID_S0		(AWVALID_S0	),
		.AWREADY_S0		(AWREADY_S0	),

		.AWID_S1		(AWID_S1	),
		.AWADDR_S1		(AWADDR_S1	),
		.AWLEN_S1		(AWLEN_S1	),
		.AWSIZE_S1		(AWSIZE_S1	),
		.AWBURST_S1		(AWBURST_S1	),
		.AWVALID_S1		(AWVALID_S1	),
		.AWREADY_S1		(AWREADY_S1	),

		.AWID_S2		(AWID_DEFAULT),
		.AWADDR_S2		(AWADDR_DEFAULT),
		.AWLEN_S2		(AWLEN_DEFAULT),
		.AWSIZE_S2		(AWSIZE_DEFAULT),
		.AWBURST_S2		(AWBURST_DEFAULT),
		.AWVALID_S2		(AWVALID_DEFAULT),
		.AWREADY_S2		(AWREADY_DEFAULT)
	);

	WriteData uWriteData(
		.clk			(ACLK		),
		.rst			(delay_ARESETn	),

		.WDATA_M1		(WDATA_M1	),
		.WSTRB_M1		(WSTRB_M1	),
		.WLAST_M1		(WLAST_M1	),
		.WVALID_M1		(WVALID_M1	),
		.WREADY_M1		(WREADY_M1	),

		.AWVALID_S0		(AWVALID_S0	),
		.WDATA_S0		(WDATA_S0	),
		.WSTRB_S0		(WSTRB_S0	),
		.WLAST_S0		(WLAST_S0	),
		.WVALID_S0		(WVALID_S0	),
		.WREADY_S0		(WREADY_S0	),

		.AWVALID_S1		(AWVALID_S1	),
		.WDATA_S1		(WDATA_S1	),
		.WSTRB_S1		(WSTRB_S1	),
		.WLAST_S1		(WLAST_S1	),
		.WVALID_S1		(WVALID_S1	),
		.WREADY_S1		(WREADY_S1	),

		.AWVALID_S2		(AWVALID_DEFAULT),
		.WDATA_S2		(WDATA_DEFAULT),
		.WSTRB_S2		(WSTRB_DEFAULT),
		.WLAST_S2		(WLAST_DEFAULT),
		.WVALID_S2		(WVALID_DEFAULT),
		.WREADY_S2		(WREADY_DEFAULT)
	);

	WriteResponse uWriteResponse(
		.clk			(ACLK		),
		.rst			(delay_ARESETn	),

		.BID_M1			(BID_M1		),
		.BRESP_M1		(BRESP_M1	),
		.BVALID_M1		(BVALID_M1	),
		.BREADY_M1		(BREADY_M1	),

		.BID_S0			(BID_S0		),
		.BRESP_S0		(BRESP_S0	),
		.BVALID_S0		(BVALID_S0	),
		.BREADY_S0		(BREADY_S0	),
		
		.BID_S1			(BID_S1		),
		.BRESP_S1		(BRESP_S1	),
		.BVALID_S1		(BVALID_S1	),
		.BREADY_S1		(BREADY_S1	),

		.BID_S2			(BID_DEFAULT),
		.BRESP_S2		(BRESP_DEFAULT),
		.BVALID_S2		(BVALID_DEFAULT),
		.BREADY_S2		(BREADY_DEFAULT)
	);











endmodule
