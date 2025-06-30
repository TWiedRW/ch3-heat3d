// These are filled in by R
code = "Practice";

// An array of 10 length-10 vectors.
bar_size_array = [
[13.9842790630609,21.4725188196495,36.5231137419716,40.5791770493563,33.3333333333333,20.5804341633138,41.4217790568764,31.8789185824677,52.5581485279583,55.3231201740734],
[11.9957839496579,34.7390501895157,17.5699938117922,39.1669885385394,48.2775758641332,29.0010248890615,39.5343405267226,34.9943608321081,56.4800389393885,65.9036226716289],
[22.1545337572433,18.9120026780087,19.8413445489733,40.4295031886461,26.660442151283,56.25,45.9712786318978,50.9233664944589,53.468365632029,69.8884037039759],
[21.8370095772755,41.8668359281806,50,50,30.4364597941989,50,57.9735804821769,42.5999358527517,65.6557548870307,66.4062790587559],
[27.7777777777778,27.6245948173939,42.5854428863585,29.7557417097088,39.8685339752589,36.4383611342493,63.4950312460218,50,65.7287762723232,76.0552933224761],
[50,52.60152502046,42.4068677225321,56.630468901704,54.6905378018717,41.7238020217955,64.5912649396166,59.9993901303968,65.2225045759438,65.3263816886255],
[40.2172799362376,35.4701993258523,38.8888888888889,58.1069055975198,40.6778351444156,69.0589901682437,50,50,50,65.1639984129378],
[46.1203196150686,50,50,40.3558027597662,60.3805543083497,72.7593705227504,79.1759945896553,70.256635379882,59.0983736990249,67.8465331612418],
[37.7048521072227,41.3603948187922,63.3715847833171,45.1549898445346,64.2857142857143,63.8301593776552,77.6351901821253,78.9289202201015,73.2456462015194,90],
[41.0300821405906,44.4444444444444,57.2077695642461,72.6369903289333,53.6505801266332,81.1954674461225,68.587873921168,70.0843599687216,75,99.9888686439928]
];


letter_array = [
["","","","","r","","","","",""],
["","","","","","","","","",""],
["","","","","","M","","","",""],
["","","m","D","","R","","","",""],
["d","","","","","","","f","",""],
["g","","","","","","","","",""],
["","","G","","","","F","y","A",""],
["","Q","H","","","","","","",""],
["","","","","q","","","","","a"],
["","h","","","","","","","Y",""]
];

x_axis_label = "Factor 1";
y_axis_label = "Factor 2";

bar_dims_xy=[10,10]; // in mm
n_bars_xy=[10,10];
plot_margins_xy=[[10,10],[10,10]]; // in mm

base_color = [0, 0, 0]; // black
label_color = [1, 1, 1]; // white
bar_color = [.5, .5, .5]; // grey

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
    difference(){
        union(){
            // Base
            color(base_color) cube([base_x,base_y,base_z]);

            // Bars
            for(i = [0:9]) {
                for(j = [0:9]) {
                    translate([bar_y[j], bar_x[i], bar_z[i]])
                        color(bar_color)
                        cube([bar_size_y[j], bar_size_x[i], bar_size_array[i][j]]);
                    translate([letter_y[j], letter_x[i], letter_z[i][j]])
                        color(label_color)
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
                    color(label_color)
                    letter(labels[i]);
            }

        };
        // Subtract off the code
        translate([base_x/2,base_y/2,letter_height])
            rotate([180,0,0])
            color(label_color)
            letter(code, 7);
    }
}
