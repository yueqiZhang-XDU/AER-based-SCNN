`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/02 09:36:24
// Design Name: 
// Module Name: Conv_layer_1
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


module Conv_layer_1(
    input                   work_clk,
    input                   rst_n,
    input       [15:0]      Conv1_AER_i,
    output reg              Conv1_AER_req_flag,      // when a input AER operation conpleted it changes to zero
    output wire [17:0]      Conv1_AER_spike_o,
    output wire             spike_emit_flag
    );


//  Conv layer         
    reg     [15:0]    conv1_AER_buf;
    reg               AER_input_flag;
//  address generator
    wire    [ 4:0]    conv1_A_weight;
    wire    [15:0]    conv1_A_Vmem;
    wire    [ 7:0]    conv1_current_M;
    wire    [ 7:0]    conv1_current_N;
    wire              conv1_operating_flag;
//
    // check the input AER spike       AER_input_flag
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            conv1_AER_buf   <=   16'b0;
            AER_input_flag  <=   1'b0;
        end
        else begin
            if(Conv1_AER_i==0)begin
                AER_input_flag  <=   1'b0;
            end
            else if(Conv1_AER_i != conv1_AER_buf)begin
                conv1_AER_buf   <=   Conv1_AER_i;
                AER_input_flag  <=   1'b1;
            end
            else begin
                AER_input_flag  <=   1'b0;
            end
        end
    end
    
    //address generator
    Conv_layer1_address_generator conv1_address_gen(
        .work_clk(work_clk),
        .rst_n(rst_n),
        .AER_conv_layer1(conv1_AER_buf),
        .AER_input_flag(AER_input_flag),
        .A_weight(conv1_A_weight),
        .A_Vmem(conv1_A_Vmem),
        .current_M(conv1_current_M),
        .current_N(conv1_current_N),
        .operating_flag(conv1_operating_flag)
        );

// the message request to the Input AER ram      
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Conv1_AER_req_flag   <=  0;
        end
        else begin
            if(conv1_A_weight==0)
                Conv1_AER_req_flag   <=  1; 
            else
                Conv1_AER_req_flag   <=  0;
        end
    end
    
//conv core     
    Conv_core_1 convolutional_operation_conv1(
        .work_clk(work_clk),
        .rst_n(rst_n),
        .operating_flag(conv1_operating_flag),
        .Vmem_ram_address(conv1_A_Vmem),
        .Weight_rom_address(conv1_A_weight),
        .Location_M(conv1_current_M),
        .Location_N(conv1_current_N),
        .Conv_layer1_spike(Conv1_AER_spike_o),
        .Conv_layer1_spike_emit_f(spike_emit_flag)
    );
    
    
    
endmodule
