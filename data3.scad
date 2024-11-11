// These are filled in by R
code = "Test code";

// An array of 10 length-10 vectors.
bar_size_array = [
[21.3670894573443,10.9659287708604,18.6576377372775,28.1609112451163,49.6908682455412,50,50,66.8062931503583,82.9983647421209,95.9568265359849],
[22.6285418844782,28.2962502634877,21.5404532366018,25.4480424298284,40.1219557864695,65.6934974471935,50,59.9695831695054,84.9296079270749,75],
[0.179731969255954,16.9122853994163,42.5933168437849,23.3811150079903,37.4204533417813,50,68.7842002154017,71.9912154129189,64.2857142857143,81.9164445484057],
[1.12660388695076,21.6290334149057,39.1869850578304,35.2693394835417,56.4029603717952,50,50,65.2644381434139,90,84.1504465043545],
[3.63026502309367,15.1188452777246,20.506271545827,50,60.1439542054302,67.9975502019645,68.5469578780855,73.6980362347741,79.9668872353828,82.1429919125512],
[19.9648126331158,33.3333333333333,42.0190219679433,40.0936918364217,42.9380405099235,56.25,59.2287150832514,61.4322784630996,65.1836641921869,73.602016416844],
[26.3295967876911,28.3100410576703,38.8888888888889,35.9273974069705,46.4152312009699,66.3332136710071,65.2076859764444,71.7054252810259,71.9013227612918,78.0357896769419],
[27.7777777777778,31.6858941621871,24.0000185352336,50,44.4444444444444,41.8533246162244,58.313701710819,58.5109673202452,83.6332494483536,94.7363456338644],
[13.1390283303335,34.798800803514,25.0920609157119,32.0280566539926,42.7531951885774,57.5066644711316,50,59.3413361762133,64.908528143747,79.1146955266595],
[16.2053430522792,15.0993859630802,50,39.762012991899,32.4740748816273,52.5884858485208,76.0757231797712,61.0544510669489,72.8704696285745,76.7849955102429]
];


letter_array = [
["","","","","","D","g","","",""],
["","","","","","","h","","","G"],
["","","","","","R","","","H",""],
["","","","","","d","F","","r",""],
["","","","A","","","","","",""],
["","a","","","","f","","","",""],
["","","M","","","","","","",""],
["e","","","E","N","","","","",""],
["","","","","","","n","","",""],
["","","m","","","","","","",""]
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
