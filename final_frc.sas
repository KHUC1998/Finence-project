proc import 
out = FRC
datafile = "/home/u63347966/sasuser.v94/Final project/FRC (1).csv"
dbms = csv replace;
getnames = yes;
datarow = 2;
run;

data work.frc1;
set frc;
rename 'Adj Close'n = adj_close;
run;


proc sort data = frc1;
by date;
run;

data frc1;
set frc1;
frc_return = adj_close/lag(adj_close) - 1;
run;

proc contents data = frc1;
run;


proc means data = frc1;
var frc_return;
output out = frc_stat mean = std = /autoname;
run;

proc univariate data=frc1 all;
var frc_return;
run;

proc import 
out = riskfree
datafile = "/home/u63347966/sasuser.v94/Final project/daily-treasury-rates (1).csv"
dbms = csv replace;
getnames = yes;
datarow = 2;
run;

data work.riskfree1;
set work.riskfree;
rename 'Date'n = new_date;
rename '1 Mo'n = bc_1month;
run; 

data riskfree1;
set riskfree1;
Date = put(new_date, yymmdd10.);
format Date yymmdd10.;
t_dailyreturn = bc_1month/100/365;
run;

proc contents data = riskfree1;
run;

proc means data = riskfree1;
var t_dailyreturn;
output out = tbill_stat (drop = _freq_ _type_) mean = /autoname;
run;

data ratio;
merge frc_stat tbill_stat;
run;

proc contents data = ratio;
run;

data ratio_sf_sharpe;
set ratio;
cv=frc_return_StdDev/frc_return_Mean;
acceptable_rate=0.03/365;/*I assume the annual acceptable rate is 0.03*/
sf_ratio=(frc_return_Mean-acceptable_rate)/frc_return_StdDev;
sharpe_ratio=(frc_return_Mean- t_dailyreturn_Mean)/frc_return_StdDev;
SFprobability=probnorm(-sf_ratio);
run;

