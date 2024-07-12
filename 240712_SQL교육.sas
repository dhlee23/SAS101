libname fsi 'C:\educ\FSI_SAS_SQL';
libname sq "C:\educ\FSI_SAS_SQL\sql_m6\data" ;

proc sql ;

	describe table fsi.customer ;
	select * 
		from fsi.customer (obs=10);

quit ;


/* 1. 고객 데이타 질의 */
proc sql inobs=20 ; *input 기준;

	select accountid, gender, dob, married, zip, creditscore
		from fsi.customer
		where accountid is not null and employed= 'N'
		order by creditscore desc
;

quit;

proc sql outobs=20 number; *output 기준;

	select accountid, gender, dob, married, zip, creditscore
		from fsi.customer
		where accountid is not null and employed= 'N'
		order by creditscore desc, 3 desc
;

quit;

proc sql outobs=20 number; *output 기준;

	select accountid, gender, dob format=yymmdd10., married, zip, creditscore
			, intck('year', dob, today()) as age_2024 /* 단순 년도 차이 (연나이)*/
			, intck('year', dob, today(), 'c') as age_2024_2 /* 실제 년도 차이 (만나이)*/
		from fsi.customer
		where accountid is not null and employed= 'N'
		order by creditscore desc, 3 desc
;

quit;

proc sql outobs=20 number; *output 기준;
	
	select accountid, gender, dob format=yymmdd10., married, zip, creditscore
			, intck('year', dob, today()) as age_2024 /* 단순 년도 차이 (연나이)*/
			, intck('year', dob, today(), 'c') as age_2024_2 /* 실제 년도 차이 (만나이)*/
			, substr( put(zip, z5.) , 1,1) as usa_area /* put은 컬럼의 형식 자체를 바꿔줌... format은 단순 보이는 형태만 변경*/
			, case
				when married = 'M' then 1 /* 조건에 따라 단순 값을 지정*/
				else 0
			end as m_yn
			, case 
				when creditscore is null then 'null'
				when creditscore >= 700 then 'High'
				when 625 < creditscore < 700 then 'Middle'
				else 'Low'
			end as grp_cs
		from fsi.customer
		where accountid is not null and 15 <= calculated age_2024 <= 100 
		order by usa_Area, grp_cs desc
;

quit;

proc sql ; *output 기준;
	create table work.cn_Customer as 
	select accountid, gender, dob format=yymmdd10., married, zip, creditscore
			, intck('year', dob, today()) as age_2024 /* 단순 년도 차이 (연나이)*/
			, intck('year', dob, today(), 'c') as age_2024_2 /* 실제 년도 차이 (만나이)*/
			, substr( put(zip, z5.) , 1,1) as usa_area /* put은 컬럼의 형식 자체를 바꿔줌... format은 단순 보이는 형태만 변경*/
			, case
				when married = 'M' then 1 /* 조건에 따라 단순 값을 지정*/
				else 0
			end as m_yn
			, case 
				when creditscore is null then 'null'
				when creditscore >= 700 then 'High'
				when 625 < creditscore < 700 then 'Middle'
				else 'Low'
			end as grp_cs
		from fsi.customer
		where accountid is not null and 15 <= calculated age_2024 <= 100 
		order by usa_Area, creditscore desc
;

quit;


/*** 2. 거래테이블 --> 사용자 정의 테이블 생성 */
proc sql ;
	* describe table fsi.transacton2 ;
	create table work.trans2 as

	select trans_date
	, month(trans_date) as trans_month
	, weekday(trans_date) as trans_weekday	
	, merchantid
	, accountid
	, amount
	, amount * 0.03 as fee format = comma10.2
	, case
		when 20 <= amount <= 90 then 'M'
		when amount > 90 then 'H'
		else 'L' 
	end as grp_amt
	, case
		when 20 <= amount <= 90 then amount*0.01
		when amount > 90 then amount*0.03
		else 0
	end as point
	, /* 금액 100 이상 여부 Amt_YN : 1 or 0 */
	(amount >= 100) as amt_yn /*더미 변수 생성 만들 때 사용*/

	from fsi.transaction2
	where year(trans_date) = 2018 and accountid is not null /*and calculated point > 100*/

