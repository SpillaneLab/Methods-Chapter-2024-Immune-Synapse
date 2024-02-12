setOption("JFileChooser", true);

dir = "";
outputDir = "";
normFile = "";
bgFile = "";
pxSize = "";
 
//Dialog box for user
Dialog.create("Select directories, background image and flatfield image")
Dialog.addDirectory("Input image directory", dir);
Dialog.addDirectory("Output image directory", outputDir);
Dialog.addFile("Select a background image", bgFile);
Dialog.addFile("Select a flatfield image (all channels merged)", normFile);
Dialog.addString("Image pixel size (µm)", pxSize);
Dialog.show();

//Get user input values
dir = Dialog.getString();
outputDir = Dialog.getString();
bgFile = Dialog.getString();
normFile = Dialog.getString();
pxSize = Dialog.getString();
list = getFileList(dir);

setOption("JFileChooser", false);

//Set batch mode
setBatchMode(true);

count = 0;
countFiles(dir);
n = 0;
processFiles(dir);

//Open all files within the folder
function countFiles(dir) {
	for (i = 0; i<list.length; i++) {
		if (endsWith(list[i], "/"))
			countFiles(""+dir+list[i]);
		else
			count++;
	}
}

function processFiles(dir) {
	list = getFileList(dir);
	for (j = 0; j<list.length; j++) {
		if (endsWith(list[j], "/"))
			processFiles(""+dir+list[j]);
		else {
			showProgress(j, count);
			path = dir+list[j];
			processFile(path);
		}
	}
}

//Open all tif files 
function processFile(path) {
	if (endsWith(path, ".tif")) {
		open(path);

		//Get the file name
		name = getTitle();

		//Rename image
		rename("image");

		//Get image details
		getDimensions(width, height, channels, slices, frames);
		num_of_slices = slices;
		num_of_channels = channels;
		depth = num_of_slices*num_of_slices;
		
		//Open background image
		open(bgFile);
		rename("bgFile");

		//Subtract background from multi-channel image
		imageCalculator("Subtract create stack", "image", "bgFile");

		//Close the background image and original image file
		selectImage("bgFile");
		close();
		selectImage("image");
		close();

		//Rename the background-subtracted image
		selectImage("Result of image");
		rename("image");
		
		//Open the flatfielding image
		open(normFile);

		//Rename the flatfielding image
		rename("norm");
		
		//Generate a flatfield image stack
		rp2 = "x=1.0 y=1.0 z=" + num_of_slices + " width=" + width + " height=" + height+ " depth=" + depth + " interpolation=None average create";
		run("Scale...", rp2);
		rp2 = "order=xyczt(default) channels=" + num_of_channels + " slices=" + num_of_slices + " frames=1 display=Color";
		run("Stack to Hyperstack...", rp2);
		
		//Close unneeded window
		selectImage("norm");
		close();
		
		//Flatfield the background-subtracted image
		imageCalculator("Divide create stack", "image", "norm-1");
		
		//Close unneeded window
		selectImage("image");
		close();
		selectImage("norm-1");
		close();

		//Set image pixel size
		selectImage("Result of image");
		rename("image");
		run("Set Scale...", "distance=1 known=pxSize unit=µm");

		//Save the image
		outName1 = name;
		saveAs("tif", outputDir + "/" + outName1);

		//Close all windows
		run("Close All");
	}
}

//Set batch mode
setBatchMode(false);



























