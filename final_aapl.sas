proc import 
out = aapl
datafile = "/home/u63347966/sasuser.v94/Final project/AAPL (2).csv"
dbms = csv replace;
getnames = yes;
datarow = 2;
run;

data work.aapl1;
set aapl;
rename 'Adj Close'n = adj_close;
run;


proc sort data = aapl1;
by date;
run;

data aapl1;
set aapl1;
aapl_return = adj_close/lag(adj_close) - 1;
run;

proc contents data = aapl1;
run;


proc means data = aapl1;
var aapl_return;
output out = aapl_stat mean = std = /autoname;
run;

proc univariate data=aapl1 all;
var aapl_return;
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
merge aapl_stat tbill_stat;
run;

proc contents data = ratio;
run;

data ratio_sf_sharpe;
set ratio;
cv=aapl_return_StdDev/aapl_return_Mean;
acceptable_rate=0.03/365;/*I assume the annual acceptable rate is 0.03*/
sf_ratio=(aapl_return_Mean-acceptable_rate)/aapl_return_StdDev;
sharpe_ratio=(aapl_return_Mean- t_dailyreturn_Mean)/aapl_return_StdDev;
SFprobability=probnorm(-sf_ratio);
run;


