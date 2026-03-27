module WB_Stage (
    input   wire                       data_sel,
    input   wire    [`DATA_WIDTH -1:0] WB_rd_dir,
    input   wire    [`DATA_WIDTH -1:0] WB_rd_DM,
    output  wire    [`DATA_WIDTH -1:0] WB_rd_data
);
    assign  WB_rd_data  =   ( data_sel ) ? WB_rd_DM : WB_rd_dir;
endmodule