`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/05 18:04:21
// Design Name: 
// Module Name: FIFO_Conv1_Pool
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


module FIFO_Conv1_Pool(
    input   work_clk,
    input   rst_n,
    input   [17:0]Conv1_AER_data_i,
    input   conv1_spike_emit_flag,
    input   Read_req,
    output  wire [17:0]Conv1_AER_data_FIFO_o,
    output  reg        Conv1_AER_data_FIFO_o_flag,
    output  wire       FIFO_Conv1_Pool_empty
    );
    
    reg wr_en;
    reg rd_en;
    reg [17:0]  Conv1_AER_data;
    wire        FIFO_Conv1_Pool_full;
    
    parameter S_free      =  4'b0001;
    parameter S_read_req  =  4'b0010;
    parameter S_read_data =  4'b0100;
    parameter S_req_buf   =  4'b1000;  

    reg [3:0]   current_state;
    reg [3:0]   next_state;

//fifo read
        
    //FSM section1
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            current_state   <=  S_free;
        end
        else begin
            current_state   <=  next_state;
        end
    end

    //FSM section2
    always@(*)begin
        if(!rst_n)begin
            next_state  =   S_free;
        end
        else begin
            case(current_state)
                S_free:
                begin
                    if(Read_req)
                        next_state  =   S_read_req;
                    else 
                        next_state  =   S_free;
                end
                S_read_req:
                begin
                    if(!FIFO_Conv1_Pool_empty && Read_req)
                        next_state  =   S_read_data;
                    else 
                        next_state  =   S_read_req;
                end
                S_read_data:
                begin
                    next_state  =   S_req_buf;
                end
                S_req_buf:
                begin
                    next_state  =   S_free;
                end
                default:
                begin
                    next_state  =   S_free;
                end
            endcase
        end
    end

    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            rd_en   <=  0;
            Conv1_AER_data_FIFO_o_flag<=0;
        end
        else begin
            case(current_state)
                S_free:begin
                    rd_en   <=  0;
                    Conv1_AER_data_FIFO_o_flag<=0;
                end
                S_read_req:begin
                    rd_en   <=  0;
                end
                S_read_data:begin  // every times req, when fifo not empty the rd_en only one period 
                    rd_en   <=  1;
                end
                S_req_buf:begin
                    rd_en   <=  0;
                    Conv1_AER_data_FIFO_o_flag<=1;
                end
                default begin
                    rd_en   <=  0;
                end
            endcase
        end
    end

    // spike_emit_flag
    // when the current state=S_read_data, the spike will output in the next period
    // the output spike emit flag can be pull up to 1, in the next period


// fifo write
    always @(posedge work_clk or negedge rst_n)begin 
        if(!rst_n)begin
            wr_en               <=  0;
            Conv1_AER_data      <=  0;
        end
        else begin
            if(conv1_spike_emit_flag)begin
                Conv1_AER_data      <=  Conv1_AER_data_i;
                wr_en               <=  1;
            end
            else begin
                wr_en               <=  0;
            end
        end
    
    end
    
    FIFO_Conv1_to_Pool FIFO_conv1_pool (
      .clk(work_clk),      // input wire clk
      .srst(!rst_n),    // input wire srst
      .din(Conv1_AER_data),      // input wire [17 : 0] din
      .wr_en(wr_en),  // input wire wr_en
      .rd_en(rd_en),  // input wire rd_en
      .dout(Conv1_AER_data_FIFO_o),    // output wire [17 : 0] dout
      .full(FIFO_Conv1_Pool_full),    // output wire full
      .empty(FIFO_Conv1_Pool_empty)  // output wire empty
);
    

reg [31:0]spike_cnt_conv_layer1;
always @(posedge work_clk or negedge rst_n)begin
    if(!rst_n)begin
        spike_cnt_conv_layer1<=0;
    end
    else begin
        if(conv1_spike_emit_flag)begin
            spike_cnt_conv_layer1<=spike_cnt_conv_layer1+1;
        end
        else begin
            spike_cnt_conv_layer1<=spike_cnt_conv_layer1;
        end
    end
end
    
endmodule
