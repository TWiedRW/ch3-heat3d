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
    q2_error_rate = abs(user_slider - 100*true_ratio) / (100*true_ratio);
    where set ^= "practice" & pair_id ^= 5 & q1_correct = "TRUE";
run;

proc contents data=work.results; run;  /* Check the imported dataset structure */    
*proc print data=work.results (obs=10); run;  /* Print first 10 observations to verify data */


ods word file="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_sas\q2-analysis.docx" ;
/* Signed Error */
proc glimmix data=work.results plots=residualpanel;
    class block user_id set media pair_id;
    model q2_signed_error = set|media|pair_id  / solution;
    random block;
    random block*user_id;
    random block*user_id*set*media;
    lsmeans set|media|pair_id / diff adjust=tukey ilink cl;
    nloptions tech=newrap;
    ods output lsmeans=lsmeans diffs=diffs;
run;

proc export data=lsmeans
    outfile="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_data\q2_signed_error_lsmeans.csv"
    dbms=csv
    replace;
run;

proc export data=diffs
    outfile="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_data\q2_signed_error_diffs.csv"
    dbms=csv
    replace;
run;

/* Abs Error */
proc glimmix data=work.results plots=residualpanel(ilink) method=laplace;
    class block user_id set media pair_id;
    model q2_abs_error = set|media|pair_id  / solution dist=gamma link=log;
    random block;
    random block*user_id;
    random block*user_id*set*media;
    lsmeans set|media|pair_id / diff adjust=tukey ilink cl;
    nloptions tech=quanew;
    ods output lsmeans=lsmeans diffs=diffs;
run;

proc export data=lsmeans
    outfile="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_data\q2_abs_error_lsmeans.csv"
    dbms=csv
    replace;
run;

proc export data=diffs
    outfile="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_data\q2_abs_error_diffs.csv"
    dbms=csv
    replace;    
run;

/* Error Rate */
proc glimmix data=work.results plots=residualpanel(ilink) method=laplace;
    class block user_id set media pair_id;
    model q2_error_rate = set|media|pair_id  / solution dist=gamma link=log;
    random block;
    random block*user_id;
    random block*user_id*set*media;
    lsmeans set|media|pair_id / diff adjust=tukey cl ilink;
    nloptions tech=quanew;
    ods output lsmeans=lsmeans diffs=diffs;
run;

proc export data=lsmeans
    outfile="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_data\q2_error_rate_lsmeans.csv"
    dbms=csv
    replace;
run;

proc export data=diffs
    outfile="C:\Users\twied\Documents\R Directory\dissertation\ch3-heat3d\writeups\_data\q2_error_rate_diffs.csv"
    dbms=csv
    replace;
run;

ods word close;