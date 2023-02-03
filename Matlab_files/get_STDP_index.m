function [STDP_index,STDP_counter,STDP_inh]=get_STDP_index(current_spike,STDP_index,STDP_counter,STDP_inh,learning_layer,offset,pad,t)
    STDP_inh_matrix=STDP_inh{learning_layer};
    [Si,Sj,D]=size(STDP_inh_matrix);
    spike_channel=current_spike(1);spike_X=current_spike(2);spike_Y=current_spike(3);%脉冲位置数据

    if STDP_inh_matrix(spike_X,spike_Y,spike_channel)==0 %更新STDP_index,STDP_counter,STDP_inh
       STDP_index{spike_channel}=[spike_channel,spike_X-pad,spike_Y-pad,t]; 
       STDP_counter=STDP_counter+1;
    %抑制机制的实现 
       for d=1:D
            STDP_inh_matrix(max(spike_X-offset,1):min(spike_X+offset,Si),max(spike_Y-offset,1):min(spike_Y+offset,Sj),d)=1;%互抑制实现
       end
       STDP_inh_matrix(:,:,spike_channel)=1;%侧抑制实现
       
       STDP_inh{learning_layer}=STDP_inh_matrix;
    end
end