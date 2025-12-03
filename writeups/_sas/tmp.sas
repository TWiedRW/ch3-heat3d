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
    q2_error_rate = abs(user_slider - 100*true_ratio) / (100*true_ratio);
    where set ^= "practice" & pair_id ^= 5 & q1_correct = "TRUE";
run;

*proc contents data=work.results; run;  /* Check the imported dataset structure */    
*proc print data=work.results (obs=10); run;  /* Print first 10 observations to verify data */


/* Signed Error */
proc glimmix data=work.results plots=residualpanel(ilink)  method=RSPL;
    class block user_id set media pair_id;
    model q2_abs_error = set*media*pair_id / noint dist=gamma link=log s;
    random block;
    random user_id(block);
    random media*pair_id / subject=user_id(block);
    lsmeans set*media*pair_id / diff adjust=tukey ilink cl;
    nloptions tech=newrap;
run;

