function [ deta] = deta_STDP( a,time,tao)
%a为学习速率
%tao为学习实常数
%time为时间间隔delta_t
deta=zeros(1,time);
for i=1:time
    deta(i)=a*exp(-(i-1)/tao);
end

end

