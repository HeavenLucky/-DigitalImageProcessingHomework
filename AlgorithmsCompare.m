clear all;clc;
% name = {'New'};
name={'HDR images'};
dataset = strcat('data', filesep, name, filesep, '*.*');
xlsName='result.xls';
outImgFolder='outputImg2';
mkdir(outImgFolder);
for i=1:length(name)
    mkdir([outImgFolder,filesep,name{i}]);
end
% specify methods and metrics
method = {@ALTM @mALTM};
metric = {}; 
% metric = {@loe100x100 @vif}; % NOTE matlabPyrTools is required to run VIF metric (vif.m).

for n = 1:numel(dataset) %for each dataset
    datasetName=dataset{n};
    filenames=dir(datasetName);
    imgFileNum=0;
    for i=1:length(filenames)  %count number of image files
        if filenames(i).isdir
            continue;
        end
        imgFileNum=imgFileNum+1;
    end
    result=zeros(imgFileNum,length(method),length(metric));
    fileIdx=0;
    for i=1:length(filenames)  %for each file in a dataset
        if filenames(i).isdir
            continue;
        end
        fileIdx=fileIdx+1;
        fullFileName=fullfile(filenames(i).folder,filesep,filenames(i).name);
        try
            img = double(hdrread(fullFileName));
        catch
            delete(fullFileName);
        end
        if max(size(img))>2000
            img=imresize(img,0.5);
            img(img<0)=0;
        end
        orgImg=img.^(1/1.6);
        
        methodIdx=0;
       for m=1:length(method) %for each kind of algorithm
           methodIdx=methodIdx+1;
           func=method{m};
           outImg=func(img);
           
           %保存图像
           saveFileName=strcat(filenames(i).name(1:end-4),'_',func2str(method{m}),'.png');
           saveFilePath=strcat(outImgFolder,filesep,name{n},filesep,saveFileName);
           imwrite(outImg,saveFilePath);
           metricIdx=0;
           for k=1:length(metric) %for each evaluation method
               metricIdx=metricIdx+1;
               evalMethod=metric{k};
               if strcmp(func2str(evalMethod),func2str(@vif))==1
                   temp=orgImg;
                   orgImg=outImg;        
                   outImg=temp;
               end
               evalIdx=evalMethod(orgImg,outImg);
               result(fileIdx,methodIdx,metricIdx)=evalIdx;
           end
       end
       saveFileName=strcat(filenames(i).name(1:end-4),'.png');
       saveFilePath=strcat(outImgFolder,filesep,name{n},filesep,saveFileName);
       imwrite(orgImg,saveFilePath);
    end
    
    %生成表格
    for k=1:length(metric)
        sheetName=[name{n} ,'_', func2str(metric{k})];
        %生成表头
        for m=1:length(method)
            colCh=char('A'+m);
            range=sprintf('%s1:%s1',colCh,colCh);
            xlswrite(xlsName,{func2str(method{m})},sheetName,range);
        end
        
        %生成序号
        for i=1:fileIdx
            range=sprintf('A%d:A%d',i+1,i+1);
            xlswrite(xlsName,i,sheetName,range);
        end
        
                %写入评价结果
        range=sprintf('B2:%s%d',char('A'+length(method)),fileIdx+1);
        xlswrite(xlsName,result(:,:,k),sheetName,range);
    end
end
