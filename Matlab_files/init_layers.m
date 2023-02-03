function layers = init_layers(network_struct)%STDP_timeָSTDP������ʱ��
global total_time
%�����������S��Ĥ��λ����V��ѧϰ����K_STDP�������ƾ���K_inh
[inet,jnet]=size(network_struct);
layers=cell(inet,jnet);
for i=1:jnet
      H=network_struct{i}.shape.H_layer;
      W=network_struct{i}.shape.W_layer;
      D=network_struct{i}.shape.num_filters;
      S=uint16(zeros(H,W,D));%H��W��D��t
      V=double(zeros(H,W,D));
      K_STDP=uint8(ones(H,W,D)*total_time);%��¼���Խ���STDPѧϰ�ľ���,��¼ǰ������ߺ�����ķ���ʱ�䡣��С���������S�Ĺ�ģ��ͬ
      K_inh=uint8(zeros(H,W));%�����ƾ���
      d_tmp=struct('S',S,'V',V,'K_STDP',K_STDP,'K_inh',K_inh);
    layers{i}=d_tmp;
end
end
