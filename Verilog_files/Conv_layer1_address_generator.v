`timescale 1ns / 1ps
`include "defile.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/02 10:16:52
// Design Name: 
// Module Name: Conv_layer1_address_generator
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


module Conv_layer1_address_generator(
    input   			work_clk,
    input   			rst_n,
    input   [15:0]      AER_conv_layer1,
    input               AER_input_flag,
    output  reg [ 4:0]  A_weight,
    output  reg [15:0]  A_Vmem,
    output  reg [ 7:0]  current_M,
    output  reg [ 7:0]  current_N,
    output  reg         operating_flag
    );
    
    
    
    parameter   S_FREE  =3'b001;
    parameter   S_OPER  =3'b010;
    parameter   S_END   =3'b100;
    

    reg     [15:0]addr_initial;
    reg     [ 3:0]countN,countM;
    
    
//FSM
	reg    [3:0]current_state;
	reg    [3:0]next_state;

    //section1
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            current_state   <=  S_FREE;
        end
        else begin
            current_state   <=  next_state;
        end
    end
	
	//section2
    always @(*)begin
        if(!rst_n)begin
            next_state  <=  S_FREE;
		end
		else begin
			case(current_state)
				S_FREE:
				    begin
                        if(AER_input_flag)    // this signal just has one period
                            next_state  <=  S_OPER;
                        else
                            next_state  <=  S_FREE;
                    end
                S_OPER:
                    begin
                        if(A_weight==1)
                            next_state  <=  S_END;
                        else
                            next_state  <=  S_OPER;
                    end
				S_END:
				    begin
				        next_state  <=  S_FREE;
				    end
				default:
					    next_state  <=  S_FREE;
			endcase
        end
    end

    //section3
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            A_weight        <=  `weight_rom_conv1_Address_initial;  //25
            operating_flag  <=  0;
        end
        else begin
            case(current_state)
                S_FREE:
                    begin
                        operating_flag  <=  0;
                        A_weight        <=  `weight_rom_conv1_Address_initial;
                    end
                S_OPER:
                    begin
                        operating_flag  <=  1;
                        A_weight        <=  A_weight-1;
                    end
                S_END :
                    begin
                        operating_flag  <=  1;
                        A_weight        <=  `weight_rom_conv1_Address_initial;
                    end
            endcase
        end
    end


    //addr initial
    always @(posedge work_clk or negedge rst_n)begin
       if(!rst_n)begin
            addr_initial<=0;
        end
        else begin
            if(AER_input_flag)
                addr_initial    <=  AER_conv_layer1[15:8] * (`conv1_image_pad_W) +   AER_conv_layer1[7:0]; // get the initial address
            else begin
                if(countN==`conv1_filter_size-1)
                    addr_initial<=addr_initial + `conv1_image_pad_W;
                else begin
                    addr_initial<=addr_initial;
                end
            end    
        end
    end

    // count M  countN
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            countN          <=  0;
            countM          <=  0;    
        end
        else begin
            if(current_state==S_OPER)begin
                if(countN==`conv1_filter_size-1)begin
                   countN   <=  0;
                   countM   <=  countM+1;
                end
                else begin
                    countN  <=  countN+1;
                end
            end
            else begin
                countN      <=  0;
                countM      <=  0;  
            end
        end
    end            
            
    // current M  current N        
    always @(posedge work_clk or negedge rst_n)begin       
        if(!rst_n)begin
            current_M   <=  0;
            current_N   <=  0;      
        end
        else begin
            if(current_state==S_OPER)begin
                current_M   <=  AER_conv_layer1[15:8] + countM;
                current_N   <=  AER_conv_layer1[ 7:0] + countN;   
            end
            else begin
                current_M   <=  0;
                current_N   <=  0;
            end
        end
    end
    
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            A_Vmem  <=  0;
        end
        else begin
            if(current_state == S_OPER)begin
                A_Vmem  <=  addr_initial+countN;
            end
            else begin
                A_Vmem  <=  0;
            end
        end
    end
 
            
endmodule



