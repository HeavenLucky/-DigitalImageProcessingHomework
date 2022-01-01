function wM = varBasedWeight(img,phi)
if ~exist('phi','var')
    phi=0.75;
end
img=img-min(img(:));
L=max(img(:))-min(img(:));
r=15;
paddedImg=padarray(img,[r r],'replicate','both');
sq_paddedImg=paddedImg.^2;
intMap=intergalMap(paddedImg);
sq_intMap=intergalMap(sq_paddedImg);
sumImg=zeros(size(img));
meanImg=zeros(size(img));
sq_sumImg=zeros(size(img));
varImg=zeros(size(img));
wM=zeros(size(img)); %edge-aware weight image
num=(2*r+1)^2;
for i=1:size(img,1)
    for j=1:size(img,2)
        sumImg(i,j)=intMap(i+2*r+1,j+2*r+1)+intMap(i,j)-intMap(i,j+2*r+1)-intMap(i+2*r+1,j);
        meanImg(i,j)=sumImg(i,j)/num;
        sq_sumImg(i,j)=sq_intMap(i+2*r+1,j+2*r+1)+sq_intMap(i,j)-sq_intMap(i,j+2*r+1)-sq_intMap(i+2*r+1,j);
        varImg(i,j)= sq_sumImg(i,j)-(sumImg(i,j)^2)/num;
    end
end
v1=(0.001*L)^2;
v2=10^-9;
wM=((varImg+v1)./(meanImg.^2+v2)).^phi;
temp=1./wM;
wM=wM*mean(temp(:));
