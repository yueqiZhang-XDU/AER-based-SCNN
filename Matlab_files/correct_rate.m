function [ correct] = correct_rate(label,result)
%UNTITLED �˴���ʾ�йش˺�����ժҪ
correct=0;
for i= 1:100
    if label(i)==result(i)
        correct=correct+1;
    end
end

end

