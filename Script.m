close all;clc
filename = 'data/HDR images/Arches_E_PineTree_3k.hdr';
try
    hdr = double(hdrread(filename));
catch
    disp('Can not open file!');
    return;
end
% if max(size(hdr))>2000
%     hdr=imresize(hdr,0.5);
%     hdr(hdr<0)=0;
% end
gamma=1/1.6;
figure,imshow(hdr.^gamma);
tic
rgb1=ALTM(hdr,gamma); %带参数估计的Reinhard全局色调映射算法
toc
figure,imshow(rgb1);
C=1.0; %控制最大增益的关键参数
tic
rgb2=mALTM(hdr,gamma,C); %改进版本
toc
figure,imshow(rgb2);
tic
rgb3=AGTM(hdr,gamma);%局部色调映射
toc
figure,imshow(rgb3);

tic
rgb4=mAGTM1(hdr,gamma);%局部色调映射
toc
figure,imshow(rgb4);

tic
rgb5=mAGTM2(hdr,gamma);%局部色调映射
toc
figure,imshow(rgb5);