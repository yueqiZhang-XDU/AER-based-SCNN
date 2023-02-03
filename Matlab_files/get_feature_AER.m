function [Vmem_features] = get_feature_AER(weights,layers,network_struct,image_path,num_img,DoG_params,total_time,fi_width)
%获得一个N*M的矩阵，N为训练的样本数，M为最后一层的层数，即每一列保存训练结果
%需要首先把最后一层的膜电位更改为无穷大

[~,num_layers]=size(network_struct);
network_struct{num_layers}.th=1000;
n=1; 
[~,~,n_featuers]=size(layers{num_layers}.V);%最后一层卷积层的深度层数

Vmem_features=zeros(num_img,n_featuers);
max_fifo_nums=zeros(num_img,5);

       fprintf('-------------------------------------------------------------\n')
       fprintf('--------------EXTRACTING----------FEATURES-------------------\n')
       fprintf('-------------------------------------------------------------\n')
    spike_number=zeros(1,num_img);
    t=zeros(1,num_img);
    input_spike_num=zeros(1,num_img);
    conv1_spike_num=zeros(1,num_img);
    pool1_spike_num=zeros(1,num_img);

DoG_Encoding_time = zeros(1,100);    
inference_time    = zeros(1,100);

spike_number_input = zeros(1,100);
spike_number_conv1 = zeros(1,100);
spike_number_pool1 = zeros(1,100);

    
for ii=1:num_img
           perc=ii/num_img;
            fprintf('----------------EXTRACTING PROGRESS %2.3f-------------------\n',perc)
            %reset layers
            layers=reset_layers(layers,num_layers);
             path_img=image_path{n};
              if n<num_img
                  n=n+1;
              else
                  n=1;
              end    
tic;
              AER_M = DoG_filter_to_AER_mem( path_img,DoG_params.DoG_size,DoG_params.img_size,total_time,num_layers);
DoG_Encoding_time(ii)=toc;
              %save('t_step_ram_AER.mat','AER_M');
tic;
%           [si,sj,sz]=size(layers{2}.S);
%           S_record=zeros(si,sj,sz);
            [~,AER_num]=size(AER_M);    
            spike_number_input(ii)=AER_num;
  
% %更改一下weight 做一个test 观察其是否是第二卷积层在卷积过程中出现的问题
%    weight_test=ones(15,15,4,10)*0.0625;
%    weights{4}=weight_test;
            
        
spike_number(ii)=AER_num;
    i=2; %对于conv1 i=2
    V=layers{i}.V;
    S=layers{i}.S;
    K_inh=layers{i}.K_inh;
    pad=network_struct{i}.pad; %将s进行周围补零操作，以便于卷积  s的规模为H×W×D
    th=network_struct{i}.th;
    stride=network_struct{i}.stride;
    [ S_pad ]=pad_for_conv(S,pad );    %t-1时刻的前一层的输出脉冲
    [ V_pad ]=pad_for_conv(V,pad);
    [ K_inh_pad]=pad_for_Kinh(K_inh,pad);
    conv_spike_AER=zeros(4,32768);
    conv_spike_AER_num=1;

    %有关fifo的数据定义： 
    %这里定义的脉冲写入时间与发出时间为改变fifo内部信息数量的时间。
        conv_layer1_fifo_write_time=zeros(1,32768);% 第一个卷积层写入fifo的时间
       %conv_layer1_fifo_read_time                 % 池层从第一个卷积层读取脉冲的时间
       
        conv_layer2_fifo1_write_time=zeros(1,1000);
        conv_layer2_fifo2_write_time=zeros(1,1000);
        conv_layer2_fifo3_write_time=zeros(1,1000);
        conv_layer2_fifo4_write_time=zeros(1,1000);
        
        %conv_layer2_fifo1_read_time
        %conv_layer2_fifo2_read_time
        %conv_layer2_fifo3_read_time
        %conv_layer2_fifo4_read_time
        
        
%AER传播过程 
    operating_time=0;%初始时刻
%% conv Layer 1    
for current_spike_num=1:AER_num    
    spike_AER=AER_M(:,current_spike_num);    
    operating_time=operating_time+3;%刚开始的三个时刻
    [S_pad,V_pad,K_inh_pad,conv_spike_AER,conv_layer1_fifo_write_time,conv_spike_AER_num,operating_time]=AER_conv_prop(spike_AER,S_pad,V_pad,K_inh_pad,weights{2},th,conv_spike_AER,conv_layer1_fifo_write_time,conv_spike_AER_num,operating_time);%反卷积过程
    %这里将反卷积的结果放入了队列
