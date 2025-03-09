% Load images and save only the red channel from the 48-bit RGB tif input
addpath('./natsortfiles');
filedir = ['./data/'];
imglist = dir([filedir,'*.tif']);  % Generate the image list
N = natsortfiles({imglist.name});
Nimg = length(imglist);
for m = 1:Nimg
      fn = [filedir,N{m}];
      disp(fn);
      inputI = (imread(fn))(:,:,1);  %Read red channel from 48-bit color TIFF.
      outputI = transpose(downsample(transpose(downsample(inputI(:,:,1),2,0)),2,1));
      imwrite(interp2(outputI,1,'pchip'), strcat(filedir, "red_", N{m}));
 end
