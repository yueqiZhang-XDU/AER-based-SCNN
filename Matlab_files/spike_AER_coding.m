function st=spike_AER_coding(path_img,DoG_size,img_size,total_time,num_layers)
    H=img_size.img_sizeH;
    W=img_size.img_sizeW;
    filt_size=DoG_size;
    %path_img='.\datasets\LearningSet\Motorbike\moto_0051.png';
    image=imread(path_img);
    image=imresize(image,[H W]);
    image_for_DoG=double(image);
    %归一化的DoG滤波器
    filt=load('filt.mat');
    filt=filt.filt;
    out1=imfilter(image_for_DoG,filt,'replicate','same','conv'); % image_filted
    %boarder
    border=zeros(H,W);
    border(filt_size+1:H-filt_size,filt_size+1:W-filt_size)=1;
    out1=out1.*border;
    out_threshold=out1;
    out_threshold(out1<16)=0;
    img_out=out_threshold;%输出脉冲位置，以及对应位置的值。
    for i=1:H
        for j=1:W
            out_threshold(i,j)=1/out_threshold(i,j);
        end
    end
  
%% 对于矩阵的操作 生成脉冲数据
    out_x=reshape(out_threshold,[1,H*W]);%out_X  矩阵降维，变成为一维向量
    [lat,I] = sort(out_x); %排序
    I(lat==Inf)=[];%   I 为最终将要发出脉冲的序列的（序数）
    [X,Y] = ind2sub([H,W],I);%这里生成的X,Y为I的AER位置信息   AER地址为X(i),Y(i)
    [~,I_num]=size(I);

    out_max=max(max(img_out));
    out_min=min(min(img_out));
    spike_rank=zeros(1,I_num);
    for i=1:I_num
        spike_rank(i)=floor( ( out_max-img_out(X(i),Y(i)) )/(out_max-out_min)*(total_time-num_layers+1) )+1; %max= total_time-num_layers+1
    end
%% 将脉冲按照时刻打包
    %用于存储脉冲信息的数据包
    spike_package=cell(1,30);
    
%     %生成脉冲数据包
%     t=1;
%     for i=1:I_num
%             current_spike_time=spike_rank(i);
%             row=X(i);
%             column=Y(i);
%             spike_AER=[row,column];
%         if  current_spike_time==t
%             spike_package{t}=[spike_package{t}; spike_AER ];
%         elseif t<30
%             t=t+1;
%             
%                 spike_package{t}=[spike_package{t}; spike_AER ];
%         end
%     end
%     
    i=1;
    for t=1:(total_time-num_layers+1)
       while spike_rank(i)==t
            row=X(i);
            column=Y(i);
            spike_AER=[1,row,column];
            spike_package{t}=[spike_package{t}; spike_AER ];
            if i<I_num
                i=i+1;
            else
                i=1;
            end
       end
    end
    st=spike_package;
    
%% AER_message_for fpga project   
%     AER_M=zeros(I_num,3);
%     for i = 1: I_num
%        X_AER=X(i);
%        Y_AER=Y(i);
%        T_st=spike_rank(i);
%        
%        AER_M(i,1)=X_AER;
%        AER_M(i,2)=Y_AER;
%        AER_M(i,3)=T_st;
%     end
%  %  data file name    
% data_location_learn='.\datasets\LearningSet';
% data_location_train='.\datasets\LearningSet';
%  
% %最高六位为T，前八位为X，后八位为Y，
%      fid=fopen('t_step_for_ram_928_1.coe','w'); %创建.coe文件
%      for i = 1: I_num
%          X10=X(i);
%          Y10=Y(i);
%          X2=dec2bin(X10,8);
%          Y2=dec2bin(Y10,8);
%          AER=[X2,Y2];
%          if i<I_num
%              fprintf(fid,'%s,\n',AER);%向.coe文件中写入数据
%          else 
%              fprintf(fid,'%s;',AER);
%          end
%       end
%       fclose(fid); %关闭.coe文件    
%     
%     
%     
end