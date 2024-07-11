/* work.cn_transaction2 (multi), work.cn_customer (key-one) : accountid */
proc sort data=cn_transaction2 out=srt_trans;
	by accountid;
run;
proc sort data= cn_customer out=srt_cust ;
	by accountid;
run;

/** ��Ī �� : work.trans_cust
     �ŷ������� �� ������ ���� ��� : work.trans_nocust
     �� �� �ѹ��� �ŷ��� ���� ���� �� : work.cust_notrans ***/

data trans_cust ;
	merge cn_transaction2 work.cn_customer ; 
	by accountid; *���� ��� ���̺� ����, �ݵ�� ���� ����;

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


/* �� �����ῡ ���� ���� Į�� 
���� CASE�� ������ �ȵǴ� �߸��� ����*/
data acc1;
	set work.cn_transaction2 ;
	acc_fee = sum(acc_fee, fee) ;

	keep trans_date fee acc_fee ;
run ;


/* �� �����ῡ ���� ���� Į�� 
���� CASE�� ����� �� ����*/
data acc1;
	set work.cn_transaction2 ;
	retain acc_fee 0 ; *compile���� �ʱⰪ 0���� ����, ��Ģ ����;
	acc_fee = sum(acc_fee, fee) ; *�Ҵ� ������ ���� reset�� �Ǿ���ϳ� ���� retain�Լ��� ���� ������;

	keep trans_date fee acc_fee ;
run ;

/* Sum ����Ἥ ���� Į�� ����*/
data acc1;
	set work.cn_transaction2 ;
	retain acc_fee 0 ;
	acc_fee = sum(acc_fee, fee) ;

	acc_fee2 + fee ;
	acc_count + 1 ; 

	keep trans_date fee acc_fee acc_fee2 acc_count;
run ;
/* ����(�׷���) �� ������(����)
�߸��� ����.. ������ �ȵ�
*/
data acc2;
	set work.cn_transaction2 ; 
	by trans_month ; *�׷��� : ���� ���� �ʼ� ;

	acc_fee + fee ;

	keep trans_month fee acc_fee ;
run ;

/* ����(�׷���) �� ������(����)
����� �� ����
*/
data acc2;
	set work.cn_transaction2 ; 
	by trans_month ; *�׷��� : ���� ���� �ʼ� ;

	/* �׷쳻 ù��° ����ġ : ���������� ���� �ʱⰪ */
	if first.trans_month=1 then acc_fee=0 ; *�Ӹ��� ������ where �� �����ȵ�;

	/* ���� */
	acc_fee + fee ;

	keep trans_month fee acc_fee ;
run ;

/* ����(�׷���) �� ������(����)
���ɻ�� ������ �� ���� ��������
*/
data acc2;
	set work.cn_transaction2 ; 
	by trans_month ; *�׷��� : ���� ���� �ʼ� ;

	/* �׷쳻 ù��° ����ġ : ���������� ���� �ʱⰪ */
	if first.trans_month=1 then acc_fee=0 ; *�Ӹ��� ������ where �� �����ȵ�;

	/* ���� */
	acc_fee + fee ;

	/* �׷쳻 ������ ����ġ ��� */
	if last.trans_month=1 then output ;

	keep trans_month acc_fee ;
run ;

/* ����(�׷���) �� ������(����)
*/
data acc2;
	set work.cn_transaction2 ; 
	by trans_month ;

	if first.trans_month=1 then do ;
			acc_fee = 0 ;
			acc_cnt = 0 ;
	end; *then do �������� �� �־��ֱ�;

	/* ���� */
	acc_fee + fee ;
	acc_cnt + 1;

	/* �׷쳻 ������ ����ġ ��� */
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
	var fee; *�м�Į��;
	class trans_month ; *�з����� : ���� ���� �ʿ���� N�� missing data ������ ��;
run ;

proc means data=work.cn_transaction2 sum mean n;
	var fee; *�м�Į��;
	class trans_month ; *�з����� : ���� ���� �ʿ���� N�� missing data ������ ��;
	output out = work.trans_stats sum=total_fee mean=avg_fee n=count_fee;
run ;

