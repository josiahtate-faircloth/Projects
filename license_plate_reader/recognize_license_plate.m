function license_string = recognize_license_plate(isolated_image)
%RECOGNIZE_LICENSE_PLATE Segments characters and uses Normalized Cross Correlation (NCC) for recognition.
%
%   license_string = recognize_license_plate(isolated_image)
%
%   Inputs:
%       isolated_image (logical array): The binary image containing ONLY 
%                                       the license number, output from 
%                                       segment_plate_text.m.
%
%   Output:
%       license_string (string): The recognized license plate characters.
%
%   Example Usage (assuming the previous function was run):
%   % 1. isolated_text = segment_plate_text('unblurred_plate.png');
%   % 2. plate_number = recognize_license_plate(isolated_text);
%   % 3. disp(['Recognized Plate: ', plate_number]);

    % Define the character set to match (uppercase letters and numbers 0-9)
    char_set = ['0':'9', 'A':'Z'];
    
    % Initialize the output string
    license_string = '';

    % --- 1. Segmentation using Column Sums ---
    
    % Calculate the column sums. Since the text is 1 and background is 0,
    % columns corresponding to letters will have high sums (peaks), and columns
    % corresponding to spaces will have sums close to 0 (valleys).
    column_sums = sum(isolated_image, 1);
    
    % Determine a threshold for distinguishing between a character column 
    % and a space column useing a fraction of the maximum sum.
    peak_threshold = max(column_sums) * 0.05; % 5% of max sum
    
    % Find all columns that are 'valleys' (less than the threshold)
    valley_indices = find(column_sums < peak_threshold);
    
    % Find the start and end of continuous sequences of valleys
    diff_valleys = diff(valley_indices);
    
    % The start of a new valley region is where the difference is > 1
    valley_starts = [1, find(diff_valleys > 1) + 1];
    valley_ends = [find(diff_valleys > 1), length(valley_indices)];
    
    % Calculate the center index for each valley region
    center_valley_indices = zeros(1, length(valley_starts));
    for i = 1:length(valley_starts)
        start_idx = valley_indices(valley_starts(i));
        end_idx = valley_indices(valley_ends(i));
        % The center is the average of the first and last column index in the valley
        center_valley_indices(i) = round((start_idx + end_idx) / 2);
    end
    
    % Add image boundaries to segmentation points
    start_col = 1;
    end_col = size(isolated_image, 2);
    
    % Combine start/end boundaries with the calculated valley centers
    all_segment_points = [start_col, center_valley_indices, end_col];
    all_segment_points = unique(all_segment_points);
    
    % Remove adjacent points that are too close
    min_gap = 5; % Minimum pixel width for a valid segment gap
    segment_points = all_segment_points([true, diff(all_segment_points) > min_gap]);
    
    % --- 2. Iterate through Segments and Match Templates ---
    
    % iterate through the gaps between our segment points
    num_segments = length(segment_points) - 1;
    
    disp(['Step 4: Found ', num2str(num_segments), ' potential character segments.']);
    
    figure('Name', 'Character Segmentation and Matching');
    
    char_count = 0;
    
    for k = 1:num_segments
        start_idx = segment_points(k);
        end_idx = segment_points(k+1);
        
        % Ensure the segment has a minimum width (to ignore noise)
        if (end_idx - start_idx) < 10
            continue;
        end
        
        % Extract the current character segment
        current_char_img = isolated_image(:, start_idx:end_idx);
        
        % Remove rows that are entirely zero (top/bottom padding)
        row_sums = sum(current_char_img, 2);
        non_zero_rows = find(row_sums > 0);

        if isempty(non_zero_rows)
            continue; % Skip empty segments
        end
        
        % Remove columns that are entirely zero (left/right padding)
        col_sums = sum(current_char_img, 1);
        non_zero_cols = find(col_sums > 0);
        
        current_char_img = current_char_img(min(non_zero_rows):max(non_zero_rows), min(non_zero_cols):max(non_zero_cols));
        
        % Ensure a minimum size before matching
        if size(current_char_img, 1) < 15 || size(current_char_img, 2) < 5
            continue;
        end
        

        char_count = char_count + 1;

        % display
        subplot(1, num_segments, char_count);
        imshow(current_char_img);
        
        % --- Template Matching using NCC ---
        
        max_ncc = -Inf; % Initialize max correlation score & best match
        best_match = '?';
        
        for char_code = char_set
            try
                % Load the template image
                template_path = ['template_', char_code, '.png'];
                template = imread(template_path);
                
                % Templates must be converted to binary and resized to match the 
                % current character's height for fair NCC comparison.
                template_binary = template;
                template_resized = imresize(template_binary, [size(current_char_img, 1), NaN]);
                
                
                % NCC is simpler if both images are the exact same size.
                % resize the character image to the template width for simple comparison.
                template_height = size(current_char_img, 1);
                template_width = size(template_resized, 2);

                % Make the character image exactly the same size as the resized template
                current_char_resized = imresize(current_char_img, [template_height, template_width]);

                % Calculate the simple correlation
                
                A = double(current_char_resized);
                B = double(template_resized);

                % Ensure they are inverted so black characters are high value (1)
                %A = ~A; 
                B = ~B;

                % Simple element-wise correlation sum
                correlation = sum(A(:) .* B(:));
                
                % Normalized Correlation (simplest form for aligned images):
                ncc_score = correlation / sqrt(sum(A(:).^2) * sum(B(:).^2));
                
                if ncc_score > max_ncc
                    max_ncc = ncc_score;
                    best_match = char_code;
                end
                
            catch
                % Template file not found, skip this character
            end
        end
        
        % If the best match score is below a confidence threshold, label it as unknown
        confidence_threshold = 0.6;
        
        if max_ncc < confidence_threshold
            best_match = '?';
            title('Unknown (?)');
        else
            title(['Match: ', best_match, ' (', num2str(max_ncc, '%.2f'), ')']);
        end

        license_string = [license_string, best_match]; % Append to the result

        if k == 4
            license_string = [license_string, '-'];
        end

    end
    
    disp('Step 5: Template matching complete.');
    
end