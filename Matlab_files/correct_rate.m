function [ correct] = correct_rate(label,result)
%UNTITLED 此处显示有关此函数的摘要
correct=0;
for i= 1:100
    if label(i)==result(i)
        correct=correct+1;
    end
end

end

