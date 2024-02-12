	setOption("JFileChooser", true);
	
	dir = "";
	outputDir1 = "";
	outputDir2 = "";
	chCell = "";
	chAg = "";
	min = ""; 
	max = "";
	pxSize = "";
    zSize = "";
   
	//Dialog box for user
	Dialog.create("Select input and output directories");
	Dialog.addDirectory("Choose an input image directory (where cell crops saved)", dir);
	Dialog.addDirectory("Choose an output directory for resliced cells", outputDir1);
	Dialog.addDirectory("Choose an output directory for segmented cells", outputDir2);
	Dialog.addString("Which channel should be used for cell segmentation?", chCell);
	Dialog.addString("Which channel should be used to quantify antigen internalisation?", chAg);
	Dialog.addString("What is the minimum cell size (µm^2)?", min);
	Dialog.addString("What is the maximum cell size (µm^2)?", max)
	Dialog.addString("Image pixel size (µm)", pxSize);
    Dialog.addString("Z-stack step size (µm)", zSize);
	Dialog.show();
	
	//Get user input values
	dir = Dialog.getString();
	outputDir1 = Dialog.getString();
	outputDir2 = Dialog.getString();
	chCell = Dialog.getString();
	chAg = Dialog.getString();
	minSize = Dialog.getString();
	maxSize = Dialog.getString();
	pxSize = Dialog.getString();
   	zSize = Dialog.getString();
	
	setOption("JFileChooser", false);
	
   setBatchMode(true);
   count = 0;
   countFiles(dir);
   n = 0;
   processFiles(dir);

//Open all of the files within the folder 
   
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

//Process all tif files

  function processFile(path) {
       if (endsWith(path, ".tif")) {
       		//Open the .tif image and get the file name 
       		open(path);
       		imagesName=getTitle();
       		
       		//Get the file name without extension 
       		title = imagesName;
			dotIndex = indexOf(title, ".");
			basename = substring(title, 0, dotIndex); 
       		
       		//Get image properties 
       		getDimensions(width, height, channels, slices, frames);
       		    		
       		//Duplicate the image and rename
	       	run("Duplicate...", "duplicate");
			
			//Run reslice
			run("Remove Overlay");
			run("Select None");
			run("Reslice [/]...", "output=zSize start=Top avoid");
			rename("Resliced");
			
			//Duplicate and create a sum projection (for internalisation data)
			run("Duplicate...", "duplicate");
			run("Z Project...", "projection=[Sum Slices]");
			
			//Rename to be "Image" for ease of referencing 
			rename("Image");
			
			//Split the channels of the sum projection
	       	run("Split Channels");
	       	
	       	//Select the internalised antigen channel and rename for referencing 
	       	selectWindow("C"+chAg+"-Image");
	       	rename("IntAg");
			
			//Duplicate the resliced image to create a max projection (for visualisation and segmentation) and rename
			selectWindow("Resliced");
			run("Duplicate...", "duplicate");
			run("Z Project...", "projection=[Max Intensity]");
			rename("Max_proj");
			
			//Save the max projection 
			run("Duplicate...", "duplicate");
			resetMinAndMax();
			outName1 = "re_" + basename;
			saveAs("tif", outputDir1 + "/" + outName1);
			
			//Rename the max projection as "Image2" for ease of referencing when segmenting
			selectWindow("Max_proj");
			rename("Image2");
				
			//Segment the cell in the user-defined channel
				
			//Split the channels of the sum projection
	       	run("Split Channels");
	       	
	       	//Select the B220 channel
	       	selectWindow("C"+chCell+"-Image2");
	       	
	       	//Duplicate the B220 channel
	       	run("Duplicate...", "duplicate");
	       	
	       	//Rename 
	       	rename("Thresholded");
	       	
	       	//Use Otsu thresholding - change thresholding method to improve segmentation if required
	       	setAutoThreshold("Otsu dark");	       		
	       	run("Convert to Mask");
	       	
	       	//Fill any holes in the binary image 
			run("Fill Holes");
			
			//Rename the final segmented image
			rename("Cell_thresholded");
	
			//Set measurements - redirect to the internalised antigen channel 
			run("Set Measurements...", "integrated redirect=IntAg decimal=3");
	
	       	//Analyse particles and filter ROI from based on size - adjust based on properties of acquired image and cell size 
			//Exclude cells touching the edge of the image and add segmented cells to the ROI manager 
			selectWindow("Cell_thresholded");
			run("Analyze Particles...", "size="+minSize+"-"+maxSize+" display exclude add");
	       		
	       	//Show cell segmentation using the ROI manager 
	       	selectWindow("C"+chCell+"-Image2"); 
			run("Duplicate...", "duplicate"); 
	       	rename("Cell_overlay");
	       	resetMinAndMax();
			roiManager("Show All");
			//Save .jpeg image with cell segmentation 
			//This allows you to check the segmentation is doing a good job 
			outName1 = "Mask_" + basename;
			saveAs("JPEG", outputDir2 + "/" + outName1);

	
			//Clear the ROI manager
			count = roiManager("count");
			if (count != 0)
				roiManager("delete");
		     //Close everything
			run("Close All");
       		}
        }

//Save the results table and then clear
saveAs("Results", outputDir2 + "/Results.csv");
run("Clear Results");