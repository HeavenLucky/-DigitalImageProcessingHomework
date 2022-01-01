function rgb=ALTM(hdr,gamma)
if ~exist('gamma','var')
    gamma=1/1.6;
end
picNum=8;
ratio=1.3;
refV=1.0;
phi=8.0;
eps=0.05;
alpha=1/sqrt(8);
%%  预处理，log域均值取指数结果映射到中性灰
L = 0.27*hdr(:,:,1) + 0.67*hdr(:,:,2) + 0.06*hdr(:,:,3) + 1e-6; %论文推荐的world luminance计算公式,小偏移量为避免被0除的情况
R = hdr(:,:,1) ./ L;
G = hdr(:,:,2) ./ L;
B = hdr(:,:,3) ./ L;

% maxL=max(L(:));
% settedMaxL=20;
% thL=10;
% mask=L>thL;
% settedMaxL=min(maxL,settedMaxL);
% L(mask)=(settedMaxL-thL)*(L(mask)-thL)/(maxL-thL)+thL;%高曝光部分压缩动态范围

LL=log(L+10^-9);
meanL=exp(mean(LL(:)));
maxL=quantile(L(:),0.99);
minL=quantile(L(:),0.01);
zone=log2(maxL)-log2(minL);
a=0.18*4^((2*log2(meanL)-log2(minL)-log2(maxL))/zone);
L=L*a/meanL;
%% 核心部分：多尺度FFT滤波、不引起对比度突变的最大尺度选择及亮度变换
V1=zeros([size(L),picNum+1]); % V2的当前尺度与V1的下一尺度相同
%----------------------频域实现------------------------------%
% tic
% PQ=paddedsize(size(L));
% for i=1:picNum+1 % picNum+1个尺度，以ratio为倍数递增
%     s=ratio^(i-1);
%     d=sqrt(PQ(1)*PQ(2))/(sqrt(2)*pi*alpha*s); %为使用lpfilter直接在频域生成滤波器所做的变换，注意lpfilter中指数的分母部分是2*d^2而非d^2
%     H=lpfilter('gaussian',PQ(1),PQ(2),d);
%     figure,imshow(H./max(H(:)));
%     fL=abs(dftfilt(L,H,'original'));
%     figure,imshow(fL);
%     V1(:,:,i)=fL;
% end
% toc

%-----------------------空域实现-------------------------------%
for i=1:picNum+1 % picNum+1个尺度，以ratio为倍数递增
    s=ratio^(i-1);
    sigma=alpha*s;
    kernelRadius = ceil(2*sigma);
    kernelSize = 2*kernelRadius+1;
    gaussKernelHorizontal = fspecial('gaussian', [kernelSize 1], sigma);
    meanL= conv2(L, gaussKernelHorizontal, 'same');
    gaussKernelVertical = fspecial('gaussian', [1 kernelSize], sigma);
    V1(:,:,i)= conv2(meanL, gaussKernelVertical, 'same');
end
V=zeros([size(L),picNum]);
for i=1:picNum
    s=ratio^(i-1);
    V(:,:,i)=abs(V1(:,:,i+1)-V1(:,:,i))./(a*2^phi/s^2+V1(:,:,i));
end

Vsm=V1(:,:,picNum); %给Vsm初始化，作为8个尺度都不满足条件下的预设值
for i=1:size(L,1)
    for j=1:size(L,2)
        for k=1:picNum
            if V(i,j,k)>eps
                Vsm(i,j)=V1(i,j,k);
                break;
            end
        end
    end
end

Ld=L./(refV+Vsm);
Ld(Ld>1)=1;
%% 色彩还原
rgb=zeros(size(L,1),size(L,2),3);
rgb(:,:,1)=Ld.*R;
rgb(:,:,2)=Ld.*G;
rgb(:,:,3)=Ld.*B;
rgb=rgb.^gamma;