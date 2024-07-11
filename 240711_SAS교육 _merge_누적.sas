/* work.cn_transaction2 (multi), work.cn_customer (key-one) : accountid */
proc sort data=cn_transaction2 out=srt_trans;
	by accountid;
run;
proc sort data= cn_customer out=srt_cust ;
	by accountid;
run;

/** 매칭 건 : work.trans_cust
     거래데이터 중 고객정보 없는 경우 : work.trans_nocust
     고객 중 한번도 거래한 적이 없는 고객 : work.cust_notrans ***/

data trans_cust ;
	merge cn_transaction2 work.cn_customer ; 
	by accountid; *공통 모든 테이블에 존재, 반드시 사전 정렬;

run;

data trans_cust ;
	merge srt_trans (in=ina)
	         srt_cust (in=inb) ;
 
	by accountid;

	if ina = 1 and inb =1 ;

run;

data trans_cust trans_nocust cust_notrans ;
	merge srt_trans (in=ina)
	         srt_cust (in=inb) ;
 
	by accountid;

	if usa_area in ("0","1","2") then tax=amount*0.3;

	if ina = 1 and inb = 1 then output trans_cust;
	else if ina = 1 and inb = 0 then output trans_nocust ;
	else if ina = 0 and inb = 1 then output cust_notrans ;

run;


/* 총 수수료에 대한 누적 칼럼 
지금 CASE는 누적이 안되는 잘못된 예시*/
data acc1;
	set work.cn_transaction2 ;
	acc_fee = sum(acc_fee, fee) ;

	keep trans_date fee acc_fee ;
run ;


/* 총 수수료에 대한 누적 칼럼 
지금 CASE는 제대로 된 예시*/
data acc1;
	set work.cn_transaction2 ;
	retain acc_fee 0 ; *compile시점 초기값 0부터 시작, 규칙 적용;
	acc_fee = sum(acc_fee, fee) ; *할당 변수는 원래 reset이 되어야하나 상기된 retain함수로 인해 미적용;

	keep trans_date fee acc_fee ;
run ;

/* Sum 문장써서 누적 칼럼 생성*/
data acc1;
	set work.cn_transaction2 ;
	retain acc_fee 0 ;
	acc_fee = sum(acc_fee, fee) ;

	acc_fee2 + fee ;
	acc_count + 1 ; 

	keep trans_date fee acc_fee acc_fee2 acc_count;
run ;
/* 월별(그룹대상) 총 수수료(누적)
잘못된 예시.. 월별로 안됨
*/
data acc2;
	set work.cn_transaction2 ; 
	by trans_month ; *그룹대상 : 사전 정렬 필수 ;

	acc_fee + fee ;

	keep trans_month fee acc_fee ;
run ;

/* 월별(그룹대상) 총 수수료(누적)
제대로 된 예시
*/
data acc2;
	set work.cn_transaction2 ; 
	by trans_month ; *그룹대상 : 사전 정렬 필수 ;

	/* 그룹내 첫번째 관측치 : 누적변수에 대한 초기값 */
	if first.trans_month=1 then acc_fee=0 ; *머리속 변수는 where 로 수정안됨;

	/* 누적 */
	acc_fee + fee ;

	keep trans_month fee acc_fee ;
run ;

/* 월별(그룹대상) 총 수수료(누적)
관심사는 마지막 월 누적 수수료임
*/
data acc2;
	set work.cn_transaction2 ; 
	by trans_month ; *그룹대상 : 사전 정렬 필수 ;

	/* 그룹내 첫번째 관측치 : 누적변수에 대한 초기값 */
	if first.trans_month=1 then acc_fee=0 ; *머리속 변수는 where 로 수정안됨;

	/* 누적 */
	acc_fee + fee ;

	/* 그룹내 마지막 관측치 출력 */
	if last.trans_month=1 then output ;

	keep trans_month acc_fee ;
run ;

/* 월별(그룹대상) 총 수수료(누적)
*/
data acc2;
	set work.cn_transaction2 ; 
	by trans_month ;

	if first.trans_month=1 then do ;
			acc_fee = 0 ;
			acc_cnt = 0 ;
	end; *then do 다음에는 꼭 넣어주기;

	/* 누적 */
	acc_fee + fee ;
	acc_cnt + 1;

	/* 그룹내 마지막 관측치 출력 */
	if last.trans_month=1 then output ;

	keep trans_month acc_fee acc_cnt ;
run ;

proc means data=work.cn_transaction2 ;
	var fee;
run ;


proc means data=work.cn_transaction2 sum mean n;
	var fee;
run ;

proc means data=work.cn_transaction2 sum mean n;
	var fee; *분석칼럼;
	class trans_month ; *분류변수 : 사전 정렬 필요없음 N은 missing data 제외한 수;
run ;

