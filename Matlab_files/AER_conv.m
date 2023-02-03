function [spike_AER_out,V,K_inh]=AER_conv(spike_AER_in,V,K_inh,weight,th)
    [weight_size,~,~,filter_num]=size(weight);
    spike_AER_out=[];
     conv_spike_AER=zeros(1,3);
%AER_conv
[spike_num,~]=size(spike_AER_in);
    
 for K=1:spike_num     %��ÿһ���������巢�������
    M=spike_AER_in(K,2);
    N=spike_AER_in(K,3);
    for i=0:weight_size-1
        for j=0:weight_size-1
            for d=1:filter_num
                x=M+i;y=N+j;
                V(x,y,d)=V(x,y,d)+weight(weight_size-i,weight_size-j,1,d);%Ĥ��λ�ı�
            end
            %�۲�Ĥ��λ�Ƿ񵽴���ֵ
            Vmax = max( V(M+i,N+j,:) );%��ͨ��Ĥ��λ���ֵ��
            if (Vmax>th && K_inh(x,y)==0) %��������ֵͬʱ���������ơ�
                x=M+i;y=N+j;
                for d=1:filter_num
                    if(V(x,y,d)==Vmax)
                        K_inh(x,y)=1; 
                        conv_spike_AER(1)=d;
                        conv_spike_AER(2)=x;
                        conv_spike_AER(3)=y;
                        spike_AER_out=[spike_AER_out;conv_spike_AER];
                    end
                end   
             end
        end
    end
 end


end