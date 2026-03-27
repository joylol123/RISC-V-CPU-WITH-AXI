module ID_FP_RegFile (

    input   wire clk,   rst,
// CTRL
    input   wire        reg_write,

// I / O
    input   wire [4:0]  rs1_addr,
    input   wire [4:0]  rs2_addr,

    input   wire [4:0]  rd_addr,
    input   wire [`DATA_WIDTH -1 : 0]   rd_data,
    output   wire [`DATA_WIDTH -1 : 0]   rs1_FP_data,
    output   wire [`DATA_WIDTH -1 : 0]   rs2_FP_data


);
// int
integer i;

reg [31:0] x_fp_reg[31:0];
// rs1 、 rs2 data
assign  rs1_FP_data =   x_fp_reg[rs1_addr];
assign  rs2_FP_data =   x_fp_reg[rs2_addr];

always_ff @(posedge clk or posedge rst) begin
    if(rst)begin
        for (i = 0;i < 32 ;i = i + 1 ) begin
            x_fp_reg[i] <= 32'b0;
        end
    end

    else if(reg_write) begin
        x_fp_reg[rd_addr]   <=  rd_data;
    end
    
end
    

endmodule