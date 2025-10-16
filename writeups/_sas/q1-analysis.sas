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

*proc contents data=work.results; run;  /* Check the imported dataset structure */    
*proc print data=work.results (obs=10); run;  /* Print first 10 observations to verify data */

/* Right or wrong */
ods pdf file="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_sas\q1-analysis.pdf";
proc glimmix data=work.results pconv=1e-6 method=laplace;
    where set ^= "practice";
    class block user_id set media pair_id;
    model q1 = set|media|pair_id  / solution dist=binomial link=logit;
    *random intercept user_id  / subject=block;
    lsmeans set*media*pair_id / diff adjust=tukey cl;
    nloptions gconv=1e-6 maxiter=100;
    ods output lsmeans=lsmeans diffs=diffs;
run;
ods pdf close;

proc export data=lsmeans
    outfile="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_sas\q1-lsmeans.csv"
    dbms=csv
    replace;
run;

proc export data=diffs
    outfile="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_sas\q1-diffs.csv"
    dbms=csv
    replace;
run;    


/*
- Run without wp term and see if it runs
- Try without random effects
- Overdispersion causes type I error rate to inflate, if no significant interaction can be sure its not significant
- Try PL, give laplace help by supplying starting values for variance components
*/