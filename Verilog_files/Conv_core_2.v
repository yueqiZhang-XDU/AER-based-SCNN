`timescale 1ns / 1ps
`include "defile.vh"

module Conv_core_2(
    input   work_clk,
    input   rst_n,
    input   operating_flag,
    input   [`A_Vmem_ram_width_conv2]    Vmem_ram_address,
    input   [`A_weight_rom_width_conv2]  Weight_rom_address,
    input   [ 3:0]  Conv2_layer_AER_channel,
    input   [ 4:0]  Location_M,
    input   [ 4:0]  Location_N,
    input           MAX_req,
    output	reg	    				      feature_vector_o_f,
    output	reg	     [`Feature_V_o_width]  V_mem_feature_o
    );
    
    parameter Vmem_depth  = `conv2_image_pad_H * `conv2_image_pad_W ;   // The depth of Vmem
    parameter feature_vector_cnt_end = 45;
// weight rom    
    wire    [`D_weight_rom_width_conv2]  Weight_read_data;
// Vmem ram
    wire    [`D_Vmem_ram_width_conv2]    Vmem_read_data;
    wire    [`A_Vmem_ram_width_conv2]    Vmem_read_address;
    reg     [`D_Vmem_ram_width_conv2]    Vmem_write_data;
    reg     [`A_Vmem_ram_width_conv2]    Vmem_write_address;
    reg     Vmem_wea_buf_1;
    reg     Vmem_wea;
 
// Vmem opeartion 
    reg                                 inh_flag;
    reg                                 pad_inh_flag;
    reg     [`A_Vmem_ram_width_conv2]   Vmem_address_buf_1;
    reg     [`A_Vmem_ram_width_conv2]   Vmem_address_buf_2;
    reg     [`conv2_Vmem_width]         Vmem_adder_1;
    reg     [`conv2_Vmem_width]         Vmem_adder_2;
    reg     [`conv2_Vmem_width]         Vmem_adder_3;
    reg     [`conv2_Vmem_width]         Vmem_adder_4;
    reg     [`conv2_Vmem_width]         Vmem_adder_5;
    reg     [`conv2_Vmem_width]         Vmem_adder_6;
    reg     [`conv2_Vmem_width]         Vmem_adder_7;
    reg     [`conv2_Vmem_width]         Vmem_adder_8;
    reg     [`conv2_Vmem_width]         Vmem_adder_9;
    reg     [`conv2_Vmem_width]         Vmem_adder_10;

// Feature Vector generator        
    reg     [`A_Vmem_ram_width_conv2]   Vmem_read_address_max;  // from 1 to 100 
    reg     [`conv2_Vmem_width]         Vmem_max_1;
    reg     [`conv2_Vmem_width]         Vmem_max_2;
    reg     [`conv2_Vmem_width]         Vmem_max_3;
    reg     [`conv2_Vmem_width]         Vmem_max_4;
    reg     [`conv2_Vmem_width]         Vmem_max_5;
    reg     [`conv2_Vmem_width]         Vmem_max_6;
    reg     [`conv2_Vmem_width]         Vmem_max_7;
    reg     [`conv2_Vmem_width]         Vmem_max_8;
    reg     [`conv2_Vmem_width]         Vmem_max_9;
    reg     [`conv2_Vmem_width]         Vmem_max_10;
    
    reg     [5:0]   feature_vector_output_cnt;

    // read address
    assign Vmem_read_address = MAX_req ? Vmem_read_address_max : Vmem_ram_address;
    
    
    
    //write address and ram wea 
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Vmem_wea_buf_1            <=  0;
        end
        else begin
            if(operating_flag)begin
                Vmem_wea_buf_1            <=  1;
            end
            else begin
                Vmem_wea_buf_1            <=  0;
            end
        end
    end
    
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Vmem_wea            <=  0;
        end
        else begin
            if(Vmem_wea_buf_1)begin
                Vmem_wea            <=  1;
            end
            else begin
                Vmem_wea            <=  0;
            end
        end
    end
    
//pad inh flag   operate from the Location_M_buf_1
always @(posedge work_clk or negedge rst_n)begin
    if(!rst_n)begin
        pad_inh_flag    <= 0;
    end
    else begin
        if( Location_M < (`conv2_pad) || Location_M >= (`conv2_pad + `conv2_image_H) )       // [0-7]  [8+11=19]
            pad_inh_flag    <= 1;
        else if( Location_N < (`conv2_pad) || Location_N >= (`conv2_pad + `conv2_image_W) )  // [0-7]  [8+16=24]
            pad_inh_flag    <= 1;
        else
            pad_inh_flag    <= 0;
    end
end
    
    
// Vmem operation  
   // in the first period, if in the prop state send the read address to the Vmem ram and weight rom
        //Vmem_ram_address; Weight_rom_address; Location_M; Location_N  
        
   // in the second period, get the value of the Vmem_data and weight_data
        //Vmem_read_data;  Weight_read_data; Vmem_ram_address_buf1=Vmem_ram_address;  judge the inh flag from the location_N location_N
        
   // in the third period, add the Vmem_read_data and the Weight_read_data, store the add result into the adder
        // adder = Vmem_read_data + weight_read_data; Vmem_ram_address_buf2=Vmem_ram_address_buf1
        
   // in the forth period, got the write data from the adder and the Vmem_write_address to up data the Vmem of the operating address
        // updata the Vmem_write_data= {adder1,adder2,.....}  Vmem_write_address = Vmem_ram_address_buf2
    
    always @(posedge work_clk or negedge rst_n)begin  //the third period
        if(!rst_n)begin
            Vmem_adder_1        <=  0;
            Vmem_adder_2        <=  0;
            Vmem_adder_3        <=  0;
            Vmem_adder_4        <=  0;
            Vmem_adder_5        <=  0;
            Vmem_adder_6        <=  0;
            Vmem_adder_7        <=  0;
            Vmem_adder_8        <=  0;
            Vmem_adder_9        <=  0;
            Vmem_adder_10       <=  0;
            Vmem_address_buf_1  <=  0;
        end
        else begin 
            Vmem_address_buf_1  <=  Vmem_ram_address;
            if(MAX_req)begin
                Vmem_adder_1        <=  0;
                Vmem_adder_2        <=  0;
                Vmem_adder_3        <=  0;
                Vmem_adder_4        <=  0;
                Vmem_adder_5        <=  0;
                Vmem_adder_6        <=  0;
                Vmem_adder_7        <=  0;
                Vmem_adder_8        <=  0;
                Vmem_adder_9        <=  0;
                Vmem_adder_10       <=  0;
                Vmem_address_buf_1  <=  0;
            end
            else if(Vmem_read_data[`conv2_inh_f]==1 || pad_inh_flag)begin
                Vmem_adder_1   <=  Vmem_read_data[`conv2_Vmem1];
                Vmem_adder_2   <=  Vmem_read_data[`conv2_Vmem2];
                Vmem_adder_3   <=  Vmem_read_data[`conv2_Vmem3];                                            
                Vmem_adder_4   <=  Vmem_read_data[`conv2_Vmem4];
                Vmem_adder_5   <=  Vmem_read_data[`conv2_Vmem5];
                Vmem_adder_6   <=  Vmem_read_data[`conv2_Vmem6];
                Vmem_adder_7   <=  Vmem_read_data[`conv2_Vmem7];
                Vmem_adder_8   <=  Vmem_read_data[`conv2_Vmem8];
                Vmem_adder_9   <=  Vmem_read_data[`conv2_Vmem9];
                Vmem_adder_10  <=  Vmem_read_data[`conv2_Vmem10];
                inh_flag       <=  1;
            end
            else begin
                Vmem_adder_1   <=  Vmem_read_data[`conv2_Vmem1]    +   Weight_read_data[`conv2_weight1];
                Vmem_adder_2   <=  Vmem_read_data[`conv2_Vmem2]    +   Weight_read_data[`conv2_weight2];
                Vmem_adder_3   <=  Vmem_read_data[`conv2_Vmem3]    +   Weight_read_data[`conv2_weight3];                                            
                Vmem_adder_4   <=  Vmem_read_data[`conv2_Vmem4]    +   Weight_read_data[`conv2_weight4];
                Vmem_adder_5   <=  Vmem_read_data[`conv2_Vmem5]    +   Weight_read_data[`conv2_weight5];
                Vmem_adder_6   <=  Vmem_read_data[`conv2_Vmem6]    +   Weight_read_data[`conv2_weight6];
                Vmem_adder_7   <=  Vmem_read_data[`conv2_Vmem7]    +   Weight_read_data[`conv2_weight7];
                Vmem_adder_8   <=  Vmem_read_data[`conv2_Vmem8]    +   Weight_read_data[`conv2_weight8];
                Vmem_adder_9   <=  Vmem_read_data[`conv2_Vmem9]    +   Weight_read_data[`conv2_weight9];
                Vmem_adder_10  <=  Vmem_read_data[`conv2_Vmem10]   +   Weight_read_data[`conv2_weight10];
                inh_flag       <=  0;
            end
        end
    end
    
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Vmem_write_data     <=  0;
            Vmem_address_buf_2  <=  0;
        end
        else begin
            Vmem_address_buf_2 <=  Vmem_address_buf_1;
            Vmem_write_data[`conv2_Vmem1]   <=  Vmem_adder_1;
            Vmem_write_data[`conv2_Vmem2]   <=  Vmem_adder_2;
            Vmem_write_data[`conv2_Vmem3]   <=  Vmem_adder_3;
            Vmem_write_data[`conv2_Vmem4]   <=  Vmem_adder_4;
            Vmem_write_data[`conv2_Vmem5]   <=  Vmem_adder_5;       
            Vmem_write_data[`conv2_Vmem6]   <=  Vmem_adder_6;
            Vmem_write_data[`conv2_Vmem7]   <=  Vmem_adder_7;
            Vmem_write_data[`conv2_Vmem8]   <=  Vmem_adder_8;
            Vmem_write_data[`conv2_Vmem9]   <=  Vmem_adder_9;
            Vmem_write_data[`conv2_Vmem10]  <=  Vmem_adder_10;            
            // change the inh_flag of the write Vmem_data; 
            if(inh_flag)begin
                Vmem_write_data[`conv2_inh_f] <=  1;
            end
            else begin
                Vmem_write_data[`conv2_inh_f] <=  0;
            end
        end
    end
    
    
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Vmem_write_address  <=  0;
        end
        else begin
            Vmem_write_address  <=  Vmem_address_buf_2;
        end
    end
    
    
    
    
    
    
