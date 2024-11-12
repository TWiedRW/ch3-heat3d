// These are filled in by R
code = "Test code";

// An array of 10 length-10 vectors.
bar_size_array = [
[60.2187839254727,78.8807147808153,79.3008329500238,72.1404903908801,88.8552993210032,71.9631432276219,68.5601758179796,66.6070612696725,69.8263552386094,67.0018816401241],
[28.2793585428823,44.8092706582499,56.25,57.9235174942735,72.3710779284944,81.3649237130654,79.886165465505,57.4891447012964,50,43.5204537826445],
[30.9540542843747,40.4243724893896,59.09942868743,72.0345413753208,71.9591248401161,50,64.2857142857143,50,29.7324401124498,38.0328875174741],
[26.5405745229769,44.3349358666897,52.4071773706001,58.7804025352923,50,67.6647503532957,45.0662476557297,50,23.2141119492449,13.0091356260787],
[19.0809030435048,44.4444444444444,30.2020240140265,57.2903552861095,63.4067786589255,62.6486458547404,43.6011653603197,36.8157033350436,41.0279135180923,13.1682603084482],
[14.0152195561677,42.8714455904725,38.8888888888889,35.3390650800571,67.5301117205051,60.6173904996356,42.6550973160335,47.2705387937023,26.4356159938785,26.6437032516114],
[5.91948354924947,35.6628108834125,59.9709475814362,65.7621795113189,62.1609176437858,53.0222913854312,61.0449415875589,50,27.7777777777778,10.2773654165763],
[37.5370030477638,40.5208431936918,46.1497775080604,65.375655391105,50,50,73.7937374900472,41.7439190449184,53.5135148682749,33.3333333333333],
[50,47.7158282685084,69.899269132195,75,64.0112451950905,58.7317428153825,63.2300493952791,71.862528351387,67.7702398213548,50],
[58.021173489931,69.4153408284079,87.1748408456127,95.5736935828422,91.5978964976966,71.8573540402576,90.7702872288023,90,77.8545270018991,45.3599392610593]
];


letter_array = [
["","","","","","","","","",""],
["","","R","","","","","","",""],
["","","","","","r","","N","",""],
["","","","","","","","","",""],
["","","","","","","","","",""],
["","","","","","","","","",""],
["","","","","","","","n","",""],
["","","","","","D","","","","d"],
["m","","","M","","","","","",""],
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
