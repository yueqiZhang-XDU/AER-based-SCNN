function  layers=reset_layers(layers,num_layers)
%�����������
global total_time
%total_time Ϊ��ѵ����ʱ��
 for i=1:num_layers
     layers{i}.S=uint8(zeros(size(layers{i}.S)));
     layers{i}.V=double(zeros(size(layers{i}.V)));
     layers{i}.K_STDP=uint8(ones(size(layers{i}.K_STDP))*total_time);
     layers{i}.K_inh=uint8(zeros(size(layers{i}.K_inh)));
end

