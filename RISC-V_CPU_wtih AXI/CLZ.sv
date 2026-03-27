module CLZ (
    input   [`DATA_WIDTH -1:0]  significand_in,
    output  [5:0]               CLZ_result
);
    reg [`DATA_WIDTH -1:0] significand_s1;
    reg [`DATA_WIDTH -1:0] significand_s2;
    reg [`DATA_WIDTH -1:0] significand_s3;
    reg [`DATA_WIDTH -1:0] significand_s4;


    reg [5:0]              count_s16;
    reg [5:0]              count_s8;
    reg [5:0]              count_s4;
    reg [5:0]              count_s2;
    reg [5:0]              count_s1;
    always_comb begin
        if(!(significand_in & 32'hffff_0000))begin
            count_s16 = 5'd16;
            significand_s1 = {significand_in[15:0],16'b0}; 
        end
        else begin
            count_s16 = 0;
            significand_s1 = significand_in; //before significand_in = significand_s1;
        end
    end

    always_comb begin
        if(!(significand_s1 & 32'hff00_0000))begin
            count_s8 = 5'd8;
            significand_s2 = {significand_s1[23:0],8'b0}; //before [23,0] 
        end
        else begin
            count_s8 = 0;
            significand_s2 = significand_s1;
        end
    end

    always_comb begin
        if(!(significand_s2 & 32'hf000_0000))begin
            count_s4 = 5'd4;
            significand_s3 = {significand_s2[27:0],4'b0};
        end
        else begin
            count_s4 = 0;
            significand_s3 = significand_s2;
        end
        
    end
    always_comb begin
        if(!(significand_s3 & 32'hc000_0000))begin
            count_s2 = 2;
            significand_s4 = {significand_s3[29:0],2'b0};
        end
        else begin
            count_s2 =0; // before without ;
            significand_s4 = significand_s3;
        end
    end

    always_comb begin
        if(!(significand_s4 & 32'h8000_0000))begin
            count_s1 = 1;
        end
        else begin
            count_s1 = 0;
        end
    end

    assign CLZ_result = (count_s16 + count_s8) + (count_s4 + count_s2) + count_s1;
endmodule