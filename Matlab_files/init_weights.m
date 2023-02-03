function [ weights] = init_weights( weight_params,network_struct)
%ÿ��Ȩֵ�ĳ�ʼ������
%����Ȩֵ����������ṹ
%Ȩֵ����Ĵ�С����network_struct�ж���filter�Ĵ�С������
mean=weight_params.mean;
std=weight_params.std;
[inet,jnet]=size(network_struct);
weights=cell(inet,jnet);
for i=2:jnet%�������Ȩֵ��С�޹� 
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

