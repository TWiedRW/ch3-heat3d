// These are filled in by R
code = "Test code";

// An array of 10 length-10 vectors.
bar_size_array = [
[1.70976324705407,42.8471215469673,50,58.9973158831492,50,61.447994214947,50,46.8679098263472,44.4444444444444,22.0547036407515],
[50,38.8888888888889,70.2556374594566,69.7355685965403,70.7609566138059,79.0036144759439,63.8931720005593,59.9520894368176,52.1127223152863,27.7777777777778],
[61.5062044551685,69.3029292854477,50,60.7052501052553,88.5195513207701,62.3469680802201,81.5183711791346,65.7349632750198,60.4242792022411,47.0176905384376],
[41.6500794584647,63.3646106533951,81.6667132981988,70.4898245379819,90.5902839432487,92.0994779704155,77.1250528240135,87.7021280181529,80.3571135085321,50],
[62.311552501748,62.2617957298577,64.8121185552565,75,71.2588926497847,71.52628330281,90.7788750323483,90.2760651566324,80.0517259957202,66.961255950852],
[63.7249153219151,81.708321371109,84.0970713061516,90,74.6448865369894,72.6641671219841,67.7471980270014,70.310663073161,80.1821566722289,63.8854531520034],
[50,79.4270007801487,89.5140693680318,72.2314206607198,70.0345836327427,72.163807663975,73.0696726477264,61.0948196536796,73.0105283973052,50],
[41.9785266034394,50,63.7683468451657,59.8338203452462,91.0803723217224,64.937487651897,62.9134489171142,70.6980173569106,50,47.0422783065676],
[46.9741568462833,61.8164360475922,72.3345611868423,63.4933207836247,56.25,64.2857142857143,56.6140924603923,73.4909234354269,41.3348371814201,43.1019597411997],
[14.8723944858648,40.2704842300064,48.0831082575112,60.9715698682487,60.9043039097438,69.9497064035373,67.1531771053344,45.6700054337359,33.3333333333333,9.64497852372006]
];


letter_array = [
["","","N","","","","","","h",""],
["n","","","","","","","","",""],
["","","","","","","","","",""],
["","","","","","","","","","H"],
["","","","","","","","","",""],
["","","","f","","","","","",""],
["F","","","","","","","","","D"],
["","","","","","","","","",""],
["","","","","","","","","",""],
["","","","","","","","","d",""]
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
