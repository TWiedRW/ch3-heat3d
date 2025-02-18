// These are filled in by R
code = "Test code";

// An array of 10 length-10 vectors.
bar_size_array = [
[22.052445737645,29.0310709693262,29.9256664426583,35.4209484842916,50,64.2857142857143,72.9993198664548,82.0097495936271,90,99.9647289724089],
[24.9113985104486,25.1251983179504,20.7742701313044,50,42.9329477493755,58.9842331515522,64.8150790288734,81.5680497483764,87.2398964056952,93.7108011101373],
[26.1875463556498,35.8542085953781,23.4417385566566,32.4579546608341,36.9050323600984,64.8462092446991,50,62.5947995036323,71.2305717796294,70.5020942096598],
[29.1720643546432,12.8482079857753,31.4916710607294,44.4444444444444,54.6670092163711,42.2203602282227,50,57.9514849506732,76.4131778569168,84.9700096133165],
[27.7777777777778,10.6112000558318,36.0594326472427,50,58.9891685998171,56.25,55.1689648830021,58.1004376843985,86.7050946897103,74.3645866285078],
[7.97996191307902,34.9540770545395,32.5807542172778,39.7054526566838,37.3035015129588,50,73.0175545501212,75.6037183799263,85.478650775945,87.6197402970865],
[29.0475573157892,37.4247189543934,43.6406745929788,23.6566611200881,50,40.2417645988882,50,73.8654632209283,87.769793220537,74.2193494667299],
[20.2435986371711,15.5403446944224,38.8888888888889,34.4382524730948,57.3559584409102,57.7650601685875,57.425697708192,68.6399505794462,86.0957261591425,94.5870328205638],
[11.1052419058979,13.043154198935,26.4385546236816,29.3393747981948,50,67.767630106666,71.9779819056081,50,83.2791631712785,76.0020030569285],
[22.0963085023686,26.0282847031744,18.5148534416738,37.0739682305915,33.3333333333333,39.8656025611692,75.4531992731305,82.2302757407952,73.1664494934699,75]
];


letter_array = [
["","","","","F","B","","","f",""],
["","","","b","","","","","",""],
["","","","","","","","","",""],
["","","","","","","n","","",""],
["E","","","e","","","","","",""],
["","","","","","N","","","",""],
["","","","","","","","","",""],
["","","","","","","","","",""],
["","","","","","","","","",""],
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
