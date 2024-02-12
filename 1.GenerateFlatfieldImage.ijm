setOption("JFileChooser", true);

dir = "";
outputDir = "";
bgFile = "";
ch = "";

//Dialog box for user
Dialog.create("Select directories, channel, and background image");
Dialog.addDirectory("Input image directory", dir);
Dialog.addDirectory("Output image directory", outputDir);
Dialog.addString("Channel?", ch);
Dialog.addFile("Select a background image", bgFile);
Dialog.show();
    
//Get user input values
dir = Dialog.getString();
outputDir = Dialog.getString();
ch = Dialog.getString();
bgFile = Dialog.getString();
list = getFileList(dir);
pattern = "C"+ch+"-";

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
    for (i = 0; i<list.length; i++) {
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
        open(path);

        //Get the file name
        name = getTitle();

        //Split channels
        run("Split Channels");

        //Get the list of open window titles
        titles = getList("image.titles");

        //Loop through each open window
        for (i = 0; i < titles.length; i++) {
            //get the title of the current window
            title = titles[i];

            //Check if the title does not include the specified pattern
            if (title.indexOf(pattern) == -1) {
                //close the window
                selectWindow(title);
                close();
            }
        }

    }
}

//Create an image stack
run("Images to Stack");

//Rename the image stack
rename("Stack");

//Open the background image
open(bgFile);
rename("bgFile");

//Subtract the background image from the single colour image stack
imageCalculator("Subtract create stack", "Stack", "bgFile");

//Close the background image
close("bgFile");

//Create a median Z-projection
selectWindow("Stack");
run("Z Project...", "projection=Median");
selectWindow("MED_Stack");

//Measure the mean pixel value
//meanValue = list.getValue("Mean");
run("Set Measurements...", "mean redirect=None decimal=3");
run("Measure");
wait(1000);
	
//Divide the median image by the mean pixel value (denoted by v)
selectWindow("MED_Stack");
meanValue = getResult("Mean");
run("Divide...", "value=" + meanValue); 

selectWindow("Results"); 
run("Close");

//Save the normalised image
outName1 = "C"+ch+"-Norm";
saveAs("tif", outputDir + "/" + outName1);

//Close all windows
run("Close All");

