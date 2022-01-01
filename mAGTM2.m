function rgb=mAGTM2(hdr,gamma,C)
%  modified version of Reinhard's automatic global tone mapping with parameter estimation
% based on the tone mapping technology as described in Erik Reinhard, Michael Stark, 
% Peter Shirley, James Ferwerda, “Photographic Tone Reproduction for Digital Images”
% ACM, 2002
% and Reinhard's “Parameter Estimation for Photographic Tone Reproduction”
% Journal of Graphics Tools, 7:1, 45-51, DOI: 10.1080/10867651.2002.10487554
if ~exist('C','var')
    C=1.0;
end
if ~exist('gamma','var')
    gamma=1/1.6;
end
%%  参数估计及亮度压缩
Lw = 0.27*hdr(:,:,1) + 0.67*hdr(:,:,2) + 0.06*hdr(:,:,3) + 1e-6; %论文推荐的world luminance计算公式,小偏移量为避免被0除的情况
R = hdr(:,:,1) ./ Lw;
G = hdr(:,:,2) ./ Lw;
B = hdr(:,:,3) ./ Lw;

% maxL=max(L(:));
% settedMaxL=20;
% thL=10;
% mask=L>thL;
% settedMaxL=min(maxL,settedMaxL);
% L(mask)=(settedMaxL-thL)*(L(mask)-thL)/(maxL-thL)+thL;%高曝光部分压缩动态范围

LL=log(Lw+10^-9);
meanLw=exp(mean(LL(:))); 
maxLw=quantile(Lw(:),0.99);
minLw=quantile(Lw(:),0.01);
zone=log2(maxLw)-log2(minLw);
a=0.18*4^((2*log2(meanLw)-log2(minLw)-log2(maxLw))/zone);
L=Lw*a/meanLw;
Lwhite=1.5*2^(log2(maxLw)-log2(minLw)-5);
Lt=LBBGM(L,C);
Ld=(L+Lt./Lwhite)./(L+1);
Ld(Ld>1)=1;
%% 色彩还原
rgb=zeros(size(L,1),size(L,2),3);
rgb(:,:,1)=Ld.*R;
rgb(:,:,2)=Ld.*G;
rgb(:,:,3)=Ld.*B;
rgb=rgb.^gamma;
