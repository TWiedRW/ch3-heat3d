// These are filled in by R
code = "Set 2";

// An array of 10 length-10 vectors.
bar_size_array = [
[85.2024461341096,63.1803789280012,60.7259455634728,58.6058564988531,44.4444444444444,59.3169898726558,60.1846179897483,56.25,70.658362925083,85.7315825218641],
[59.496080251636,50,41.519566313891,28.4235311243551,47.3426684532285,50,40.2167782112343,50,68.5555057772825,61.5553847590991],
[69.9313635781867,50,50,34.1800172601576,33.1836172951851,27.7777777777778,18.0699406594462,34.2816644275855,34.7057484894645,58.1064694703493],
[50,28.1200266363192,42.2547485137282,33.3333333333333,15.5249664399517,19.5335530292007,34.641700560466,20.0321835593657,34.818040323988,68.2936146311301],
[66.2606815079142,46.07809322903,33.8994189669648,17.3357362726007,17.7919313027039,26.7790173219468,14.1325684985373,40.8333590821013,38.8888888888889,65.1974342544797],
[64.2857142857143,41.2589047839641,28.9558024684834,11.3888201925331,10.4827064346715,19.8887124308126,29.4553646107718,36.4298043351262,51.123971796075,52.8702761055373],
[59.5928140444751,52.111476249907,16.6924861915421,37.1372469811518,16.1732904384235,13.1005827823341,13.0575217268062,35.205468081431,29.7833316277953,64.9116962340076],
[75,45.0593576477386,46.7006543444808,35.4493919481434,40.2138765209425,19.4523151130575,25.7831478772442,50,45.6453803010264,69.9441728445259],
[62.3873715391055,65.6849444241489,35.1645695525012,33.2217293839766,30.0889828160251,50,38.539017202812,42.6912223020188,69.1530364343815,66.309225938232],
[81.0846819451742,71.9281519864221,66.4524457183477,50,41.7048821464665,52.9960686559554,50,60.8034333316305,62.0638554737754,90]
];


letter_array = [
["","","","","f","","","n","",""],
["","M","","","","N","","F","",""],
["","A","b","","","B","","","",""],
["R","","","m","","","","","",""],
["","","","","","","","","E",""],
["a","","","","","","","","",""],
["","","","","","","","","",""],
["r","","","","","","","e","",""],
["","","","","","D","","","",""],
["","","","d","","","H","","","h"]
];

x_axis_label = "Factor 1";
y_axis_label = "Factor 2";

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
