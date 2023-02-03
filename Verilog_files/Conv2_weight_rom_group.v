`timescale 1ns / 1ps
`include "defile.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/07 11:21:11
// Design Name: 
// Module Name: Conv2_weight_rom_group
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Conv2_weight_rom_group(   
    input                                   work_clk,
    input                                   rst_n,
    input      [3:0]                        AER_channel,
    input      [`A_weight_rom_width_conv2]   addra,   //  8bit  address width
    output reg [`D_weight_rom_width_conv2]  douta    //  20bit  weight data
    );

// [ 7:0] addra  is  addra of all the weight rom 
// [49:0] douta  is  the ouput of the weight 
    wire    [`D_weight_rom_width_conv2]	D_weight_C1;
    wire    [`D_weight_rom_width_conv2]	D_weight_C2;
    wire    [`D_weight_rom_width_conv2]	D_weight_C3;
    wire    [`D_weight_rom_width_conv2]	D_weight_C4;


    //weight_rom
        Conv2_weight_rom_1  conv2_rom1 (
        .clka(work_clk),    // input wire clka
        .addra(addra),  // input wire [7 : 0] addra
        .douta(D_weight_C1)  // output wire [49 : 0] douta
        );

        Conv2_weight_rom_2  conv2_rom2 (
        .clka(work_clk),    // input wire clka
        .addra(addra),  // input wire [7 : 0] addra
        .douta(D_weight_C2)  // output wire [49 : 0] douta
        );

        Conv2_weight_rom_3  conv2_rom3 (
        .clka(work_clk),    // input wire clka
        .addra(addra),  // input wire [7 : 0] addra
        .douta(D_weight_C3)  // output wire [49 : 0] douta
        );

        Conv2_weight_rom_4  conv2_rom4 (
        .clka(work_clk),    // input wire clka
        .addra(addra),  // input wire [7 : 0] addra
        .douta(D_weight_C4)  // output wire [49 : 0] douta
        );
        
//  4-1 MUX
always @(*)begin
    if(!rst_n)
        douta   =   0;
    else begin
        case(AER_channel)
            4'b0001:      douta   =   D_weight_C1;
            4'b0010:      douta   =   D_weight_C2;
            4'b0100:      douta   =   D_weight_C3;
            4'b1000:      douta   =   D_weight_C4;
            default:    douta   =   0;
        endcase
    end
end
    
    
endmodule
