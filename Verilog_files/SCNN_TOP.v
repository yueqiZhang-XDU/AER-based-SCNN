`timescale 1ns / 1ps
`include "defile.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/01 19:43:21
// Design Name: 
// Module Name: SCNN_TOP
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


module SCNN_TOP(
    input                   work_clk,
    input                   rst_n,
    input                   AER_input_flag_i,
    input           [15:0]  AER_data_i,
    output  reg     [31:0]  feature_result_o,
    output  reg             feature_result_output_flag
  
    );
    
//----------------------------------------------------//
// FSM
    parameter   S_WAIT          =   4'b0001;
    parameter   S_AER_IN        =   4'b0010;
    parameter   S_PROP          =   4'b0100;
    parameter   S_RESULT_OUT    =   4'b1000;
    
    reg     [3:0]   current_state;
    reg     [3:0]   next_state;  
    reg		        prop_en;
    
// input AER RAM    
    reg     [13:0]  A_AER_ram;
    reg     [15:0]  AER_buf;
    reg             AER_data_c_flag;
    reg             AER_ram_wea;
    wire    [15:0]  D_AER_ram_o;
// SCNN
    reg                             SCNN_rst_n;
    wire                            AER_req_flag;
    wire                            feature_vector_o_f;
    wire    [`Feature_V_o_width]     feature_vector_o;

// SVM   
    wire [1:0]SVM_result_o;
    wire      SVM_result_o_f;

    
//----------------------------------------------------//

// FSM
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            current_state   <=  S_WAIT;  
        end
        else
            current_state   <=  next_state;
    end

    always @(*)begin
        if(!rst_n)begin
            next_state       =  S_WAIT;
        end
        else begin
            case(current_state)
                S_WAIT:
                    if(AER_input_flag_i)
                        next_state   =  S_AER_IN;      // input AER flag=1 change the state to the S_AER_IN
                    else
                        next_state   =  S_WAIT;
                S_AER_IN:
                    if(!AER_input_flag_i)
					   next_state   =  S_PROP;         // input AER flag switch from 1 to 0; it will be prop the AER message
				    else 
					   next_state   =  S_AER_IN;
                S_PROP:
				    if(feature_vector_o_f)
					   next_state   =  S_RESULT_OUT;   // The SCNN module output the feature vector; ft_vctr_f=1
				else
					   next_state   =  S_PROP;
                S_RESULT_OUT:
				    if(feature_result_output_flag)
					   next_state   =  S_WAIT;         // when the SVM calculate the result; the feature_result_o_f = 1 end the current data inference
				    else 
					   next_state   =  S_RESULT_OUT;
                default:
                    next_state      =   S_WAIT;
            endcase
        end
    end
    
    
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            prop_en         <=  0;
            SCNN_rst_n      <=  1;
            A_AER_ram       <=  14'b0; 
            AER_ram_wea         <=  0;
        end
        else begin
            case(current_state)
                S_WAIT:
                    begin
                        prop_en     <=  0;
                        SCNN_rst_n  <=  0;       //reset the SCNN module
                    end
                S_AER_IN:
                    begin
                        SCNN_rst_n      <=  1;
                        //AER_ram_wea     <=  1;
                        if(!AER_input_flag_i)begin
                            A_AER_ram   <=  14'b1; 
                            AER_ram_wea <=  0;
                        end
                        else if(AER_data_c_flag)begin
                            A_AER_ram   <=  A_AER_ram + 1;  // when a different AER data is sending into the module change the ram address and save it into 
                            AER_ram_wea <=  1;
                        end
                        else begin
                            A_AER_ram   <=  A_AER_ram;     // when the output AER is not change any more we think ALL the AER has transmit into the SCNN
                            AER_ram_wea <=  0;
                        end
                    end
                S_PROP:
                    begin
                        prop_en         <=  1;
                        AER_ram_wea     <=  0;
                        if(D_AER_ram_o == 0)
                            A_AER_ram   <=  A_AER_ram;   // when AER ram output equals to zero£¬ we think all the input image AER is proped finished
                        else if(!AER_req_flag)
                            A_AER_ram   <=  A_AER_ram;   // if fifo full; wait 
                        else 
                            A_AER_ram   <=  A_AER_ram + 1;// if fifo not full read the next AER spike
                    end
                S_RESULT_OUT:   
                    begin
                        prop_en     <=  0;
                        A_AER_ram   <=  14'b0;
                    end
                default:
                    begin
                        prop_en         <=  0;
                        SCNN_rst_n      <=  1;
                        A_AER_ram       <=  14'b0; 
                        AER_ram_wea     <=  0;
                    end
            endcase
        end
    
    
    end
    
    
// AER ram
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            AER_buf         <=  16'b0;
            AER_data_c_flag <=  1'b0;
        end
        else begin
            if(AER_buf != AER_data_i)begin
                AER_buf         <= AER_data_i;
                AER_data_c_flag <= 1'b1;
            end  
            else begin
                AER_data_c_flag <= 1'b0;
            end
        end
        
    end
  
  
  
    AER_RAM AER_RAM_input (
        .clka(work_clk),            // input wire clka
        .rsta(!SCNN_rst_n),            // input wire rsta
        .wea(AER_ram_wea),              // input wire [0 : 0] wea
        .addra(A_AER_ram),          // input wire [13 : 0] addra
        .dina(AER_data_i),            // input wire [15 : 0] dina
        .douta(D_AER_ram_o)          // output wire [15 : 0] douta
    );
    
    
// SCNN module  
    SCNN SCNN_FACE_MOTO(
        .work_clk(work_clk),
        .rst_n(SCNN_rst_n),
        .AER_data_i(D_AER_ram_o),
        .prop_en(prop_en),
        .AER_req_flag(AER_req_flag),     // when the input AER buff is full , stop reading
        .feature_Vector_o_flag(feature_vector_o_f),
        .feature_Vector_o(feature_vector_o)
    );


    SVM SCNN_SVM(
        .work_clk(work_clk),
        .rst_n(SCNN_rst_n),
        .feature_vector_input(feature_vector_o),
        .feature_vector_input_f(feature_vector_o_f),
        .SVM_result_o(SVM_result_o),
        .SVM_result_o_f(SVM_result_o_f)
    );



// Feature_result_o
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            feature_result_o            <=  32'd0;
            feature_result_output_flag  <=  1'b0;
        end
        else begin
            if(SVM_result_o_f)begin
                feature_result_output_flag  <=  1'b1;
                case(SVM_result_o)
                    2'b01:  feature_result_o    <=  32'd1;
                    2'b10:  feature_result_o    <=  32'd2;
                    default:feature_result_o    <=  32'd0;
                endcase
            end
            else begin
                feature_result_output_flag  <=  1'b0;
            end    
        end
    end
    


    
endmodule