end            
 %save('conv1_result.mat','conv_spike_AER');
 spike_number_conv1(ii) = conv_spike_AER_num;
 
%% pooling_layer
    i=3; %对于conv1 i=2
    V=layers{i}.V;
    S=layers{i}.S;
    K_inh=layers{i}.K_inh;
    pad=network_struct{i}.pad; %将s进行周围补零操作，以便于卷积  s的规模为H×W×D
    stride=network_struct{i}.stride;
%输入脉冲为conv_spike_AER;
 [pooling_AER,conv_layer1_fifo_read_time,pool_spike_number]= AER_pooling_prop(conv_spike_AER,K_inh,stride,pad);

%save('pooling_AER.mat','pooling_AER');

spike_number_pool1(ii) = pool_spike_number;

%% conv_layers2
%通道权值划分
weight_channel1=weights{4}(:,:,1,:);
weight_channel2=weights{4}(:,:,2,:);
weight_channel3=weights{4}(:,:,3,:);
weight_channel4=weights{4}(:,:,4,:);

pooling_AER_channel1=zeros(4,1000);
M1=1;

pooling_AER_channel2=zeros(4,1000);
M2=1;

pooling_AER_channel3=zeros(4,1000);
M3=1;

pooling_AER_channel4=zeros(4,1000);
M4=1;

% 将池层的输入脉冲写入不同的fifo中的过程 需要添加写入的延迟


%经过验证，分通道的情况下， 所有的脉冲均能写入相应的通道内
for k=1:1000
current_AER=pooling_AER(:,k);
current_AER(4)=current_AER(4)+2;        % 这里让对应的时间+2 表示从池层发出的脉冲，写入到fifo中的写入延迟。
current_time=current_AER(4);
AER_channel=current_AER(1);
switch AER_channel
    case 1
        pooling_AER_channel1(:,M1)=current_AER;
        conv_layer2_fifo1_write_time(:,M1)=current_time;  %存入写的时间
        M1=M1+1;
    case 2
        pooling_AER_channel2(:,M2)=current_AER;
        conv_layer2_fifo2_write_time(:,M2)=current_time;  %存入写的时间
        M2=M2+1;        
    case 3
        pooling_AER_channel3(:,M3)=current_AER;
        conv_layer2_fifo3_write_time(:,M3)=current_time;  %存入写的时间
        M3=M3+1;   
    case 4
        pooling_AER_channel4(:,M4)=current_AER;
        conv_layer2_fifo4_write_time(:,M4)=current_time;  %存入写的时间
        M4=M4+1;   
end
end


%之后进行第二层卷积
    i=4; %对于conv1 i=2
    V_conv2=layers{i}.V;
    pad=network_struct{i}.pad; %将s进行周围补零操作，以便于卷积  s的规模为H×W×D
    [ V_pad_conv2 ]=pad_for_conv(V_conv2,pad);

    K_inh=layers{4}.K_inh;
    [K_inh_pad]=pad_for_Kinh(K_inh,pad);
    
    
 V_pad1=V_pad_conv2;
 V_pad2=V_pad_conv2;
 V_pad3=V_pad_conv2;
 V_pad4=V_pad_conv2;
%卷积操作
[V_pad1,conv_layer2_fifo1_read_time]=AER_conv2_prop(pooling_AER_channel1,V_pad1,weight_channel1);
[V_pad2,conv_layer2_fifo2_read_time]=AER_conv2_prop(pooling_AER_channel2,V_pad2,weight_channel2);
[V_pad3,conv_layer2_fifo3_read_time]=AER_conv2_prop(pooling_AER_channel3,V_pad3,weight_channel3);
[V_pad4,conv_layer2_fifo4_read_time]=AER_conv2_prop(pooling_AER_channel4,V_pad4,weight_channel4);

V_pad_inh1=pad_Vmem_inh(V_pad1,K_inh_pad);
V_pad_inh2=pad_Vmem_inh(V_pad2,K_inh_pad);
V_pad_inh3=pad_Vmem_inh(V_pad3,K_inh_pad);
V_pad_inh4=pad_Vmem_inh(V_pad4,K_inh_pad);

