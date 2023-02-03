function K_inh_pad=pad_for_K_inh(K_inh,pad)
global total_time
    [H,W]=size(K_inh);
     
        image=K_inh;
        aUp = ones(pad, pad + W + pad)*total_time;   %
        aLeft = ones( H, pad )*total_time;           %
        aMiddle = [aLeft, image, aLeft];    %
        tempImage = [aUp; aMiddle; aUp];    %扩展之后的图像数据
        K_inh_pad=tempImage;
        

end