function [iter,label] = get_iter_path1(path_list)
path_list_Face=[path_list,'\','Face'];
path_list_Motorbike=[path_list,'\','Motorbike'];
%随机输入两个文件夹中的图片，同时记录他们的特�?
path_Face=dir(path_list_Face);
path_Motorbike=dir(path_list_Motorbike);

[path_Face_i,~]=size(path_Face);
[path_Motorbike_i,~]=size(path_Motorbike);
image_number=path_Face_i+path_Motorbike_i-4;
iter=cell(1,image_number);
label=zeros(1,image_number);
p=randperm(100);

j=3;
k=3;
for i=1:100
    if i<=50
        files_tmp=[path_list_Face,'\',path_Face(j).name];
        j=j+1;
        iter{p(i)}=files_tmp;
        label(p(i))=1;
    else
        files_tmp=[path_list_Motorbike,'\',path_Motorbike(k).name]; 
        k=k+1;
        iter{p(i)}=files_tmp;
        label(p(i))=2;
    end
end
end

