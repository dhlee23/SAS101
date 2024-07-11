libname fsi "C:\educ\FSI_SAS_SQL";

/***********************************************
Step1. 고객 데이터 탐색
  : AccountID가 존재하는 20~100세 고객
************************************************/
*1.1. 성별 분포;
 proc freq data=fsi.customer ;
    where accountid is not null;
    tables gender ;
run;
*1.4. 신용점수 분포;
proc means data=fsi.customer ;
    where accountid is not null;
	var CreditScore;
run;
proc sgplot data=fsi.customer ;
    where accountid is not null;
	histogram CreditScore / nbins=100;
	*hbox CreditScore ;
run;

* 새로운 고객 테이블 생성 : WORK.CN_CUSTOMER;
proc sql;
   create table CN_Customer as
   select accountid
           ,customerid
           ,catx(" ", lastname,",", firstname,middlename) as full_name
		   ,gender
		   ,dob format=yymmdd10.
		   ,year(today()) - year(dob) as age_y2024 '기준년도 나이'
		   ,employed
		   ,zip
		   ,substr( put(zip,z5.) ,1,1)  as usa_area label="미국지역(주)" 
		   ,case 
		       when married="M" then 1
			   else 0
		    end as married_yn
		   ,income format=comma10.
		   ,creditscore format=comma10.
		   ,case
		      when creditscore >= 700 then "High"
			  when 625 < creditscore < 700 then "Middle"
			  else 'Low'
		    end as grp_cs
      from fsi.customer
	  where accountid is not null and 15 <= calculated age_y2024 <= 100

      order by usa_area, creditscore desc;
quit;

*1.2 연령분포;
proc means data=work.cn_customer ;
   var age_y2024;
run;
proc sgplot data=cn_customer ;
   histogram age_y2024 ;
run;

/***********************************************
Step2. 거래 데이터 탐색
  : 2018년도 거래건 중 고객계좌ID가 결측이 아닌건
************************************************/
*2.1. 거래월별 분포;
 proc freq data=fsi.transaction2 ;
    where year(trans_Date)= 2018 and accountid is not null;
    tables trans_Date ;
	format trans_date monname.;
run;
*2.2. 거래 요일 별 분포;
 proc freq data=fsi.transaction2 ;
    where year(trans_Date)= 2018 and accountid is not null;
    tables trans_Date ;
	format trans_date weekday.;
run;
*2.3. 가맹점별 분포;
/*
 proc freq data=fsi.transaction2 nlevels order=freq;
    where year(trans_Date)= 2018 and accountid is not null;
    tables MerchantID ;
run; 
*/
proc sql;
   select MerchantID , count(*) as cnt
     from fsi.transaction2
     where year(trans_Date)= 2018 and accountid is not null

     group by MerchantID 
     order by cnt desc;
quit;
*2.4. 거래금액 분포;
 proc means data=fsi.transaction2 n min q1 median mean q3 max maxdec=2;
    where year(trans_Date)= 2018 and accountid is not null;
    var amount ;
run;
   
* 새로운 거래 테이블 생성 : WORK.CN_TRANSACTION2;
proc sql;
   create table cn_transaction2 as
   select trans_Date format=yymmdd10. 
           ,month(trans_date) as trans_month
		   ,weekday(trans_date) as trans_weekday
		   ,MerchantID, AccountID
		   ,amount format=comma10.2
		   ,amount * 0.03 as fee format=comma10.2
		   ,case
		      when 20<= amount <= 90 then "M"
			  when amount > 90 then "H"
			  else "L"
		    end as grp_amt
		   ,case
		      when 20<= amount <= 90 then amount*0.01
			  when amount > 90 then amount*0.03
			  else 0
		    end as point format=comma10.2
      from fsi.transaction2 
	  where year(trans_Date)= 2018 and  accountid is not null ;
quit;

/***********************************************
Step3. 분석테이블 (거래/고객 가로 결합)
***********************************************/

proc sql;
   create table work.mt_Trans_cust as
   select  t.*, c.gender, c.dob, c.age_y2024, c.usa_area, c.customerid, c.grp_Cs
            ,case
			   when c.usa_area in ('0','1','9')    then amount*0.3
			   when c.usa_area in ('4','5','6','8') then amount*0.2
			   when c.usa_area in ('3','7')      then amount*0.1
			 end as state_tax
       from  cn_transaction2 as t inner join work.cn_customer as c
	         on t.accountid = c.accountid ;
quit;

/**[참고]  매칭 건 및 매칭되지 않는 건 확인 작업 **/
proc sql;
   create table trans_nocust as
   select  t.* , c.accountid as accountid_chk, c.full_name
       from  cn_transaction2 as t left join work.cn_customer as c
	         on t.accountid = c.accountid 
       where c.accountid is null;
quit;


/***********************************************
Step4. 고객의 거래 분석
***********************************************/
*4.1. 거래월/지역 별 요약 테이블 생성;
proc sql;
   create table smy_month_area as
   select trans_month, usa_area, sum(amount) as amount_total, avg(amount) as amount_mean, count(amount) as trans_count 
     from mt_trans_cust
     group by trans_month, usa_area ;
quit;
* 시각화 : 막대선 그래프;
proc sgplot data=work.smy_month_area ;
   vbar trans_month / response= amount_mean stat=mean ;   
   vline trans_month / response=trans_count y2axis;
run;


*4.2. 고객의 월별 거래건수 및 인보이스 (거래금액-수수료) 금액 요약 테이블 생성;
*1) 그룹내 요약;
proc sql;
   create table work.smy_cust as
   select customerid, trans_month, sum( sum(amount,-1*fee) ) as cust_total, count(*) as cust_cnt
     from mt_trans_cust

	 group by 1,2;
quit;
*2) 전치 작업 : 하나의 칼럼을 여러 칼럼으로 분할;
proc transpose data=smy_cust out=CUST_MNT_AMT prefix=Month_ ;
   var cust_total; 
   by customerid;
   id trans_month ;
run;



