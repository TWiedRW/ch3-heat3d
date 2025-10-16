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

proc contents data=work.results; run;  /* Check the imported dataset structure */    
*proc print data=work.results (obs=10); run;  /* Print first 10 observations to verify data */


ods word file="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_sas\q2-analysis.docx" ;
/* Signed Error */
proc glimmix data=work.results plots=residualpanel  method=RSPL;
    class block user_id set media pair_id;
    model q2_signed_error = set media pair_id set*pair_id  / solution;
    random user_id / subject = block type=cs;
    parms (1)(204.8)(351.6);
    lsmeans set media pair_id set*pair_id / diff adjust=tukey ilink cl;
    nloptions tech=newrap;
    ods output lsmeans=lsmeans diffs=diffs;
run;

proc export data=lsmeans
    outfile="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_data\q2_signed_error_lsmeans.csv"
    dbms=csv
    replace;
run;

proc export data=diffs
    outfile="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_data\q2_signed_error_diffs.csv"
    dbms=csv
    replace;
run;

/* Abs Error */
proc glimmix data=work.results plots=residualpanel(ilink) method=laplace;
    class block user_id set media pair_id;
    model q2_abs_error = set media pair_id  / solution dist=gamma link=log;
    random intercept user_id / subject = block;
    parms (0.001575)(0.381)(0.7658);
    lsmeans set media pair_id / diff adjust=tukey ilink cl;
    nloptions tech=quanew;
    ods output lsmeans=lsmeans diffs=diffs;
run;

proc export data=lsmeans
    outfile="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_data\q2_abs_error_lsmeans.csv"
    dbms=csv
    replace;
run;

proc export data=diffs
    outfile="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_data\q2_abs_error_diffs.csv"
    dbms=csv
    replace;    
run;

/* Error Rate */
proc glimmix data=work.results plots=residualpanel(ilink) method=laplace;
    class block user_id set media pair_id;
    model q2_error_rate = set media pair_id  / solution dist=gamma link=log;
    random intercept user_id / subject = block;
    parms (0.001575)(0.381)(0.7658);
    lsmeans set media pair_id / diff adjust=tukey cl ilink;
    nloptions tech=quanew;
    ods output lsmeans=lsmeans diffs=diffs;
run;

proc export data=lsmeans
    outfile="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_data\q2_error_rate_lsmeans.csv"
    dbms=csv
    replace;
run;

proc export data=diffs
    outfile="C:\Users\cwied\OneDrive - University of Nebraska-Lincoln\4 - Obsidian Vault\Research\dissertation\ch3-heat3d\writeups\_data\q2_error_rate_diffs.csv"
    dbms=csv
    replace;
run;

ods word close;