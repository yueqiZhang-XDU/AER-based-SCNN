function [S,V,K_inh,conv_spike_AER,conv_layer1_fifo_write_time,conv_spike_AER_num,operating_time]=AER_conv_prop(spike_AER,S,V,K_inh,weight,th,conv_spike_AER,conv_layer1_fifo_write_time,conv_spike_AER_num,operating_time)
    [weight_size,~,~,filter_num]=size(weight);
%AER_conv
    M=spike_AER(1);
    N=spike_AER(2);
    
    operating_time=operating_time+1;%得到Vmem与weight读出地址时刻
    operating_time=operating_time+1;%读出数据的时刻
 %conv_layer1_fifo_write_time 为第一个卷积层将产生脉冲写入fifo的时间
    
    %发生反卷积
    for i=0:weight_size-1
        for j=0:weight_size-1
            x=M+i;y=N+j;operating_time=operating_time+1;%将读出的数据相加，并判断是否到达阈值的时刻
            for d=1:filter_num
                V(x,y,d)=V(x,y,d)+weight(weight_size-i,weight_size-j,1,d);%膜电位改变
            end
            %观察膜电位是否到达阈值
            Vmax = max( V(M+i,N+j,:) );%各通道膜电位最大值；
            if (Vmax>th)
                x=M+i;y=N+j;
                for d=1:filter_num
                    if(V(x,y,d)==Vmax && K_inh(x,y)==0)
                        S(x,y,d)=1;
                        K_inh(x,y)=1;
                        conv_spike_AER(1,conv_spike_AER_num)=d;
                        conv_spike_AER(2,conv_spike_AER_num)=x;
                        conv_spike_AER(3,conv_spike_AER_num)=y;
                        conv_spike_AER(4,conv_spike_AER_num)=operating_time+1;%若到达阈值，在下一个时刻卷积层1将会发出脉冲
                        conv_layer1_fifo_write_time(conv_spike_AER_num)=operating_time+2;
                        conv_spike_AER_num=conv_spike_AER_num+1;
                    end
                end   
             end
        end
    end
    operating_time=operating_time+3;%结束过程需要3个周期    
end