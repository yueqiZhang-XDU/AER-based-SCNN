function K_STDP_out=K_STDP_record(spike_input,K_STDP_in,pad,t)
%改变的K_STDP的位置是实际位置，在最终网络学习的时候，还需要进行补零之后才能STDP
        [spike_num,~]=size(spike_input);
        K_STDP_out=K_STDP_in;
    for K=1:spike_num     %对每一个输入脉冲发生反卷积
        channel=spike_input(K,1);
        M=spike_input(K,2)-pad;
        N=spike_input(K,3)-pad;
        K_STDP_out(M,N,channel)=t;
    end
end