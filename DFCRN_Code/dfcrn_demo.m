% MATLAB R2015b, Windows 7, caffe, 8G
% Firstly, make sure your caffe matlab interface is available, 
% such as caffe.reset_all() function and so on.
close all;  clear; clc;
%% input image path setting
img_path = './data/';
img_name = '00442.png';
[~, name, ext] = fileparts( img_name ) ;
%% rgb image
img = imread([img_path img_name]);
img = im2double(img);
[h,w,~] = size(img);
% ensure the input image size to a multiple of 4
height = ceil(h/4) * 4;
width = ceil(w/4) * 4;
img = imresize(img, [height, width], 'bicubic'); 
img(img<0) = 0;
img(img>1) = 1;
model_name = 'dfcrn_iter_75000.caffemodel';
% gamma 0.7 to 1.8, 
% for heavy haze level, use larger gamma
% for light haze level, use 1 or lower value 
% default gamma value is 1.0
gamma = 1.2;
% t_src is the original estimated transimission
% t_fine is the transimission using guided filter based on t_src
[dehaze, t_src, t_fine] = runcnn(img, model_name, gamma);
figure('Name', 'dehazed result'), imshow([img dehaze]), axis image;
figure('Name', 'transimission'),  imagesc([t_src t_fine]), colormap jet, axis image;

% save dehazed result

% if exist('results', 'file')
%     mkdir results;
% end
if strcmp(ext, '.jpg') || strcmp(ext, '.JPG') || strcmp(ext, '.jpeg')
    imwrite(dehaze, strcat('./results/', 'dfcrn_', num2str(gamma),  ...
                             '_', img_name), 'jpg', 'Quality', 100);
    imwrite(t_fine,  strcat('./results/', 'dfcrn_trans_', num2str(gamma),  ...
                             '_', img_name), 'jpg', 'Quality', 100);
    % save transimission using pseudocolor way
    rgb = ind2rgb( gray2ind(t_fine,255),jet(255) );
    figure('Name', 'pseudocolor transimission'), imshow(rgb), colorbar, colormap jet, axis on, axis image;
    saveas( gcf, strcat('./results/dfcrn_pseudo_t_bar_', num2str(gamma), '_', img_name) );
    imwrite(rgb, strcat('./results/dfcrn_pseudo_t_', num2str(gamma),  '_',img_name), 'jpg', 'Quality', 100);
else
    imwrite(dehaze, strcat('./results/', 'dfcrn_', num2str(gamma),'_', img_name));
    imwrite(t_fine,  strcat('./results/', 'dfcrn_trans_', num2str(gamma), '_', img_name));
    % save transimission using pseudocolor way
    rgb = ind2rgb( gray2ind(t_fine,255),jet(255) );
    figure('Name', 'pseudocolor transimission'), imshow(rgb), colorbar, colormap jet, axis on, axis image;
    saveas( gcf, strcat('./results/dfcrn_pseudo_t_bar_', num2str(gamma), '_', name, '.jpg') );
    imwrite(rgb, strcat('./results/dfcrn_pseudo_t_', num2str(gamma), '_',name, '.jpg'), 'jpg', 'Quality', 100);    
end



