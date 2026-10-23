function restored_img = apply_wiener_filter(degraded_image_path, len, theta, K_ratio)
% apply wiener filter Restores a degraded image using the Wiener Filter.
%
%   restored_img = apply_wiener_filter(degraded_image_path, len, theta, K_ratio)
%
%   Inputs:
%       degraded_image_path (string): File path to the corrupted image g(x,y).
%       len (scalar): The estimated length (L) of the motion blur in pixels.
%       theta (scalar): The estimated angle (theta) of the motion blur in degrees.
%       K_ratio (scalar): The Noise-to-Signal Power Ratio (K). A good starting 
%                         value is often around 0.001 to 0.01 for slight noise.
%                         If noise variance is known (e.g., 0.001), use a ratio 
%                         based on that.
%
%   Output:
%       restored_img: The resulting restored image f_hat(x,y).
%
%   Example:
%       restored = apply_wiener_filter('degraded_plate.png', L_est, Theta_est, 0.005);

    % --- 1. Read and Prepare Image ---
    try
        g = imread(degraded_image_path);
    catch
        error('Could not read image file. Please check the path and file name.');
    end
    
    disp('Step 1: Constructing and applying Wiener filter.');
    % Convert to double precision [0, 1] for all frequency domain math
    g_double = im2double(g);
    
    % Determine padding size
    [M, N, channels] = size(g_double);
    P = 2 * M; 
    Q = 2 * N; 
    
    % --- 2. Generate the Transfer Function H(u,v) ---
    
    % Create the spatial PSF (h) based on input parameters (h is size L x L)
    PSF_spatial = fspecial('motion', len, theta);
    
    % Pad the PSF to the DFT size (P x Q)
    PSF_padded = padarray(PSF_spatial, [P - size(PSF_spatial, 1), Q - size(PSF_spatial, 2)], 'post');
    
    % Shift the PSF origin to the top-left corner (0,0) before taking FFT
    PSF_shifted = circshift(PSF_padded, -floor(size(PSF_spatial)/2));
    
    % Compute the Transfer Function H(u,v)
    H = fft2(PSF_shifted);

    % --- 3. Compute DFT of the Degraded Image G(u,v) ---
    
    % Zero-pad the degraded image g(x,y) to size PxQ
    g_padded = padarray(g_double, [M, N], 'post'); 
    
    % Compute the 2D DFT of the padded image
    G = fft2(g_padded);

    % --- 4. Apply the Wiener Filter ---
    
    % The Wiener filter formula is applied element-wise in the frequency domain.
    % H_conj = H*(u,v)
    H_conj = conj(H); 
    
    % H_mag_sq = |H(u,v)|^2 = H*(u,v) * H(u,v)
    H_mag_sq = abs(H).^2;
    
    % Calculate the Wiener Filter Transfer Function H_w(u,v)
    % K_ratio is the K constant (Noise-to-Signal Power Ratio)
    H_w = H_conj ./ (H_mag_sq + K_ratio);
    
    % Element-wise multiplication to get the Restored Spectrum F_hat(u,v)
    F_hat = G .* repmat(H_w, [1, 1, channels]);

    % --- 5. Obtain the Restored Image in Spatial Domain ---
    
    % Compute the Inverse DFT
    f_hat_padded = ifft2(F_hat);
    
    % Take the real part (due to numerical precision errors)
    f_hat_real = real(f_hat_padded);
    
    % Crop the image back to the original size (M x N)
    restored_img = f_hat_real(1:M, 1:N, :);
    
    % Clip values to [0, 1] range to avoid floating point overshoots 
    % (this is a critical post-processing step for restoration filters)
    restored_img = max(0, min(1, restored_img));

    % --- 6. Display Results ---
    figure;
    
    % Display Degraded Image
    subplot(1, 2, 1);
    imshow(g_double);
    title('Degraded Image g(x,y)');
    
    % Display Restored Image
    subplot(1, 2, 2);
    imshow(restored_img);
    title(['Wiener Restored (L=', num2str(len), ', \theta=', num2str(theta), ', K=', num2str(K_ratio), ')']);
    
    % Save the restored image to a file
    %imwrite(restored_img, 'restored100.png');
end