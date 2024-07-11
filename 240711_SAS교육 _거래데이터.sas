/* 거래 데이타 기준 작업*/

proc contents data =  fsi.transaction2 varnum;
run;
proc print data=fsi.transaction2 (obs=10);
run;

proc freq data=fsi.transaction2 ;
	where accountid is not null ; /* 특별연산자  */
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
 *수수료(새롭게 생성한 컬럼)가 300 이상인 건;
data trans2 ;
	set fsi.transaction2 ;
	where year(trans_date)= 2018 and AccountID is not null;*입력테이블 컬럼에 대한 조건 WHERE > IF ;
	
	wday = weekday(trans_date); *1(일)~7;
	fee = amount*0.03 ;

	if wday in (6,7,1) then wday_desc="주말"; *할당문장;
	else wday_desc="주중"; 

	if fee >= 300 ; *새롭게 생성된 컬럼에 대해 조건 : IF ;
	
	drop TransactionID datetime Trans_Time ;

run; *자동출력; *자동리턴;

data trans_fee_high trans_fee_low ; *출력데이터;
	set fsi.transaction2 ; *입력데이터;
	where year(trans_date)= 2018 and AccountID is not null ;

	fee = amount*0.03 ;

	if fee >= 300 then output; *pdv 머릿속 내용을 출력데이터에 찍어라; 

run; *자동출력; *자동리턴;


data trans_fee_high trans_fee_low ; *출력데이터;
	set fsi.transaction2 ; *입력데이터;
	where year(trans_date)= 2018 and AccountID is not null ;

	fee = amount*0.03 ;

	if fee >= 300 then output trans_fee_high ; *수동출력;
	else if fee <= 30 then output trans_fee_low ;

run; *자동출력(X); *자동리턴; *data step에 output이 있으면 수동출력이 되어 pdv 공간의 내용을 출력공간으로 내보내라 역할을 함 ;

data test;
	set fsi.transaction2 ; 
	where year(trans_date)=2018 and accountid is not null ;
	output;
	output; *output 2번해서 row 수가 두 배로 늘어남;
run;

