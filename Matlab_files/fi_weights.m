% fixed point operating for the weights, then test the correct rate of SCNN
function fi_weight=fi_weights(weights,fi_width)

    signed_flag=0;% unsigned variable for fixed
    
    fi_weight=cell(1,4);
    
    weight_conv1=weights{2};
    weight_conv2=weights{4};
    
    
%% fi Conv layer1
    [H1,W1,M1,D1]=size(weight_conv1);
    fixed_weight_conv1=zeros(H1,W1,M1,D1);
    fixed_weight_conv1_cell=cell(M1,D1);
    
     for m=1:M1
         for d=1:D1
            fixed_weight_conv1(:,:,m,d)=fi(weight_conv1(:,:,m,d),signed_flag,fi_width,fi_width-1);
            fixed_weight_conv1_cell{m,d}=fi(weight_conv1(:,:,m,d),signed_flag,fi_width,fi_width-1);
        end
    end
    
    
    
%% fi Conv layer2
    [H2,W2,M2,D2]=size(weight_conv2);
    fixed_weight_conv2=zeros(H2,W2,M2,D2);
    fixed_weight_conv2_cell=cell(M2,D2);
    for m=1:M2 
        for d=1:D2
            fixed_weight_conv2(:,:,m,d)=fi(weight_conv2(:,:,m,d),signed_flag,fi_width,fi_width-1);
            fixed_weight_conv2_cell{m,d}=fi(weight_conv2(:,:,m,d),signed_flag,fi_width,fi_width-1);
        end
    end

    fi_weight{2}=fixed_weight_conv1;
    fi_weight{4}=fixed_weight_conv2;
    
%% weight_coe_files    conv layer1
% %coe data--fixed_weight_con1v_cell
%     Coe_data=cell(H1,W1);
%     for i=1:H1 
%         for j=1:W1
%             base_coe=[];
%             for k=1:D1
%                 current_weight_cell=fixed_weight_conv1_cell{k};
%                 current_weight=current_weight_cell(i,j);
%                 current_weight_bin=bin(current_weight);
%                 base_coe=[current_weight_bin,base_coe];
%             end
%             Coe_data{i,j}=base_coe;
%         end
%     end
% % data write into coe file
%     fid=fopen('weight_rom_conv1.coe','w'); %创建.coe文件
%     fprintf(fid,'memory_initialization_radix=2;\n');
%     fprintf(fid,'memory_initialization_vector=\n');
%     for X=1:H1   
%         for Y=1:W1
%             if(X~=H1 || Y~=W1)
%                 coe_data=Coe_data{X,Y};
%                 fprintf(fid,'%s,\n',coe_data);%向.coe文件中写入数据
%             else
%                 coe_data=Coe_data{X,Y};
%                 fprintf(fid,'%s',coe_data);%向.coe文件中写入数据
%             end
%         end
%     end
%     fclose(fid); %关闭.coe文件
%     
%% weight_coe_files    conv layer2
% %coe data
%     Coe_data1=cell(H2,W2);  %15*15 准备用来做映射
%     Coe_data2=cell(H2,W2);
%     Coe_data3=cell(H2,W2);
%     Coe_data4=cell(H2,W2);
%     %channel1
%     for i=1:H2
%         for j=1:W2
%             base_coe=[];
%             for k=1:D2
%                 current_weight_cell=fixed_weight_conv2_cell{1,k};
%                 current_weight=current_weight_cell(i,j);    %位置为(i,j,1,k)处的定点数据
%                 current_weight_bin=bin(current_weight);
%                 base_coe=[current_weight_bin,base_coe];
%             end
%             Coe_data1{i,j}=base_coe;
%         end
%     end 
%     %channel2
%     for i=1:H2
%         for j=1:W2
%             base_coe=[];
%             for k=1:D2
%                 current_weight_cell=fixed_weight_conv2_cell{2,k};
%                 current_weight=current_weight_cell(i,j);
%                 current_weight_bin=bin(current_weight);
%                 base_coe=[current_weight_bin,base_coe];
%             end
%             Coe_data2{i,j}=base_coe;
%         end
%     end 
%     %channel3
%     for i=1:H2
%         for j=1:W2
%             base_coe=[];
%             for k=1:D2
%                 current_weight_cell=fixed_weight_conv2_cell{3,k};
%                 current_weight=current_weight_cell(i,j);
%                 current_weight_bin=bin(current_weight);
%                 base_coe=[current_weight_bin,base_coe];
%             end
%             Coe_data3{i,j}=base_coe;
%         end
%     end
%     %channel4
%     for i=1:H2
%         for j=1:W2
%             base_coe=[];
%             for k=1:D2
%                 current_weight_cell=fixed_weight_conv2_cell{4,k};
%                 current_weight=current_weight_cell(i,j);
%                 current_weight_bin=bin(current_weight);
%                 base_coe=[current_weight_bin,base_coe];
%             end
%             Coe_data4{i,j}=base_coe;
%         end
%     end 
% % data write into coe file    
% for i=1:M2
%     %choose data
%     switch (i)
%         case 1
%             Coe_data_current_channel=Coe_data1;
%             fid=fopen('weight_rom_conv2_channel1.coe','w'); %创建.coe文件
%         case 2
%             Coe_data_current_channel=Coe_data2;
%             fid=fopen('weight_rom_conv2_channel2.coe','w'); %创建.coe文件
%         case 3
%             Coe_data_current_channel=Coe_data3;
%             fid=fopen('weight_rom_conv2_channel3.coe','w'); %创建.coe文件
%         case 4
%             Coe_data_current_channel=Coe_data4;
%             fid=fopen('weight_rom_conv2_channel4.coe','w'); %创建.coe文件
%         otherwise
%             disp('error when coe write');
%     end
%     
%     fprintf(fid,'memory_initialization_radix=2;\n');
%     fprintf(fid,'memory_initialization_vector=\n');
%     %data_write
%     for X=1:H2
%         for Y=1:W2
%             if(X~=H2 || Y~=W2)
%                 coe_data=Coe_data_current_channel{X,Y};
%                 fprintf(fid,'%s,\n',coe_data);
%             else
%                 coe_data=Coe_data_current_channel{X,Y};
%                 fprintf(fid,'%s',coe_data);
%             end
%         end
%     end
%     fclose(fid); %关闭.coe文件   
%     
% end    
 %% conv_weight_2_test
%     test_weight=ones(15,15)*0.0625;
%     fi_test_weight=fi(test_weight,signed_flag,fi_width,fi_width-1);
%     Coe_test_data=cell(15,15);
%     for i=1:15
%         for j=1:15
%             base_coe=[];
%             for k=1:10
%                 current_weight_cell=fi_test_weight;
%                 current_weight=current_weight_cell(i,j);
%                 current_weight_bin=bin(current_weight);
%                 base_coe=[current_weight_bin,base_coe];
%             end
%             Coe_test_data{i,j}=base_coe;
%         end
%     end 
%     
%     fid=fopen('weight_rom_conv2_test.coe','w'); %创建.coe文件
%     
%     fprintf(fid,'memory_initialization_radix=2;\n');
%     fprintf(fid,'memory_initialization_vector=\n');
%     
%     for X=1:H2
%         for Y=1:W2
%             coe_data=Coe_test_data{X,Y};
%             if(X~=H2 || Y~=W2)
%                 fprintf(fid,'%s,\n',coe_data);
%             else
%                 fprintf(fid,'%s',coe_data);
%             end
%         end
%     end
%     fclose(fid); %关闭.coe文件       
end
