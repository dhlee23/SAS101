libname pg1 base 'C:\educ\FSI_SAS_SQL\prog1_v2\data'; /* dwdwdqdw */
libname pg2 v9 "C:\educ\FSI_SAS_SQL\prog2_v2";
libname fsi        'C:\educ\FSI_SAS_SQL';

/* 테이블에 대한 설명/ 값 부분 확인 */
proc contents data =  fsi.customer varnum;
run;
proc print data=fsi.customer (obs=10);
run;

/* 1. 성별 분포 (빈도) */
proc freq data=fsi.customer ;
	where accountid is not null ; /* 특별연산자  */
	tables gender ;
run;

/* 4. 신용점수 분포 (요약통계량)  */
proc means data=fsi.customer ;
	where accountid ^= . ; /* 비교연산자  */
	var CreditScore ;
run;

proc sgplot data=fsi.customer ;
	where accountid ^= . ;
	histogram CreditScore ;
run;
proc sgplot data=fsi.customer ;
	where accountid ^= . ;
	*histogram CreditScore ;
	hbox CreditScore ;
run;

/* 새로운 고객 테이블 생성
proc step은 select문과 비슷.data 불러 사용만 함*/
data work.cn_customer ;
	set fsi.customer;
	where AccountID is not null ;

	age_2024 = int( yrdif(dob, today() ) ) ; /*만나이 구하는 법*/
	usa_Area = substr(put(zip, z5.), 1, 1) ; /*put() 문자열 바꿈, 5자리형식이며 앞에 빈자리인 경우 0으로 채움)*/

	if married = "M" then married_YN = 1;
	else married_YN=0;
	
	length grp_cs $ 6 ;
	if creditscore >= 700 then grp_cs = "High";
	else if 625 < creditscore < 700 then grp_cs = "Middle";
	else grp_cs = "Low";

	drop firstname middlename lastname ;
	format dob yymmdd10. ; /*날짜값으로 변경*/

run;

proc sort data=cn_customer ;
	by usa_area descending CreditScore ;
run ;


proc freq data=cn_customer;
	tables grp_cs;
run;

proc freq data=cn_customer;
	tables usa_area;
run;

proc freq data=cn_customer;
	tables married_YN;
run;
proc print data=cn_customer (obs=10);
run;
/**/

/* 조건에 따른 처리*/
