module Master (
    input   ACLK,ARESETn,
    //RDATA
    input [`AXI_DATA_BITS -1:0]         M_R_data,
    input [`AXI_ID_BITS   -1:0]         M_R_ID,
    input [1:0]                         M_R_resp,
    input                               M_R_last,
    input                               M_R_valid,
    output logic                        M_R_ready,

    //RADDR
    output logic [1:0]                  M_AR_burst,
    output logic [`AXI_ADDR_BITS -1:0]  M_AR_addr,
    output logic [`AXI_ID_BITS   -1:0]  M_AR_ID,
    output logic [`AXI_SIZE_BITS -1:0]  M_AR_size,
    output logic [`AXI_LEN_BITS  -1:0]  M_AR_len,
    output logic                        M_AR_valid,
    input                               M_AR_ready,
    //WADDR
    output logic [1:0]                  M_AW_burst,
    output logic [`AXI_ADDR_BITS -1:0]  M_AW_addr,
    output logic [`AXI_ID_BITS   -1:0]  M_AW_ID,
    output logic [`AXI_SIZE_BITS -1:0]  M_AW_size,
    output logic [`AXI_LEN_BITS  -1:0]  M_AW_len,
    output logic                        M_AW_valid,
    input                               M_AW_ready,

    //WDATA
    output logic [`AXI_DATA_BITS -1:0]  M_W_data,
    output logic [`AXI_STRB_BITS -1:0]  M_W_strb,
    output logic                        M_W_valid,
    output logic                        M_W_last,
    input                               M_W_ready,

    //WRESP
    input                               M_B_valid,
    input [1:0]                         M_B_resp,
    input [`AXI_ID_BITS -1:0]           M_B_ID,
    output logic                             M_B_ready,

    // CPU
    input                               M_web,
    input                               M_DM_read_sel,
    input                               M_DM_write_sel,
    input [`AXI_DATA_BITS -1:0]         M_Memory_BWEB,
    input [`AXI_ADDR_BITS -1:0]         M_Memory_addr, 
    input [`AXI_DATA_BITS -1:0]         M_Memory_Din,
    output logic [`AXI_DATA_BITS -1:0]  M_Memory_Dout,
    output logic                        M_stall

);
    
logic [2:0] curr_state,next_state;

localparam [2:0] IDLE   = 3'd0,
                 RADDR  = 3'd1,
                 RDATA  = 3'd2,
                 WADDR  = 3'd3,
                 WDATA  = 3'd4,
                 WRESP  = 3'd5;

logic AR_done,R_done,AW_done,W_done,B_done;//hand shake
assign AR_done = M_AR_valid & M_AR_ready;
assign R_done  = M_R_valid  & M_R_ready;
assign AW_done = M_AW_valid & M_AW_ready;
assign W_done  = M_W_valid  & M_W_ready;
assign B_done  = M_B_valid  & M_B_ready;

// ===================== FOR PROTOCOL ===================//
logic start;
logic true_read,true_write;

always_ff @(posedge ACLK) begin
    if(!ARESETn)
        start <= 1'b0;
    else if(ARESETn)
        start <= 1'b1;
    else 
        start <= 1'b0;
end

assign true_read = start & M_DM_read_sel;
assign true_write= start & M_DM_write_sel; // WRITE_reg = start & (WRITE != 4'hf); ?? can't active full 32 bits write??

// ===================== FOR PROTOCOL ===================//

// ===================== hold data ===================//
logic [`AXI_DATA_BITS -1:0] temp_data;
assign M_Memory_Dout = (R_done) ? M_R_data : temp_data;

always_ff @(posedge ACLK) begin : blockName
    if(!ARESETn)
        temp_data <= `AXI_DATA_BITS'd0;
    else
        temp_data <= (R_done) ? M_R_data : temp_data;
end

// ===================== FIX SIGNALS ===================//
assign M_AR_ID = `AXI_ID_BITS'd0;
assign M_AR_size = `AXI_SIZE_BITS'd2; // 4 bytes
assign M_AR_burst = `AXI_BURST_INC;; // INCR
assign M_AR_len = `AXI_LEN_BITS'd0;
assign M_AR_addr = M_Memory_addr;

assign M_AW_ID = `AXI_ID_BITS'd0;
assign M_AW_size = `AXI_SIZE_BITS'd2; // 4 bytes
assign M_AW_burst = `AXI_BURST_INC; // INCR
assign M_AW_len = `AXI_LEN_BITS'd0;
assign M_AW_addr = M_Memory_addr;

assign M_W_data = M_Memory_Din;
assign M_W_strb = {|M_Memory_BWEB[31:24],|M_Memory_BWEB[23:16],|M_Memory_BWEB[15:8],|M_Memory_BWEB[7:0]}; // need to be transformed
assign M_W_last = 1'b1;

// ===================== FIX SIGNALS ===================//
always_ff @(posedge ACLK) begin 
    if(!ARESETn)
        curr_state <= IDLE;
    else
        curr_state <= next_state;
end

// ===================== START SIGNAL ================ //

// always_comb begin 
//     case (curr_state)
//         IDLE:begin
//             true_write = !M_web & M_DM_write_sel;
//             true_read  = M_web & M_DM_read_sel;
            
//         end
//         RADDR:begin
//             true_write = 1'b0;
//             true_read  = 1'b1;
//         end
//         WADDR:begin
//             true_write = 1'b1;
//             true_read  = 1'b0;
//         end
        
//         default:begin
//             true_write = 1'b0;
//             true_read  = 1'b0;
//         end
//     endcase
// end
// ===================== NEXT LOGIC ===================//
always_comb begin 
    case (curr_state)
        IDLE:begin

            if(M_AR_valid)begin
                if(AR_done)
                    next_state = RDATA;
                else
                    next_state = RADDR;
            end
            else if(M_AW_valid)begin
                if(AW_done)
                    next_state = WDATA;
                else
                next_state = WADDR;
            end  
            else
                next_state = IDLE;
            
        end
        RADDR:
            next_state = (AR_done) ? RDATA : RADDR;
        RDATA:
            next_state = (R_done & M_R_last) ? IDLE : RDATA;
        WADDR: 
            next_state = (AW_done) ? WDATA : WADDR;
        WDATA:
            next_state = (W_done & M_W_last) ? WRESP : WDATA;

        WRESP:
            next_state = (B_done) ? IDLE : WRESP;

        default: next_state = IDLE; 
    endcase
end
// always_comb begin 
//     case (curr_state)
//         IDLE:begin
//             if(AR_done)
//                 next_state = RADDR;
//             else if(AW_done)
//                 next_state = WADDR;
//             else
//                 next_state = IDLE;
//         end
//         RADDR:
//             next_state = (R_done) ? RDATA : RADDR;
//         RDATA:
//             next_state = (M_R_last) ? IDLE : RDATA;
//         WADDR: 
//             next_state = (W_done) ? WDATA : WADDR;
//         WDATA:
//             next_state = (M_W_last) ? WRESP : WDATA;

//         WRESP:
//             next_state = (B_done) ? IDLE : WRESP;

//         default: next_state = IDLE; 
//     endcase
// end

//============================= OUTPUT LOGIC =============================//

// M_AR_valid , M_R_ready , M_AW_valid , M_W_valid , M_B_ready,M_stall
always_comb begin 
    case(curr_state)
    IDLE:begin
        M_AR_valid = (M_DM_read_sel & start) ? 1'b1 : 1'b0;
        M_R_ready  = 1'b0;
        M_AW_valid = true_write ? 1'b1 : 1'b0;
        M_W_valid  = 1'b0;
        M_B_ready  = 1'b0;

        M_stall    = (M_DM_read_sel & !R_done) | (M_DM_write_sel&!W_done);//(!true_read & M_web) |true_write;
    end

    RADDR:begin
        M_AR_valid = 1'b1;
        M_R_ready  = 1'b0;
        M_AW_valid = 1'b0;
        M_W_valid  = 1'b0;
        M_B_ready  = 1'b0;
        M_stall    = (M_DM_read_sel & !R_done) | (M_DM_write_sel & !W_done);//1'b1;
    end

    RDATA:begin
        M_AR_valid = 1'b0;
        M_R_ready  = 1'b1;
        M_AW_valid = 1'b0;
        M_W_valid  = 1'b0;
        M_B_ready  = 1'b0;
        M_stall    = (M_DM_read_sel & !R_done) | (M_DM_write_sel & !W_done);//~(R_done);
    end

    WADDR:begin
        M_AR_valid = 1'b0;
        M_R_ready  = 1'b0;
        M_AW_valid = 1'b1;
        M_W_valid  = 1'b0;
        M_B_ready  = 1'b0;
        M_stall    = (M_DM_read_sel & !R_done) | (M_DM_write_sel & !W_done);//1'b1;
    end

    WDATA:begin
        M_AR_valid = 1'b0;
        M_R_ready  = 1'b0;
        M_AW_valid = 1'b0;
        M_W_valid  = 1'b1;
        M_B_ready  = 1'b0;
        M_stall    = (M_DM_read_sel & !R_done) | (M_DM_write_sel & !W_done);//~(W_done);
    end

    WRESP:begin
        M_AR_valid = 1'b0;
        M_R_ready  = 1'b0;
        M_AW_valid = 1'b0;
        M_W_valid  = 1'b0;
        M_B_ready  = 1'b1 ;
        M_stall    = (M_DM_read_sel & !R_done)| (M_DM_write_sel & !W_done);//true_read | true_write;
    end

    default: begin
        M_AR_valid = 1'b0;
        M_R_ready  = 1'b0;
        M_AW_valid = 1'b0;
        M_W_valid  = 1'b0;
        M_B_ready  = 1'b0;
        M_stall    = (M_DM_read_sel & !R_done) | (M_DM_write_sel & !W_done);//1'b0;
    end
    endcase
end
endmodule