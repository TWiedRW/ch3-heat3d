// These are filled in by R
code = "Test code";

// An array of 10 length-10 vectors.
bar_size_array = [
[5.66050093621016,28.5665695964255,33.8484540211761,15.9352784013997,23.9363934710208,45.9791717370455,30.209188038328,50,34.49765172192,41.3417534017935],
[30.3640615231254,28.757616379557,15.3089734880875,18.3496935298252,38.0611938512367,27.7777777777778,33.9319598788602,44.1455772669158,38.8888888888889,46.3379472157814],
[31.3221336251849,15.5589135635334,20.8134284480992,39.5925444545638,49.1629253382174,33.3333333333333,32.5749013397015,46.4668357139453,65.5818855891832,65.945427259689],
[33.8089983623164,15.7585431221459,40.8786914213043,42.5946919138854,50,47.7014543312705,50,50,45.6448980376849,56.4315552233408],
[25.2604990527551,35.2133397450153,25.8453929967557,37.2269031775391,56.3655664595879,53.0890657566488,59.1916093080201,64.2857142857143,57.970128589465,50],
[44.4444444444444,46.8068862388221,28.2997469298748,47.8989582263037,35.2943927794695,67.3035198253476,61.8276503032798,69.8813716360989,70.9356494555767,77.623723656353],
[42.4113862363932,34.4183955688236,56.9211095302469,41.5884768171236,50,60.8206540232317,71.1023205976623,58.8599597760994,61.5878893965338,85.0550896146645],
[30.2230681266843,50,50,67.2188532924176,50,67.985438608254,77.6804177607927,68.5330650181923,84.2493907742513,63.3225632805584],
[45.8320167717627,55.528687259648,65.7486861049094,50,68.8151741485732,66.7410496254969,69.4889410067763,90,84.3426798048636,75],
[56.25,58.5959509028018,46.4099294345619,57.3636207884798,73.1449339055042,78.5526814562682,72.3153838965421,81.0448155316731,76.4252561154879,86.9479357800446]
];


letter_array = [
["","","","","","","","D","",""],
["","","","","","","","","G",""],
["","","","","","d","","","",""],
["","","","","b","","","g","",""],
["","","","","","","","B","",""],
["h","","","","","","","","",""],
["","","","","N","","","","",""],
["","H","","","","","","","",""],
["","","","n","","","","","",""],
["","","","","","","","","",""]
];

x_axis_label = "X axis label";
y_axis_label = "Y axis label";

bar_dims_xy=[10,10]; // in mm
n_bars_xy=[10,10];
plot_margins_xy=[[10,10],[10,10]]; // in mm

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
font = "Liberation Sans";

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
    difference(){
        union(){
            // Base
            cube([base_x,base_y,base_z]);

            // Bars
            for(i = [0:9]) {
                for(j = [0:9]) {
                    translate([bar_y[j], bar_x[i], bar_z[i]])
                        cube([bar_size_y[j], bar_size_x[i], bar_size_array[i][j]]);
                    translate([letter_y[j], letter_x[i], letter_z[i][j]])
                        letter(letter_array[i][j]);
                }
            }

            // TODO: Create this based off of groups...


            labels_x = [base_x/2, margins_x[0]/2];
            labels_y = [margins_y[0]/2, base_y/2];
            labels_z = [base_z, base_z];
            rotation = [0, 90];
            labels = [x_axis_label, y_axis_label];

            for(i = [0:(len(labels)-1)]) {
                translate([labels_x[i], labels_y[i], labels_z[i]])
                rotate(rotation[i])
                    letter(labels[i]);
            }

        };
        // Subtract off the code
        translate([base_x/2,base_y/2,letter_height])
            rotate([180,0,0])
            letter(code, 7);
    }
}
