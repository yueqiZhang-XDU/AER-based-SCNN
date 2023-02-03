`timescale 1ns / 1ps
`include "defile.vh"


module SCNN(
    input                                work_clk,
    input                                rst_n,
    input        [15:0]                  AER_data_i,
    input                                prop_en,
    output  wire                         AER_req_flag,     //  pull up to 1 for one period when need AER to put into   这个一个周期的上升时钟是用来改地址的
    output  wire                        feature_Vector_o_flag,
    output  wire [`Feature_V_o_width]    feature_Vector_o
    );
    

// Conv layer 1
    reg     [15:0]  AER_data_buf;
    wire    [17:0]  Conv1_spike_AER_o;
    wire            Conv1_spike_emit_flag;
// Conv layer 1 fifo
    wire    [17:0]  Conv1_AER_data_FIFO_o;
    wire            Conv1_AER_data_FIFO_o_flag;
    wire            FIFO_Conv1_Pool_empty;
// Pool layer 1
    wire            Pool_layer_read_req;
    wire    [11:0]  Pool_spike_AER_o;
    wire            Pool_spike_emit_flag;
// Pool layer fifo
    wire    [11:0]  Pool_AER_data_FIFO_o;
    wire            Pool_AER_data_FIFO_o_flag;
    wire            FIFO_Pool_Conv2_empty;
// Conv layer 2
    wire            Conv2_layer_read_req;

// Max_req
    parameter      prop_end_num = 256;
    wire            MAX_req;
    reg      [8:0]  prop_end_cnt;
//------------------------------------------------------//
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            AER_data_buf    <=  16'b0;
        end
        else begin
            if(prop_en)
                AER_data_buf    <=  AER_data_i;
            else
                AER_data_buf    <=  16'b0;
        end
    end

    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            prop_end_cnt    <=  0;
        end
        else if( Conv1_AER_data_FIFO_o_flag || Pool_AER_data_FIFO_o_flag || AER_req_flag)
            prop_end_cnt    <=  0;
        else if(&prop_end_cnt)begin
            prop_end_cnt    <=  prop_end_cnt;
        end
        else if( prop_en==1 ) begin
            prop_end_cnt    <=  prop_end_cnt + 1;
        end
        else begin
            prop_end_cnt    <=  0;
        end
    end


    assign MAX_req = prop_end_cnt[8];


    
    Conv_layer_1    SCNN_conv1(
        .work_clk(work_clk),
        .rst_n(rst_n),
        .Conv1_AER_i(AER_data_buf),
        .Conv1_AER_req_flag(AER_req_flag),      // when a input AER operation conpleted it changes to zero
        .Conv1_AER_spike_o(Conv1_spike_AER_o),
        .spike_emit_flag(Conv1_spike_emit_flag)
    );
    
    
    FIFO_Conv1_Pool SCNN_FIFO_Conv1(
        .work_clk(work_clk),
        .rst_n(rst_n),
        .Conv1_AER_data_i(Conv1_spike_AER_o),
        .conv1_spike_emit_flag(Conv1_spike_emit_flag),
        .Read_req(Pool_layer_read_req),
        .Conv1_AER_data_FIFO_o(Conv1_AER_data_FIFO_o),
        .Conv1_AER_data_FIFO_o_flag(Conv1_AER_data_FIFO_o_flag),
        .FIFO_Conv1_Pool_empty(FIFO_Conv1_Pool_empty)
    );
    
    
    Pool_layer      SCNN_pool(
        .work_clk(work_clk),
        .rst_n(rst_n),
        .Conv1_AER_data_input(Conv1_AER_data_FIFO_o),
        .Conv1_AER_data_FIFO_input_f(Conv1_AER_data_FIFO_o_flag),
        .Read_req(Pool_layer_read_req),
        .Pool_spike_AER_o(Pool_spike_AER_o),
        .Pool_spike_emit_flag(Pool_spike_emit_flag)
    );
    
    FIFO_Pool_Conv2 SCNN_FIFO_Pool(
        .work_clk(work_clk),
        .rst_n(rst_n),
        .Pool_AER_data_i(Pool_spike_AER_o),
        .Pool_spike_emit_flag(Pool_spike_emit_flag),
        .Read_req(Conv2_layer_read_req),
        .Pool_AER_data_FIFO_o(Pool_AER_data_FIFO_o),
        .Pool_AER_data_FIFO_o_flag(Pool_AER_data_FIFO_o_flag),
        .FIFO_Pool_Conv2_empty(FIFO_Pool_Conv2_empty)
    );
    
    
    
    Conv_layer_2    SCNN_Conv2(
        .work_clk(work_clk),
        .rst_n(rst_n),
        .Conv2_AER_i(Pool_AER_data_FIFO_o),
        .Conv2_AER_input_flag(Pool_AER_data_FIFO_o_flag),
        .Conv2_AER_req_flag(Conv2_layer_read_req),        // when a input AER operation conpleted it changes to zero
        .MAX_req(MAX_req),
        .Feature_Vector_o(feature_Vector_o),
        .Feature_Vector_o_flag(feature_Vector_o_flag)
    );
    
    
    
    
    
    
endmodule
