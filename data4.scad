// These are filled in by R
code = "Test code";

// An array of 10 length-10 vectors.
bar_size_array = [
[14.3272697576322,16.5397195274838,11.68825293917,34.9297714202354,44.0242961263802,27.7777777777778,26.1679070054864,39.6251180788709,50,43.9761362131685],
[14.9389850803547,20.3296253902631,35.7548950767765,25.6329918774362,30.424624625076,25.7343759255794,50,37.5640967894449,38.1352600385435,56.1038252002456],
[27.4087534358518,23.5496601571018,25.0973517406318,35.5742404744443,50,45.2420960247724,36.2421220830745,38.3250661473721,58.3086826222845,55.9099710642153],
[28.6607860137398,44.4444444444444,24.2957595008839,25.7503223566649,46.0527153846083,50,35.5629528476857,64.0458887991392,58.5978770351762,74.120172720092],
[28.7404663679707,42.9459137324658,25.6949981007104,27.5443829965985,42.2292771293885,60.2868611342274,58.7746222260305,57.0808075603822,50,56.25],
[47.6651631174092,42.5254062291545,47.2937094650438,38.8888888888889,46.4541727607138,52.4923354935729,64.2857142857143,50,77.5934928916912,78.758084827051],
[36.7768844480937,45.9250857445618,37.562132371693,50,62.4795686093987,50,66.2526134766328,62.2153025521483,81.5264288773243,85.2068945843105],
[33.3333333333333,59.8674755437403,50,43.1344150741481,58.4610848294364,73.9481209629836,69.6168100000877,56.4098971308623,77.4145837508452,76.375212396702],
[45.2898138981416,43.1092305644415,50.4450087122516,62.7528875160755,66.8890299477304,50,82.6005189325143,90,75,82.194153499893],
[59.1131007159129,42.1210536536657,68.009952344259,51.2314482351455,73.8663265649747,70.2837172424834,62.813987073799,71.1190840925297,84.1465869253605,81.0702149104327]
];


letter_array = [
["","","","","","g","","","G",""],
["","","","","","","a","","",""],
["","","","","r","","","","",""],
["","R","","","","A","","","",""],
["","","","","","","","","d","E"],
["","","","N","","","D","e","",""],
["","","","m","","H","","","",""],
["M","","n","","","","","","",""],
["","","","","","f","","h","F",""],
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
