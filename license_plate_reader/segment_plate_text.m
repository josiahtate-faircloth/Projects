function isolated_plate = segment_plate_text(image_path)
%SEGMENT_PLATE_TEXT Preprocesses a Texas license plate image to isolate 
% the main license number from smaller text using morphological filtering.
%
%   isolated_plate = segment_plate_text(image_path)
%
%   Inputs:
%       image_path (string): File path to the cropped, unblurred license plate image.
%
%   Output:
%       isolated_plate: The resulting binary image (logical format) containing
%                       only the license number.
%
%   Example Usage:
%   %    isolated_text = segment_plate_text('unblurred_plate.png');
%   %    figure; imshow(isolated_text);


    % --- 1. Read and Prepare Image ---
    try
        %I = imread(image_path);
        I = image_path;
    catch
        error('Could not read image file. Please check the path and file name.');
    end
    
    % Convert to Grayscale
    if size(I, 3) == 3
        I_gray = rgb2gray(I);
    else
        I_gray = I;
    end
    
    % --- 2. Basic Thresholding  ---
    % Plates are white background (high intensity) with black text (low intensity).
    % We want the letters to be 1 (foreground) and the background 0.
    
    % Find optimal threshold using Otsu's method
    level = graythresh(I_gray);
    
    % Create binary image: Black text becomes 1 (white), White background becomes 0 (black).
    % Invert the output to make the text white for morphological operations
    I_binary = ~imbinarize(I_gray, level);
    
    disp('Step 2: Image binarized.');
    
    % --- 3. Filter Smaller Text using Mathematical Morphology ---
    % The smaller text is shorter than the main license number characters.
    % use vertical erosion and reconstruction to isolate the large characters.
    
    % Define vertical line structural element.
    % This will only link up vertical components that are sufficiently tall.
    SE_height = size(I,1) * (3/16);     % Determine SE height as fraction of image height
    SE_vertical = strel('line', SE_height, 90); % SE_height pixels high, 90 degrees
    
    % Morphological Erosion: Eradicates small objects 
    % while having less effect on tall objects (license number).
    I_eroded = imerode(I_binary, SE_vertical);
    
    % Morphological Reconstruction (by opening): reconstructs connected 
    % components in I_binary that are 'marked' by I_eroded
    I_reconstructed = imreconstruct(I_eroded, I_binary);
    
    % remove anything connected to the border
    isolated_plate = imclearborder(I_reconstructed);
    
    disp('Step 3: Small text removed using vertical morphology and reconstruction.');

    % --- Display Results ---
    figure;
    subplot(1, 2, 1);
    imshow(I_binary);
    title('1. Thresholded Image');
    
    subplot(1, 2, 2);
    imshow(isolated_plate);
    title('2. Isolated License Number');
    
end