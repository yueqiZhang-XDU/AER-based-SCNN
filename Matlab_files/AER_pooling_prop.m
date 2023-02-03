function  [pooling_AER,conv_layer1_fifo_read_time,m]= AER_pooling_prop(conv_spike_AER,K_inh,stride,pad)

%pooling_stride=16
pre_pad=2;
pooling_AER=zeros(4,2000);
m=1;
[~,conv_spike_AER_num]=size(conv_spike_AER);

conv_layer1_fifo_read_time=zeros(1,conv_spike_AER_num);

%这里需要复现fifo的作用
%fifo 输入时间+1 存储+1 输出时间+1
%% 时间变量定义
    operating_end_time=0;
%% 传播过程    
for n=1:conv_spike_AER_num
    conv_AER=conv_spike_AER(:,n);
    spike_channel=conv_AER(1);
    spike_M=conv_AER(2);                                              
    spike_N=conv_AER(3);
    spike_time=conv_AER(4);
    
    if spike_channel==0  %若所有脉冲均传播完毕，则跳出循环
            break;
    end   
    
    current_time=spike_time;
    current_time=current_time+1;   %数据输入+数据写入时间 从而将信息存入fifo中
    
    if current_time>operating_end_time %当前操作的脉冲的输出时间，如果可以大于上一个脉冲结束的时间，就可以从fifo中读出此脉冲信息
        current_time=current_time+1;%空闲状态 从fifo中读出脉冲
        %进行卷积的操作
    else
        current_time=operating_end_time;%非空闲状态，这里就需要等待上一个卷积层结束运行才能进行读的操作。
        current_time=current_time+1;
    end
    
    current_time=current_time+1;%从fifo中将脉冲信息读出，需要一个周期
    conv_layer1_fifo_read_time(n)=current_time; %将读出来的脉冲时间存储
    
    %以下是卷积操作
        pool_AER_M=floor( (spike_M-pre_pad+pad)/stride )+1;
        pool_AER_N=floor( (spike_N-pre_pad+pad)/stride )+1;
        pool_AER_M_bin=dec2bin(pool_AER_M-1,5);
        pool_AER_N_bin=dec2bin(pool_AER_N-1,5);
        
        if K_inh(pool_AER_M,pool_AER_N)==0
            pooling_AER(1,m)=spike_channel;
            pooling_AER(2,m)=pool_AER_M;
            pooling_AER(3,m)=pool_AER_N;
            pooling_AER(4,m)=current_time+4;%池化层的脉冲发出时间
            K_inh(pool_AER_M,pool_AER_N)=1;
            m=m+1;
            operating_end_time=current_time+4;
        else
            operating_end_time=current_time+3;
        end

        
end
end

