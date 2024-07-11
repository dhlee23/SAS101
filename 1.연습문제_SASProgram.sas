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
data CN_Customer;
   set fsi.customer;
   where accountid is not null;

   format dob yymmdd10. income creditscore comma10. ;

   age_Y2024 = year(today()) - year(dob);
   if  age_y2024 >=15 and age_y2024 <= 100;

   length usa_area $ 1 full_name $ 50;
   usa_area  = substr( put(zip,z5.) ,1,1) ;
   full_name = catx(" ", lastname,",", firstname,middlename);

   if married = 'M' then married_yn=1;
   else married_yn=0;

   length GRP_CS $ 6;
   if creditscore >= 700 then GRP_CS = "High";
   else if 625 < creditscore < 700 then GRP_CS = "Middle";
   else GRP_CS = "Low";

   drop FirstName MiddleName LastName Race Married Street: stateid userid ;
   label age_y2024 = "기준년도 나이" usa_area="미국지역(주)" ;
run;
proc sort data=CN_Customer ;
   by usa_area descending creditscore ;
run;

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
 proc freq data=fsi.transaction2 nlevels order=freq;
    where year(trans_Date)= 2018 and accountid is not null;
    tables MerchantID ;
run;
*2.4. 거래금액 분포;
 proc means data=fsi.transaction2 n min q1 median mean q3 max maxdec=2;
    where year(trans_Date)= 2018 and accountid is not null;
    var amount ;
run;

* 새로운 거래 테이블 생성 : WORK.CN_TRANSACTION2;
data CN_transaction2;
   set fsi.transaction2;
   where year(trans_Date)= 2018 and  accountid is not null;
   
   trans_month = month(trans_date);
   trans_weekday = weekday(trans_date);
   fee = amount * 0.03;

   length grp_amt $ 1;
   if 20<= amount <= 90 then do;
      grp_amt='M'; point= amount*0.01;
   end;
   else if amount > 90 then do;
      grp_amt='H'; point= amount*0.03;
   end;
   else do;
      grp_amt='L'; point= 0;
   end;

   format amount fee point comma10.2;
   keep Trans_Date MerchantID AccountID Amount trans_month trans_weekday fee grp_amt point;
run;


/***********************************************
Step3. 분석테이블 (거래/고객 가로 결합)
***********************************************/
proc sort data=work.cn_transaction2 out=srt_trans2;
   by AccountID ;
run;
proc sort data=work.cn_customer out=srt_cust;
   by AccountID;
run;

data work.mt_trans_cust ;
   merge srt_trans2 (in=t) srt_cust (in=c);
   by accountid;

   if t=1 and c=1 ;
 
        if usa_area in ('0','1','9')    then state_Tax=amount*0.3;
   else if usa_area in ('4','5','6','8')  then state_Tax=amount*0.2;
   else if usa_area in ('3','7')     then state_Tax=amount*0.1;
run;

/**[참고]  매칭 건 및 매칭되지 않는 건 확인 작업 **/
data work.mt_trans_cust trans_nocust cust_notrans;
   merge srt_trans2 (in=t) srt_cust (in=c);
   by accountid;
 
        if usa_area in (0,1,9)   then state_Tax=amount*0.3;
   else if usa_area in (4,5,6,8) then state_Tax=amount*0.2;
   else if usa_area in (3,7)     then state_Tax=amount*0.1;

   if t=1 and c=1 then output mt_Trans_cust;
   else if t=1 and c=0 then output trans_nocust ;
   else if t=0 and c=1 then output cust_notrans;
run;


/***********************************************
Step4. 고객의 거래 분석
***********************************************/
*4.1. 거래월/지역 별 요약 테이블 생성;
proc means data=mt_trans_cust noprint ;
   class trans_month usa_area ;
   var amount;
   output out=work.smy_month_area sum=amount_total mean=amount_mean  n=trans_count;
run;
* 시각화 : 막대선 그래프;
proc sgplot data=work.smy_month_area ;
   where _type_ = 2; *월별 요약된 부분만 필터링;
   vbar trans_month / response= amount_mean stat=mean ;   
   vline trans_month / response=trans_count y2axis;
run;


*4.2. 고객의 월별 거래건수 및 인보이스 (거래금액-수수료) 금액 요약 테이블 생성;
*1) 그룹내 요약;
proc sort data=mt_trans_cust out=tmp_cust_sort;
   by customerid trans_month ;
run;
data smy_cust;
   set tmp_cust_sort;
   by customerid trans_month;
   invoice = sum(amount,-1*fee);

   if first.trans_month=1 then do;
      cust_cnt = 0 ; cust_total=0;
   end;
   cust_cnt + 1;
   cust_total+ invoice;
   if last.trans_month=1;

   keep customerid trans_month cust_cnt cust_total;
   format cust_total comma10.2;
run;
*2) 전치 작업 : 하나의 칼럼을 여러 칼럼으로 분할;
proc transpose data=smy_cust out=CUST_MNT_AMT prefix=Month_ ;
   var cust_total; 
   by customerid;
   id trans_month ;
run;   



