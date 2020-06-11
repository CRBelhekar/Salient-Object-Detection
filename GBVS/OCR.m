%board  = imread('09.jpg');
[file,path]=uigetfile({'*.jpg;*.bmp;*.png;*.tif'},'Choose an image');
s=[path,file];
board=imread(s);
     ocrResults     = ocr(board);
     recognizedText = ocrResults.Text;
     figure;
     imshow(board);
     text(600, 150, recognizedText, 'BackgroundColor', [1 1 1]);