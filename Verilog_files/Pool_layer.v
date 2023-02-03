`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/06 08:56:29
// Design Name: 
// Module Name: Pool_layer
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


module Pool_layer(
    input           work_clk,
    input           rst_n,
    input           [17:0]Conv1_AER_data_input,       //18    [17:16]spike_channel    [15:0]Vmem address    input []conv_spike_input
    input           Conv1_AER_data_FIFO_input_f,
    output  reg     Read_req,
    output  reg     [11:0]Pool_spike_AER_o,
    output  reg     Pool_spike_emit_flag
    );
    
    //
    parameter pad_pre_layer     =2;
    parameter pad_current_layer =8;
    parameter W=16;
    parameter H=11;

    parameter S_FREE     =6'b000001;
    parameter S_OPER     =6'b000010;
    parameter S_BUFF1    =6'b000100;
    parameter S_BUFF2    =6'b001000;
    parameter S_INH      =6'b010000;
    parameter S_EMIT     =6'b100000;
    
    //pool layer
    reg     [5:0]   current_state;
    reg     [5:0]   next_state;
    reg		[2:0]	 AER_channel;
    reg     [7:0]  	 AER_M,AER_N;
    // inh  ram
    reg             ram_wea;
    wire            inh_flag_i;
    wire            inh_flag_o;
    reg     [7:0]   inh_ram_address;
    assign          inh_flag_i=1;
    
    //------------AER_input flag---------------------        
    reg [31:0]conv1_spike_num;
        
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            AER_M           <=   0;
            AER_N           <=   0;
            conv1_spike_num <=   0;
            AER_channel     <=   0;
        end
        else begin
            if(Conv1_AER_data_FIFO_input_f)begin
                AER_channel <=   Conv1_AER_data_input[17:16];
                AER_M       <=   Conv1_AER_data_input[15:8]-pad_pre_layer+pad_current_layer +1;
			    AER_N       <=   Conv1_AER_data_input[ 7:0]-pad_pre_layer+pad_current_layer +1;
			    // conv spike
			    conv1_spike_num  <= conv1_spike_num+1;
            end
        end
    end
    
//------------------------------FSM---------------------------------//  
    //section1
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            current_state   <=  S_FREE;
        end
        else begin
            current_state   <=  next_state;
        end
    end
    
    //seciton2
    always @(*)begin
        if(!rst_n)begin
            next_state  =   S_FREE;
        end
        else begin
            case(current_state)
                S_FREE:begin
                    if(Conv1_AER_data_FIFO_input_f)
                        next_state  =   S_OPER;
                    else 
                        next_state  =   S_FREE;
                end
                    
                S_OPER:begin
                        next_state  =   S_BUFF1;
                end
                
                S_BUFF1:begin
                        next_state  =   S_BUFF2;
                end
                
                S_BUFF2:begin
                        next_state  =   S_INH;
                end
                    
                S_INH :begin
                     if( !inh_flag_o ) // if inh free, else  do the next job
                        next_state  =   S_EMIT;
                     else 
                        next_state  =   S_FREE;
                end
                S_EMIT:begin
                    next_state  =   S_FREE;
                end
                default:begin
                    next_state  =   S_FREE;
                end
            endcase
        end
    end
    
    //section3
    // ram_wea   spike_emit
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            inh_ram_address <=  0;
            ram_wea         <=  0;
            Pool_spike_emit_flag <=  0;
            Pool_spike_AER_o      <=  0;
        end
        else begin
            case(current_state)
                S_FREE:begin
                    Pool_spike_emit_flag    <=  0; 
                    ram_wea                 <=  0;
                    if(Conv1_AER_data_FIFO_input_f)begin
                        Read_req            <=  0;
                    end
                    else
                        Read_req            <=  1;
                end
                    
                S_OPER:begin
                    ram_wea                 <=  0;
                    Read_req                <=  0;
                end
                
                S_BUFF1:begin
                    inh_ram_address         <=  AER_M[7:4]*W + AER_N[7:4];
                end
                
                S_BUFF2,
                    
                S_INH:begin
                    ram_wea                 <=  0;
                    Read_req                <=  0;
                end
                
                S_EMIT:begin
                    Pool_spike_emit_flag    <=  1;
                    Pool_spike_AER_o[11:10] <=  AER_channel;
                    Pool_spike_AER_o[ 9: 5] <=  AER_M[7:4];
                    Pool_spike_AER_o[ 4: 0] <=  AER_N[7:4];
                    ram_wea                 <=  1;
                    Read_req                <=  0;
                end
                
                default:begin
                    ram_wea                 <=  0;
                    Pool_spike_emit_flag    <=  0;
                end
            endcase
        end
    end
    
  
    
     Pool_layer_Inh_ram Inh_RAM_pool_layer (
      .clka(work_clk),    // input wire clka
      .rsta(!rst_n),    // input wire rsta
      .wea(ram_wea),      // input wire [0 : 0] wea
      .addra(inh_ram_address),  // input wire [7 : 0] addra
      .dina(inh_flag_i),    // input wire [0 : 0] dina
      .douta(inh_flag_o)  // output wire [0 : 0] douta
    );   
    
    
    
    
    
    
    
endmodule
