function  predict_correct_rate=SVM_predict(SVM_model,Vmem_feature_input,label)
%% SVM parameter
    Beta_float=SVM_model.Beta;
    Bias_float=SVM_model.Bias;
	%对这些数据进行定点化处理
    Beta_parameter=10000;
    Bias_parameter=Beta_parameter*1000;
%     Beta=fi(Beta_float,1,6,5);
%     Bias=fi(Bias_float,1,6,5);
    Beta=floor(Beta_float*Beta_parameter);
    Bias=floor(Bias_float*Bias_parameter);
%% predict
    [feature_num,~]=size(Vmem_feature_input);
    predict_label=zeros(1,feature_num);
    for i=1:feature_num
        input_feature_data=Vmem_feature_input(i,:)*1000;%15位表示足够
        input_feature_data=input_feature_data';
        FX=sum(input_feature_data.*Beta)+Bias;
        if(FX>0)
            predict_label(i)=2;
        else
            predict_label(i)=1;
        end
    end
    predict_correct_rate=correct_rate(label,predict_label);

end