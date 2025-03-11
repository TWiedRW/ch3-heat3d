// These are filled in by R
code = "Set 1";

// An array of 10 length-10 vectors.
bar_size_array = [
[17.2132916532488,36.0726778298176,54.2805262628744,44.4444444444444,61.9245526818619,50.7074818380197,56.25,40.0785338307062,22.0127311987223,22.4791120091637],
[38.8888888888889,36.5326685973083,60.6048197004773,79.1733622802731,57.8561014062212,63.6954720806375,73.9009126352287,69.5058337232162,50,35.883306175941],
[38.1227054057077,50,71.5781966823856,78.0387893728885,73.0247641215147,79.3457321581292,76.4487140449692,60.2850865121486,73.6180225635272,51.6168085569634],
[51.6338022642176,50,72.1359195374152,77.8564545475736,77.6548459734233,83.6727355531855,80.1118734750418,78.0822829776518,58.8090469659699,60.4772399602897],
[53.1909972031816,73.6119311325102,78.7898152265196,93.0707104707105,75,91.2860602492667,88.7231732538991,82.430390424427,82.7221844761274,56.7836807418812],
[50,70.4978204440376,82.9419683036247,77.3135338983101,93.5021713686879,92.7988617990163,92.2702618237552,84.4433450329672,62.5809750772325,67.5406969859362],
[50,54.04074810748,78.3429021915171,90,78.8655086916362,84.8496818563354,71.3615695358822,63.9732487434342,72.2713392999096,54.210772462078],
[53.156399060411,60.0248403434983,64.2857142857143,76.0232773758408,74.3494959853926,79.3062840090834,88.5882590982453,73.3749200518473,69.2533076489751,50],
[33.3333333333333,53.0511631182311,55.6600056166252,75.9804710617615,67.0628823114062,75.9764709211653,65.6082979786601,50,48.7851150015597,27.7777777777778],
[18.8303895035829,50,52.7256323320697,50,62.759087567418,48.0849922621125,50,32.1382652843772,29.8500876249718,12.1695641200453]
];


letter_array = [
["","","","H","","","m","","",""],
["G","","","","","","","","M",""],
["","h","","","","","","","",""],
["","Y","","","","","","","",""],
["","","","","y","","","","",""],
["g","","","","","","","","",""],
["a","","","A","","","","","",""],
["","","q","","","","","","","f"],
["r","","","","","","","F","","d"],
["","Q","","R","","","D","","",""]
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
