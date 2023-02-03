`timescale 1ns / 1ps
`include "defile.vh"


module Conv_core_1(
    input   work_clk,
    input   rst_n,
    input   operating_flag,
    input   [15:0]  Vmem_ram_address,
    input   [ 4:0]  Weight_rom_address,
    input   [ 7:0]  Location_M,
    input   [ 7:0]  Location_N,
    output  reg  [17:0]  Conv_layer1_spike,
    output  reg          Conv_layer1_spike_emit_f      
    );
    
    parameter Vth   =   4'b110_0;
    
// Vmem ram and weight rom
    wire    [7:0]    Weight_read_data;
    wire    [16:0]   Vmem_read_data;
    reg     [16:0]   Vmem_write_data; // write the Vmem+weight into the ram
    reg     [15:0]   Vmem_write_address;   
    reg              Vmem_wea_buf_1;
    reg              Vmem_wea;
    //  Vmem_read_address = Vmem_ram_address from input
//Vmem operation
    reg                    inh_flag;
    reg                    pad_inh_flag;
    reg     [15:0]         Vmem_address_buf_1;
    reg     [15:0]         Vmem_address_buf_2;
    reg     [`conv1_Vmem_width] Vmem_adder_1;
    reg     [`conv1_Vmem_width] Vmem_adder_2;
    reg     [`conv1_Vmem_width] Vmem_adder_3;
    reg     [`conv1_Vmem_width] Vmem_adder_4;
    reg     Carry_1,Carry_2,Carry_3,Carry_4;
    reg     [ 7:0]  Location_M_buf_1,Location_N_buf_1;
    reg     [ 7:0]  Location_M_buf_2,Location_N_buf_2;
// Vmem_write_data
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
        if( Location_M < (`conv1_pad) || Location_M >= (`conv1_pad + `conv1_image_H) )
            pad_inh_flag    <= 1;
        else if( Location_N < (`conv1_pad) || Location_N >= (`conv1_pad + `conv1_image_W) )
            pad_inh_flag    <= 1;
        else
            pad_inh_flag    <= 0;
    end
end

    // Vmem updata process
    //  read Latecy = 1 clk period

// In the first period, send the address of Vmem and weight
    //Vmem_ram_address; Weight_rom_address; Location_M; Location_N
    
// In the second period, get the output Vmem and weight
    //Vmem_address_buf_1; Location_M_buf_1; Location_N_buf_1
    
// In the third period, judge inh flag or the positon, then update the adder,and check if the adder reach the threshold and set the carry flag
    // Vmem_address_buf_2; Location_M_buf_2; Location_N_buf_2 ; inh_flag        
    // adder 1 2 3 4 
        //---- the judge of the inh flag can be perfect by the pad location check of the Location_M_buf_1 and Locaton_N_buf_1
    
    
