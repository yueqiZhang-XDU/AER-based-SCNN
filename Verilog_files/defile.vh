// this file define the port width when the width of weights changes
    `define     Weight_width       4:0
	`define     Vmem_width_conv1   3:0
    `define     Vmem_width_conv2   6:0
// TOP module
    `define     AER_width_i       16:0
    `define     Feature_o          2:0 


//  SCNN
    // change with width
    `define     Feature_V_o_width  6:0    
    

    // conv layer 1
    `define     conv1_AER_i       15:0     
    `define     conv1_AER_o       17:0

    `define     D_Vmem_ram_width_conv1    16:0
    `define     D_weight_rom_width_conv1   7:0
	`define	 	conv1_Vmem_range 15:0
	`define     conv1_Vmem_width 3:0
    `define     conv1_Vmem1      3: 0
    `define     conv1_Vmem2      7: 4
    `define     conv1_Vmem3     11: 8
    `define     conv1_Vmem4     15:12
    `define     conv1_inh_f        16
    `define     conv1_weight1    1: 0
    `define     conv1_weight2    3: 2
    `define     conv1_weight3    5: 4
    `define     conv1_weight4    7: 6
    // conv layer 2
    `define     D_Vmem_ram_width_conv2     70:0
    `define     D_weight_rom_width_conv2   19:0
    `define     A_weight_rom_width_conv2    7:0
    `define     A_Vmem_ram_width_conv2      9:0  
 		//conv2_core
 		`define      conv2_Vmem_width   6: 0			
        `define      conv2_Vmem1        6: 0 	          
		`define      conv2_Vmem2        13: 7	
        `define      conv2_Vmem3        20:14	       
		`define      conv2_Vmem4        27:21
		`define      conv2_Vmem5        34:28 
		`define      conv2_Vmem6        41:35 
		`define      conv2_Vmem7        48:42 
		`define      conv2_Vmem8        55:49
		`define      conv2_Vmem9        62:56
		`define      conv2_Vmem10       69:63
		`define      conv2_inh_f        70 	

        `define      conv2_weight1   1: 0    
        `define      conv2_weight2   3: 2    
        `define      conv2_weight3   5: 4    
        `define      conv2_weight4   7: 6    
        `define      conv2_weight5   9: 8  
        `define      conv2_weight6  11:10    
        `define      conv2_weight7  13:12    
        `define      conv2_weight8  15:14    
        `define      conv2_weight9  17:16    
        `define      conv2_weight10 19:18    


    
// SCNN Parameter     
    `define conv1_filter_size           5
    `define conv1_image_H               160
    `define conv1_image_W               250
    `define conv1_pad                   2
    
    `define conv1_image_pad_H           164
    `define conv1_image_pad_W           254
       
    `define weight_rom_conv1_Address_initial   25
    
    `define conv2_filter_size           15
    `define conv2_image_H               11 
    `define conv2_image_W               16
    `define conv2_pad                   8
    `define conv2_image_pad_H           25
    `define conv2_image_pad_W           30
    
    `define weight_rom_conv2_Address_initial 225
    
    `define conv2_Vmem_depth            750
    
//  SVM
// the fixed width of the SVM is 5
    `define     SVM_result_o         1:0
    `define     signed_FV_width      7:0
    `define     Beta_width           5:0
	
    `define     multi_result_width  13:0
    `define     multi_result_sign   13
    
    `define     multi_result_sum_width	15:0
	
	`define		SVM_result_width		15:0
    `define     SVM_result_sign       	15
    
    
