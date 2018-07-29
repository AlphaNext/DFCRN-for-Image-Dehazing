
function [dehaze,  t,  transimission] = runcnn(img, model_name, gamma)
    caffe.reset_all()
    r0 = 50;   
    eps = 10^-3; 
    % gray_I = rgb2gray(img);
    rgb = rgb2ycbcr(img);
    gray_I = rgb(:, :, 1);
    [h,w,~] = size(img);
    %% estimate atmosphere A
    win_size = 15;    
    dark_channel = get_dark_channel(img, win_size);
    A = get_atmosphere(img, dark_channel);
    A = reshape(A,1,1,3);
    %% cnn forward using caffe build-in function
    outFile = 'net_out.prototxt';
    oid = fopen(outFile, 'w+');
    proto_name = 'dfcrn_template.prototxt';
    content = fileread(proto_name);
    content1 = strrep(content, 'height', num2str(h));
    content2 = strrep(content1, 'width', num2str(w));
    fprintf(oid, content2);
    % CPU mode
    caffe.set_mode_cpu();
    net_full = caffe.Net(outFile, model_name, 'test');
    input_data = prepare_image(img);    
    out = net_full.forward(input_data);
    te = out{1,1};
    te = imcrop(te, [20, 20 size(te, 2)-20, size(te, 1)-20]);
    te = imresize(te, [h, w], 'bicubic');
    te(te<0.05)=0.05;
    %%  fine adjustment  using different gamma value 
    t = te;  
    transimission = guidedfilter(gray_I, te, r0, eps);
    transimission = transimission.^gamma;
    transimission(transimission<0.05) = 0.05;
    transimission(transimission>1) = 1;   
    fclose(oid);
    %% recover dehazed image J
    J = bsxfun(@minus, img, A);
    J = bsxfun(@rdivide, J, transimission);
    J = bsxfun(@plus, J, A);
    dehaze = J;
end

function [dst] = prepare_image(src)
    [h,~,~] = size(src);
    temp = mat2cell(src, [h, 0]);
    dst = temp(1,1);
end

function dark_channel = get_dark_channel(img, win_size)
    [h, w, ~] = size(img);
    pad_size = floor(win_size/2);
    padded_img = padarray(img, [pad_size, pad_size], inf);
    dark_channel = zeros(h, w);
    for j = 1:h
        for i = 1:w
            patch = padded_img(j:j+(win_size-1),  i:i+(win_size-1),  :);
            dark_channel(j,i) = min(patch(:));
        end
    end
end

function atmosphere = get_atmosphere(image, dark_channel)
    [m, n, ~] = size(image);
    n_pixels = m * n;
    n_search_pixels = floor(n_pixels * 0.001);
    dark_vec = reshape(dark_channel, n_pixels, 1);
    image_vec = reshape(image, n_pixels, 3);
    [~, indices] = sort(dark_vec, 'descend');
    accumulator = zeros(1, 3);
    for k = 1 : n_search_pixels
        accumulator = accumulator + image_vec(indices(k),:);
    end
    atmosphere = accumulator / n_search_pixels;
end

