// These are filled in by R
code = "Test code";

// An array of 10 length-10 vectors.
bar_size_array = [
[ 1,  2,  3,  4,  5,  6,  7,  8,  9, 10],
[20, 19, 18, 17, 16, 15, 14, 13, 12, 11],
[21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
[40, 39, 38, 37, 36, 35, 34, 33, 32, 31],
[41, 42, 43, 44, 45, 46, 47, 48, 49, 50],
[60, 59, 58, 57, 56, 55, 54, 53, 52, 51],
[61, 62, 63, 64, 65, 66, 67, 68, 69, 70],
[80, 79, 78, 77, 76, 75, 74, 73, 72, 71],
[81, 82, 83, 84, 85, 86, 87, 88, 89, 90],
[100, 99, 98, 97, 96, 95, 94, 93, 92, 91]
];


letter_array = [
["A", "", "", "", "", "", "", "", "", ""],
["", "B", "", "", "", "", "", "", "", ""],
["", "", "", "", "", "", "", "C", "", ""],
["", "", "", "", "", "", "D", "", "", ""],
["", "", "", "", "E", "", "", "", "", ""],
["", "", "", "", "", "F", "", "", "", ""],
["", "", "", "", "", "", "", "", "", "I"],
["", "", "G", "", "", "", "", "", "", ""],
["", "", "", "H", "", "", "", "", "", ""],
["", "", "", "", "", "", "", "", "J", ""]
];

x_axis_label = "Factor 1";
y_axis_label = "Factor 2";

bar_dims_xy=[10,10]; // in mm
n_bars_xy=[10,10];
plot_margins_xy=[[10,10],[10,10]]; // in mm

base_color = [0, 0, 0]; // black
label_color = [1, 1, 1]; // white
bar_color = [.5, .5, .5]; // grey

height_diff = 5;
max_height = max([for (i=0; i<len(bar_size_array); i=i+1) max(bar_size_array[i])]);
height_levels = ceil(max_height/height_diff);


// 20 values from the jet palette in viridis
height_colors = [[0.19, 0.07, 0.23], [0.25, 0.22, 0.58], [0.27, 0.37, 0.82], [0.27, 0.50, 0.96],
[0.23, 0.63, 0.98], [0.14, 0.76, 0.89], [0.09, 0.87, 0.75], [0.17, 0.94, 0.62],
[0.36, 0.98, 0.45], [0.55, 1.00, 0.29], [0.71, 0.97, 0.21], [0.84, 0.90, 0.21],
[0.93, 0.80, 0.23], [0.98, 0.69, 0.21], [0.99, 0.54, 0.15], [0.95, 0.38, 0.08],
[0.88, 0.26, 0.04], [0.78, 0.16, 0.01], [0.64, 0.07, 0.00], [0.48, 0.02, 0.01]];
echo(height_levels, " height levels with height size ", height_diff);


//---------------------------------------------------------------------

// Cumulative sum function
// https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Tips_and_Tricks#Cumulative_sum
function cumsum(values) = ([ for (a=0, b=values[0]; a < len(values); a= a+1, b=b+(values[a]==undef?0:values[a])) b] );

// Add vector values
// https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Tips_and_Tricks#Add_all_values_in_a_list
function add(v, i = 0, r = 0) = i < len(v) ? add(v, i + 1, r + v[i]) : r;

// Add vectors
// https://forum.openscad.org/adding-vectors-function-td14524.html
function addvec(v, av) = (len(v) == len(av)) ? [ for (i = [ 0 : len(v)-1 ]) v[i] + av[i] ] : [0,0,0];

// Letter extrusion code
// https://files.openscad.org/examples/Basics/text_on_cube.html
font = "Atkinson Hyperlegible Next:style=Bold";

module letter(l, size=letter_size, height=letter_height) {
	// Use linear_extrude() to make the letters 3D objects as they
	// are only 2D shapes when only using text()
    if(1!="") {
        linear_extrude(height = height) {
            text(l, size = size, font = font, halign = "center", valign = "center", $fn = 16);
        }
    }
}

letter_size = 5; // 5mm
letter_height = 2; // 2mm

//---------------------------------------------------------------------

// These define the [x,y] dims of the bar, in mm
bar_size_x = [for(i = [0:(n_bars_xy[0]-1)]) bar_dims_xy[0]];
bar_size_y = [for(i = [0:(n_bars_xy[1]-1)]) bar_dims_xy[1]];

// These define the plot margins
margins_x = plot_margins_xy[0];
margins_y = plot_margins_xy[1];

// This calculates the base dimensions
base_x = margins_x[0] + margins_x[1] + add(bar_size_x);
base_y = margins_y[0] + margins_y[1] + add(bar_size_y);
base_z = 10;
echo("Base size", base_x, base_y, base_z);

// These define the location of the bottom of the bar
bar_x = cumsum(bar_size_x);
bar_y = cumsum(bar_size_y);
bar_z = [for(i = [0:1:9]) base_z];

// These define the location of the text on the bar (if applicable)
letter_x = addvec(bar_x, bar_size_x/2);
letter_y = addvec(bar_y, bar_size_x/2);
letter_z = [for(i=[0:(n_bars_xy[0]-1)]) addvec(bar_z, bar_size_array[i])];


render(){
    union(){
        // Base
        color(base_color)
        difference(){
             cube([base_x,base_y,base_z]);
            // Subtract off the code
            translate([base_x/2,base_y/2,letter_height])
                rotate([180,0,0])
                letter(code, 7);
        }
        
        // Bars
        for(i = [0:9]) {
            for(j = [0:9]) {    
                union() {
                    for(k = [0:height_levels]) {               
                        myheight = max(0, min(bar_size_array[i][j] - k*height_diff, height_diff));
                        barstart = bar_z[i] + k*height_diff;
                        
                        if(myheight > 0){
                        echo("Bar with height ", myheight, " starting at ", barstart);
                        translate([bar_y[j], bar_x[i], barstart])
                            color(height_colors[k])
                            cube([bar_size_y[j], bar_size_x[i], myheight]);
                        }
                    }
                } // Not sure if unioning this makes it easier or not but it seems like it'd at least result in fewer objects?
            }
        }
        
        // Letters
        for(i = [0:9]) {
            for(j = [0:9]) {   
                translate([letter_y[j], letter_x[i], letter_z[i][j]])
                    color(label_color)
                    letter(letter_array[i][j]);
            }
        }



        labels_x = [base_x/2, margins_x[0]/2];
        labels_y = [margins_y[0]/2, base_y/2];
        labels_z = [base_z, base_z];
        rotation = [0, 90];
        labels = [x_axis_label, y_axis_label];

        for(i = [0:(len(labels)-1)]) {
            translate([labels_x[i], labels_y[i], labels_z[i]])
                rotate(rotation[i])
                color(label_color)
                letter(labels[i]);
        }
    }
}
