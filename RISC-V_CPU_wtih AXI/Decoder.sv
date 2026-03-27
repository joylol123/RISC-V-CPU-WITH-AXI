module Decoder (
    input clk,rst,

    // INPUT
    input [`AXI_ADDR_BITS - 1:0] IN_addr,
    input                        IN_valid,
    output  logic                IB_Ready, // B mean invert

    //slave 0
    input                       O0_ready,
    output  logic               O0_valid,
    //slave 1
    input                       O1_ready,
    output  logic               O1_valid,

    //default slave
    input                       Odefault_slave_ready,
    output  logic               Odefault_slave_valid

);


always_comb begin

    case (IN_addr[31:16])
        16'h0000:begin
            IB_Ready    =   IN_valid ? O0_ready : 1'b1;
            O0_valid    =   IN_valid;
            O1_valid     =   1'b0;
            Odefault_slave_valid    =   1'b0;
        end 

        16'h0001:begin
            IB_Ready    =   IN_valid ? O1_ready : 1'b1;
            O0_valid    =   1'b0;
            O1_valid    =   IN_valid;
            Odefault_slave_valid    =   1'b0;
        end

        default:begin
            IB_Ready    =   IN_valid ? Odefault_slave_ready : 1'b1;
            O0_valid    =   1'b0;
            O1_valid    =   1'b0;
            Odefault_slave_valid    =   1'b0;  
        end

    endcase
    
end
endmodule