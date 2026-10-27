# License Plate Restoration

## Description

This project’s objective is to read the license plate numbers from images of license plates that have been corrupted by motion blurring. My program does this in two parts. 

Part 1: Perform image restoration using Wiener Filter

- Input: 
    - closely cropped picture of a license plate with motion blur
    - estimated motion blur parameters
- Estimate degradation function h(x, y)
- Use DFT of the estimated degradation function H(u, v) to create a Wiener filter
- Apply Wiener Filter

Part 2: Use template matching to read license plate number

- Use Otsu’s method thresholding to convert the restored image to a binary image
- Remove smaller text that is not the license number
    - Apply morphological erosion with a vertical filter
    - Apply morphological restoration by opening 
- Segment characters into separate images
    - Total column values to identify the gaps between the characters
- Compare characters to templates
    - Use normalized cross-correlation to generate a match score for each template
    - Take the highest score
- Output: String of the detected characters

## Constraints and Performance

- Input image must be cropped closely to the license plate
- The license plate format should be the Texas general issue design

- Optimal performance is achieved when the length of the image blur is about 10% or less of the relevant axis of the image according to the blur angle.
- Testing was done with a k value of 0.005 and using length and angle parameters of the images that were manually blurred.

## Contents
The folder’s contents are as follows: 

- Three MATLAB code files each including a separate function
    - apply_wiener_filter.m
        - Input: blurred image and blur parameters
        - Output: unblurred image achieved with a Wiener filter
    - segment_plate_text.m
        - Input: unblurred image
        - Output: binary image with any text or noise smaller than the plate numbers removed using mathematical morphology techniques
    - recognize_license_plate.m
        - Input: binary image with isolated license number
        - Output: segmented characters along with the license number string

- sample license plate images with and without motion blur applied
    - images without blur are labeled ‘sampleX’
    - images with blur are labeled ‘sampleX_blurred(YpZdegrees)’ where Y and Z represent the motion blur parameters, Y in pixels and Z in degrees

- Template images for each possible license number character (A-Z, 0-9)

## Usage

When all of these files are contained in the same folder, the program may be executed in
MATLAB by executing the following commands in the command window where L is the blur length in pixels, theta is the blur angle in degrees, and k is 1/SNR:

```matlab
restored_image = apply_wiener_filter('blurred_image.png', L, theta, k);
filtered_image = segment_plate_text(restored_image);
recognized_plate = recognize_license_plate(filtered_image);
disp(['The recognized license plate number is: ', recognized_plate]);
```