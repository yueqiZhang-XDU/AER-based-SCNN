function layers = init_layers(network_struct)%STDP_time指STDP的作用时间
global total_time
%定义脉冲矩阵S，膜电位矩阵V，学习矩阵K_STDP，侧抑制矩阵K_inh
[inet,jnet]=size(network_struct);
layers=cell(inet,jnet);
for i=1:jnet
      H=network_struct{i}.shape.H_layer;
      W=network_struct{i}.shape.W_layer;
      D=network_struct{i}.shape.num_filters;
      S=uint16(zeros(H,W,D));%H×W×D×t
      V=double(zeros(H,W,D));
      K_STDP=uint8(ones(H,W,D)*total_time);%记录可以进行STDP学习的矩阵,记录前脉冲或者后脉冲的发射时间。大小与脉冲矩阵S的规模相同
      K_inh=uint8(zeros(H,W));%侧抑制矩阵
      d_tmp=struct('S',S,'V',V,'K_STDP',K_STDP,'K_inh',K_inh);
    layers{i}=d_tmp;
end
end
