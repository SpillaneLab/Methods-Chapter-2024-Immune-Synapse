# Percentage-antigen-internalization
Complete set of Fiji macros used to determine percent antigen internalization.
# General overview
Users are directed to our Methods Chapter (reference to come) on the experimental setup to investigate antigen internalization. A common way to analyse the efficiency of B cell antigen internalization is to quantify the percentage of available antigen that B cells internalize from the immune synapse (1,2). This can be determined by measuring the antigen fluorescence intensity in the cell (above the synapse plane) and dividing it by the total antigen fluorescence intensity in the cell and in the synapse (Figure 1). <br/> <br/>

 <br/> <br/>
Figure 1. (A) Maximum intensity projections of a naive B cell isolated from a B1-8i mouse that was plated onto a planar lipid bilayer coated with NIP-coupled DNA sensors, fixed after 45 minutes, and stained for the surface marker B220. (B) Schematic showing the distribution of internalized antigen located inside the cell, and total antigen in the cell and in the synapse. (C) Using Otsu thresholding, we generate masks using the B220 signal to define the "cell" and “cell + synapse" regions of interest and overlay the masks onto the Atto647N signal. (D) The extracted Atto647N signal intensities are used to quantify the percentage of antigen internalized using the equation given in (B). Scale bars, 5 µm. <br/> <br/>
Here, we provide a complete series of Fiji macros that are used to generate single colour flatfield images from image stacks, flatfield raw experimental images to correct for uneven illumination, crop around cells (poorly segmented cells should be removed manually), reslice and sum intensities to visualize antigen internalization. Users should then manually define the “cell” and “cell + synapse” regions, save these ROIs separately and run the automated segmentation macro, which segments objects on the membrane stain (in our case is B220) and references the internalized antigen channel (Atto647N signal). Users should use the Raw Integrated Density from the output “.csv” files to then determine the percent internalization using the equation given in Figure 1. <br/> <br/>
# How to save macros
Analysis performed using Fiji (3).
1.	Copy the code (from browser or download as “.txt”) and paste into macro window as: 
     Plugins > New > Macro