Vmem=V_pad_inh1+V_pad_inh2+V_pad_inh3+V_pad_inh4;
%求特征向量
%% conv layer2 signal channel
    %参与卷积运算的资源
    i=4; 
    AER_conv2_single_channel=pooling_AER;
    V_conv2_single_channel=layers{i}.V;
    [ V_pad_conv_layer2 ]=pad_for_conv(V_conv2_single_channel,pad);
    weight_conv2_single_channel=weights{4};
    
    %单通道情况下对于所有的池层输出脉冲进行卷积
    [V_pad_conv_layer2,conv_layer2_fifo_write_time_single_channel,conv_layer2_fifo_read_time_single_channel]=AER_conv2_prop_multi_channel(AER_conv2_single_channel,V_pad_conv_layer2,weight_conv2_single_channel);
    
    V_pad_conv_layer2=pad_Vmem_inh(V_pad_conv_layer2,K_inh_pad);

%% 计算最终结果
features=Vmem;%最后一层V的值是一个1*1*D的三维矩阵
features1=max(features,[],1);
V_mem_feature=max(features1,[],2);
%Vmem_features(ii,:)=V_mem_feature;

% single channel conv layer 2 计算最终的结果
    single_channel_feature=V_pad_conv_layer2;
    single_channel_feature1=max(single_channel_feature,[],1);
    V_mem_feature_single_channel=max(single_channel_feature1,[],2);
    %Vmem_features_single_channel(ii,:)=V_mem_feature_single_channel;

Vmem_features(ii,:)=V_mem_feature_single_channel;

% %生成一个将结果转化为16进制的函数
% fi_V_pad1=fi(V_pad1,0,fi_width+5,fi_width-1);
% X=25;Y=30;
% data_149=[];
% for i=1:10
%     fi_V_pad1_part=fi_V_pad1(X,Y,fi_width);
%     hex_fi_V_pad1_part=bin(fi_V_pad1_part);
%     data_149=[hex_fi_V_pad1_part,data_149];
% end
hex_spike_message=monitor_conv1_pool(conv_spike_AER,pooling_AER);

fi_vmem_feature=fi(V_mem_feature,0,fi_width+5,fi_width-1);
bin_fi_vmem_feature=bin(fi_vmem_feature);
hex_fi_vmem_feature=hex(fi_vmem_feature);

inference_time(ii)=toc;

%% 计算fifo中的脉冲最高的数目
    %分别记录的有conv1 fifo write time 以及conv1 fifo read time
    max_number_conv1_pool_fifo=fifo_number_calculate(conv_layer1_fifo_write_time,conv_layer1_fifo_read_time);
    %分别记录了 conv2 fifo1 write time | conv2 fifo2 write time | conv2 fifo3 write time | conv2 fifo4 write time 
    max_number_pool_conv2_fifo1=fifo_number_calculate(conv_layer2_fifo1_write_time,conv_layer2_fifo1_read_time);
    max_number_pool_conv2_fifo2=fifo_number_calculate(conv_layer2_fifo2_write_time,conv_layer2_fifo2_read_time);
    max_number_pool_conv2_fifo3=fifo_number_calculate(conv_layer2_fifo3_write_time,conv_layer2_fifo3_read_time);
    max_number_pool_conv2_fifo4=fifo_number_calculate(conv_layer2_fifo4_write_time,conv_layer2_fifo4_read_time);
    
    %记录单通道的signal channel
    max_number_pool_conv2_fifo_single_channel=fifo_number_calculate(conv_layer2_fifo_write_time_single_channel,conv_layer2_fifo_read_time_single_channel);
    current_img_fifo_max_num=[max_number_conv1_pool_fifo,max_number_pool_conv2_fifo1,max_number_pool_conv2_fifo2,max_number_pool_conv2_fifo3,max_number_pool_conv2_fifo4];
    max_fifo_nums(ii,:)=current_img_fifo_max_num;
    
    %计算输入脉冲数量
    input_spike_num(ii) = AER_num;
    conv1_spike_num(ii) = conv_spike_AER_num;
    pool1_spike_num(ii) = pool_spike_number;
    

end
       fprintf('---------------------TRAINING PROGRESS %2.3f----------------- \n',num_img/num_img)
       fprintf('-------------------------------------------------------------\n')
       fprintf('---------------TRAINING FEATURES EXTRACTED-------------------\n')
       fprintf('-------------------------------------------------------------\n')

end

