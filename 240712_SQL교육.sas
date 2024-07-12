libname fsi 'C:\educ\FSI_SAS_SQL';
libname sq "C:\educ\FSI_SAS_SQL\sql_m6\data" ;

proc sql ;

	describe table fsi.customer ;
	select * 
		from fsi.customer (obs=10);

quit ;


/* 1. �� ����Ÿ ���� */
proc sql inobs=20 ; *input ����;

	select accountid, gender, dob, married, zip, creditscore
		from fsi.customer
		where accountid is not null and employed= 'N'
		order by creditscore desc
;

quit;

proc sql outobs=20 number; *output ����;

	select accountid, gender, dob, married, zip, creditscore
		from fsi.customer
		where accountid is not null and employed= 'N'
		order by creditscore desc, 3 desc
;

quit;

proc sql outobs=20 number; *output ����;

	select accountid, gender, dob format=yymmdd10., married, zip, creditscore
			, intck('year', dob, today()) as age_2024 /* �ܼ� �⵵ ���� (������)*/
			, intck('year', dob, today(), 'c') as age_2024_2 /* ���� �⵵ ���� (������)*/
		from fsi.customer
		where accountid is not null and employed= 'N'
		order by creditscore desc, 3 desc
;

quit;

proc sql outobs=20 number; *output ����;
	
	select accountid, gender, dob format=yymmdd10., married, zip, creditscore
			, intck('year', dob, today()) as age_2024 /* �ܼ� �⵵ ���� (������)*/
			, intck('year', dob, today(), 'c') as age_2024_2 /* ���� �⵵ ���� (������)*/
			, substr( put(zip, z5.) , 1,1) as usa_area /* put�� �÷��� ���� ��ü�� �ٲ���... format�� �ܼ� ���̴� ���¸� ����*/
			, case
				when married = 'M' then 1 /* ���ǿ� ���� �ܼ� ���� ����*/
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

proc sql ; *output ����;
	create table work.cn_Customer as 
	select accountid, gender, dob format=yymmdd10., married, zip, creditscore
			, intck('year', dob, today()) as age_2024 /* �ܼ� �⵵ ���� (������)*/
			, intck('year', dob, today(), 'c') as age_2024_2 /* ���� �⵵ ���� (������)*/
			, substr( put(zip, z5.) , 1,1) as usa_area /* put�� �÷��� ���� ��ü�� �ٲ���... format�� �ܼ� ���̴� ���¸� ����*/
			, case
				when married = 'M' then 1 /* ���ǿ� ���� �ܼ� ���� ����*/
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


/*** 2. �ŷ����̺� --> ����� ���� ���̺� ���� */
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
	, /* �ݾ� 100 �̻� ���� Amt_YN : 1 or 0 */
	(amount >= 100) as amt_yn /*���� ���� ���� ���� �� ���*/

	from fsi.transaction2
	where year(trans_date) = 2018 and accountid is not null /*and calculated point > 100*/

;
quit;

proc sql ;
	select distinct merchantid /* ���� �� �ߺ�����*/
	from work.cn_transaction2
	end
;
quit;

/* ����ó�� select * �������� �ʿ��� ������ �����ͼ� distinct �ϱ�*/
proc sql ;
	create table m_list at
	select distinct * /* ���� �� �ߺ�����*/
	from work.cn_transaction2
end;

proc sql ;
	select count(merchantid) as a_cnt from work.cn_transaction2;
quit;

*�������� �� �ŷ��Ǽ�, �� �ŷ��ݾ�, �� ������;

*1. �Ǽ� ��� : 1) Ư�� Į���� �̽��� �ƴ� �Ǽ� : count(arg)
					 2) ���� �� : count(*)
					 3) ���� �Ǽ� : count(distinct col-name) ;


proc sql ;
	select count(merchantid) as a_cnt, count(*) as all_cnt from work.cn_transaction2; /* Missing data Ȯ�� ���*/
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

/* ������ ����*/

/* Cartesian Product
�߻������� ��� row�� ����
8 rows X 12 rows = 9 rows
overlap ���� ����
*/

proc sql; *�Ǽ� Ȯ��;
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
	select t.merchantid /* 3. ���� Į�� ���� */
	, t.total_fee, m.city, m.service
		from work.trans_summary2 as t inner join fsi.merchant as m/* 1. ���� ���� */
			on t.merchantid = m.merchantid /* 2. ��Ī ���� */
		where m.state = "NY"
	;
quit;
/* inner join : method 2 */
proc sql;
	create table work.prom_merchant_info as
	select t.merchantid /* 3. ���� Į�� ���� */
	, t.total_fee, m.city, m.service
		from work.trans_summary2 as t , fsi.merchant as m/* 1. ���� ���� */
		where t.merchantid = m.merchantid /* 2. ��Ī ���� */
			and m.state="NY"
	;
quit;

/* ������ ���̺�(fsi.merchant : 37 rows)�� 500�޷� �ʰ� ������ �Ѽ�����(31 rows)�� �߰� */
proc sql;
	create table work.merchant_fee500 as
	select m.merchantid /* 3. ���� Į�� ���� */
	, m.city, m.state, m.service, t.total_fee
		from fsi.merchant as m left join work.trans_summary2 as t /* 1. ���� ���� */
			on m.merchantid = t.merchantid /* 2. ��Ī ���� */
	;
quit;


/* ���θ��(�Ѽ����� 500 �ʰ�) �������� �ƴ� ������ ���� */
proc sql;
create table work.merchant_nonfee500 as
	select m.*
		from fsi.merchant as m left join work.trans_summary2 as t
			on m.merchantid = t.merchantid
		where t.merchantid is null
	;
quit;

