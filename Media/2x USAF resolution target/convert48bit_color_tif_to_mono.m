% Load images and save only the red channel from the 48-bit RGB tif input
filedir = ['./data/'];
addpath('./natsortfiles');
imglist = dir([filedir,'*.tif']);  % Generate the image list
N = natsortfiles({imglist.name});
Nimg = length(imglist);
for m = 1:Nimg
      fn = [filedir,N{m}];
      disp(fn);
      I = (imread(fn))(:,:,1);  %Read red channel from 48-bit color TIFF.
      imwrite(I, strcat(filedir, "mono_", N{m}));
 end
