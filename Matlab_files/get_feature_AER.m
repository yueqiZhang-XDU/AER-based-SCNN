function [Vmem_features] = get_feature_AER(weights,layers,network_struct,image_path,num_img,DoG_params,total_time,fi_width)
%���һ��N*M�ľ���NΪѵ������������MΪ���һ��Ĳ�������ÿһ�б���ѵ�����
%��Ҫ���Ȱ����һ���Ĥ��λ����Ϊ�����

[~,num_layers]=size(network_struct);
network_struct{num_layers}.th=1000;
n=1; 
[~,~,n_featuers]=size(layers{num_layers}.V);%���һ���������Ȳ���

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
  
% %����һ��weight ��һ��test �۲����Ƿ��ǵڶ�������ھ�������г��ֵ�����
%    weight_test=ones(15,15,4,10)*0.0625;
%    weights{4}=weight_test;
            
        
spike_number(ii)=AER_num;
    i=2; %����conv1 i=2
    V=layers{i}.V;
    S=layers{i}.S;
    K_inh=layers{i}.K_inh;
    pad=network_struct{i}.pad; %��s������Χ����������Ա��ھ��  s�Ĺ�ģΪH��W��D
    th=network_struct{i}.th;
    stride=network_struct{i}.stride;
    [ S_pad ]=pad_for_conv(S,pad );    %t-1ʱ�̵�ǰһ����������
    [ V_pad ]=pad_for_conv(V,pad);
    [ K_inh_pad]=pad_for_Kinh(K_inh,pad);
    conv_spike_AER=zeros(4,32768);
    conv_spike_AER_num=1;

    %�й�fifo�����ݶ��壺 
    %���ﶨ�������д��ʱ���뷢��ʱ��Ϊ�ı�fifo�ڲ���Ϣ������ʱ�䡣
        conv_layer1_fifo_write_time=zeros(1,32768);% ��һ�������д��fifo��ʱ��
       %conv_layer1_fifo_read_time                 % �ز�ӵ�һ��������ȡ�����ʱ��
       
        conv_layer2_fifo1_write_time=zeros(1,1000);
        conv_layer2_fifo2_write_time=zeros(1,1000);
        conv_layer2_fifo3_write_time=zeros(1,1000);
        conv_layer2_fifo4_write_time=zeros(1,1000);
        
        %conv_layer2_fifo1_read_time
        %conv_layer2_fifo2_read_time
        %conv_layer2_fifo3_read_time
        %conv_layer2_fifo4_read_time
        
        
%AER�������� 
    operating_time=0;%��ʼʱ��
%% conv Layer 1    
for current_spike_num=1:AER_num    
    spike_AER=AER_M(:,current_spike_num);    
    operating_time=operating_time+3;%�տ�ʼ������ʱ��
    [S_pad,V_pad,K_inh_pad,conv_spike_AER,conv_layer1_fifo_write_time,conv_spike_AER_num,operating_time]=AER_conv_prop(spike_AER,S_pad,V_pad,K_inh_pad,weights{2},th,conv_spike_AER,conv_layer1_fifo_write_time,conv_spike_AER_num,operating_time);%���������
    %���ｫ������Ľ�������˶���
end            
 %save('conv1_result.mat','conv_spike_AER');
 spike_number_conv1(ii) = conv_spike_AER_num;
 
%% pooling_layer
    i=3; %����conv1 i=2
    V=layers{i}.V;
    S=layers{i}.S;
    K_inh=layers{i}.K_inh;
    pad=network_struct{i}.pad; %��s������Χ����������Ա��ھ��  s�Ĺ�ģΪH��W��D
    stride=network_struct{i}.stride;
%��������Ϊconv_spike_AER;
 [pooling_AER,conv_layer1_fifo_read_time,pool_spike_number]= AER_pooling_prop(conv_spike_AER,K_inh,stride,pad);

%save('pooling_AER.mat','pooling_AER');

spike_number_pool1(ii) = pool_spike_number;

%% conv_layers2
%ͨ��Ȩֵ����
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

% ���ز����������д�벻ͬ��fifo�еĹ��� ��Ҫ���д����ӳ�


%������֤����ͨ��������£� ���е��������д����Ӧ��ͨ����
for k=1:1000
current_AER=pooling_AER(:,k);
current_AER(4)=current_AER(4)+2;        % �����ö�Ӧ��ʱ��+2 ��ʾ�ӳز㷢�������壬д�뵽fifo�е�д���ӳ١�
current_time=current_AER(4);
AER_channel=current_AER(1);
switch AER_channel
    case 1
        pooling_AER_channel1(:,M1)=current_AER;
        conv_layer2_fifo1_write_time(:,M1)=current_time;  %����д��ʱ��
        M1=M1+1;
    case 2
        pooling_AER_channel2(:,M2)=current_AER;
        conv_layer2_fifo2_write_time(:,M2)=current_time;  %����д��ʱ��
        M2=M2+1;        
    case 3
        pooling_AER_channel3(:,M3)=current_AER;
        conv_layer2_fifo3_write_time(:,M3)=current_time;  %����д��ʱ��
        M3=M3+1;   
    case 4
        pooling_AER_channel4(:,M4)=current_AER;
        conv_layer2_fifo4_write_time(:,M4)=current_time;  %����д��ʱ��
        M4=M4+1;   
