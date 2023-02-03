function weights=SCNN_AER_train(weights,network_struct,datasets_path_learn,DoG_params,STDP_params,learnable_layers,deta_STDP_minus,deta_STDP_plus,total_time)
    [~,num_layers]=size(network_struct);
    max_iter=STDP_params.max_iter;
    
    [~,num_image_learn]=size(datasets_path_learn);
    
    curr_lay_idx=1;
    learning_layer=learnable_layers(1);
    counter=1;
    
    n=1;
    for i=1:max_iter
        perc=i/max_iter;
        %tic to test the traing time
        fprintf('---------------------LEARNING PROGRESS %1.0f/%1.0f --- %2.4f-------------------- \n',i,max_iter,perc)
        
         if counter>STDP_params.max_learning_iter(learning_layer) 
             curr_lay_idx=curr_lay_idx+1;
             learning_layer=learnable_layers(curr_lay_idx);
             counter=1;
         else
             counter=counter+1;
         end
         
         path_img=datasets_path_learn{n};
         if n<num_image_learn
             n=n+1;
         else
             n=1;
         end   
         % TTFS spike encoding
         spike_package=spike_AER_coding(path_img,DoG_params.DoG_size,DoG_params.img_size,total_time,num_layers);
         layers = init_layers(network_struct);
         spike_buffer=cell(1,4); 
         STDP_for_AER_train=struct('STDP_parames',STDP_params,'learning_layer',learning_layer,'deta_STDP_minus',deta_STDP_minus,'deta_STDP_plus',deta_STDP_plus);
         %training function 
         weights=AER_train_step(weights, layers, spike_buffer, network_struct, STDP_for_AER_train, total_time, spike_package);
        %toc
    end
    fprintf('---------LEARNING PROGRESS %2.3f------------- \n',perc)
    fprintf('-------------------- FINISHED LEARNING---------------------\n')
    
end    
    
    
    
    