// spike convolutional operation
    //weight rom
    Conv2_weight_rom_group conv2_rom(   
    .work_clk(work_clk),
    .rst_n(rst_n),
    .AER_channel(Conv2_layer_AER_channel),    // 4bit  channel select
    .addra(Weight_rom_address),              //  8bit  address width
    .douta(Weight_read_data)                  //  20bit  weight data
    );
    

    //Vmem ram
    Conv_layer2_Vmem_ram conv2_ram (
      .clka(work_clk),    // input wire clka
      .wea(Vmem_wea),      // input wire [0 : 0] wea
      .addra(Vmem_write_address),  // input wire [9 : 0] addra
      .dina(Vmem_write_data),    // input wire [70 : 0] dina
      .clkb(work_clk),    // input wire clkb
      .rstb(!rst_n),    // input wire rstb
      .addrb(Vmem_read_address),  // input wire [9 : 0] addrb
      .doutb(Vmem_read_data)  // output wire [70 : 0] doutb
    );




// the conv layer 2 do not emit spikes but it has the feature vector generate function
    //feature_vector_o_f  feature_vector_o
    
//  Vmem feature Vector generate     
 
    // MAX address
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Vmem_read_address_max  <=  Vmem_depth;
        end
        else if( !(|Vmem_read_address_max))begin
            Vmem_read_address_max  <=  Vmem_read_address_max;
        end
        else if(MAX_req)begin
            Vmem_read_address_max  <=  Vmem_read_address_max - 1;
        end
        else begin
            Vmem_read_address_max  <=  Vmem_depth;
        end
    end 
    
    always@(posedge work_clk or negedge rst_n)begin  // Vmem_max_1
        if(!rst_n)begin
            Vmem_max_1  <=  0;
        end
        else if(MAX_req && Vmem_read_data[`conv2_Vmem1]>Vmem_max_1)begin
            Vmem_max_1  <=  Vmem_read_data[`conv2_Vmem1];
        end
        else begin
            Vmem_max_1  <=  Vmem_max_1;
        end 
    end
    
    always@(posedge work_clk or negedge rst_n)begin  // Vmem_max_2
        if(!rst_n)begin
            Vmem_max_2  <=  0;
        end
        else if(MAX_req && Vmem_read_data[`conv2_Vmem2]>Vmem_max_2)begin
            Vmem_max_2  <=  Vmem_read_data[`conv2_Vmem2];
        end
        else begin
            Vmem_max_2  <=  Vmem_max_2;
        end 
    end
    
    always@(posedge work_clk or negedge rst_n)begin  // Vmem_max_3
        if(!rst_n)begin
            Vmem_max_3  <=  0;
        end
        else if(MAX_req && Vmem_read_data[`conv2_Vmem3]>Vmem_max_3)begin
            Vmem_max_3  <=  Vmem_read_data[`conv2_Vmem3];
        end
        else begin
            Vmem_max_3  <=  Vmem_max_3;
        end 
    end
    
    always@(posedge work_clk or negedge rst_n)begin  // Vmem_max_4
        if(!rst_n)begin
            Vmem_max_4  <=  0;
        end
        else if(MAX_req && Vmem_read_data[`conv2_Vmem4]>Vmem_max_4)begin
            Vmem_max_4  <=  Vmem_read_data[`conv2_Vmem4];
        end
        else begin
            Vmem_max_4  <=  Vmem_max_4;
        end 
    end 
    
    always@(posedge work_clk or negedge rst_n)begin  // Vmem_max_5
        if(!rst_n)begin
            Vmem_max_5  <=  0;
        end
        else if(MAX_req && Vmem_read_data[`conv2_Vmem5]>Vmem_max_5)begin
            Vmem_max_5  <=  Vmem_read_data[`conv2_Vmem5];
        end
        else begin
            Vmem_max_5  <=  Vmem_max_5;
        end 
    end 
    
    always@(posedge work_clk or negedge rst_n)begin  // Vmem_max_6
        if(!rst_n)begin
            Vmem_max_6  <=  0;
        end
        else if(MAX_req && Vmem_read_data[`conv2_Vmem6]>Vmem_max_6)begin
            Vmem_max_6  <=  Vmem_read_data[`conv2_Vmem6];
        end
        else begin
            Vmem_max_6  <=  Vmem_max_6;
        end 
    end 
    
    always@(posedge work_clk or negedge rst_n)begin  // Vmem_max_7
        if(!rst_n)begin
            Vmem_max_7  <=  0;
        end
        else if(MAX_req && Vmem_read_data[`conv2_Vmem7]>Vmem_max_7)begin
            Vmem_max_7  <=  Vmem_read_data[`conv2_Vmem7];
        end
        else begin
            Vmem_max_7  <=  Vmem_max_7;
        end 
    end
    
    always@(posedge work_clk or negedge rst_n)begin  // Vmem_max_8
        if(!rst_n)begin
            Vmem_max_8  <=  0;
        end
        else if(MAX_req && Vmem_read_data[`conv2_Vmem8]>Vmem_max_8)begin
            Vmem_max_8  <=  Vmem_read_data[`conv2_Vmem8];
        end
        else begin
            Vmem_max_8  <=  Vmem_max_8;
        end 
    end
    
    always@(posedge work_clk or negedge rst_n)begin  // Vmem_max_9
        if(!rst_n)begin
            Vmem_max_9  <=  0;
        end
        else if(MAX_req && Vmem_read_data[`conv2_Vmem9]>Vmem_max_9)begin
            Vmem_max_9  <=  Vmem_read_data[`conv2_Vmem9];
        end
        else begin
            Vmem_max_9  <=  Vmem_max_9;
        end 
    end    
    
    always@(posedge work_clk or negedge rst_n)begin  // Vmem_max_10
        if(!rst_n)begin
            Vmem_max_10  <=  0;
        end
        else if(MAX_req && Vmem_read_data[`conv2_Vmem10]>Vmem_max_10)begin
            Vmem_max_10  <=  Vmem_read_data[`conv2_Vmem10];
        end
        else begin
            Vmem_max_10  <=  Vmem_max_10;
        end 
    end   


// generate the output product
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            feature_vector_output_cnt   <=  0;
        end
        else if (feature_vector_output_cnt == feature_vector_cnt_end )begin
            feature_vector_output_cnt = feature_vector_output_cnt;
        end
        else if(MAX_req && Vmem_read_address_max==0)begin
            feature_vector_output_cnt   <= feature_vector_output_cnt+1;
        end
        else begin
            feature_vector_output_cnt   <=  0;
        end
    end

//    output	reg	    				      feature_vector_o_f
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            feature_vector_o_f  <=  0;
        end
        else if(feature_vector_output_cnt == 6'b101101)        
            feature_vector_o_f  <=  0;
        else if(MAX_req && feature_vector_output_cnt == 6'b000011)
            feature_vector_o_f  <=  1;
        else 
            feature_vector_o_f  <=  feature_vector_o_f;
    end
//    output	reg	     [`Feature_V_o_width]  V_mem_feature_o
//      reg     [5:0]   feature_vector_output_cnt;
    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            V_mem_feature_o <=  0;
        end
        else begin
            case(feature_vector_output_cnt[5:2])
                4'b0001:    V_mem_feature_o <=  Vmem_max_1;
                4'b0010:    V_mem_feature_o <=  Vmem_max_2;
                4'b0011:    V_mem_feature_o <=  Vmem_max_3;
                4'b0100:    V_mem_feature_o <=  Vmem_max_4;
                4'b0101:    V_mem_feature_o <=  Vmem_max_5;
                4'b0110:    V_mem_feature_o <=  Vmem_max_6;
                4'b0111:    V_mem_feature_o <=  Vmem_max_7;
                4'b1000:    V_mem_feature_o <=  Vmem_max_8;
                4'b1001:    V_mem_feature_o <=  Vmem_max_9;
                4'b1010:    V_mem_feature_o <=  Vmem_max_10;
                default:    V_mem_feature_o <=  0;
            endcase
        end
    end














endmodule
