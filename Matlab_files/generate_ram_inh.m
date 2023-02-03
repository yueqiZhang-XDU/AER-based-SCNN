function generate_ram_inh(layers,network_struct)
pad=network_struct{2}.pad;
K_inh=layers{2}.K_inh;
[ K_inh_pad]=pad_for_Kinh(K_inh,pad);
[H,W]=size(K_inh_pad);
%% conv layer1 

M=1;
inh_pad=dec2bin(0,3);
for i=1:H
    for j=1:W
        if M==1
            fid=fopen('low_32768_64_high32_initial.txt','w'); %鍒涘缓.coe鏂囦欢
            
            inh_flag=dec2bin(K_inh_pad(i,j),1);
            ram_zero=dec2bin(0,28);
            ram_initial=[inh_pad,inh_flag,ram_zero];
            fprintf(fid,'%s\n',ram_initial);
            M=M+1;
        elseif M<=32768 
            inh_flag=dec2bin(K_inh_pad(i,j),1);
            ram_zero=dec2bin(0,28);
            ram_initial=[inh_pad,inh_flag,ram_zero];
            fprintf(fid,'%s\n',ram_initial);
            M=M+1;
        elseif M==32769 
            fclose(fid); %关闭.coe文件
            fid=fopen('high_32768_64_high32_initial.txt','w'); %鍒涘缓.coe鏂囦欢
%             fprintf(fid,'memory_initialization_radix=2;\n');
%             fprintf(fid,'memory_initialization_vector=\n');  
            inh_flag=dec2bin(K_inh_pad(i,j),1);
            ram_zero=dec2bin(0,28);
            ram_initial=[inh_pad,inh_flag,ram_zero];
            fprintf(fid,'%s\n',ram_initial);
            M=M+1;
        else
            inh_flag=dec2bin(K_inh_pad(i,j),1);
            ram_zero=dec2bin(0,28);
            ram_initial=[inh_pad,inh_flag,ram_zero];
            fprintf(fid,'%s\n',ram_initial);
            M=M+1;
        end
    end
end

zero32=dec2bin(0,32);
for i=1:65536-H*W
    fprintf(fid,'%s\n',zero32); 
end
fclose(fid); %关闭.coe文件



fid=fopen('high_32768_64_low32_initial.txt','w');
for i=1:32768
    fprintf(fid,'%s\n',zero32); 
end
fclose(fid); %关闭.coe文件

fid=fopen('low_32768_64_low32_initial.txt','w');
for i=1:32768
    fprintf(fid,'%s\n',zero32); 
end
fclose(fid); %关闭.coe文件
%% conv2

pad=network_struct{4}.pad;
K_inh=layers{4}.K_inh;
[ K_inh_pad]=pad_for_Kinh(K_inh,pad);
[H,W]=size(K_inh_pad);
fid=fopen('ram_inh_conv2_2048_high128_initial.txt','w'); %鍒涘缓.coe鏂囦欢
% fprintf(fid,'memory_initialization_radix=2;\n');
% fprintf(fid,'memory_initialization_vector=\n');
ram_top_zero=dec2bin(0,105);
for i=1:H
    for j=1:W
        inh_flag=dec2bin(K_inh_pad(i,j),1);
        ram_zero=dec2bin(0,22);
        ram_initial=[ram_top_zero,inh_flag,ram_zero];
        fprintf(fid,'%s\n',ram_initial);
    end
end
 ram_zero=dec2bin(0,128);
for i=2048-H*W
     fprintf(fid,'%s\n',ram_zero);
end
fclose(fid); %鍏抽棴.coe鏂囦欢


fid=fopen('ram_inh_conv2_2048_low128_initial.txt','w'); %鍒涘缓.coe鏂囦欢
ram_zero=dec2bin(0,128);
for i=1:2048
     fprintf(fid,'%s\n',ram_zero);
end
fclose(fid); %鍏抽棴.coe鏂囦欢



end