proc means data=work.cn_transaction2 noprint;
	var fee; *�м�Į��;
	class trans_month ; *�з����� : ���� ���� �ʿ���� N�� missing data ������ ��;
	output out = work.trans_stats sum=total_fee mean=avg_fee n=count_fee;
run ;

proc means data=work.cn_transaction2 noprint nway; *noprint �⺻���̺� ������ nway 0 ���ְ� ������;
	var fee; *�м�Į��;
	class trans_month ; *�з����� : ���� ���� �ʿ����.;
	output out = work.trans_stats sum=total_fee mean=avg_fee n=count_fee;
run ;

proc means data=work.cn_transaction2 noprint nway;
	var fee; *�м�Į��;
	class trans_month grp_amt; *�з����� : ���� ���� �ʿ����.;
	output out = work.trans_stats sum=total_fee mean=avg_fee n=count_fee;
run ;

data acc2;
	set work.cn_transaction2 ; 
	by trans_month ;

	if first.trans_month=1 then do ;
			acc_fee = 0 ;
			acc_cnt = 0 ;
	end; *then do �������� �� �־��ֱ�;

	/* ���� */
	acc_fee + fee ;
	acc_cnt + 1;

	/* �׷쳻 ������ ����ġ ��� */
	if last.trans_month=1 then output ;

	keep trans_month acc_fee acc_cnt ;
run ; *���ο� �÷��� ���� �߰� �۾��ϱ� ���ؼ��� data step������ ���� ��) ����;

* �ŷ�����Ÿ ���� �� �ŷ��ݾ��� ���� 10�� ��(acountid) : trans_top10 ;


/* SAS���� �� ���ܿ��� �ȵǴ� ��쵵 ���� */
proc sort data=work.cn_transaction2 out=sort_trans;
	by accountid;
run;
data trans_accid;
	set sort_trans;
	by accountid ; * �������� : first. / last. ;
	
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


* �ŷ�����Ÿ ���� ���� �� �ŷ��ݾ��� ���� 10�� ��(accountid) : trans_month_top10 ;

/* 2. ��/���� �� �ŷ��ݾ� */

proc sort data=work.cn_transaction2 out=sort_trans; *���� ����� �����;
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
/* sort summary�� �����ϸ�, means �ε� ����*/

proc sort data=trans_month_accountid; *������ �����;
	by trans_month descending total_amt ;
run;
data month_top10; *���� top10 �̱�;
	set trans_month_accountid;
	by trans_month;

	if first.trans_month=1 then cnt=0;
	cnt+1;

	if cnt <= 10;
run;

/*���� ���� ���� put �Լ� 
�� �ݴ� ��쵵 ����*/

/*comma10.2 �������ֱ�*/
libname pg1 base 'C:\educ\FSI_SAS_SQL\prog1_v2\data'; /* dwdwdqdw */
libname pg2 v9 "C:\educ\FSI_SAS_SQL\prog2_v2\data";
libname fsi        'C:\educ\FSI_SAS_SQL';

/* 7�� ��ġ transpose �۾� */
proc print data= pg2.class_birthdate;
run;

proc transpose data= pg2.class_birthdate out=work.trans1;
	var height weight; *��ġ��� Į��;
run;

proc transpose data= pg2.class_birthdate out=work.trans1;
	var height weight;
	id name ; *��ġ�� ���� �ĺ��� Į��;
run;

proc transpose data= pg2.class_birthdate out=work.trans2;
	var height weight;
	by name ; *��ġ�� ���� �ĺ��� Į��;
run;
proc transpose data= pg2.class_birthdate out=work.trans2 (rename=(_name_=check col1=value ) );
	var height weight;
	by name ; *��ġ�� ���� �ĺ��� Į��;
run;

*���� ���� �� �ŷ��ݾ�;
proc means data = work.cn_transaction2 noprint nway;
	class AccountID trans_month;
	var amount;
	output out=work.trans_stats sum=total;
run;

proc transpose data=trans_stats out=trans_wide prefix=month;
	by accountid ; *����;
	var total;
	id trans_month ; *��ġ�� ���� �ĺ��� �� �̰� �߿�;
run;
