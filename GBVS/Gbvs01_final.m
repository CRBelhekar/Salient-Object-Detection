clc
close all;
clear;
[file,path]=uigetfile({'*.jpg;*.bmp;*.png;*.tif'},'Choose an image');%to choose image file from file explorer/image database
s=[path,file];
data=imfinfo(s);
img=imread(data.Filename);
img1=imresize(img,[400 800]);
%imshow(img1);
% if(size(img1,3)==3)
%     img1=rgb2gray(img1);
% end
%%
out_gbvs = gbvs(img);
subplot(2,3,1);
imshow(img);
title('Original Image');
subplot(2,3,2);
show_imgnmap(img,out_gbvs);
title('GBVS map overlayed');
subplot(2,3,3);
imshow( out_gbvs.master_map_resized );
title('GBVS map');
im3=out_gbvs.master_map_resized;
im4 = im2bw(im3); 
figure;
subplot(2,3,1);
imshow( im4 );
title('BW GBVS map');
%% region of interest
I=out_gbvs.master_map;
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
    discard_thresh = 0.25;
    
    labelimg = bwlabel(fgm);
    s = regionprops(labelimg, I, 'MeanIntensity');
    avg_sal = [s.MeanIntensity];
   % avg_sal = rescale(avg_sal,0,1);
    
    idx = find(avg_sal > discard_thresh);
    
    if ~isempty(idx)
    fgm = ismember(labelimg,idx);
    end
    
 subplot(2,3,4);
 imshow(fgm);title('ROI')

%% 
%masking
h=out_gbvs.master_map_resized;
th=graythresh(h);
h1=im2bw(h,th);
[rows, columns] = find(h1);
topRow = min(rows);
bottomRow = max(rows);
leftColumn = min(columns);
rightColumn = max(columns);
width=rightColumn-leftColumn+1;
height=bottomRow-topRow+1;
BW=imcrop(img,[topRow leftColumn width height]);
figure();
subplot();imshow(BW);
subplot(2,3,5);imshow(BW);title('board');


%%

%OCR
f=imresize(BW,[400 NaN]);% Resizing the image keeping aspect ratio same.
figure;
subplot(2,2,1);
imshow(f);
g=rgb2gray(f); % Converting the RGB (color) image to gray (intensity).
g=medfilt2(g,[3 3]); % Median filtering to remove noise.
se=strel('disk',1); % Structural element (disk of radius 1) for morphological processing.
gi=imdilate(g,se); % Dilating the gray image with the structural element.
ge=imerode(g,se); % Eroding the gray image with structural element.
gdiff=imsubtract(gi,ge); % Morphological Gradient for edges enhancement.
gdiff=mat2gray(gdiff); % Converting the class to double.
gdiff=conv2(gdiff,[1 1;1 1]); % Convolution of the double image for brightening the edges.
gdiff=imadjust(gdiff,[0.5 0.7],[0 1],0.1); % Intensity scaling between the range 0 to 1.
B=logical(gdiff); % Conversion of the class from double to binary. 
% Eliminating the possible horizontal lines from the output image of regiongrow
% that could be edges of license plate.
er=imerode(B,strel('line',100,0));
out1=imsubtract(B,er);
% Filling all the regions of the image.
F=imfill(out1,'holes');
% Thinning the image to ensure character isolation.
H=bwmorph(F,'thin',2);
H=imerode(H,strel('line',4,90));
% Selecting all the regions that are of pixel area more than 100.
final=bwareaopen(H,100);
subplot(2,2,2);
imshow(final);
Iprops=regionprops(final,'BoundingBox','Image');
% figure;
% Selecting all the bounding boxes in matrix of order numberofboxesX4;
NR=cat(1,Iprops.BoundingBox);
% Calling of controlling function.
r=controlling(NR); % Function 'controlling' outputs the array of indices of boxes required for extraction of characters.
if ~isempty(r) % If succesfully indices of desired boxes are achieved.
    I={Iprops.Image}; % Cell array of 'Image' (one of the properties of regionprops)
    noPlate=[]; % Initializing the variable of number plate string.
    for v=1:length(r)
        N=I{1,r(v)}; % Extracting the binary image corresponding to the indices in 'r'.
        letter= readLetter(N); % Reading the letter corresponding the binary image 'N'.
        while letter=='O' || letter=='0' % Since it wouldn't be easy to distinguish
            if v<=3                      % between '0' and 'O' during the extraction of character
                letter='O';              % in binary image. Using the characteristic of plates in Karachi
            else                         % that starting three characters are alphabets, this code will
                letter='0';              % easily decide whether it is '0' or 'O'. The condition for 'if'
            end                          % just need to be changed if the code is to be implemented with some other
            break;                       % cities plates. The condition should be changed accordingly.
        end
        noPlate=[noPlate letter]; % Appending every subsequent character in noPlate variable.
    end
    fid = fopen('noPlate.txt', 'wt'); % This portion of code writes the number plate
    fprintf(fid,'%s\n',noPlate);      % to the text file, if executed a notepad file with the
    fclose(fid);                      % name noPlate.txt will be open with the number plate written.
    winopen('noPlate.txt')
    
%     Uncomment the portion of code below if Database is  to be organized. Since my
%     project requires database so I have written this code. DB is the .mat
%     file containing the array of structure of all entries of database.
%     load DB
%     for x=1:length(DB)
%         recordplate=getfield(DB,{1,x},'PlateNumber');
%         if strcmp(noPlate,recordplate)
%             disp(DB(x));
%             disp('*-*-*-*-*-*-*');
%         end
%     end
    
else % If fail to extract the indexes in 'r' this line of error will be displayed.
    fprintf('Unable to extract the characters from the number plate.\n');
    fprintf('The characters on the number plate might not be clear or touching with each other or boundries.\n');
end




