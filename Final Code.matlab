clc
close all;
clear;

[file,path] = uigetfile({'*.jpg;*.bmp;*.png;*.tif'},'Choose an image'); %to choose image file from file explorer/image database
s = [path,file];
data = imfinfo(s);
img = imread(data.Filename);
img1 = imresize(img,[400 800]);

%imshow(img1);
%if(size(img1,3)==3)
%     img1=rgb2gray(img1);
%end
%%

out_gbvs = gbvs(img);

%subplot(3,3,1);
figure;
imshow(img);
title('Original Image');
figure;

imshow(out_gbvs.master_map_resized);
title('GBVS map');
figure;

show_imgnmap(img,out_gbvs);
title('GBVS map overlayed');

%% region of interest/ Morphological image processing
I = out_gbvs.master_map_resized;
% Opening by reconstruction

    se = strel('disk',5,0);
    Ie = imerode(I, se);
    Iobr = imreconstruct(Ie, I);
    
    if mean2(Iobr)==0 %rare case when sal. map is completely eroded
        fgm = I > 0;
        return;
    end

    % Regional maxima selects flat peaks
    fgm = imregionalmax(Iobr,18);
    
    % Discard regions with very low saliency values; Extra step not
    % included in the paper. 
    discard_thresh = 0.5;
    
    labelimg = bwlabel(fgm);
    s = regionprops(labelimg, I, 'MeanIntensity');
    avg_sal = [s.MeanIntensity];
  	% avg_sal = rescale(avg_sal,0,1);
    
    idx = find(avg_sal > discard_thresh);
    
    if ~isempty(idx)
    fgm = ismember(labelimg,idx);
    end
    
 figure;

 imshow(fgm);title('ROI')

%% 
%
%th=graythresh(I);
%h1=im2bw(I,th);

X1 = im2bw(I);
se = strel('disk',5);

%opening and closing to remove small values
X2 = imopen(X1,se);
X3 = imclose(X2,se);

%% new saliency map
[r1 c1] = size(X3);
I1 = zeros(r1,c1);
I2 = zeros(r1,c1,3);
for i = 1:r1
    for j = 1:c1
        if I(i,j) >= 0.65
            I1(i,j) = 1;
        end
        j = j+1;
    end
    i = i+1;
end

figure;
imshow(I1);title('new saliency map');
%detremining the boundries of objects
[B,L] = bwboundaries(I1,'noholes');

% Display the label matrix and draw each boundary
figure;
imshow(label2rgb(L, @jet, [.5 .5 .5]));title('with boundries');
hold on

for k = 1:length(B)
  boundary = B{k};
  plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2)
end

%% considering area having objects only
img2 = im2double(img); 
[rows, columns] = find(I1);
topRow = min(rows);
bottomRow = max(rows);
leftColumn = min(columns);
rightColumn = max(columns);
width = rightColumn-leftColumn+1;
height = bottomRow-topRow+1;
for k = 1 :3
    for i = topRow:bottomRow+1
        for j = leftColumn:rightColumn+1
                 I2(i,j,k) = img2(i,j,k);
                 j = j+1;
        end
    i = i+1;
    end
k = k+1;
end
figure;

imshow(I2);title('Objects Considered');

%% cropping the board area
h6 = [-100 -100 200 200];
CC = bwconncomp(I1);
LL = labelmatrix(CC);
SS = regionprops(LL);
allArea = [SS.Area];
maxArea = max(allArea);
mem1 = find(allArea==maxArea);
h5 = SS(mem1,1).BoundingBox;
h7 = h5+h6;
I3 = imcrop(img,h7);
figure;
imshow(I3);title('Cropped Board');

%% location detection
% loca=struct;
% loca=data.GPSInfo;
% lat=loca.GPSLatitude;
% lon=loca.GPSLongitude;
% x=dms2degrees(lon);
% y=dms2degrees(lat);
% figure();
% plot(x,y,'.b','MarkerSize',20);
% plot_google_map('APIKey','AIzaSyCoWw98OWhxLya9Q7bUjaBAV22NN8p4HCk','Scale',2,'MapType','hybrid','Showlabels',1);
%%
%filtering/masking
% th=graythresh(ans);
% ObjectMask=~im2bw(ans,th);
% cc = bwconncomp(ObjectMask);
% stats = regionprops(cc ,h1,'Area','BoundingBox');
% A = [stats.Area];
% [~,biggest] = max(A);
% ObjectMask(labelmatrix(cc)~=biggest) = 0;
% ObjectMask = imfill(ObjectMask,'holes');
% subplot(2,3,4);
% imshow(ObjectMask);title('mask');
%%

%%
 ocrResults = ocr(I3);
     recognizedText = ocrResults.Text;
     figure;
     imshow(I3);
     
     text(600, 150, recognizedText, 'BackgroundColor', [1 1 1]);