proc means data=work.cn_transaction2 sum mean n;
	var fee; *분석칼럼;
	class trans_month ; *분류변수 : 사전 정렬 필요없음 N은 missing data 제외한 수;
	output out = work.trans_stats sum=total_fee mean=avg_fee n=count_fee;
run ;

proc means data=work.cn_transaction2 noprint;
	var fee; *분석칼럼;
	class trans_month ; *분류변수 : 사전 정렬 필요없음 N은 missing data 제외한 수;
	output out = work.trans_stats sum=total_fee mean=avg_fee n=count_fee;
run ;

proc means data=work.cn_transaction2 noprint nway; *noprint 기본테이블 보여줌 nway 0 없애고 보여줌;
	var fee; *분석칼럼;
	class trans_month ; *분류변수 : 사전 정렬 필요없음.;
	output out = work.trans_stats sum=total_fee mean=avg_fee n=count_fee;
run ;

proc means data=work.cn_transaction2 noprint nway;
	var fee; *분석칼럼;
	class trans_month grp_amt; *분류변수 : 사전 정렬 필요없음.;
	output out = work.trans_stats sum=total_fee mean=avg_fee n=count_fee;
run ;

data acc2;
	set work.cn_transaction2 ; 
	by trans_month ;

	if first.trans_month=1 then do ;
			acc_fee = 0 ;
			acc_cnt = 0 ;
	end; *then do 다음에는 꼭 넣어주기;

	/* 누적 */
	acc_fee + fee ;
	acc_cnt + 1;

	/* 그룹내 마지막 관측치 출력 */
	if last.trans_month=1 then output ;

	keep trans_month acc_fee acc_cnt ;
run ; *새로운 컬럼을 만들어서 추가 작업하기 위해서는 data step에서만 가능 예) 누적;

* 거래데이타 기준 총 거래금액이 높은 10명 고객(acountid) : trans_top10 ;


/* SAS에서 한 스텝에서 안되는 경우도 많음 */
proc sort data=work.cn_transaction2 out=sort_trans;
	by accountid;
run;
data trans_accid;
	set sort_trans;
	by accountid ; * 사전정렬 : first. / last. ;
	
	if first.accountid =1 then total_amt=0;
	total_amt + amount;
	if last.accountid=1;

	keep accountid total_amt ;
run;
proc sort data=trans_accid;
	by descending total_amt;
run;
data top10;
	set trans_accid (obs=10);
run;


* 거래데이타 기준 월별 총 거래금액이 높은 10명 고객(accountid) : trans_month_top10 ;

/* 2. 월/고객별 총 거래금액 */

proc sort data=work.cn_transaction2 out=sort_trans; *새로 만드는 경우임;
	by trans_month accountid ; *first. last. ;
run;
data trans_month_accountid;
	set work.sort_trans ;
	by trans_month accountid;

	if first.accountid=1 then total_amt=0;
	total_amt + amount ;
	if last.accountid=1;

	keep trans_month AccountID total_amt ;
run;
/* sort summary도 가능하며, means 로도 가능*/

proc sort data=trans_month_accountid; *덮어씌우는 경우임;
	by trans_month descending total_amt ;
run;
data month_top10; *월별 top10 뽑기;
	set trans_month_accountid;
	by trans_month;

	if first.trans_month=1 then cnt=0;
	cnt+1;

	if cnt <= 10;
run;

/*문자 숫자 변경 put 함수 
그 반대 경우도 가능*/

/*comma10.2 옷입혀주기*/
libname pg1 base 'C:\educ\FSI_SAS_SQL\prog1_v2\data'; /* dwdwdqdw */
libname pg2 v9 "C:\educ\FSI_SAS_SQL\prog2_v2\data";
libname fsi        'C:\educ\FSI_SAS_SQL';

/* 7장 전치 transpose 작업 */
proc print data= pg2.class_birthdate;
run;

proc transpose data= pg2.class_birthdate out=work.trans1;
	var height weight; *전치대상 칼럼;
run;

proc transpose data= pg2.class_birthdate out=work.trans1;
	var height weight;
	id name ; *전치한 값의 식별할 칼럼;
run;

proc transpose data= pg2.class_birthdate out=work.trans2;
	var height weight;
	by name ; *전치한 값의 식별할 칼럼;
run;
proc transpose data= pg2.class_birthdate out=work.trans2 (rename=(_name_=check col1=value ) );
	var height weight;
	by name ; *전치한 값의 식별할 칼럼;
run;

*고객의 월별 총 거래금액;
proc means data = work.cn_transaction2 noprint nway;
	class AccountID trans_month;
	var amount;
	output out=work.trans_stats sum=total;
run;

proc transpose data=trans_stats out=trans_wide prefix=month;
	by accountid ; *정렬;
	var total;
	id trans_month ; *전치할 값의 식별할 값 이거 중요;
run;
