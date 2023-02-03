function [AER_M] = DoG_filter_to_AER_mem( path_img,filt_size,img_size,total_time,num_layers)
%UNTITLED5 此处显示有关此函数的摘要
%   此处显示详细说明
H=img_size.img_sizeH;
W=img_size.img_sizeW;
% path_img='.\datasets\LearningSet\Motorbike\moto_0007.png';
% path_img='.\datasets\LearningSet\Face\image_0002.png';
%path_img='0001.bmp';
image=imread(path_img);
image=imresize(image,[H W]);%对图片大小进行调�?
image_for_DoG=double(image);
%对图像进行滤�?
filt=load('filt.mat');
filt=filt.filt;

fi_filt = double( fi(filt,1,8,5));


% out1=imfilter(image_for_DoG,filt,'replicate','same','conv'); %out1
out1=imfilter(image_for_DoG,fi_filt,0,'same','conv'); %out1



%boarder                                                     
border=zeros(H,W);
border(filt_size+1:H-filt_size,filt_size+1:W-filt_size)=1;
out1=out1.*border;

%-----------------------------------------------------------
%a fixed pointed try
fraction_length = 6;
out2 =  fi(out1,1,16,fraction_length);
out_threshold=double(out2);
%-----------------------------------------------------------

out_threshold(out1<16)=0;
img_out=out_threshold;
% for i=1:H
%     for j=1:W
%         out_threshold(i,j)=1/out_threshold(i,j);
%     end
% end
for i=1:H
    for j=1:W
        out_threshold(i,j)=1/out_threshold(i,j);
    end
end
out_S=out_threshold;
%图像大小为H,W
out_x=reshape(out_threshold,[1,H*W]);%矩阵降维，数据按照列的顺序进行填充成为一维矩�? 即第 x个数�?=j*H+i
%取�?�数

[lat,I] = sort(out_x);  
I(lat==Inf)=[];%删去I中的inf位置，可以认为该位置不发出脉�?
%I中存储的是索�?
[X,Y] = ind2sub([H,W],I);        %将I�?存的向量序数转化为矩阵中的行列位�?    XY中为out_x中发出脉冲的索引
[~,I_num]=size(I);
out_max=max(max(img_out));%输出�?大�??
out_min=min(min(img_out));%输出�?小�??

t_step=zeros(size(out_S))*total_time;
for i=1:I_num
t_step(X(i),Y(i))=floor((out_max-img_out(X(i),Y(i)))/(out_max-out_min)*(total_time-num_layers+1))+1;
end
% memory_initialization_radix=10;
%    memory_initialization_vector =

AER_M=zeros(2,I_num);   %AER_MΪ�����������Ϣ
%生成AER形式的矩�?
for i = 1: I_num
   X10=X(i);
   Y10=Y(i);
   AER_M(1,i)=X10;
   AER_M(2,i)=Y10;
end


%----------------------------------------------------------------------------------
%����coe�ļ�
% 
% coe_name='Input_AER_1_14.coe';
% fid=fopen(coe_name,'w'); %创建.coe文件
% fprintf(fid,'memory_initialization_radix=2;\n');
% fprintf(fid,'memory_initialization_vector=\n');
% 
% for i = 1: I_num
%     X10=X(i);
%     Y10=Y(i);
%     X2=dec2bin(X10,8);
%     Y2=dec2bin(Y10,8);
%     AER=[X2,Y2];
%   
%     %AER=str2num(AER);
%     %t_step_for_ram(i,:)=AER;
%     
%     if i<I_num
%         fprintf(fid,'%s,\n',AER);
%     else 
%         fprintf(fid,'%s;',AER);
%     end       
% end
% fclose(fid); 


%--------------------------------------------------------------------------------
%����txt�ļ�
% 
% txt_name='Input_AER_moto_0007.txt';
% fid=fopen(txt_name,'w'); %创建.coe文件
% % fprintf(fid,'memory_initialization_radix=2;\n');
% % fprintf(fid,'memory_initialization_vector=\n');
% 
% %AER_data----------
% for i = 1: I_num
%     X10=X(i);
%     Y10=Y(i);
%     X2=dec2bin(X10-1,8);
%     Y2=dec2bin(Y10-1,8);
%     
%     AER=[X2,Y2];
% 
%     if i<I_num
%         fprintf(fid,'%s\n',AER);
%     else 
%         fprintf(fid,'%s\n',AER);
%     end 
% end


% for i=1:16383-I_num
%     pad_data=dec2bin(0,16);
%     if i<16383-I_num
%         fprintf(fid,'%s\n',pad_data);
%     else 
%         fprintf(fid,'%s',pad_data);
%     end
% end
% 
% fclose(fid); 

end