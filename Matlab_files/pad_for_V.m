function V_pad=pad_for_V(V,pad)
    
    [H,W,D]=size(V);
     for j=1:D
            image=V(:,:,j);
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
    V_pad=image_pad;
end