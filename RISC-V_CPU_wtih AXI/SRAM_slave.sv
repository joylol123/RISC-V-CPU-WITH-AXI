
`include "../include/AXI_define.svh"
`include "../include/CPU_define.svh"
module SRAM_slave (
    input ACLK,ARESETn,
    // R_addr
    input   [`AXI_IDS_BITS-1:0]        AR_ID_sla,
    input   [`AXI_ADDR_BITS-1:0]       AR_addr_sla,
    input   [`AXI_LEN_BITS-1:0]        AR_len_sla,
    input   [`AXI_SIZE_BITS-1:0]       AR_size_sla,
    input   [1:0]                      AR_burst_sla,
    input                              AR_valid_sla,
    output  logic                      AR_ready_sla,
    // R_data
    output  logic [`AXI_IDS_BITS-1:0]  R_ID_sla,
    output  logic [`AXI_DATA_BITS-1:0] R_data_sla,
    output  logic [1:0]                R_resp_sla,
    output  logic                      R_last_sla,
    output  logic                      R_valid_sla,
    input                              R_ready_sla,
    // W_resp
    output logic [1:0]                 B_resp_sla,
    output logic [`AXI_IDS_BITS-1:0]   B_ID_sla,
    output logic                       B_valid_sla,
    input  logic                       B_ready_sla,
    // W_data  
    input  [`AXI_DATA_BITS-1:0]        W_data_sla,
    input                              W_last_sla,
    input  [`AXI_STRB_BITS-1:0]        W_strb_sla,
    input                              W_valid_sla,
    output logic                       W_ready_sla,

    // W_addr  
    input  [`AXI_ADDR_BITS-1:0]        AW_addr_sla,//32bits
    input  [`AXI_IDS_BITS-1:0]         AW_ID_sla,
    input  [`AXI_LEN_BITS-1:0]         AW_len_sla,
    input  [1:0]                       AW_burst_sla,
    input                              AW_valid_sla,
    input  [`AXI_SIZE_BITS -1:0]       AW_size_sla,
    output logic                       AW_ready_sla,

    // TO MEMOEY //////////////////////////////////
    input        [`DATA_WIDTH -1:0]    DO,
    output logic [`DATA_WIDTH -1:0]    DI,
    output logic [`MEM_ADDR_LEN -1:0] A,
    output logic [`DATA_WIDTH -1:0]    BWEB,
    output logic                       WEB,

    output logic [1:0]                 curr_state

);
logic [1:0] next_state;
localparam  ADDR = 2'd0,
            RDATA = 2'd1,
            WDATA = 2'd2,
            WRESP = 2'd3; 
logic W_resp_done,R_addr_done,W_addr_done,R_data_done,W_data_done; //hand shake done
logic R_last,W_last; // transaction done
always_ff @(posedge ACLK) begin 
    if(!ARESETn) curr_state <= ADDR;
    else         curr_state <= next_state;
end

//========================= COUNT DATA =========================//
logic [`AXI_LEN_BITS -1 : 0] data_cnt;

always_ff @(posedge ACLK) begin : blockName
    if(!ARESETn) data_cnt <= `AXI_LEN_BITS'd0;

    else begin
        if(R_last || W_last)begin
            data_cnt <= `AXI_LEN_BITS'd0;
        end
        else if(R_data_done || W_data_done)begin
            data_cnt <= data_cnt + `AXI_LEN_BITS'd1;
        end
        else data_cnt <= data_cnt;
    end
end
//========================= COUNT DATA =========================//

// ======================== AR_ready_signal assert =============//
always_ff @(posedge ACLK) begin 
    if(!ARESETn) 

        AR_ready_sla <= 1'b0;

    else begin
        case (curr_state)
            ADDR: AR_ready_sla <= R_addr_done | AW_valid_sla ? 1'b0 : 1'b1;

            WRESP:AR_ready_sla <= 1'b0;

            default: AR_ready_sla <= 1'b0;
        endcase
    end
end
// ======================== AR_ready_signal assert =============//

// ======================== AW_ready_signal assert =============//
always_ff @(posedge ACLK) begin
    if(!ARESETn) 
        AW_ready_sla <= 1'b0;
    else begin
        case (curr_state)
            ADDR:begin
                AW_ready_sla <= W_addr_done ? 1'b0 : 1'b1;
            end
        
            WRESP: AW_ready_sla <= 1'b0;

            default: AW_ready_sla <= 1'b0; // WDATA 、 WRESP
        endcase
    end
end
// ======================== AW_ready_signal assert =============//



// ========================================NEXT STATE LOGIC  =================================


assign R_data_done = R_valid_sla  & R_ready_sla;
assign R_addr_done = AR_valid_sla & AR_ready_sla;
assign W_addr_done = AW_valid_sla & AW_ready_sla; 
assign W_data_done = W_valid_sla  & W_ready_sla;
assign W_resp_done = B_valid_sla  & B_ready_sla;

assign R_last      = R_data_done & R_last_sla;
assign W_last      = W_data_done & W_last_sla;

// localparam  ADDR = 2'd0,
//             RDATA = 2'd1,
//             WDATA = 2'd2,
//             WRESP = 2'd3; 
always_comb begin 
    case (curr_state)
        ADDR:begin
            if(W_addr_done && W_data_done)
                next_state = WRESP;
            else if(W_addr_done)    next_state = WDATA;
            else if(R_addr_done)         next_state = RDATA;
            else                    next_state = ADDR;
        end
        RDATA: next_state = (R_last)      ? ADDR   : RDATA;

        WDATA: next_state = (W_last)      ? WRESP : WDATA;

        WRESP: next_state = (W_resp_done) ? ADDR : WRESP;

        default: next_state = ADDR;
    endcase
end

// ========================================NEXT STATE LOGIC  =================================

// ======================================== READ CHANNEL OUTPUT=================================

logic [`MEM_ADDR_LEN-1:0] reg_AR_addr,reg_AW_addr;
logic [`AXI_IDS_BITS-1:0] reg_AR_ID,reg_AW_ID;
logic [`AXI_LEN_BITS-1:0] reg_AR_len,reg_AW_len;