;
quit;

proc sql ;
	select distinct merchantid /* 정렬 후 중복제거*/
	from work.cn_transaction2
	end
;
quit;

/* 지금처럼 select * 하지말고 필요한 쿼리만 가져와서 distinct 하기*/
proc sql ;
	create table m_list at
	select distinct * /* 정렬 후 중복제거*/
	from work.cn_transaction2
end;

proc sql ;
	select count(merchantid) as a_cnt from work.cn_transaction2;
quit;

*가맹정별 총 거래건수, 총 거래금액, 총 수수료;

*1. 건수 요약 : 1) 특정 칼럼의 미싱이 아닌 건수 : count(arg)
					 2) 행의 수 : count(*)
					 3) 값의 건수 : count(distinct col-name) ;


proc sql ;
	select count(merchantid) as a_cnt, count(*) as all_cnt from work.cn_transaction2; /* Missing data 확인 방법*/
quit;

proc sql ;
	select merchantid, count(merchantid) as a_cnt, count(*) as all_cnt, count(distinct merchantid) as mer_cnt
	, avg(amount) as avg_amount format=comma10.1
	, sum(fee) as total_fee format=comma10.1
	from work.cn_transaction2
	group by merchantid
	having calculated total_fee >= 500
	order by total_fee desc
;
quit;


proc sql ;

	describe table work.cn_transaction2 ;
	select * 
		from work.cn_transaction2 (obs=10);

quit ;

/* 데이터 조인*/

/* Cartesian Product
발생가능한 모든 row의 조합
8 rows X 12 rows = 9 rows
overlap 하지 않음
*/

proc sql; *건수 확인;
	select count(*) as cnt1, count(merchantid) as cnt2, count(distinct merchantid) as cnt3
		from fsi.merchant
	;
quit;

proc sql;
	/*create table work.prom_merchant_table;*/
	select *
		from work.trans_summary2 as t inner join fsi.merchant as m/* CP */
			on t.merchantid = m.merchantid
	;
quit;
/* inner join : method 1 */
proc sql;
	create table work.prom_merchant_info as
	select t.merchantid /* 3. 기준 칼럼 선택 */
	, t.total_fee, m.city, m.service
		from work.trans_summary2 as t inner join fsi.merchant as m/* 1. 조인 유형 */
			on t.merchantid = m.merchantid /* 2. 매칭 기준 */
		where m.state = "NY"
	;
quit;
/* inner join : method 2 */
proc sql;
	create table work.prom_merchant_info as
	select t.merchantid /* 3. 기준 칼럼 선택 */
	, t.total_fee, m.city, m.service
		from work.trans_summary2 as t , fsi.merchant as m/* 1. 조인 유형 */
		where t.merchantid = m.merchantid /* 2. 매칭 기준 */
			and m.state="NY"
	;
quit;

/* 가맹점 테이블(fsi.merchant : 37 rows)에 500달러 초과 가맹점 총수수료(31 rows)를 추가 */
proc sql;
	create table work.merchant_fee500 as
	select m.merchantid /* 3. 기준 칼럼 선택 */
	, m.city, m.state, m.service, t.total_fee
		from fsi.merchant as m left join work.trans_summary2 as t /* 1. 조인 유형 */
			on m.merchantid = t.merchantid /* 2. 매칭 기준 */
	;
quit;


/* 프로모션(총수수료 500 초과) 가맹점이 아닌 가맹점 추출 */
proc sql;
create table work.merchant_nonfee500 as
	select m.*
		from fsi.merchant as m left join work.trans_summary2 as t
			on m.merchantid = t.merchantid
		where t.merchantid is null
	;
quit;

