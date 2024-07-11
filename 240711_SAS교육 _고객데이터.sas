libname pg1 base 'C:\educ\FSI_SAS_SQL\prog1_v2\data'; /* dwdwdqdw */
libname pg2 v9 "C:\educ\FSI_SAS_SQL\prog2_v2";
libname fsi        'C:\educ\FSI_SAS_SQL';

/* ���̺� ���� ����/ �� �κ� Ȯ�� */
proc contents data =  fsi.customer varnum;
run;
proc print data=fsi.customer (obs=10);
run;

/* 1. ���� ���� (��) */
proc freq data=fsi.customer ;
	where accountid is not null ; /* Ư��������  */
	tables gender ;
run;

/* 4. �ſ����� ���� (�����跮)  */
proc means data=fsi.customer ;
	where accountid ^= . ; /* �񱳿�����  */
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

/* ���ο� �� ���̺� ����
proc step�� select���� ���.data �ҷ� ��븸 ��*/
data work.cn_customer ;
	set fsi.customer;
	where AccountID is not null ;

	age_2024 = int( yrdif(dob, today() ) ) ; /*������ ���ϴ� ��*/
	usa_Area = substr(put(zip, z5.), 1, 1) ; /*put() ���ڿ� �ٲ�, 5�ڸ������̸� �տ� ���ڸ��� ��� 0���� ä��)*/

	if married = "M" then married_YN = 1;
	else married_YN=0;
	
	length grp_cs $ 6 ;
	if creditscore >= 700 then grp_cs = "High";
	else if 625 < creditscore < 700 then grp_cs = "Middle";
	else grp_cs = "Low";

	drop firstname middlename lastname ;
	format dob yymmdd10. ; /*��¥������ ����*/

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

/* ���ǿ� ���� ó��*/
