/* Import CSV (DBMS=CSV). Use GETNAMES= to read header row; GUESSINGROWS to improve type detection */
proc import
     datafile="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_data\stat218fall2025.csv"
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
ods word file="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_sas\q1-analysis.docx";
proc glimmix data=work.results pconv=1e-6 method=laplace nobound;
    where set ^= "practice";
    class block user_id set media pair_id;
    model q1 = set|media|pair_id  / solution dist=binomial link=logit;
    random block;
    random block*user_id;
    random block*user_id*set*media;
    lsmeans set*media*pair_id  / diff adjust=tukey cl;
    parms (0)(3.1)(0.91);
    nloptions gconv=1e-6 maxiter=100;
    ods output lsmeans=lsmeans diffs=diffs;
run;
ods word close;

proc export data=lsmeans
    outfile="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_sas\q1-lsmeans.csv"
    dbms=csv
    replace;
run;

proc export data=diffs
    outfile="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_sas\q1-diffs.csv"
    dbms=csv
    replace;
run;    


/*
- Run without wp term and see if it runs
- Try without random effects
- Overdispersion causes type I error rate to inflate, if no significant interaction can be sure its not significant
- Try PL, give laplace help by supplying starting values for variance components
*/