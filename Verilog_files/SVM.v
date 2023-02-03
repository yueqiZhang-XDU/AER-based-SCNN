`timescale 1ns / 1ps
`include "defile.vh"

module SVM(
    input                                   work_clk,
    input                                   rst_n,
    input   [`Feature_V_o_width]            feature_vector_input,
    input                                   feature_vector_input_f,
    output  reg     [1:0]                   SVM_result_o,
    output  reg                             SVM_result_o_f
    );

	// SVM parameters 
		parameter Bias  =  16'b111_1110_1101_10110;
		parameter Beta0 =  6'b001001;
		parameter Beta1 =  6'b110101;
		parameter Beta2 =  6'b111000;
		parameter Beta3 =  6'b000011;
		parameter Beta4 =  6'b000011;
		parameter Beta5 =  6'b111101;
		parameter Beta6 =  6'b001101;
		parameter Beta7 =  6'b000111;
		parameter Beta8 =  6'b111011;
		parameter Beta9 =  6'b000101;


    reg     [ 5:0]   feature_vector_input_cnt;
    reg     [ 7:0]   Signed_FV_buff;
    reg     [ 5:0]   Signed_Beta_buff;  

    wire    [13:0]   Multi_result; // multiplier output result 
    reg     [15:0]   Multi_result_buff;  // the multi result saved in 16 bit
    reg     [15:0]   SVM_result;
    
// feature_Vector input cnt
     always@ (posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            feature_vector_input_cnt    <=  0;
        end
        else if(feature_vector_input_f)begin
            feature_vector_input_cnt    <=  feature_vector_input_cnt + 1;
        end
        else begin
            feature_vector_input_cnt    <=  0;
        end
     end
 
     always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Signed_FV_buff  <=  0;
        end
        else if(feature_vector_input_f &&  feature_vector_input_cnt[1:0]==2'b01)begin
            Signed_FV_buff  <=  {1'b0,feature_vector_input};
        end
        else begin
            Signed_FV_buff  <= Signed_FV_buff;
        end
     end
 
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Signed_Beta_buff  <=  0;
        end
        else if(feature_vector_input_f &&  feature_vector_input_cnt[1:0]==2'b01)begin
            case(feature_vector_input_cnt[5:2])
                4'b0000:    Signed_Beta_buff    <=  Beta0;
                4'b0001:    Signed_Beta_buff    <=  Beta1;
                4'b0010:    Signed_Beta_buff    <=  Beta2;
                4'b0011:    Signed_Beta_buff    <=  Beta3;
                4'b0100:    Signed_Beta_buff    <=  Beta4;
                4'b0101:    Signed_Beta_buff    <=  Beta5;
                4'b0110:    Signed_Beta_buff    <=  Beta6;
                4'b0111:    Signed_Beta_buff    <=  Beta7;
                4'b1000:    Signed_Beta_buff    <=  Beta8;                
                4'b1001:    Signed_Beta_buff    <=  Beta9;         
                default:    Signed_Beta_buff    <=  0;
            endcase
        end
    end
 
    SVM_FV_Beta SVM_multi (
      .A(Signed_FV_buff),  // input wire [7 : 0] A
      .B(Signed_Beta_buff),  // input wire [5 : 0] B
      .P(Multi_result)  // output wire [13 : 0] P
    );
    
    
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Multi_result_buff   <=  0;
        end
        else if(feature_vector_input_cnt[1:0]==2'b10)begin
            Multi_result_buff   <=  {{2{Multi_result[13]}}, Multi_result};  //   Multi_result : signed 14bit, expend it to signed 16bit
        end
        else begin
            Multi_result_buff   <= Multi_result_buff;
        end
    end
    
    
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            SVM_result  <=  Bias;
        end
        else if(feature_vector_input_cnt[1:0]==2'b11)begin
            SVM_result  <=  SVM_result + Multi_result_buff;
        end
        else begin
            SVM_result  <=  SVM_result;
        end
    end
    
    
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            SVM_result_o_f  <=  0;
            SVM_result_o    <=  0;
        end
        else begin
            if(feature_vector_input_cnt == 41)begin
                SVM_result_o_f  <=  1;
                case(SVM_result[15])
                    1'b0:   SVM_result_o    <=  2'b01;
                    1'b1:   SVM_result_o    <=  2'b10;
                    default:SVM_result_o    <=  2'b00;
                endcase
            end
            else if(feature_vector_input_cnt==0)begin
                SVM_result_o_f  <=  0;
            end
            else begin
                SVM_result_o_f  <=  SVM_result_o_f;
                SVM_result_o    <=  SVM_result_o;               
            end
        end
    end

endmodule