2.	Ensure the language is set to IJ1 Macro in the Language tab of the macro window. 
3.	Save the macro using “.ijm” extension. 
# How to use macros
Run macros in order numbered. <br/> <br/>
Macros are written for multi-channel image acquisition. The test images provided have 3 channels (acquired as C1 - B220 (405 nm), C2 - Ag550 (561 nm), C3 - Ag647 (647 nm)). The minimum number of channels needed is two – one for cell segmentation and one for antigen internalisation. <br/> <br/>
Dialog boxes are provided for the user to specify file paths and set image properties according to the microscope used. For example, our camera’s pixel size is 0.11 µm.  <br/> <br/>
Test data is provided for running macros and can be downloaded from:
https://figshare.com/s/982dca32b0276b96874f (Test input)<br/> <br/>
https://figshare.com/s/3a57826368cf3f3547d3 (Test output). <br/> <br/>
We suggest that you go through the macros with our test data to familiarize yourself with how they work, before moving onto your own data. <br/> <br/># 1.GenerateFlatfieldImage.ijm
Background: <br/> <br/>
To ensure accurate image analysis, correction for non-uniform illumination using flatfielding is recommended. The typical Gaussian illumination profile results in dimmer edges compared to the center of the image. Flatfielding evens out the illumination (Figure 2) enhancing accuracy of image analysis. <br/> <br/>
![Picture1](https://github.com/SpillaneLab/Flatfielding/assets/143707918/c04eadb4-92d9-43f9-9049-492d84366528) <br/> <br/>
Figure 2: Representative image showing example raw image (left) having non-uniform illumination, which follows a Gaussian distribution. Flatfielding corrects for aberrations and uneven illumination (right). <br/> <br/>
Experimental setup: <br/> <br/>
Image a dye on a clean glass coverslip matching each channel of a multi-channel acquisition (termed “single colours”; see Figure 3). Acquire a minimum of 36 images per channel and ensure the same imaging conditions (intensity, exposure, and laser power) as used for the imaging experiment. Acquire in the same order as for the imaging experiment to check for bleedthrough between channels. <br/> <br/>
![Picture2](https://github.com/SpillaneLab/Flatfielding/assets/143707918/394d3299-d2c0-4edf-a5d1-c48c28940d44) <br/> <br/>
Figure 3: Example setup for single colour imaging using an 8-well Lab-Tek chamber. The outside chambers should be avoided where possible to prevent knocking the objective whilst imaging. <br/> <br/>
Also, acquire a minimum of 36 images with no laser to obtain background counts (dark counts). In Fiji, generate a mean Z-projection of the image stack (Image → Stacks → Z-project→ Average Intensity) and save it as “AVG_Stack.tif ”. <br/> <br/>
Macro description: <br/> <br/>
This macro generates a background-subtracted and normalised image for flatfield correction. <br/> <br/>

Macro steps:
1.	Dialog box opens and asks the user to specify parameters. The input directory is where the single-colour images for that channel are saved, the output directory is where the resulting flatfield images will be saved, and the channel is that which is to be used to generate the flatfield image. For example, in the test data provided, a B220 flatfield image should be generated using Channel 1 of the 405 nm single-colour images, an Ag550 flatfield image generated using Channel 2 of the 561 nm single-colour images, and an Ag647 flatfield image generated using Channel 3 of the 647 nm single-colour images. The user should also specify where the background (AVG_Stack.tif) image is saved. 
2.	The macro opens all .tif images in the input directory, splits channels, closes those that are not needed, and combines the images from the single-colour channel into a stack. 
3.	The macro then subtracts the background image from all images in the stack and generates a median projection of the image stack.
4.	The median projection is then normalised using the mean pixel value and the resulting image is saved. 
The macro should be run for all channels that require a flatfield image. For the test data provided, this will result in three normalised images: one each for C1 - B220, C2 - Ag550, C3 - Ag647. To proceed to the next step (2.ImageCorrection.ijm), the user should manually merge the normalised images into a multi-colour image (Image  Colour  Merge Channels), maintaining the order and dimensions as the original image acquisition. <br/> <br/>

# 2.ImageCorrection.ijm
Macro description: <br/> <br/>
This macro is applied to sample images to flatfield them. <br/> <br/>
Macro steps: <br/> <br/>
1.	Dialog box opens and asks the user to specify parameters. The input directory should be the raw experimental images, the output directory should be where the user wants the flatfielded images to be saved, the background image should be where the background (AVG_Stack.tif) image is saved, and the flatfield image should be the combined flatfielded stack. The user should also define the camera’s pixel size. For the test data provided, the pixel size is 0.11 µm. 
2.	First, the macro subtracts the background image from the sample image stack. 
3.	The macro then divides the background-subtracted image stack by the flatfield stack (generated as a result of macro 1), and saves the flatfielded images in an output folder.
# 3.CellCrops.ijm	
Macro description: <br/> <br/>
This macro saves multi-channel Z-stack images for individual cells.
Macro steps: <br/> <br/>
1.	Dialog box opens asking the user to specify: 
1.	Input image directory – this should be where flatfielded images are saved. 
2.	Output directory for cropped cells – this is where cell crops will be saved.
3.	Output directory for segmentation overlay images – this is where the overlay for the whole image is saved to allow the user to assess the segmentation.
4.	Image pixel size (µm) – the value will depend on the experimental setup. For the test data, the pixel size is 0.11 µm.  
5.	Channel used for segmentation – we recommend using the channel for the membrane stain, such as the B220 channel. For the test data, channel 1 corresponds to B220 membrane staining.
6.	Minimum and maximum cell size (pixel2) – these parameters should be adjusted to ensure good segmentation. For our test data, set the minimum value to 300 and maximum to 10,000. 
2.	The macro will segment cells using a user-defined channel and get bounding rectangles to save multi-channel Z-stack images for individual cells. 
Within the macro, the method of segmentation (e.g., Otsu) can be adjusted if required to achieve good segmentation. Note that the segmentation is required only to get bounding rectangle of the cell, and is not for quantification, so perfect segmentation is not necessary. Any debris or touching cells (will be difficult to segment later) should be removed manually by deleting the “.tif” file for the individual cell before moving onto 4.ResliceAndSegment.ijm. This can be assessed by either opening all the Z-stack images in the cell crop folder for individual cells or using the segmentation overlay (second output directory). Cell crops can alternatively be obtained manually, but you should have a folder with Z-stack files for individual cells before moving onto the next macro. <br/> <br/>
Once this macro is complete, the user should manually define the “cell” and “cell + synapse” regions and save them separately as “.tif” files for each cell (ensuring matching numbering). These regions are defined as (see Figure 1):   <br/> <br/>
“Cell + synapse” – includes the whole cell area including antigen accumulated at the synapse and internalized antigen clusters. <br/> <br/>
“Cell” – signal of internalized antigen clusters excluding synapse-accumulated antigen; usually ~ 1.5 µm above the synapse level (3 optical slices) with our microscope. <br/> <br/>
# 4.ResliceAndSegment.ijm 
Macro description: <br/> <br/>
This macro reslices the Z-stack image for each cell crop. The macro then generates a maximum intensity projection that is saved for the user to visualise antigen internalisation. Cells are segmented using the maximum intensity projection on the B220 channel (or other membrane stain, defined by the user) but the sum projection of the Atto647N channel is referenced for quantification of percent antigen internalisation. 
Macro steps: <br/> <br/>
1.	Dialog box opens and asks the user to specify: 
1.	Input image directory – this should be where the individual cell crops are saved. 
2.	Output image directory for resliced cells – this will be where the maximum intensity projections of resliced cells will be saved. 
3.	Output image directory for segmented cells – this will be where “.jpeg” images showing the segmentation on the B220 channel will be saved. This is important to allow the user to assess the accuracy of segmentation and modify the parameters within the code if segmentation is poor. 
4.	Channel to be used for cell segmentation – this should be the membrane stain channel. For the test data, this is channel 1. 
5.	Channel to be used to quantify antigen internalisation – this should be the Atto647N channel. For the test data, this is channel 3. 
6.	The minimum and maximum cell size – these values are used for filtering the cell segmentations. The user should adjust these values until they are happy with the resulting segmentations. For the test data, we recommend starting with 10-300 µm2. 
7.	Image pixel size (µm) – the value will depend on the experimental setup. For the test data, the pixel size is 0.11 µm.  
8.	Z-stack step size (µm) – the value will depend on the experimental setup. For the test data, we used optical sectioning of 0.5 µm.  
2.	The macro will first reslice the image.
3.	The macro will then create a sum projection and will rename the internalised antigen channel in order to be referenced for quantifying antigen internalisation. 
4.	The macro will then go back to the resliced image and create a maximum intensity projection. This will be saved so that the user can visualise antigen internalisation for each cell. 
5.	The macro will then split the channels of the maximum intensity projection, select the channel used for membrane staining and threshold. The macro will then reference the internalised antigen channel of the sum projection and output the Integrated Density and Raw Integrated Density (saving as a “.csv” file for the user). In Fiji, when you select “Integrated Density” from the “Set Measurements” plugin, you get two outputs - Integrated Density (IntDen) and Raw Integrated Density (RawIntDen) The IntDen is “the product of area and mean gray value” whereas the RawIntDen is “the sum of the values of the pixels in the image or selection” (https://imagej.net/ij/docs/menus/analyze.html#:~:text=Integrated%20Density%20%2D%20Calculates%20and%20displays,the%20same%20for%20uncalibrated%20image).
Once the macro has finished running, the user should open the “.csv” file for both the “cell” and “cell + synapse” regions of interest. The user can then calculate the percentage of antigen internalisation by dividing the intensity of the “cell” by that of the “cell + synapse” and multiplying by 100 (equation given in Figure 1). <br/> <br/>
# Authors 
Hannah McArthur, Anna Bajur and Katelyn Spillane
# References 
1.	Nowosad CR, Spillane KM, Tolar P. Germinal center B cells recognize antigen through a specialized immune synapse architecture. Nature Immunology. 2016 Jul;17(7):870–7. 
2.	Spillane KM, Tolar P. B cell antigen extraction is regulated by physical properties of antigen-presenting cells. Journal of Cell Biology. 2017 Jan;216(1):217–30. 
3.	Schindelin J, Arganda-Carreras I, Frise E, Kaynig V, Longair M, Pietzsch T, et al. Fiji: An open-source platform for biological-image analysis. Nature Methods. 2012;9(7):676–82. 



