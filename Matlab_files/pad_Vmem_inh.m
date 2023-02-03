function Vmem_pad=pad_Vmem_inh(Vmem,K_inh)

    [H,W,D]=size(Vmem);
    Vmem_pad=zeros(H,W,D);

for i=1:H
    for j=1:W
            inh_flag=K_inh(i,j);
        for k=1:D
               if inh_flag==1
                    Vmem_pad(i,j,k)=0;
               else
                    Vmem_pad(i,j,k)=Vmem(i,j,k);
               end
        end
    end
end

end