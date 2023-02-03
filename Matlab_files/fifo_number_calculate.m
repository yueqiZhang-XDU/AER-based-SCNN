function  max_number=fifo_number_calculate(write_time,read_time)
% write time 和read time都是从出脉冲读写的时间
    max_number=0;
    fifo_number=0;
    W_num=1;
    R_num=1;
    current_write_time=write_time(W_num);
    current_read_time =read_time (R_num);
    for t=1:300000  %经过了30万个周期，传播结束

        
        if current_write_time==t
            fifo_number=fifo_number+1;
            W_num=W_num+1;
            current_write_time=write_time(W_num);
        end
        
        if current_read_time==t
            fifo_number=fifo_number-1;
            R_num=R_num+1;
            current_read_time =read_time (R_num);
        end

        if fifo_number>max_number
            max_number=fifo_number;
        end


    end

end