function  weights=AER_train_step(weights,layers,spike_buffer,network_struct,STDP_for_AER_train,total_time,spike_package)
%% 先初始化layers 与 STDP学习抑制矩阵
layers=pad_for_AER_operation(layers,network_struct); %补过pad的layers 用于反卷积映射

%用于STDP抑制的矩阵STDP_inh    用于实现学习过程中的侧抑制与互抑制
STDP_inh2=zeros(size(layers{2}.V));
STDP_inh4=zeros(size(layers{4}.V));
STDP_inh={0,STDP_inh2,0,STDP_inh4};%STDP inh based on the STDP offset
%% initial for each image
learning_layer=STDP_for_AER_train.learning_layer;%当前网络的学习层
[~,~,Sz]=size(layers{learning_layer}.S);
STDP_counter=0;
STDP_index=cell(Sz,1);%预先分配STDP_index的内存位置。
STDP_per_layer=STDP_for_AER_train.STDP_parames.STDP_per_layer;
offset=STDP_for_AER_train.STDP_parames.offset(learning_layer);
%% prop 
    %采用AER传播方式对于网络进行STDP学习，脉冲信息由 spike_buffer存储    
spike_register=cell(1,4);    

for t=1:total_time
    spike_register{1}=spike_package{t};
    layers{1}.K_STDP=K_STDP_refresh_1(spike_register{1}, layers{1}.K_STDP, t);%输入层K_STDP矩阵进行更新,纪录发出脉冲的时间
    
    for i=2:learning_layer %当前层信息   
        w=weights{i};
        V=layers{i}.V;       
        K_inh=layers{i}.K_inh;
        K_STDP_in=layers{i}.K_STDP;%这个pad没补零，仍然是原来的大小，该变的也就是原始数据
        pad=network_struct{i}.pad;
        th=network_struct{i}.th;
        stride=network_struct{i}.stride;        
    %输入脉冲信息
        spike_AER_in=spike_buffer{i-1};%上一时刻，上一层的输出
        if strcmp( network_struct{i}.Type,'conv' )%该层为卷积层时  
            [spike_AER_out,V_out,K_inh_out]=AER_conv(spike_AER_in,V,K_inh,w,th);%这里通过运算输出的spike，都是带有pad的spike
            K_STDP_out=K_STDP_record(spike_AER_out,K_STDP_in,pad,t);
        elseif strcmp( network_struct{i}.Type,'pool' )%当该层为池层时
            pad=network_struct{i}.pad;pre_pad=network_struct{i-1}.pad;
            [spike_AER_out,K_inh_out]=AER_pooling(spike_AER_in,K_inh,stride,pad,pre_pad);
            K_STDP_out=K_STDP_record_pool(spike_AER_out,K_STDP_in,t);
            %pool层作为学习层的输入层，发出脉冲后更新突触前神经元的K_STDP，作为是否发出抑制型STDP的标志。
        end
        layers{i}.V=V_out; %更新为本时刻的膜电位
        layers{i}.K_STDP=K_STDP_out;
        layers{i}.K_inh=K_inh_out;
        spike_register{i}=spike_AER_out;
    end
    spike_buffer=spike_register;
    
    % get STDP index
    
    if ( sum(sum(spike_register{learning_layer}))>0 && STDP_counter<STDP_per_layer(learning_layer) )%卷积层中有脉冲产生，同时本次迭代还有学习次数
        [K,~]=size(spike_register{learning_layer});%该时间步产生的脉冲数
        for i=1:K
            current_spike=spike_register{learning_layer}(K,:);
            STDP_pad=network_struct{learning_layer}.pad;
            [STDP_index,STDP_counter,STDP_inh]=get_STDP_index(current_spike,STDP_index,STDP_counter,STDP_inh,learning_layer,offset,STDP_pad,t);
        end
    end
end    


%% 传播完毕 进行STDP学习
        deta_STDP_minus=STDP_for_AER_train.deta_STDP_minus;
        deta_STDP_plus =STDP_for_AER_train.deta_STDP_plus;
        weights=STDP(layers,learning_layer,network_struct,STDP_index,weights,deta_STDP_minus,deta_STDP_plus,STDP_per_layer(learning_layer));

end  %end function