// ADDR UPDATE
always_ff @(posedge ACLK) begin
    if(!ARESETn)begin
        reg_AR_addr <= `MEM_ADDR_LEN'd0;
        reg_AR_ID   <= `AXI_IDS_BITS'd0;
        reg_AR_len  <= `AXI_LEN_BITS'd0;
    end
    else begin
        reg_AR_addr <= (R_addr_done) ? AR_addr_sla[15:2] : reg_AR_addr;
        reg_AR_ID   <= (R_addr_done) ? AR_ID_sla         : reg_AR_ID;
        reg_AR_len  <= (R_addr_done) ? AR_len_sla        : reg_AR_len;
    end
end

// DATA UPDATE
assign R_resp_sla = `AXI_RESP_OKAY;
assign R_ID_sla   = reg_AR_ID;
assign R_last_sla = (data_cnt == reg_AR_len) ? 1'b1 : 1'b0;
assign R_data_sla = DO; // FROM DM
assign R_valid_sla = (curr_state == RDATA) ? 1'b1 : 1'b0;

// ======================================= WRITE CHANNEL OUTPUT ===========================

// ADDR UPDATE
always_ff @(posedge ACLK) begin
    if(!ARESETn)begin
        reg_AW_addr <= `MEM_ADDR_LEN'd0;
        reg_AW_ID   <= `AXI_IDS_BITS'd0;
        reg_AW_len  <= `AXI_LEN_BITS'd0;
    end
    else begin
        reg_AW_addr <= (W_addr_done) ? AW_addr_sla[15:2] : reg_AW_addr;
        reg_AW_ID   <= (W_addr_done) ? AW_ID_sla   : reg_AW_ID;
        reg_AW_len  <= (W_addr_done) ? AW_len_sla  : reg_AW_len;
    end
end

// DATA UPDATE
assign W_ready_sla = (curr_state == WDATA) ? 1'b1 : 1'b0;
// BRESP
assign B_ID_sla = reg_AW_ID;
assign B_resp_sla = `AXI_RESP_OKAY;
assign B_valid_sla = (curr_state == WRESP) ? 1'b1 : 1'b0;

// =================== MEMORY ================ //

assign BWEB = { {8{W_strb_sla[3]}}, {8{W_strb_sla[2]}}, {8{W_strb_sla[1]}}, {8{W_strb_sla[0]}} }; // need to be  2025/10/15
 
always_comb begin 
    case (curr_state)
        ADDR:   WEB = 1'b1;
        RDATA:  WEB = 1'b1;
        WDATA:  WEB = 1'b0;
        WRESP:  WEB = 1'b1;
        default: WEB = 1'b1;
    endcase    
end

always_comb begin
    case (curr_state)
        ADDR: A = (W_addr_done) ? AW_addr_sla[15:2] : AR_addr_sla[15:2]; // assign 0 is fine?
        RDATA: A = reg_AR_addr;
        WDATA: A = reg_AW_addr;
        default: A = ~W_resp_done? reg_AW_addr:(W_addr_done ? AW_addr_sla[15:2]:AR_addr_sla[15:2]);//14'd0;
    endcase
    
end

assign DI = W_data_sla;

endmodule