// In the forth period, up data the Vmem ram by the (Vmem_write_data) and (Vmem_write_address), if carry or inh the Vmem_write_data[`conv1_inh_f]=1
// if the carry flag=1, output the conv1 spike, the spike channel is depended on the carry flag, and the AER message is M=Location_M_buf_2  N=Location_N_buf_2
// 

    always @(posedge work_clk or negedge rst_n)begin  //the third period
        if(!rst_n)begin
            Vmem_adder_1        <=  0;
            Vmem_adder_2        <=  0;
            Vmem_adder_3        <=  0;
            Vmem_adder_4        <=  0;
            Vmem_address_buf_1  <=  0;
        end
        else begin 
            Vmem_address_buf_1  <=  Vmem_ram_address;
            if(Vmem_read_data[`conv1_inh_f]==1 || pad_inh_flag)begin
                Vmem_adder_4   <=  Vmem_read_data[`conv1_Vmem4];
                Vmem_adder_3   <=  Vmem_read_data[`conv1_Vmem3];
                Vmem_adder_2   <=  Vmem_read_data[`conv1_Vmem2];
                Vmem_adder_1   <=  Vmem_read_data[`conv1_Vmem1];
                inh_flag       <=  1;
            end
            else begin
                Vmem_adder_4   <=  Vmem_read_data[`conv1_Vmem4]    +   Weight_read_data[`conv1_weight4];
                Vmem_adder_3   <=  Vmem_read_data[`conv1_Vmem3]    +   Weight_read_data[`conv1_weight3];
                Vmem_adder_2   <=  Vmem_read_data[`conv1_Vmem2]    +   Weight_read_data[`conv1_weight2];
                Vmem_adder_1   <=  Vmem_read_data[`conv1_Vmem1]    +   Weight_read_data[`conv1_weight1];
                inh_flag       <=  0;
            end
        end
    end

    always @(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Vmem_write_data     <=  0;
            Vmem_address_buf_2  <=  0;
        end
        else begin
            Vmem_address_buf_2 <=  Vmem_address_buf_1;
            Vmem_write_data[`conv1_Vmem4] <=  Vmem_adder_4;
            Vmem_write_data[`conv1_Vmem3] <=  Vmem_adder_3;
            Vmem_write_data[`conv1_Vmem2] <=  Vmem_adder_2;
            Vmem_write_data[`conv1_Vmem1] <=  Vmem_adder_1;        
            // change the inh_flag of the write Vmem_data; 
            //if the no_inh place reach the threshold Voltage, emit the spike of that place and set the Vmem_write_data[`conv1_inh_f] 
            if(inh_flag)begin
                Vmem_write_data[`conv1_inh_f] <=  1;
            end
            else begin
                if( Carry_1 || Carry_2 || Carry_3 || Carry_4 )begin
                    Vmem_write_data[`conv1_inh_f]   <=  1;
                end
                else begin
                    Vmem_write_data[`conv1_inh_f]   <=  0;
                end
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
// Vmem ram
    // read Vmem from B port and write from A port 
    Conv_layer1_Vmem_ram   conv1_ram (
      .clka(work_clk),    // input wire clka
      .wea(Vmem_wea),      // input wire [0 : 0] wea
      .addra(Vmem_write_address),  // input wire [15 : 0] addra
      .dina(Vmem_write_data),    // input wire [16 : 0] dina
      .clkb(work_clk),    // input wire clkb
      .rstb(!rst_n),    // input wire rstb
      .addrb(Vmem_ram_address),  // input wire [15 : 0] addrb
      .doutb(Vmem_read_data)  // output wire [16 : 0] doutb         
    );
//Weight rom 
    // read the weight from the rom, and updata the Vmem
    Conv_layer1_Weight_rom conv1_rom (
      .clka(work_clk),    // input wire clka
      .addra(Weight_rom_address),  // input wire [4 : 0] addra
      .douta(Weight_read_data)  // output wire [7 : 0] douta
    );
    
    
        // judge weather reach the threshold
    //carry 1 2 3 4; when the adder > Vth Carry = 1 
    
        always @(*)begin  // carry1
            if(!rst_n)
                Carry_1    =  0;
            else begin
                if(Vmem_adder_1>Vth && inh_flag==0)
                    Carry_1 =   1;
                else
                    Carry_1 =   0;
            end
        end
    
        always @(*)begin  // carry2
            if(!rst_n)
                Carry_2     =  0;
            else begin
                if(Vmem_adder_2>Vth && inh_flag==0)
                    Carry_2 =   1;
                else
                    Carry_2 =   0;
            end
        end
        
        always @(*)begin  // carry3
            if(!rst_n)
                Carry_3     =  0;
            else begin
                if(Vmem_adder_3>Vth && inh_flag==0)
                    Carry_3 =   1;
                else
                    Carry_3 =   0;
            end
        end       
         
        always @(*)begin  // carry4
            if(!rst_n)
                Carry_4     =  0;
            else begin
                if(Vmem_adder_4>Vth && inh_flag==0)
                    Carry_4 =   1;
                else
                    Carry_4 =   0;
            end
        end    
        
//Location buf_1
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Location_M_buf_1    <=  0;
            Location_N_buf_1    <=  0;
        end
        else begin
            Location_M_buf_1    <=  Location_M;
            Location_N_buf_1    <=  Location_N;
        end
    end

//Location buf_2    
    always@(posedge work_clk or negedge rst_n)begin
        if(!rst_n)begin
            Location_M_buf_2    <=  0;
            Location_N_buf_2    <=  0;
        end
        else begin
            Location_M_buf_2    <=  Location_M_buf_1;
            Location_N_buf_2    <=  Location_N_buf_1;
        end
    end
    
    
    
    
    // when carry set the output spike
        //Conv_layer1_spike   
        //Conv_layer1_spike_emit_f
            // also we need buffer to store the carry place
        
        always @(posedge work_clk or negedge rst_n)begin
            if(!rst_n)begin
                Conv_layer1_spike           <=  17'b0;
                Conv_layer1_spike_emit_f    <=   1'b0;
            end
            else begin
                if(inh_flag)begin
                    Conv_layer1_spike_emit_f    <=   1'b0;
                end
                else if(Carry_1 || Carry_2 || Carry_3 || Carry_4) begin // carry 1 2 3 4  is high ,meams there are some
                    Conv_layer1_spike_emit_f    <=   1'b1;
                    Conv_layer1_spike[15:8]     <=   Location_M_buf_2;
                    Conv_layer1_spike[ 7:0]     <=   Location_N_buf_2;
                    if( (Carry_1 + Carry_2 + Carry_3 + Carry_4)>1 )begin     // more than one channel has reach the threshold
                        // 加上判断条件
                        if     ( Vmem_adder_4>Vmem_adder_1 && Vmem_adder_4>Vmem_adder_2 && Vmem_adder_4>Vmem_adder_3 )begin
                            Conv_layer1_spike[17:16]    <=  11;
                        end
                        else if( Vmem_adder_2>Vmem_adder_1 && Vmem_adder_2>Vmem_adder_3 && Vmem_adder_2>Vmem_adder_4 )begin
                            Conv_layer1_spike[17:16]    <=  01;
                        end
                        else if( Vmem_adder_3>Vmem_adder_1 && Vmem_adder_3>Vmem_adder_2 && Vmem_adder_3>Vmem_adder_4 )begin
                            Conv_layer1_spike[17:16]    <=  10;
                        end
                        else begin
                            Conv_layer1_spike[17:16]    <=  00;
                        end
                    end
                    else begin
                        case( {Carry_1, Carry_2, Carry_3, Carry_4} )
                            4'b1000:    Conv_layer1_spike[17:16]    <=  00;
                            4'b0100:    Conv_layer1_spike[17:16]    <=  01;
                            4'b0010:    Conv_layer1_spike[17:16]    <=  10;
                            4'b0001:    Conv_layer1_spike[17:16]    <=  11;
                            default:    Conv_layer1_spike[17:16]    <=  00;
                        endcase
                    end
                end
                else begin
                    Conv_layer1_spike_emit_f    <=   1'b0;
                end
            end
        end
    
endmodule
