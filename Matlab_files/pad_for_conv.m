function [ image_pad ] = pad_for_conv( input_image,pad )
%UNTITLED5 �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
[H,W,D]=size(input_image);
 for j=1:D
            image=input_image(:,:,j);
            aUp = zeros(pad, pad + W + pad);   %
            aLeft = zeros( H, pad );           %
            aMiddle = [aLeft, image, aLeft];    %
            tempImage = [aUp; aMiddle; aUp];    %��չ֮���ͼ������
            if j==1
                 image_pad=tempImage;
            else
                 image_pad=cat(3,image_pad,tempImage);
            end
 end

end

