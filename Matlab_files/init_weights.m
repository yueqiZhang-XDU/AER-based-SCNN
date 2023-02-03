function [ weights] = init_weights( weight_params,network_struct)
%每层权值的初始化函数
%输入权值参数与网络结构
%权值矩阵的大小根据network_struct中对于filter的大小所定义
mean=weight_params.mean;
std=weight_params.std;
[inet,jnet]=size(network_struct);
weights=cell(inet,jnet);
for i=2:jnet%输入层与权值大小无关 
%     if i==1
%        HH=network_struct{i}.filter_size;
%        WW=network_struct{i}.filter_size;
%        DD=network_struct{i}.num_filters;
%        w_shape=struct('HH',HH,'WW',WW,'DD',DD);
%         W_shape{i}=w_shape;
%     else
    HH=network_struct{i}.filter_size;
    WW=network_struct{i}.filter_size;
    MM=network_struct{i-1}.num_filters;
    DD=network_struct{i}.num_filters;
    if strcmp( network_struct{i}.Type,'conv' )
        weights_tmp=mean+std*normrnd(0,1,[HH,WW,MM,DD]);
           
    elseif strcmp( network_struct{i}.Type,'pool' )
        weights_tmp=ones(HH,WW,MM)/(HH*WW);
    else
        continue
    end
    weights{i}=weights_tmp;
%     end

end

