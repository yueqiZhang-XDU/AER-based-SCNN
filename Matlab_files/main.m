% A simulation of AER-based-SCNN
clc 
clear
%% datasets path
path_list='.\datasets';
datasets_learn=[path_list,'\LearningSet'];
datasets_train=[path_list,'\TrainingSet'];
datasets_test=[path_list,'\TestingSet'];
%% SDNN flag
%定义FLAG
global learn_SDNN
global set_weights
global save_weights
global save_feature
global total_time
%标志位定义
learn_SDNN=0;   % learn_SDNN=0 test mode; learn_SDNN=1 train mode   
if  learn_SDNN==0                  
    set_weights=0;
    save_weights=1;
    save_feature=1;
else
    set_weights=1;
    save_weights=0;
    save_feature=0;
end
%% network_params
img_size=struct('img_sizeH',160,'img_sizeW',250);
DoG_params=struct('img_size', img_size, 'DoG_size', 7, 'std1', 1, 'std2', 2);
% network structure define
l1=struct('type','input', 'num_filters', 1, 'pad',0, 'H_layer',DoG_params.img_size.img_sizeH,'W_layer', DoG_params.img_size.img_sizeW);
l2=struct('type', 'conv', 'num_filters', 4, 'filter_size', 5, 'th', 6);
l3=struct('type', 'pool', 'num_filters', 4, 'filter_size', 16, 'th', 0., 'stride', 16);
l4=struct('type', 'conv', 'num_filters',10, 'filter_size', 15, 'th', 18);
% network training parameters
learnable_layers=[2,4];
network_params={l1,l2,l3,l4};
weight_params=struct('mean',0.8,'std',0.01);
max_learn_iter=[0,1000,0,1500];
STDP_per_layer=[0,4,0,1];
max_iter=sum(max_learn_iter);
a_minus=[0,0.003,0,0.003];
a_plus=[0,0.007,0,0.007];
offset=[0 5 0 0];
tao_minus=40;
tao_plus=20;
STDP_time=35;

deta_STDP_minus=deta_STDP(0.03,STDP_time,tao_minus);
deta_STDP_plus=deta_STDP(0.07,STDP_time,tao_plus);   

STDP_params=struct('max_learning_iter',max_learn_iter,'STDP_per_layer',STDP_per_layer,...
                   'max_iter',max_iter,'a_minus',a_minus,'a_plus',a_plus,'offset',offset);
total_time=30;

%% network_struct init
network_struct=init_net_struct(network_params);
layers = init_layers(network_struct);

%% weights
weights = init_weights(weight_params,network_struct);

%% 获得输入图像路径
     [datasets_path_learn,label_learn]=get_iter_path1(datasets_learn);
     [datasets_path_test,label_test]=get_iter_path1(datasets_test);
     [~,num_img_learn]=size(datasets_path_learn);
     [~,num_img_test]=size(datasets_path_test);

%% network train
if learn_SDNN==1
    weights_unfixed=SCNN_AER_train(weights,network_struct,datasets_path_learn,DoG_params,STDP_params,learnable_layers,deta_STDP_minus,deta_STDP_plus,total_time);
else
    weights_unfixed=load('unfixed_weight.mat');
    weights_unfixed=weights_unfixed.weights_unfixed;
end
%% weights fixed
    fi_width=4;
    weights=fi_weights(weights_unfixed,fi_width);
%% network test
[Vmem_feature_learn] = get_feature_AER(weights,layers,network_struct,datasets_path_learn,num_img_learn,DoG_params,total_time,fi_width); 
[Vmem_feature_test] = get_feature_AER(weights,layers,network_struct,datasets_path_test,num_img_test,DoG_params,total_time,fi_width);
%% classification
SVM_train=fitcsvm(Vmem_feature_learn,label_learn);                         
result_learn=predict(SVM_train,Vmem_feature_learn);                           
SVM_learning_correct_rate=correct_rate(label_learn,result_learn);
result_test=predict(SVM_train,Vmem_feature_test);
SVM_testing_correct_rate=correct_rate(label_test,result_test);

svm_predict_result_correct_rate=SVM_predict(SVM_train,Vmem_feature_learn,label_learn);
svm_fixed_predict_result_correct_rate=SVM_predict_fixed_point(SVM_train,Vmem_feature_learn,label_learn,fi_width);
