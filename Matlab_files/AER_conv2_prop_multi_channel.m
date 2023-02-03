function [V,conv_layer2_fifo_write_time,conv_layer2_fifo_read_time]=AER_conv2_prop_multi_channel(AER_conv2,V,weight_conv2)

    [weight_size,~,~,filter_num]=size(weight_conv2);%这里输入的weight指的是conv2的所有weight
    [~,pooling_AER_num]=size(AER_conv2);
    conv_layer2_fifo_read_time=zeros(1,pooling_AER_num);
    conv_layer2_fifo_write_time=zeros(1,pooling_AER_num);
    operating_end_time=0;%卷积层的空闲时刻
    
for K=1:pooling_AER_num
    spike_AER=AER_conv2(:,K);
    
    if spike_AER(1)==0
        break
    end
%% 根据不同的通道选择不同的weight进行映射
    spike_channel=spike_AER(1);
    switch spike_channel
        case 1
            weight=weight_conv2(:,:,1,:);
        case 2
            weight=weight_conv2(:,:,2,:);
        case 3
            weight=weight_conv2(:,:,3,:);
        case 4
            weight=weight_conv2(:,:,4,:);
        otherwise
            weight=zeors(15,15,1,10);
    end
    
    M=spike_AER(2);
    N=spike_AER(3);
    current_time=spike_AER(4);
    conv_layer2_fifo_write_time(K)=current_time+1; % 池层输出脉冲写入fifo的时间
    
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
                V(x,y,d)=V(x,y,d)+weight(weight_size-i,weight_size-j,1,d);%膜电位改变
            end
        end
    end
    operating_end_time=current_time+225;
end

end