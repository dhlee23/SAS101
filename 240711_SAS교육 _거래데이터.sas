/* �ŷ� ����Ÿ ���� �۾�*/

proc contents data =  fsi.transaction2 varnum;
run;
proc print data=fsi.transaction2 (obs=10);
run;

proc freq data=fsi.transaction2 ;
	where accountid is not null ; /* Ư��������  */
	tables Trans_Date ;
run;

data work.cn_transaction2 ;
	set fsi.transaction2 ;
	where AccountID is not null and trans_date BETWEEN '2018-01-01' AND '2018-12-31';

	trans_month = month(trans_date);

run;


data transaction2 ;
	set fsi.transaction2 ;
	where year(trans_date)= 2018 and AccountID is not null;

	trans_month = month(trans_date) ;
	trans_weekday = weekday(trans_date) ;
	fee = amount*0.03 ;

	length grp_amt $ 1 ;
	if 20 <= amount <= 90 then do;
		grp_amt = "M" ;
		point = amount*0.01;
	end;
	else if amount > 90 then do ;
		grp_amt = "H" ; point = amount*0.03;
	end;
	else  do; 
		grp_amt = "L"; point = 0;
	end;

	keep trans_date trans_month trans_weekday MerchantID AccountID amount fee grp_amt point;
	format amount fee point comma10.2;
run;

/* COMPILE => PDV => EXEC */
 *������(���Ӱ� ������ �÷�)�� 300 �̻��� ��;
data trans2 ;
	set fsi.transaction2 ;
	where year(trans_date)= 2018 and AccountID is not null;*�Է����̺� �÷��� ���� ���� WHERE > IF ;
	
	wday = weekday(trans_date); *1(��)~7;
	fee = amount*0.03 ;

	if wday in (6,7,1) then wday_desc="�ָ�";
	else wday_desc="����"; 

	if fee >= 300 ; *���Ӱ� ������ �÷��� ���� ���� : IF ;
	
	drop TransactionID datetime Trans_Time ;

run; *�ڵ����; *�ڵ�����;

