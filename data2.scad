// These are filled in by R
code = "Test code";

// An array of 10 length-10 vectors.
bar_size_array = [
[50.7477814203119,75,83.4821701366248,92.0596872191486,98.4691115049645,94.4556906679645,80.6451269207132,68.5916391541044,72.0300539533388,50.985037364251],
[42.5378835488897,60.2008591836309,50,80.2769135793644,83.6169565955993,81.9914446280223,71.0478241781677,59.4924528075102,50,36.9914938424569],
[37.1933494810941,56.900377309241,58.8196816632515,50,63.0325784736964,67.765271215951,54.4636442999732,50,30.695377058175,38.6341661214823],
[8.75633041449741,50,60.6534787692127,57.1609663648521,56.25,54.5912744219903,50,60.6613968108778,43.2733264373824,32.4527499669316],
[13.0134967155755,41.0236293457734,37.5783131581849,45.816880525104,54.0858889987683,50,60.6538132741258,29.8853930745391,46.0756282865355,19.5627560745925],
[5.79158512176946,44.4444444444444,36.14457027131,38.8888888888889,46.1213686817316,45.0995652318923,36.0382012301267,34.8911849859288,24.4635582140932,20.092565047089],
[4.7319826840508,48.6038905120663,42.2097790759054,58.5272709873495,69.3984797595557,69.4306319508258,64.2857142857143,33.3333333333333,32.5588657538615,14.5586217691276],
[27.7777777777778,57.5062688238105,40.9386835002331,50,57.5111348268296,66.966881604651,57.7478237611619,57.6236166234119,40.4635819427787,23.0844091693866],
[30.746397397839,43.1356706644399,50,82.3371370782118,62.2671260915582,87.743397226825,58.7784570751685,71.9442348291818,41.005861597321,48.5509497471009],
[42.5989089940665,50,86.1679854723419,80.2225923948531,92.8281329222955,90,95.3958880124223,68.6065753772649,61.5386019481126,64.9590935336416]
];


letter_array = [
["","r","","","","","","","",""],
["","","B","","","","","","h",""],
["","","","E","","","","d","",""],
["","R","","","b","","H","","",""],
["","","","","","a","","","",""],
["","N","","e","","","","","",""],
["","","","","","","A","D","",""],
["f","","","F","","","","","",""],
["","","n","","","","","","",""],
["","g","","","","G","","","",""]
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
