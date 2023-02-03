function weights=STDP(layers,learning_layer,network_struct,STDP_index,weights,deta_STDP_minus,deta_STDP_plus,STDP_num)
    global total_time
    
    pad=network_struct{learning_layer}.pad; %卷积层的周围补零范围，
    stride=network_struct{learning_layer}.stride;%卷积窗移动步长
    
    K_STDP=layers{learning_layer-1}.K_STDP; %学习层上一层的脉冲输入时间矩阵
    K_STDP_pad=pad_for_K_STDP( K_STDP,pad );
    w=weights{learning_layer};
    [H,W,D,M]=size(w);
for K=1:M
  if STDP_index{K}>0
     si=STDP_index{K}(2);
     sj=STDP_index{K}(3); %sk=K
     t=STDP_index{K}(4); %即将进行STDP的位置，按层得到
     local_K_STDP=K_STDP_pad((si-1)*stride+1:(si-1)*stride+H,(sj-1)*stride+1:(sj-1)*stride+W,:);%找到发生更新的位置对应的发生映射关系的前一层的神经元 
     %大小范围为H_W_D 与weight范围一致
    for k=1:D
        for i=1:H
            for j=1:W
                if local_K_STDP(i,j,k)==total_time  %没有发出脉冲，未激活
                    dw=-deta_STDP_minus(1);%*最大的惩罚
                else
                    if local_K_STDP(i,j,k)>=t
                        dw=-deta_STDP_minus(local_K_STDP(i,j,k)-t+1);%*w(i,j,k,sk);
                    elseif local_K_STDP(i,j,k)<t
                        dw=deta_STDP_plus(t-local_K_STDP(i,j,k));%*(1-w(i,j,k,sk));
                    end
                end
                w(i,j,k,K)=w(i,j,k,K)+dw;
                if w(i,j,k,K)>0.999999
                    w(i,j,k,K)=0.999999;
                elseif w(i,j,k,K)<0.000001
                    w(i,j,k,K)=0.000001;
                end  
            end
        end
    end
  end
end
weights{learning_layer}=w;
    
    
end