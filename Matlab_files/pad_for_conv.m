function [ image_pad ] = pad_for_conv( input_image,pad )
%UNTITLED5 此处显示有关此函数的摘要
%   此处显示详细说明
[H,W,D]=size(input_image);
 for j=1:D
            image=input_image(:,:,j);
            aUp = zeros(pad, pad + W + pad);   %
            aLeft = zeros( H, pad );           %
            aMiddle = [aLeft, image, aLeft];    %
            tempImage = [aUp; aMiddle; aUp];    %扩展之后的图像数据
            if j==1
                 image_pad=tempImage;
            else
                 image_pad=cat(3,image_pad,tempImage);
            end
 end

end

