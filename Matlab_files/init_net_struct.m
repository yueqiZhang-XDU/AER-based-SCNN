function [network_struct]= init_net_struct(network_params)
%����ṹ�ĳ�ʼ������
%�������������������ڲ���г�ʼ������
[~,jnet]=size(network_params);
network_struct=cell(1,jnet);%Ԥ����ռ�

for i=1:jnet
    d_tmp={};
    if strcmp( network_params{i}.type,'input' )
        d_tmp=struct('Type',network_params{i}.type,'H_layer',network_params{i}.H_layer,...
              'W_layer',network_params{i}.W_layer,'num_filters',network_params{i}.num_filters,...
              'pad',network_params{i}.pad,'shape',struct('H_layer',network_params{i}.H_layer,'W_layer',network_params{i}.W_layer,'num_filters',network_params{i}.num_filters));
          
    elseif strcmp( network_params{i}.type,'conv' )
        pad=floor(network_params{i}.filter_size/2);  %��Ҫ����Ĵ�С��Ԥ����˲����Ĵ�С�йأ���֤������ͼ���С����ǰ��ͬ   
        stride=1;
        H_layer=1+ floor( (network_struct{i-1}.H_layer+2*pad-network_params{i}.filter_size)/stride );
        W_layer=1+ floor( (network_struct{i-1}.W_layer+2*pad-network_params{i}.filter_size)/stride );
        offset=floor(network_params{i}.filter_size/2);
        d_tmp=struct('Type',network_params{i}.type,'th',network_params{i}.th,'filter_size',network_params{i}.filter_size,...
            'num_filters',network_params{i}.num_filters,'stride',stride,'pad',pad,'offset',offset,...
            'H_layer',H_layer,'W_layer',W_layer,...
            'shape',struct('H_layer',H_layer,'W_layer',W_layer,'num_filters',network_params{i}.num_filters));
        
    elseif strcmp( network_params{i}.type,'pool' )
        if i==jnet
            pad=0;     
            stride=network_params{i}.stride;
            H_layer=1+floor( (network_struct{i-1}.H_layer+2*pad-network_params{i}.filter_size)/stride );
            W_layer=1+floor( (network_struct{i-1}.W_layer+2*pad-network_params{i}.filter_size)/stride );
            offset=floor(network_params{i}.filter_size/2);
            d_tmp=struct('Type',network_params{i}.type,'th',network_params{i}.th,'filter_size',network_params{i}.filter_size,...
            'num_filters',network_params{i}.num_filters,'stride',stride,'pad',pad,'offset',offset,...
            'H_layer',H_layer,'W_layer',W_layer,...
            'shape',struct('H_layer',H_layer,'W_layer',W_layer,'num_filters',network_params{i}.num_filters));  
        else
        pad=floor(network_params{i}.filter_size/2);     
        stride=network_params{i}.stride;
        H_layer=1+floor( (network_struct{i-1}.H_layer+2*pad-network_params{i}.filter_size)/stride );
        W_layer=1+floor( (network_struct{i-1}.W_layer+2*pad-network_params{i}.filter_size)/stride );
        offset=floor(network_params{i}.filter_size/2);
        d_tmp=struct('Type',network_params{i}.type,'th',network_params{i}.th,'filter_size',network_params{i}.filter_size,...
            'num_filters',network_params{i}.num_filters,'stride',stride,'pad',pad,'offset',offset,...
            'H_layer',H_layer,'W_layer',W_layer,...
            'shape',struct('H_layer',H_layer,'W_layer',W_layer,'num_filters',network_params{i}.num_filters));
        end
    else 
        printf('unknown layer specified');
    end
      network_struct{i}=d_tmp;
end
end

