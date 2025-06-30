// These are filled in by R
code = "Practice";

// An array of 10 length-10 vectors.
bar_size_array = [
[1.01581608178094,32.64801413183,18.5996113673577,30.1596168304483,28.5056726919073,50,30.4467625085575,41.1307913644446,56.25,55.2882887166925],
[28.1574310142443,35.7688432282561,35.7391692503976,41.7351609310653,29.6150766121637,29.9106310944383,41.1744096639773,50,58.4647342353128,64.703246491392],
[9.79198096113072,18.5289471728417,22.1579026552435,35.8595470543433,43.879248679926,50,38.1707721935689,44.9191409861669,57.739494700347,62.7816815746741],
[17.1583334209087,33.3333333333333,24.0102199390013,25.8632297216294,55.2627626664212,59.1932919981062,64.2857142857143,41.0596791760892,50,68.5946382574427],
[28.4533188147988,50,24.6898935323892,38.8888888888889,57.6624521600186,42.3497674404643,57.6659334417329,72.573594539685,60.7437323887522,66.1808202537294],
[41.5543811669987,50,40.7322742042339,34.3917494137875,44.4444444444444,66.9670979272471,66.7457382895777,50,69.8311483958322,71.3410607999604],
[50,35.3444984296544,34.9207137488863,51.5947389486246,50,66.7778917870277,70.6374970932181,72.1126060472387,50,67.3854277081167],
[27.7777777777778,53.6752559511094,63.2679619640112,45.316045872298,61.2873909345621,73.588251703574,55.2596638217154,75,60.6164817822476,84.7055747986047],
[44.7817059733077,48.3335855114274,64.5389296872438,53.6888175669851,72.352290962978,60.1151475897576,70.3317384300236,79.973703805202,80.056531640908,78.7657587915762],
[40.8940837834962,52.2180245876209,57.0279408714527,59.9771891899096,66.8322952050302,64.0192537051108,80.4286254531083,73.5734406320585,93.4536063728026,90]
];


letter_array = [
["","","","","","M","","","m",""],
["","","","","","","","f","",""],
["","","","","","G","","","",""],
["","R","","","","","Q","","F",""],
["","h","","g","","","","","",""],
["","d","","","H","","","q","",""],
["r","","","","Y","","","","A",""],
["D","","","","","","","y","",""],
["","","","","","","","","",""],
["","","","","","","","","","a"]
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
