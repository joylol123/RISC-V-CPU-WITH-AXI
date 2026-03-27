
`define minus_abs(a,b) (a>=b ? a-b : b-a)
`include "CLZ.sv"
module EXE_FP_ALU (
    input   wire [4:0] FP_ALU_ctrl,
    // I / O
    input   wire [`DATA_WIDTH -1:0] rs1,
    input   wire [`DATA_WIDTH -1:0] rs2,
    output  wire [`DATA_WIDTH -1:0] ALU_FP_out    
);
    
    wire    compare_flag;
    reg     [`DATA_WIDTH -1:0] FPU_rs1;
    reg     [`DATA_WIDTH -1:0] FPU_rs2;

    wire    [`DATA_WIDTH -1:0] significand_rs1;
    wire    [`DATA_WIDTH -1:0] significand_rs2;
    wire    [`DATA_WIDTH -1:0] significand_rs2_s;
    wire    [5:0]              shift;
    wire    [`DATA_WIDTH:0]    significand_add; // 
    wire    [`DATA_WIDTH -1:0]    significand_sub;
    wire     [`DATA_WIDTH -1:0]    sub_normalize_temp;
    reg     [`FRACTION -1:0]   fract_add;
    reg     [`EXP -1:0]        exp_add;
    reg     [`FRACTION -1:0]   fract_sub;
    wire    [5:0]              sub_shift;
    wire    [`EXP -1:0]              exp_sub; 
    wire    [`FRACTION -1:0]   fract_out;
    wire    [`EXP      -1:0]   exp_out;
    wire                       signed_out;
    reg                               ALU_real_type;

    assign compare_flag = rs1[30:0] >= rs2[30:0];

    localparam  ALU_FP_add = 5'd22;
    localparam  ALU_FP_sub = 5'd23;
//  compare exponent 
    always_comb begin
        if(compare_flag)begin
            FPU_rs1 = rs1;
            FPU_rs2 = rs2;
        end
        else begin
            FPU_rs1 = rs2;
            FPU_rs2 = rs1;
        end
        
        
    end
assign  significand_rs1 = (FPU_rs1[30:23] == 8'd0) ? {1'b0,FPU_rs1[22:0],8'd0} : {1'b1,FPU_rs1[22:0],8'd0};
assign  significand_rs2 = (FPU_rs2[30:23] == 8'd0) ? {1'b0,FPU_rs2[22:0],8'd0} : {1'b1,FPU_rs2[22:0],8'd0};
assign  shift           =   `minus_abs(rs1[30:23],rs2[30:23]);
assign  significand_rs2_s   =   significand_rs2 >> shift;

assign  fract_out       =   ALU_real_type ? fract_add : fract_sub;
assign  exp_out         =   ALU_real_type ? exp_add   : exp_sub;
assign  signed_out      =   ((FP_ALU_ctrl == ALU_FP_sub) && !compare_flag) ? !(FPU_rs1[31]) : FPU_rs1[31]; 
assign  ALU_FP_out      =   {signed_out,exp_out,fract_out};
// ============================= operation type =====================//

always_comb begin
    case (FP_ALU_ctrl)
        ALU_FP_add: ALU_real_type =     !(FPU_rs1[31] ^ FPU_rs2[31]);
        ALU_FP_sub: ALU_real_type =       FPU_rs1[31] ^ FPU_rs2[31];
        default:    ALU_real_type =     !(FPU_rs1[31]  ^ FPU_rs2[31]);// before !(FPU_rs1[31  ^ FPU_rs2[31]]) 
    endcase
end
// ADD
assign  significand_add =   significand_rs1 +   significand_rs2_s;

always_comb begin 

    if(significand_add[32])begin
        exp_add = FPU_rs1[30:23] + 8'd1;

        if(significand_add[8:7] == 2'b11)begin // Situation G & R == 11 
            fract_add   =   significand_add[31:9] + 23'd1;
        end

        else if(significand_add[8:7] == 2'b10)begin
        // sticky bit + LSB
            if( | significand_add[6:0] || significand_add[9])begin
                fract_add   =   significand_add[31:9] + 23'd1;
            end
            else begin
                fract_add   =   significand_add[31:9] ; 
            end
        end
        else begin
            fract_add   =   significand_add[31:9];
        end
    end

    else begin
        exp_add =   FPU_rs1[30:23];

        if(significand_add[7:6] ==  2'b11)begin // G
            fract_add   =  significand_add[30:8] + 23'd1;

        end
        else if(significand_add[7:6] == 2'b10)begin
            if( | significand_add[5:0] || significand_add[8])begin
                fract_add   =  significand_add[30:8] + 23'd1;
            end
            else begin
                fract_add   =  significand_add[30:8];
            end

        end
        else begin
            fract_add   =  significand_add[30:8];
        end

    end

end

// ============================= SUB ===================================//
assign  significand_sub = significand_rs1 - significand_rs2_s;

//CLZ
CLZ CLZ_inst(
    .significand_in(significand_sub),
    .CLZ_result(sub_shift)
);
assign  exp_sub =   FPU_rs1[30:23] - sub_shift;
assign  sub_normalize_temp  =   significand_sub <<  sub_shift;
always_comb begin
    if(sub_normalize_temp[7:6] == 2'b11)begin
        fract_sub = sub_normalize_temp[30:8]    +   23'd1;
    end
    else if(sub_normalize_temp[7:6] == 2'b10)begin
        if( | sub_normalize_temp[5:0] || sub_normalize_temp[8])begin
            fract_sub = sub_normalize_temp[30:8] + 23'd1;
        end
        else begin
            fract_sub = sub_normalize_temp[30:8];
        end
    end
    else begin
        fract_sub   =   sub_normalize_temp[30:8];
    end
end

endmodule