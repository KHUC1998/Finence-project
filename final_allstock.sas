proc import 
out = aapl
datafile = "/home/u63347966/sasuser.v94/Final project/AAPL (2).csv"
dbms = csv replace;
getnames = yes;
datarow = 2;
run;

proc import
out = agm 
datafile = "/home/u63347966/sasuser.v94/Final project/AGM (2).csv"
dbms = csv replace;
getnames = yes;
datarow = 2;
run;


proc import 
out = frc
datafile = "/home/u63347966/sasuser.v94/Final project/FRC (1).csv" 
dbms = csv replace;
getnames = yes;
datarow = 2;
run;

proc import
out = kdp 
datafile = "/home/u63347966/sasuser.v94/Final project/KDP (1).csv"
dbms = csv replace;
getnames = yes;
datarow = 2;
run;



data aapl1;
set aapl;
ticker = "AAPL";
run;

data agm1;
set agm;
ticker = "AGM";
run;

data frc1;
set frc;
ticker = "FRC";
run;

data kdp1;
set kdp;
ticker = "KDP";
run;


data aapl1;
set aapl1;
rename 'Adj Close'n = adj_close;
run;

data agm1;
set agm1;
rename 'Adj Close'n = adj_close;
run;

data kdp1;
set kdp1;
rename 'Adj Close'n = adj_close;
run;

data frc1;
set frc1;
rename 'Adj Close'n = adj_close;
run;


data aapl1;
set aapl1;
ret = adj_close / lag(adj_close) -1;
run;

data agm1;
set agm1;
ret = adj_close / lag(adj_close) -1;
run;

data frc1;
set frc1;
ret = adj_close / lag(adj_close) -1;
run;

data kdp1;
set kdp1;
ret = adj_close / lag(adj_close) -1;
run;


data aapl1(drop = Open High Low Close Volume);
set aapl1;
shrout = 10;
run;

data agm1(drop = Open High Low Close Volume);
set agm1;
shrout = 100;
run;

data frc1(drop = Open High Low Close Volume);
set frc1;
shrout = 200;
run;

data kdp1(drop = Open High Low Close Volume);
set kdp1;
shrout = 200;
run;


data portfolio;
set aapl1 agm1 frc1 kdp1;
run;

data portfolio;
set portfolio;
calc_market_cap = adj_close * shrout;
run;

proc sort data = portfolio;
by date;
run;

proc sql;
  create table cmc_sum as
  select date, sum(calc_market_cap) as total_cmc
  from portfolio
  group by date;
quit;

data portfolio;
merge portfolio cmc_sum;
by date;
run;

data portfolio;
set portfolio;
calc_weight = calc_market_cap / total_cmc;
run;

proc sql;
create table daily_return as 
select date, sum(ret * calc_weight) as daily_return
from portfolio
group by date;
quit;

proc means data = daily_return;
var daily_return;
output out = portfolio_stat mean = std = min = max = n = /autoname;
run;

proc sql;
create table down as
select n(daily_return) as obs, daily_return - mean(daily_return) as downside
from daily_return;
quit;

proc sql;
create table downside_risk as
select sqrt(sum(downside*downside)/(obs-1)) as semidiviation
from down
where downside le 0;
quit;

data geo;
set daily_return;
return_1 = daily_return+1;
run;

proc univariate data = geo noprint;
var return_1;
output out=stats geomean=gm;
run;

proc univariate data = daily_return;
var daily_return;
run;

proc gchart data = daily_return;
vbar daily_return;
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
merge portfolio_stat tbill_stat;
run;

data sf_sharpe_ratio;
set ratio;
acceptable_rate = 0.001;
cv = daily_return_StdDev / abs(daily_return_Mean);
sf_ratio = (daily_return_Mean - acceptable_rate)/daily_return_StdDev;
sharpe_ratio = (daily_return_Mean - t_dailyreturn_Mean)/daily_return_StdDev;
SFProbability = probnorm(-sf_ratio);
run;