end
end


%֮����еڶ�����
    i=4; %����conv1 i=2
    V_conv2=layers{i}.V;
    pad=network_struct{i}.pad; %��s������Χ����������Ա��ھ��  s�Ĺ�ģΪH��W��D
    [ V_pad_conv2 ]=pad_for_conv(V_conv2,pad);

    K_inh=layers{4}.K_inh;
    [K_inh_pad]=pad_for_Kinh(K_inh,pad);
    
    
 V_pad1=V_pad_conv2;
 V_pad2=V_pad_conv2;
 V_pad3=V_pad_conv2;
 V_pad4=V_pad_conv2;
%�������
[V_pad1,conv_layer2_fifo1_read_time]=AER_conv2_prop(pooling_AER_channel1,V_pad1,weight_channel1);
[V_pad2,conv_layer2_fifo2_read_time]=AER_conv2_prop(pooling_AER_channel2,V_pad2,weight_channel2);
[V_pad3,conv_layer2_fifo3_read_time]=AER_conv2_prop(pooling_AER_channel3,V_pad3,weight_channel3);
[V_pad4,conv_layer2_fifo4_read_time]=AER_conv2_prop(pooling_AER_channel4,V_pad4,weight_channel4);

V_pad_inh1=pad_Vmem_inh(V_pad1,K_inh_pad);
V_pad_inh2=pad_Vmem_inh(V_pad2,K_inh_pad);
V_pad_inh3=pad_Vmem_inh(V_pad3,K_inh_pad);
V_pad_inh4=pad_Vmem_inh(V_pad4,K_inh_pad);

Vmem=V_pad_inh1+V_pad_inh2+V_pad_inh3+V_pad_inh4;
%����������
%% conv layer2 signal channel
    %�������������Դ
    i=4; 
    AER_conv2_single_channel=pooling_AER;
    V_conv2_single_channel=layers{i}.V;
    [ V_pad_conv_layer2 ]=pad_for_conv(V_conv2_single_channel,pad);
    weight_conv2_single_channel=weights{4};
    
    %��ͨ������¶������еĳز����������о��
    [V_pad_conv_layer2,conv_layer2_fifo_write_time_single_channel,conv_layer2_fifo_read_time_single_channel]=AER_conv2_prop_multi_channel(AER_conv2_single_channel,V_pad_conv_layer2,weight_conv2_single_channel);
    
    V_pad_conv_layer2=pad_Vmem_inh(V_pad_conv_layer2,K_inh_pad);

%% �������ս��
features=Vmem;%���һ��V��ֵ��һ��1*1*D����ά����
features1=max(features,[],1);
V_mem_feature=max(features1,[],2);
%Vmem_features(ii,:)=V_mem_feature;

% single channel conv layer 2 �������յĽ��
    single_channel_feature=V_pad_conv_layer2;
    single_channel_feature1=max(single_channel_feature,[],1);
    V_mem_feature_single_channel=max(single_channel_feature1,[],2);
    %Vmem_features_single_channel(ii,:)=V_mem_feature_single_channel;

Vmem_features(ii,:)=V_mem_feature_single_channel;

% %����һ�������ת��Ϊ16���Ƶĺ���
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

%% ����fifo�е�������ߵ���Ŀ
    %�ֱ��¼����conv1 fifo write time �Լ�conv1 fifo read time
    max_number_conv1_pool_fifo=fifo_number_calculate(conv_layer1_fifo_write_time,conv_layer1_fifo_read_time);
    %�ֱ��¼�� conv2 fifo1 write time | conv2 fifo2 write time | conv2 fifo3 write time | conv2 fifo4 write time 
    max_number_pool_conv2_fifo1=fifo_number_calculate(conv_layer2_fifo1_write_time,conv_layer2_fifo1_read_time);
    max_number_pool_conv2_fifo2=fifo_number_calculate(conv_layer2_fifo2_write_time,conv_layer2_fifo2_read_time);
    max_number_pool_conv2_fifo3=fifo_number_calculate(conv_layer2_fifo3_write_time,conv_layer2_fifo3_read_time);
    max_number_pool_conv2_fifo4=fifo_number_calculate(conv_layer2_fifo4_write_time,conv_layer2_fifo4_read_time);
    
    %��¼��ͨ����signal channel
    max_number_pool_conv2_fifo_single_channel=fifo_number_calculate(conv_layer2_fifo_write_time_single_channel,conv_layer2_fifo_read_time_single_channel);
    current_img_fifo_max_num=[max_number_conv1_pool_fifo,max_number_pool_conv2_fifo1,max_number_pool_conv2_fifo2,max_number_pool_conv2_fifo3,max_number_pool_conv2_fifo4];
    max_fifo_nums(ii,:)=current_img_fifo_max_num;
    
    %����������������
    input_spike_num(ii) = AER_num;
    conv1_spike_num(ii) = conv_spike_AER_num;
    pool1_spike_num(ii) = pool_spike_number;
    

end
       fprintf('---------------------TRAINING PROGRESS %2.3f----------------- \n',num_img/num_img)
       fprintf('-------------------------------------------------------------\n')
       fprintf('---------------TRAINING FEATURES EXTRACTED-------------------\n')
       fprintf('-------------------------------------------------------------\n')

end

