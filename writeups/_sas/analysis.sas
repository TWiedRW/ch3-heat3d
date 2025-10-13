/* Import CSV (DBMS=CSV). Use GETNAMES= to read header row; GUESSINGROWS to improve type detection */
proc import
     datafile="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_data\stat218fall2025.csv"
     out= work.results
     dbms=csv
     replace;
     getnames=YES;
     guessingrows=32767;    /* increase to inspect many rows for correct types */
run;


data work.results;
    set work.results;
    if q1_correct = "TRUE" then q1 = 1;
    if q1_correct = "FALSE" then q1 = 0;
run;

proc contents data=work.results; run;  /* Check the imported dataset structure */    
proc print data=work.results (obs=10); run;  /* Print first 10 observations to verify data */

/* Right or wrong */
proc glimmix data=work.results method=laplace nofit;
    where set ^= "practice";
    class block user_id set media pair_id;
    model q1 = set|media|pair_id block block*user_id block*user_id*set*media / solution dist=binomial link=logit;
run;




data work.resultsq2;
    set work.results;
    where set NE "practice" and pair_id NE 5 and q1 = 1;
run;

/* Signed Error */
proc glimmix data=work.resultsq2 plots=residualpanel nobound nofit;
    class block user_id set media pair_id;
    model q2_signed_error = set|media|pair_id  / ddfm=satterthwaite;
    random block block*user_id block*user_id*set*media;
run;


/* Abs Error */
proc glimmix data=work.resultsq2 plots=residualpanel method=laplace nobound;
    class block user_id set media pair_id;
    model q2_cm_error = set|media|pair_id @2 ;
    random block block*user_id block*user_id*set*media;
run;