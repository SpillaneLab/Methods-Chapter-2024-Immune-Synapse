   setOption("JFileChooser", true);
   
   dir = "";
   outputDir1 = "";
   outputDir2 = "";
   ch = "";
   pxSize = "";
   minSize = "";
   maxSize = "";
   
   //Dialog box for user
   Dialog.create("Select directories and membrane stain channel");
   Dialog.addDirectory("Input image directory", dir);
   Dialog.addDirectory("Output directory for cropped cell images", outputDir1);
   Dialog.addDirectory("Output directory for segmentation overlay images", outputDir2);
   Dialog.addString("Image pixel size (µm)", pxSize);
   Dialog.addString("Which channel should be used for segmentation?", ch);
   Dialog.addString("Minimum cell size (pixel^2)", minSize);
   Dialog.addString("Maximum cell size (pixel^2)", maxSize);
   Dialog.show();
   
   //Get user input values
   dir = Dialog.getString();
   outputDir1 = Dialog.getString();
   outputDir2 = Dialog.getString();
   pxSize = Dialog.getString();
   ch = Dialog.getString();
   minSize = Dialog.getString();
   maxSize = Dialog.getString();
   
   setOption("JFileChooser", false);
   
   setBatchMode(true);
   count = 0;
   countFiles(dir);
   n = 0;
   processFiles(dir);

//Open all of the files within subfolders 
   
   function countFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              countFiles(""+dir+list[i]);
          else
              count++;
      }
  }

   function processFiles(dir) {
      list = getFileList(dir);
      for (i=0; i<list.length; i++) {
          if (endsWith(list[i], "/"))
              processFiles(""+dir+list[i]);
          else {
             showProgress(n++, count);
             path = dir+list[i];
             processFile(path);
          }
      }
  }
  
//Open all tif files 
  function processFile(path) {
       if (endsWith(path, ".tif")) {
       		//Open the image
       		open(path);
       		
       		//Get the file name without extension 
       		imagesName=getTitle();
       		title = imagesName;
			dotIndex = indexOf(title, ".");
			basename = substring(title, 0, dotIndex); 
			
			//Set image properties, make sure you adjust pixel dimensions based on your camera properties
			getDimensions(width, height, channels, slices, frames);
			run("Properties...", "channels=channels slices=slices frames=frames unit=µm pixel_width="+pxSize+" pixel_height="+pxSize+" voxel_depth=1.0000000");
       		
       		//Duplicate the original image and rename
       		run("Duplicate...", "duplicate");
       		
			//Rename the image 
       		rename("Image"); 
       		
       		//Duplicate again so can easily save cells with all channels
       		selectWindow("Image"); 
       		run("Duplicate...", "duplicate");
       		rename("Channels"); 
       		
       		//Open the original duplicate and create a max intensity projection to segment on
       		selectWindow("Image"); 
       		run("Z Project...", "projection=[Max Intensity]");
       		
       		//Rename to be the max projection 
       		rename("Maxproj");
       		
       		//Split the channels of the max projection of the original duplicate
       		run("Split Channels");
       		
       		//Segment on the desired channel e.g., membrane stain like B220 or brightfield, in our example it is channel 3
       		//Adjust thresholding parameters as required, segmentation method needs to be tested and adjusted to the images, good results are generally acquired with Otsu, Huang and Triangle for thresholding
       		
       		selectWindow("C3-Maxproj");
       		run("Duplicate...", " ");
       		setAutoThreshold("Otsu dark");
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Fill Holes");
			
			//Separate any touching cells
			run("Watershed");
       		
       		//Rename to be the segmented image 
       		rename("Segmented Image");
       		
       		//Rename the channel used for segmentation to be the reference 
       		selectWindow("C"+ch+"-Maxproj");
       		rename("Reference"); 
       		
      		//Set the parameters for measuring and reference the channel used for segmentation
			run("Set Measurements...", "area mean standard modal min perimeter shape integrated median redirect=Reference");	
				
       		//Analyse particles and filter ROI based on size - adjust based on properties of acquired image and cell size
       		//Our camera's pixel size = 0.11um
       		//Exclude cells touching the edge of the image and add segmented cells to ROI manager
       		selectWindow("Segmented Image");
			run("Analyze Particles...", "size="+minSize+"-"+maxSize+" pixel exclude add");
			
			//Select the image with all channels 
			selectWindow("Channels");
			
			//If no segmented cells/ROIs, do nothing
			if (roiManager("count")==0) {
				
				//Save overlay as proof of no ROIs
				selectWindow("Channels"); 
				run("Duplicate...", "duplicate");
				run("Select None"); 
				saveAs("TIFF", outputDir2 + "/" + basename + "_overlay_none");
			}
				
			//If there are cells/ROIs, draw a rectangle on around each ROI and crop (keeping all channels)
			//The user will have to manually check segmentation and remove any poorly segmented cells
			if (roiManager("count")>0) {
				n = roiManager("count"); 
				
				for (i=0; i<n; i++) {
				
				//Save the image with ROI overlay
				selectWindow("Channels");
				run("Duplicate...", "duplicate");
				roiManager("Show All");
				
				//Save overlay/segmentation
				saveAs("TIFF", outputDir2 + "/" + basename + "_overlay");
				
				//Iterate through all the ROIs/all the cells
				roiManager("Select", i);
				
				//Make segmentation bigger
				run("Enlarge...", "enlarge=2");							
				
				//Get bounding rectangle coordinates from the segmentation enlargement
				Roi.getBounds(x, y, width, height);
				
				//Crop
				run("Crop");
				
				//Save with ROI number in file title
				saveAs("TIFF", outputDir1 + "/" + basename + "_Cell_" + (i + 1));
				
				//Clear the results
				run("Clear Results");
				run("Close");
			}
		}
				
		//Clear the ROI manager
		roiManager("reset");
		
		//Close everything
		run("Close All");
       }
  }


  
