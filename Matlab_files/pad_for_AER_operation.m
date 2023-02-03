function layers=pad_for_AER_operation(layers,network_struct)
    [~,K]=size(network_struct);
    %从第二个卷积层开始补pad
    for i=2:K
        if i==2   %conv1 layer
            pad=network_struct{i}.pad; %将s进行周围补零操作，以便于卷积  s的规模为H×W×D
            layers{i}.K_inh=pad_for_K_inh(layers{i}.K_inh,pad);     %K_inh边界补1，其他位置为0
            layers{i}.V=pad_for_V(layers{i}.V,pad);                 %V_直接就是0
            %layers{i-1}.K_STDP=pad_for_K_STDP(layers{i}.K_STDP,pad);  %K_STDP,周围应该就还是30，这个不会变
        end
        if i==4   %conv2 layer
            pad=network_struct{i}.pad; %将s进行周围补零操作，以便于卷积  s的规模为H×W×D
            layers{i}.K_inh=pad_for_K_inh(layers{i}.K_inh,pad);     %K_inh边界补1，其他位置为0
            layers{i}.V=pad_for_V(layers{i}.V,pad);                 %V_直接就是0
            %layers{i-1}.K_STDP=pad_for_K_STDP(layers{i}.K_STDP,pad);  %K_STDP,周围应该就还是30，这个不会变
        end
    end
end