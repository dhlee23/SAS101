libname fsi "C:\educ\FSI_SAS_SQL";

/***********************************************
Step1. �� ������ Ž��
  : AccountID�� �����ϴ� 20~100�� ��
************************************************/
*1.1. ���� ����;
 proc freq data=fsi.customer ;
    where accountid is not null;
    tables gender ;
run;
*1.4. �ſ����� ����;
proc means data=fsi.customer ;
    where accountid is not null;
	var CreditScore;
run;
proc sgplot data=fsi.customer ;
    where accountid is not null;
	histogram CreditScore / nbins=100;
	*hbox CreditScore ;
run;

* ���ο� �� ���̺� ���� : WORK.CN_CUSTOMER;
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
   label age_y2024 = "���س⵵ ����" usa_area="�̱�����(��)" ;
run;
proc sort data=CN_Customer ;
   by usa_area descending creditscore ;
run;

*1.2 ���ɺ���;
proc means data=work.cn_customer ;
   var age_y2024;
run;
proc sgplot data=cn_customer ;
   histogram age_y2024 ;
run;

/***********************************************
Step2. �ŷ� ������ Ž��
  : 2018�⵵ �ŷ��� �� ������ID�� ������ �ƴѰ�
************************************************/
*2.1. �ŷ����� ����;
 proc freq data=fsi.transaction2 ;
    where year(trans_Date)= 2018 and accountid is not null;
    tables trans_Date ;
	format trans_date monname.;
run;
*2.2. �ŷ� ���� �� ����;
 proc freq data=fsi.transaction2 ;
    where year(trans_Date)= 2018 and accountid is not null;
    tables trans_Date ;
	format trans_date weekday.;
run;
*2.3. �������� ����;
 proc freq data=fsi.transaction2 nlevels order=freq;
    where year(trans_Date)= 2018 and accountid is not null;
    tables MerchantID ;
run;
*2.4. �ŷ��ݾ� ����;
 proc means data=fsi.transaction2 n min q1 median mean q3 max maxdec=2;
    where year(trans_Date)= 2018 and accountid is not null;
    var amount ;
run;

* ���ο� �ŷ� ���̺� ���� : WORK.CN_TRANSACTION2;
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
Step3. �м����̺� (�ŷ�/�� ���� ����)
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

/**[����]  ��Ī �� �� ��Ī���� �ʴ� �� Ȯ�� �۾� **/
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
Step4. ���� �ŷ� �м�
***********************************************/
*4.1. �ŷ���/���� �� ��� ���̺� ����;
proc means data=mt_trans_cust noprint ;
   class trans_month usa_area ;
   var amount;
   output out=work.smy_month_area sum=amount_total mean=amount_mean  n=trans_count;
run;
* �ð�ȭ : ���뼱 �׷���;
proc sgplot data=work.smy_month_area ;
   where _type_ = 2; *���� ���� �κи� ���͸�;
   vbar trans_month / response= amount_mean stat=mean ;   
   vline trans_month / response=trans_count y2axis;
run;


*4.2. ���� ���� �ŷ��Ǽ� �� �κ��̽� (�ŷ��ݾ�-������) �ݾ� ��� ���̺� ����;
*1) �׷쳻 ���;
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
*2) ��ġ �۾� : �ϳ��� Į���� ���� Į������ ����;
proc transpose data=smy_cust out=CUST_MNT_AMT prefix=Month_ ;
   var cust_total; 
   by customerid;
   id trans_month ;
run;   



