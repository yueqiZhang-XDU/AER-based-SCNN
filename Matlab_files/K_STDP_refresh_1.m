function [ K_STDP ]=K_STDP_refresh_1(spike_register,K_STDP,t)
%UNTITLED2 �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
[N,~]=size(spike_register);
for i=1:N
    spike_AER=spike_register(i,:);
    spike_x=spike_AER(2);
    spike_y=spike_AER(3);
    K_STDP(spike_x,spike_y)=t;
end

end

