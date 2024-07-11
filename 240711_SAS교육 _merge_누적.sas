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

*월별 총 거래금액이 높은 10명 고객(accountid);

data trans_month_top10;
	set work.cn_transaction2 ;

	keep trans_month AccountID amount ;
run;