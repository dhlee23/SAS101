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

*���� �� �ŷ��ݾ��� ���� 10�� ��(accountid);

data trans_month_top10;
	set work.cn_transaction2 ;

	keep trans_month AccountID amount ;
run;