
module DefaultSlave (
    input ACLK,ARESTn,
 

    // READ DATA CHANNEL
    output  logic [`AXI_DATA_BITS -1:0] D_S_Rdata,
    output  logic [`AXI_IDS_BITS -1:0]  D_S_RID,
    output  logic [1:0]                 D_S_Rresp,
    output  logic                       D_S_Rlast,
    output  logic                       D_S_Rvalid,
    input                               D_S_Rready,


    // READ ADDR CNANNEL
    input    [`AXI_IDS_BITS -1:0]  D_S_ARID,
    input    [`AXI_ADDR_BITS -1:0] D_S_ARaddr,
    input    [`AXI_LEN_BITS -1:0] D_S_ARlen,
    input    [`AXI_SIZE_BITS -1:0] D_S_ARsize,
    input    [1:0]                 D_S_ARburst,
    input                          D_S_ARvalid,
    output  logic                   D_S_ARready,
    // WRITE DATA CNANNEL

    input   [`AXI_DATA_BITS -1:0]  D_S_Wdata,
    input   [`AXI_STRB_BITS -1:0]  D_S_Wstrb,
    input                          D_S_Wlast,
    input                          D_S_Wvalid,
    output  logic                 D_S_Wready,
    // WRITE ADDR CHANNEL
    input   [`AXI_IDS_BITS -1:0]   D_S_AWID,
    input   [`AXI_ADDR_BITS -1:0]  D_S_AWaddr,
    input   [`AXI_LEN_BITS -1:0]   D_S_AWlen,
    input   [1:0]                  D_S_AWburst,
    input   [`AXI_SIZE_BITS -1:0]  D_S_AWsize,
    input                          D_S_AWvalid,
    output  logic                  D_S_AWready,
    // WRITE RESPONSE
    output  logic[1:0]                  D_S_Bresp,
    output  logic[`AXI_IDS_BITS -1:0]   D_S_BID,
    output  logic                       D_S_Bready,
    input                          D_S_Bvalid

);

// STATE REGISTER
logic [1:0] curr_state,next_state;
logic [1:0] ADDR = 2'd0,
            RDATA = 2'd1,
            WDATA = 2'd2,
            WRESP = 2'd3;
// ============== FSM ==================
always_ff@(posedge ACLK) begin
    if(!ARESTn)begin
        curr_state <= ADDR;    
    end
    else begin
        curr_state <= next_state;
    end

end
// ============== NEXT STATE LOGIC ===============
always_comb begin
    case (curr_state)
        ADDR:begin
            if(Raddr_hand_done)
                next_state = RDATA;
            else if(Waddr_hand_done)
                next_state = WDATA;
            else 
                next_state = ADDR;
        end 
        RDATA:begin
            if(Rdata_hand_done)
                next_state = ADDR;
            else
                next_state = RDATA; 
        end
        WDATA:begin
            if(Wdata_hand_done && D_S_Wlast)
                next_state = WRESP;
            else
                next_state = WDATA;
        end
        WRESP:begin
            if(Wresp_hand_done)
                next_state = ADDR;
            else
                next_state = WRESP; 
        end
        default: next_state = ADDR;

       
    endcase
end
// ============= HANDSHAKE DONE SIGNAL ================
logic Wdata_hand_done;
logic Waddr_hand_done;
logic Wresp_hand_done;
logic Raddr_hand_done;
logic Rdata_hand_done;

assign Wdata_hand_done  = D_S_Wvalid  &&  D_S_Wready;
assign Waddr_hand_done  = D_S_AWvalid &&  D_S_AWready;
assign Wresp_hand_done  = D_S_Bvalid  &&  D_S_Bready;
assign Raddr_hand_done  = D_S_ARvalid &&  D_S_ARready;
assign Rdata_hand_done  = D_S_Rvalid  &&  D_S_Rready;
// ============== RCHANNEL ========== //
logic [`AXI_LEN_BITS -1:0] reg_ARLEN;

// ADDR
always_ff @( posedge ACLK ) begin
    if(!ARESTn)begin
        reg_ARLEN   <=  `AXI_LEN_BITS'd0;
    end
    else begin
        reg_ARLEN   <= (Raddr_hand_done) ? D_S_ARlen :reg_ARLEN;
    end
end

// DATA 
always_ff @(posedge ACLK) begin 
    if(!ARESTn)begin
        D_S_RID <= `AXI_IDS_BITS'd0;
    end
    else begin
        D_S_RID <= (Raddr_hand_done) ? D_S_ARID : D_S_RID;
    end
end

endmodule