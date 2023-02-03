function [V,conv_layer2_fifo_read_time]=AER_conv2_prop(pooling_AER_channel,V,weight)

    [weight_size,~,~,filter_num]=size(weight);
    [~,pooling_AER_num]=size(pooling_AER_channel);
    conv_layer2_fifo_read_time=zeros(1,pooling_AER_num);
    
    operating_end_time=0;%卷积层的空闲时刻
    
for K=1:pooling_AER_num
    spike_AER=pooling_AER_channel(:,K);
    if spike_AER(1)==0
        break
    end
    M=spike_AER(2);
    N=spike_AER(3);
    current_time=spike_AER(4);
    
%%  从fifo中把脉冲读出来    
    if current_time>operating_end_time %当前操作的脉冲的输出时间，如果可以大于上一个脉冲结束的时间，就可以从fifo中读出此脉冲信息
        current_time=current_time+1;%空闲状态 从fifo中读出脉冲
        %进行卷积的操作
    else
        current_time=operating_end_time;%非空闲状态，这里就需要等待上一个卷积层结束运行才能进行读的操作。
        current_time=current_time+1; %从fifo中读出脉冲
        
    end
    current_time=current_time+1;
    conv_layer2_fifo_read_time(K)=current_time; % 从fifo中读出数据的时间
    current_time=current_time+5;
    
    for i=0:weight_size-1
        for j=0:weight_size-1
            x=M+i;y=N+j;
            for d=1:filter_num
                Vmem_read=V(x,y,d);
                weight_read=weight(weight_size-i,weight_size-j,1,d);
                V(x,y,d)=V(x,y,d)+weight(weight_size-i,weight_size-j,1,d);%膜电位改变
            end
        end
    end
    operating_end_time=current_time+225;
end

end