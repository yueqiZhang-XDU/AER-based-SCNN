function [ image_pad ] = pad_for_K_STDP( input_image,pad )
%UNTITLED5 此处显示有关此函数的摘要
%   此处显示详细说明
global total_time
[H,W,D]=size(input_image);
 for j=1:D
            image=input_image(:,:,j);
            aUp = ones(pad, pad + W + pad)*total_time;   %
            aLeft = ones( H, pad )*total_time;           %
            aMiddle = [aLeft, image, aLeft];    %
            tempImage = [aUp; aMiddle; aUp];    %扩展之后的图像数据
            if j==1
                 image_pad=tempImage;
            else
                 image_pad=cat(3,image_pad,tempImage);
            end
 end

end