function predict_correct_rate=SVM_predict_fixed_point(SVM_model,Vmem_feature_input,label,fi_width)
    Beta_float=SVM_model.Beta;
    Bias_float=SVM_model.Bias;
    
%% fixed
 %已知，fi-width=2
    Beat_fix=fi(Beta_float,1, 6 ,4 ); %beta的最终定点精度为: 定点位数共6位，六位有符号数，一位符号位 ，一位整数，四位小数
    Bias_fix=fi(Bias_float,1,16, 5); %Bias的定点位数为12位  一位符号位 整数位6位  小数位5位。 
%% predict
    [feature_num,~]=size(Vmem_feature_input);
    predict_label=zeros(1,feature_num);
    for i=1:feature_num
        input_feature_data=Vmem_feature_input(i,:);
        input_feature_data=input_feature_data';
        input_feature_data_fixed=fi(input_feature_data,1,fi_width+6,fi_width-1);% FV为八位有符号数，符号位+六位整数+一位小数
        FX=sum(input_feature_data_fixed.*Beat_fix)+Bias_fix;   %特征向量与Beta相乘  得到
        if(FX>0)
            predict_label(i)=2;
        else
            predict_label(i)=1;
        end
    end
    predict_correct_rate=correct_rate(label,predict_label);

end