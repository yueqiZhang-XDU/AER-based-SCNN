%conv result show

function spike_message=monitor_conv1_pool(conv_spike_AER,pooling_AER)
 spike_message=cell(4,10000);
    for i=1:10000
        cone_spike_channel=conv_spike_AER(1,i)-1;
        conv_spike_H=conv_spike_AER(2,i)-1;
        conv_spike_W=conv_spike_AER(3,i)-1;
    %% bin conv spike
        bin_conv_spike_channel=dec2bin(cone_spike_channel,2);
        bin_conv_spike_H=dec2bin(conv_spike_H);
        bin_conv_spike_W=dec2bin(conv_spike_W);
        bin_conv_spike=[bin_conv_spike_channel,bin_conv_spike_H,bin_conv_spike_W];

    %% hex convspike    
        hex_conv_spike_channel=dec2hex(cone_spike_channel,1);
        hex_conv_spike_H=dec2hex(conv_spike_H);
        hex_conv_spike_W=dec2hex(conv_spike_W);
        hex_conv_spike=[hex_conv_spike_channel,hex_conv_spike_H,hex_conv_spike_W];
      %% save these messages
        spike_message{1,i}=hex_conv_spike;
        spike_message{2,i}=bin_conv_spike;     
   end         
        
        
   for i =1:2000
        pool_spike_channel=pooling_AER(1,i)-1;
        pool_spike_H=pooling_AER(2,i)-1;
        pool_spike_W=pooling_AER(3,i)-1;
    %% bin pool spike  
        bin_pool_spike_channel=dec2bin(pool_spike_channel,2);
        bin_pool_spike_H=dec2bin(pool_spike_H,5);
        bin_pool_spike_W=dec2bin(pool_spike_W,5);
        bin_pool_spike=[bin_pool_spike_channel,bin_pool_spike_H,bin_pool_spike_W];
    %% hex pool spike
        dec_pool_soike=bin2dec(bin_pool_spike);
        hex_pool_spike=dec2hex(dec_pool_soike);
    %% save these messages
        spike_message{3,i}=hex_pool_spike;
        spike_message{4,i}=bin_pool_spike;
    end
    


end