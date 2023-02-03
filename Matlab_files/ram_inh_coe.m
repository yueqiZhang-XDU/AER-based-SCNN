function ram_inh_coe(layers,network_struct,fi_width)
fi_Vmem_width1=fi_width+2;
fi_Vmem_width2=fi_width+5;
%% Cone_layer1
pad=network_struct{2}.pad;
K_inh=layers{2}.K_inh;
[ K_inh_pad]=pad_for_Kinh(K_inh,pad); % inh_flag=1;
[H,W]=size(K_inh_pad);

% prepare data
ram_inh_data=cell(H,W);
pad=dec2bin(0,4*fi_Vmem_width1);
for i=1:H
    for j=1:W
        if(K_inh_pad(i,j))
            flag=dec2bin(1);
        else 
            flag=dec2bin(0);
        end
        ram_inh_data{i,j}=[flag,pad];
    end
end
        
% write into coe file
    fid=fopen('ram_inh_initial_conv1.coe','w'); %鍒涘缓.coe鏂囦欢
    fprintf(fid,'memory_initialization_radix=2;\n');
    fprintf(fid,'memory_initialization_vector=\n');
    for X=1:H
        for Y=1:W
            Current_write_data=ram_inh_data{X,Y};
            if(X~=H || Y~=W)
                fprintf(fid,'%s,\n',Current_write_data);
            else
                fprintf(fid,'%s',Current_write_data);
            end
        end
    end
    
    fclose(fid);


%% Cone_layer2
pad=network_struct{4}.pad;
K_inh=layers{4}.K_inh;
[ K_inh_pad]=pad_for_Kinh(K_inh,pad);
[H,W]=size(K_inh_pad);

% prepare data
ram_inh_data=cell(H,W);
pad=dec2bin(0,10*fi_Vmem_width2);
for i=1:H
    for j=1:W
        if(K_inh_pad(i,j))
            flag=dec2bin(1);
        else 
            flag=dec2bin(0);
        end
        ram_inh_data{i,j}=[flag,pad];
    end
end

% write into coe file
    fid=fopen('ram_inh_initial_conv2.coe','w'); %鍒涘缓.coe鏂囦欢
    fprintf(fid,'memory_initialization_radix=2;\n');
    fprintf(fid,'memory_initialization_vector=\n');
    for X=1:H
        for Y=1:W
            Current_write_data=ram_inh_data{X,Y};
            if(X~=H || Y~=W)
                fprintf(fid,'%s,\n',Current_write_data);
            else
                fprintf(fid,'%s',Current_write_data);
            end
        end
    end
    
    fclose(fid);

end