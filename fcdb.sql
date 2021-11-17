CREATE DATABASE fcdb
WITH OWNER = postgres
   ENCODING = 'UTF8'
   TABLESPACE = pg_default
   LC_COLLATE = 'zh_CN.UTF-8'
   CONNECTION LIMIT = -1
   TEMPLATE template0;

CREATE SEQUENCE "public".broker_id_seq START WITH 1;

CREATE SEQUENCE "public".customer_id_seq START WITH 123456;

CREATE SEQUENCE "public".strategy_id_seq START WITH 501;

CREATE SEQUENCE "public".strategy_params_id_seq START WITH 1;

CREATE SEQUENCE "public".subscribers_id_seq START WITH 54321;

CREATE SEQUENCE "public".strategy_position_id_seq START WITH 21011000000100;

CREATE SEQUENCE "public".position_id_seq START WITH 1000000100;


--CREATE SEQUENCE "public".user_id_seq START WITH 10000;

CREATE  TABLE "public".broker (
    id                   integer DEFAULT nextval('broker_id_seq'::regclass) NOT NULL ,
    name                 varchar(100)  NOT NULL ,
    CONSTRAINT pk_broker_id PRIMARY KEY ( id )
 );

CREATE  TABLE "public".customer (
    id                   integer DEFAULT nextval('customer_id_seq'::regclass) NOT NULL ,
    first_name           varchar(100)   ,
    last_name            varchar(100)   ,
    mobile               bigint   ,
    mail                 varchar(50)   ,
    address              varchar(200)   ,
    active               boolean   ,
    telegram_id          integer   ,
    created_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP  ,
    updated_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP  ,
    CONSTRAINT pk_customer_id PRIMARY KEY ( id )
 );

CREATE  TABLE "public".strategy (
    id                   integer  DEFAULT nextval('strategy_id_seq'::regclass) NOT NULL ,
    name                 varchar(100)  NOT NULL ,
    min_multiplier       integer DEFAULT 1 NOT NULL ,
    capital_required     numeric(12,2)   ,
    price_per_month      numeric(10,2) DEFAULT 0 NOT NULL ,
    description          text DEFAULT 'FirstChoice Strategy'::text  ,
    created_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP  ,
    updated_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP  ,
    CONSTRAINT pk_strategy_id PRIMARY KEY ( id )
 );

CREATE  TABLE "public".strategy_params (
    id                   integer DEFAULT nextval('strategy_params_id_seq'::regclass) NOT NULL ,
    name                 varchar(100)  NOT NULL ,
    strategy_id          integer   ,
    script_name          varchar(100)   ,
    start_time           text   ,
    repair_time          time   ,
    end_time             time DEFAULT '15:05:00'::time without time zone  ,
    target               numeric(7,2)   ,
    stop_loss            numeric(7,2)   ,
    created_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP  ,
    updated_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP  ,
    CONSTRAINT pk_strategy_params_id PRIMARY KEY ( id ),
    CONSTRAINT fk_strategy_params_strategy FOREIGN KEY ( strategy_id ) REFERENCES "public".strategy( id )
 );

CREATE  TABLE "public".subscribers (
    id                   integer DEFAULT nextval('subscribers_id_seq'::regclass) NOT NULL ,
    customer_id          integer  NOT NULL ,
    strategy_id          integer  NOT NULL ,
    broker_id            integer   ,
    run_counter          integer DEFAULT 0 NOT NULL ,
    is_active            char(1)  NOT NULL ,
    start_date           date   ,
    end_date             date   ,
    created_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP  ,
    updated_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP  ,
    CONSTRAINT pk_subscribers_id PRIMARY KEY ( id ),
    CONSTRAINT fk_subscribers_customer FOREIGN KEY ( customer_id ) REFERENCES "public".customer( id )   ,
    CONSTRAINT fk_subscribers_strategy FOREIGN KEY ( strategy_id ) REFERENCES "public".strategy( id )   ,
    CONSTRAINT fk_subscribers_broker FOREIGN KEY ( broker_id ) REFERENCES "public".broker( id )
 );

CREATE OR REPLACE FUNCTION public.trigger_set_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$function$
;

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.customer FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.strategy_params FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.strategy FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.subscribers FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

CREATE TRIGGER set_timestamp BEFORE UPDATE ON public.api FOR EACH ROW EXECUTE FUNCTION trigger_set_timestamp();

INSERT INTO "public".broker( id, name ) VALUES ( 1, 'IIFL');
INSERT INTO "public".broker( id, name ) VALUES ( 2, 'Alice Blue');
INSERT INTO "public".customer( first_name, last_name, mobile, mail, address, active,telegram_id ) VALUES (
							  'Linges', 'M', 6382860148, 'nerus.q8@gmail.com', 'Chennai', 'Y', 1647735620);
INSERT INTO "public".customer( first_name, last_name, mobile, mail, address, active, telegram_id ) VALUES ( 
								'Raja', 'YOGI', 9884411611, 'acumeraja@yahoo.co.in', 'Cbe', 'Y', 1089456737);
INSERT INTO "public".api( first_name, last_name, mobile, mail, address, active, telegram_id ) VALUES (
								'IIFL', '28', 6312312312, 'iifl@yahoo.co.in', 'Madras', 'Y', 1647735620);
INSERT INTO "public".strategy(name, min_multiplier, capital_required, price_per_month, description ) VALUES (
								'Option Scalper', 1, 50000, 500, 'BUY 1 lot CE and PE at the same time.');
INSERT INTO "public".strategy(name, min_multiplier, capital_required, price_per_month, description ) VALUES ( 
								'NFO Panther', 1, 150000, 1000, 'BUY 2 lots and SELL 1 lot at SL, Same cont for every 1 hour');
INSERT INTO "public".strategy_params(name, strategy_id, script_name, start_time, repair_time, end_time, target, stop_loss ) VALUES ( 
									 'os_params', 501, 'Option_Scalper_Live', '09:45:00', '14:40:00', '15:05:00', 3000, -1500);
INSERT INTO "public".strategy_params(  name, strategy_id, script_name, start_time, repair_time, end_time, target, stop_loss ) VALUES ( 
										'nfo_params', 502, 'NFO_Panther_Live', '09:30:00','14:40:00', '15:05:00', 24000, -12000);
INSERT INTO "public".subscribers( customer_id, strategy_id, broker_id, is_active ) VALUES (
								  123456, 501, 1, 'Y');


CREATE  TABLE "public".run_counter ( 
	counter              integer   ,
	subscriber_id        integer   ,
	pnl                  numeric(7,2) DEFAULT 0.00  ,
	created_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP  ,
	CONSTRAINT fk_run_counter_subscribers FOREIGN KEY ( subscriber_id ) REFERENCES "public".subscribers( id )   
 );


CREATE  TABLE "public".order_book ( 
	id                   bigint DEFAULT nextval('strategy_position_id_seq'::regclass) NOT NULL ,
	subscriber_id        integer   ,
	order_id             integer   ,
	broker_id            integer   ,
	broker_order_id      integer   ,
	exchange             char(6)   ,
	instrument           char(40)   ,
	quantity             integer   ,
	trade_price          decimal(7,2)   ,
	status               char(15)   ,
	order_date           timestamp(0) ,
	CONSTRAINT pk_order_book_id PRIMARY KEY ( id )
 );



CREATE  TABLE "public".positions ( 
	id                   integer  DEFAULT nextval('position_id_seq'::regclass) NOT NULL  ,
	strategy_id          integer   ,
	broker_id            integer   ,
	order_id             integer   ,
	exchange             char(7)   ,
	instrument           char(50)   ,
	underlying           char(20)   ,
	expiry               char(10)   ,
	instrument_type      char(10)   ,
	strike               integer   ,
	option_type          char(2)   ,
	txn_type             char(1)   ,
	condition_type       char(20)   ,
	entry_date           timestamp   ,
	quantity             integer   ,
	traded_price         decimal(10,2)   ,
	amount               decimal(10,1)   ,
	run_counter          integer   ,
	product_type         char(7)   ,
	deployment_type      char(10)   ,
	created_at           timestamp(0) DEFAULT current_timestamp  
 );

ALTER TABLE "public".positions ADD CONSTRAINT fk_positions_strategy FOREIGN KEY ( strategy_id ) REFERENCES "public".strategy( id );

ALTER TABLE "public".positions ADD CONSTRAINT fk_positions_broker FOREIGN KEY ( broker_id ) REFERENCES "public".broker( id );

ALTER TABLE "public".positions ADD CONSTRAINT fk_positions_order_book FOREIGN KEY ( order_id ) REFERENCES "public".order_book( order_id );


--DROP TABLE public.api;

CREATE  TABLE "public".api ( 
	customer_id          integer   ,
	api_key              char(30)   ,
	api_secret           char(30)   ,
	"token"              varchar(100)   ,
	token2               varchar(100)   ,
	broker_id            integer   ,
	login_id             integer   ,
	login_password       varchar(50),
	"2fa"				 varchar(10),
	created_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP  ,
    updated_at           timestamp(0) DEFAULT CURRENT_TIMESTAMP
 );

ALTER TABLE "public".api ADD CONSTRAINT fk_api_broker FOREIGN KEY ( broker_id ) REFERENCES "public".broker( id );

ALTER TABLE "public".api ADD CONSTRAINT fk_api_customer FOREIGN KEY ( customer_id ) REFERENCES "public".customer( id );

INSERT INTO "public".api( customer_id, api_key, api_secret, broker_id, login_id, login_password,"2fa") VALUES (
							123458, '8a2c9c2c650b2334c0e432', 'Yuis804$IK', 1, 'IIFL28', 'Jul@123',123456);

CREATE  TABLE "public".banknifty_options ( 
	name                 varchar(100)   ,
	datetime             timestamp(0)   ,
	"open"               decimal(7,2)   ,
	high                 decimal(7,2)   ,
	low                  decimal(7,2)   ,
	"close"              decimal(7,2)   ,
	volume               bigint   ,
	oi                   bigint   
 );
 
 CREATE  TABLE "public".nifty_options ( 
	name                 varchar(100)   ,
	datetime             timestamp(0)   ,
	"open"               decimal(7,2)   ,
	high                 decimal(7,2)   ,
	low                  decimal(7,2)   ,
	"close"              decimal(7,2)   ,
	volume               bigint   ,
	oi                   bigint   
 );

 CREATE  TABLE "public".nifty_futures ( 
	name                 varchar(100)   ,
	datetime             timestamp(0)   ,
	"open"               decimal(7,2)   ,
	high                 decimal(7,2)   ,
	low                  decimal(7,2)   ,
	"close"              decimal(7,2)   ,
	volume               bigint   ,
	oi                   bigint   
 );
 
CREATE  TABLE "public".nifty_equity ( 
	name                 varchar(100)   ,
	symbol 				 integer		,
	datetime             timestamp(0)   ,
	"open"               decimal(7,2)   ,
	high                 decimal(7,2)   ,
	low                  decimal(7,2)   ,
	"close"              decimal(7,2)   ,
	volume               bigint     
);


--backup of PG database

--pg_dump -U postgres -W -F t fcdb > D:\Python\Postgres\fcdb.tar ;
--C:\Program Files\PostgreSQL\13\bin\pg_dump -U postgres -W -F t fcdb > "D:\Python\Postgres\fcdb.tar"

--to restore 
-- pg_restore --dbname=newdbname --username postgres -W --create --verbose c:\pgbackup\dbanme.tar

--start pg
-- inside PG --> D:/Python/PG/pgsql/bin/pg_ctl -D "D:\Python\PG\pgsql\data" -l logfile start

CREATE  TABLE "public".options_data_master (
	datetime             timestamp(0)   ,
	name                 varchar(100)  NOT NULL ,
	"date"               date  NOT NULL ,
	"time"               time  NOT NULL ,
	underlying           varchar(50)   ,
	option_type          varchar(2)   ,
	expiry               date   ,
	strike               bigint   ,
	"open"               decimal(7,2)   ,
	high                 decimal(7,2)   ,
	low                  decimal(7,2)   ,
	"close"              decimal(7,2)   ,
	volume               bigint   ,
	oi                   bigint
 );

CREATE UNIQUE INDEX unq_options_data_master_date ON "public".options_data_master ( name, datetime );


INSERT INTO public.options_data_master
	select
	datetime, name, DATE(datetime) as "date", "datetime"::time as "time",
	CASE
  	WHEN name LIKE 'NIFTY%' THEN 'NIFTY'
  	WHEN name LIKE 'BANKNIFTY%' THEN 'BANKNIFTY'
	END underlying,
	CASE
  	WHEN name LIKE '%CE%' THEN 'CE'
  	WHEN name LIKE '%PE%' THEN 'PE'
	END option_type,
	'01-01-1999' as expiry,
	regexp_replace(LEFT(RIGHT(name,7),5) , '[[:alpha:]]', '', 'g')::bigint as strike, "open", "high", "low", "close", "volume", "oi" from nifty_options where datetime >= '2021-06-25';


select count(1) from banknifty_options;
select count(1) from nifty_options_temp;
select count(1) from options_data_master;


--check for dups
SELECT (nifty_options.*)::text, count(*)
FROM nifty_options
GROUP BY nifty_options.*
HAVING count(*) > 1;


-- step 1
CREATE TABLE nifty_options_temp (LIKE nifty_options);

-- step 2
INSERT INTO nifty_options_temp
SELECT
    DISTINCT a.*
FROM nifty_options a;

-- step 3
--DROP TABLE nifty_options;

-- step 4
ALTER TABLE nifty_options_temp
RENAME TO nifty_options;

SELECT name, datetime, "open", high, low, "close", volume, oi
FROM
	"public".nifty_options_temp s limit 10;

-- insert into nifty_options_temp
-- SELECT right(split_part(name, ',', 1),-1)::varchar(100) AS name
--      , split_part(name, ',', 2)::timestamp(0) AS datetime
--      , split_part(name, ',', 3)::decimal(7,2) AS "open"
--      , split_part(name, ',', 4)::decimal(7,2) AS "high"
-- 	, split_part(name, ',', 5)::decimal(7,2) AS "low"
-- 	, split_part(name, ',', 6)::decimal(7,2) AS "close"
-- 	, split_part(name, ',', 7)::bigint AS "volume"
-- 	, left(split_part(name, ',', 8),-1)::bigint AS "oi"
-- FROM   nifty_options;


--DROP TABLE public.master_instrument_dump;

CREATE TABLE public.master_instrument_dump
(
    exchange_segment character varying(10) COLLATE pg_catalog."default",
    exchange_instrument_id bigint,
    instrument_type integer,
    name character varying(50) COLLATE pg_catalog."default",
    description character varying(100) COLLATE pg_catalog."default",
    series character varying(10) COLLATE pg_catalog."default",
    name_with_series character varying(50) COLLATE pg_catalog."default",
    instrument_id bigint,
    price_band_high numeric(12,2),
    price_band_low numeric(12,2),
    freeze_qty integer,
    ticksize numeric(2,2),
    lotsize integer,
    underlying_instrument_id bigint,
    underlying_index_name character varying(50) COLLATE pg_catalog."default",
    contract_expiration timestamp without time zone,
    strike_price numeric(10,2),
    option_type integer,
    updated_at timestamp(0) DEFAULT CURRENT_TIMESTAMP
)
TABLESPACE pg_default;

ALTER TABLE public.master_instrument_dump
    OWNER to postgres;

-------
SELECT
exchange_segment,exchange_instrument_id,name,description,series,underlying_index_name,contract_expiration
strike_price,
case
when option_type = 3 THEN 'CE'
when option_type = 4 THEN 'PE'
END option_type,
FROM public.master_instrument_dump
where name in ('NIFTY','BANKNIFTY')
and series = 'OPTIDX' and strike_price in ();



----------
ohlc query to filer strike prices

'''
SELECT   exchange_segment,
         instrument_type,
         exchange_instrument_id,
         NAME,
         description,
         series,
         underlying_index_name,
         contract_expiration,
         strike_price,
         option_type
FROM     (
                SELECT *
                FROM   PUBLIC.master_instrument_dump
                WHERE  strike_price IN
                       (
                              SELECT *
                              FROM   Generate_series(
                                     (
                                            SELECT Least(Min(strike), {nft_low} )
                                            FROM   options_data_master
                                            WHERE  Extract(month FROM datetime)=Extract(month FROM CURRENT_DATE)
                                            AND    underlying ='NIFTY'),
                                     (
                                            SELECT Greatest(Max(strike), {nft_high} )
                                            FROM   options_data_master
                                            WHERE  Extract(month FROM datetime)=Extract(month FROM CURRENT_DATE)
                                            AND    underlying ='NIFTY'),50)
                              UNION
                              SELECT *
                              FROM   Generate_series(
                                     (
                                            SELECT Least(Min(strike), {bnft_low})
                                            FROM   options_data_master
                                            WHERE  Extract(month FROM datetime)=Extract(month FROM CURRENT_DATE)
                                            AND    underlying ='BANKNIFTY'),
                                     (
                                            SELECT Greatest(Max(strike), {bnft_high} )
                                            FROM   options_data_master
                                            WHERE  Extract(month FROM datetime)=Extract(month FROM CURRENT_DATE)
                                            AND    underlying ='BANKNIFTY'),100))
                OR     instrument_type = 1) a
WHERE    a.updated_at::date = CURRENT_DATE
AND      a.series IN ('OPTIDX',
                      'FUTIDX',
                      'FUTSTK')
AND      a.NAME != 'FINNIFTY'
AND      a.instrument_type IN (1,2)
AND      a.contract_expiration BETWEEN CURRENT_DATE AND      (
                  date_trunc('month', CURRENT_DATE::date) + interval '2 month')::date
UNION
SELECT   exchange_segment,
         instrument_type,
         exchange_instrument_id,
         NAME,
         description,
         series,
         underlying_index_name,
         contract_expiration,
         strike_price,
         option_type
FROM     PUBLIC.master_instrument_dump
WHERE    instrument_type = 8
AND      NAME IN ('ACC', 'AUBANK', 'AARTIIND', 'ABBOTINDIA', 'ADANIENT', 'ADANIGREEN', 'ADANIPORTS', 'ATGL', 'ADANITRANS', 'ABCAPITAL', 'ABFRL', 'AJANTPHARM', 'APLLTD', 'ALKEM', 'AMARAJABAT', 'AMBUJACEM', 'APOLLOHOSP', 'APOLLOTYRE', 'ASHOKLEY', 'ASIANPAINT', 'AUROPHARMA', 'DMART', 'AXISBANK', 'BAJAJ-AUTO', 'BAJFINANCE', 'BAJAJFINSV', 'BAJAJHLDNG', 'BALKRISIND', 'BANDHANBNK', 'BANKBARODA', 'BANKINDIA', 'BATAINDIA', 'BERGEPAINT', 'BEL', 'BHARATFORG', 'BHEL', 'BPCL', 'BHARTIARTL', 'BIOCON', 'BBTC', 'BOSCHLTD', 'BRITANNIA', 'CESC', 'CADILAHC', 'CANBK', 'CASTROLIND', 'CHOLAFIN', 'CIPLA', 'CUB', 'COALINDIA', 'COFORGE', 'COLPAL', 'CONCOR', 'COROMANDEL', 'CROMPTON', 'CUMMINSIND', 'DLF', 'DABUR', 'DALBHARAT', 'DEEPAKNTR', 'DHANI', 'DIVISLAB', 'DIXON', 'LALPATHLAB', 'DRREDDY', 'EICHERMOT', 'EMAMILTD', 'ENDURANCE', 'ESCORTS', 'EXIDEIND', 'FEDERALBNK', 'FORTIS', 'GAIL', 'GMRINFRA', 'GLENMARK', 'GODREJAGRO', 'GODREJCP', 'GODREJIND', 'GODREJPROP', 'GRASIM', 'GUJGASLTD', 'GSPL', 'HCLTECH', 'HDFCAMC', 'HDFCBANK', 'HDFCLIFE', 'HAVELLS', 'HEROMOTOCO', 'HINDALCO', 'HAL', 'HINDPETRO', 'HINDUNILVR', 'HINDZINC', 'HDFC', 'ICICIBANK', 'ICICIGI', 'ICICIPRULI', 'ISEC', 'IDFCFIRSTB', 'ITC', 'IBULHSGFIN', 'INDIAMART', 'INDHOTEL', 'IOC', 'IRCTC', 'IGL', 'INDUSTOWER', 'INDUSINDBK', 'NAUKRI', 'INFY', 'INDIGO', 'IPCALAB', 'JSWENERGY', 'JSWSTEEL', 'JINDALSTEL', 'JUBLFOOD', 'KOTAKBANK', 'L&TFH', 'LTTS', 'LICHSGFIN', 'LTI', 'LT', 'LAURUSLABS', 'LUPIN', 'MRF', 'MGL', 'M&MFIN', 'M&M', 'MANAPPURAM', 'MARICO', 'MARUTI', 'MFSL', 'MINDTREE', 'MOTHERSUMI', 'MPHASIS', 'MUTHOOTFIN', 'NATCOPHARM', 'NMDC', 'NTPC', 'NAVINFLUOR', 'NESTLEIND', 'NAM-INDIA', 'OBEROIRLTY', 'ONGC', 'OIL', 'PIIND', 'PAGEIND', 'PETRONET', 'PFIZER', 'PIDILITIND', 'PEL', 'POLYCAB', 'PFC', 'POWERGRID', 'PRESTIGE', 'PGHH', 'PNB', 'RBLBANK', 'RECLTD', 'RELIANCE', 'SBICARD', 'SBILIFE', 'SRF', 'SANOFI', 'SHREECEM', 'SRTRANSFIN', 'SIEMENS', 'SBIN', 'SAIL', 'SUNPHARMA', 'SUNTV', 'SYNGENE', 'TVSMOTOR', 'TATACHEM', 'TCS', 'TATACONSUM', 'TATAELXSI', 'TATAMOTORS', 'TATAPOWER', 'TATASTEEL', 'TECHM', 'RAMCOCEM', 'TITAN', 'TORNTPHARM', 'TORNTPOWER', 'TRENT', 'UPL', 'ULTRACEMCO', 'UNIONBANK', 'UBL', 'MCDOWELL-N', 'VGUARD', 'VBL', 'VEDL', 'IDEA', 'VOLTAS', 'WHIRLPOOL', 'WIPRO', 'YESBANK', 'ZEEL') 
AND      series IN ('EQ', 'BE')
ORDER BY NAME;
'''


CREATE  TABLE "public".nsefo_data (
	datetime             timestamp(0)   ,
	instrument_name      varchar(100)  NOT NULL ,
	underlying           varchar(50)   ,
	instrument_type      integer,
	series				 varchar(20),
	expiry               date   ,
	strike_price         bigint   ,
	option_type          varchar(2)   ,
	"open"               decimal(7,2)   ,
	high                 decimal(7,2)   ,
	low                  decimal(7,2)   ,
	"close"              decimal(7,2)   ,
	volume               bigint   ,
	oi                   bigint,
	updated_at 			 timestamp(0) DEFAULT CURRENT_TIMESTAMP
 ) PARTITION BY LIST(instrument_type);

CREATE TABLE part.nse_fut_data PARTITION OF public.nsefo_data FOR VALUES IN (1) PARTITION BY RANGE(datetime);
CREATE TABLE public.nse_fut_data_2021_MAR PARTITION OF part.nse_fut_data
    FOR VALUES FROM ('2021-03-01 00:00:00') TO ('2021-03-31 23:00:00');
CREATE TABLE part.nse_fut_data_2021_APR PARTITION OF part.nse_fut_data
    FOR VALUES FROM ('2021-04-01 00:00:00') TO ('2021-04-30 23:00:00');
CREATE TABLE part.nse_fut_data_2021_MAY PARTITION OF part.nse_fut_data
    FOR VALUES FROM ('2021-05-01 00:00:00') TO ('2021-05-31 23:00:00');
CREATE TABLE part.nse_fut_data_2021_JUN PARTITION OF part.nse_fut_data
    FOR VALUES FROM ('2021-06-01 00:00:00') TO ('2021-06-30 23:00:00');
CREATE TABLE part.nse_fut_data_2021_JUL PARTITION OF part.nse_fut_data
    FOR VALUES FROM ('2021-07-01 00:00:00') TO ('2021-07-31 23:00:00');
CREATE TABLE part.nse_fut_data_2021_AUG PARTITION OF part.nse_fut_data
    FOR VALUES FROM ('2021-08-01 00:00:00') TO ('2021-08-31 23:00:00');
CREATE TABLE part.nse_fut_data_2021_SEP PARTITION OF part.nse_fut_data
    FOR VALUES FROM ('2021-09-01 00:00:00') TO ('2021-09-30 23:00:00');
CREATE TABLE part.nse_fut_data_2021_OCT PARTITION OF part.nse_fut_data
    FOR VALUES FROM ('2021-10-01 00:00:00') TO ('2021-10-31 23:00:00');
CREATE TABLE part.nse_fut_data_2021_NOV PARTITION OF part.nse_fut_data
    FOR VALUES FROM ('2021-11-01 00:00:00') TO ('2021-11-30 23:00:00');
CREATE TABLE part.nse_fut_data_2021_DEC PARTITION OF part.nse_fut_data
    FOR VALUES FROM ('2021-12-01 00:00:00') TO ('2021-12-31 23:00:00');


CREATE TABLE part.nse_opt_data PARTITION OF public.nsefo_data FOR VALUES IN (2) PARTITION BY RANGE(datetime);
CREATE TABLE part.nse_opt_data_2021_MAR PARTITION OF part.nse_opt_data
    FOR VALUES FROM ('2021-03-01 00:00:00') TO ('2021-03-31 23:00:00');
CREATE TABLE part.nse_opt_data_2021_APR PARTITION OF part.nse_opt_data
    FOR VALUES FROM ('2021-04-01 00:00:00') TO ('2021-04-30 23:00:00');
CREATE TABLE part.nse_opt_data_2021_MAY PARTITION OF part.nse_opt_data
    FOR VALUES FROM ('2021-05-01 00:00:00') TO ('2021-05-31 23:00:00');
CREATE TABLE part.nse_opt_data_2021_JUN PARTITION OF part.nse_opt_data
    FOR VALUES FROM ('2021-06-01 00:00:00') TO ('2021-06-30 23:00:00');
CREATE TABLE part.nse_opt_data_2021_JUL PARTITION OF part.nse_opt_data
    FOR VALUES FROM ('2021-07-01 00:00:00') TO ('2021-07-31 23:00:00');
CREATE TABLE part.nse_opt_data_2021_AUG PARTITION OF part.nse_opt_data
    FOR VALUES FROM ('2021-08-01 00:00:00') TO ('2021-08-31 23:00:00');
CREATE TABLE part.nse_opt_data_2021_SEP PARTITION OF part.nse_opt_data
    FOR VALUES FROM ('2021-09-01 00:00:00') TO ('2021-09-30 23:00:00');
CREATE TABLE part.nse_opt_data_2021_OCT PARTITION OF part.nse_opt_data
    FOR VALUES FROM ('2021-10-01 00:00:00') TO ('2021-10-31 23:00:00');
CREATE TABLE part.nse_opt_data_2021_NOV PARTITION OF part.nse_opt_data
    FOR VALUES FROM ('2021-11-01 00:00:00') TO ('2021-11-30 23:00:00');
CREATE TABLE part.nse_opt_data_2021_DEC PARTITION OF part.nse_opt_data
    FOR VALUES FROM ('2021-12-01 00:00:00') TO ('2021-12-31 23:00:00');


CREATE TABLE part.nse_cm_data PARTITION OF public.nsefo_data FOR VALUES IN (8) PARTITION BY LIST(instrument_name);
CREATE TABLE part."nse_cm_data_acc" PARTITION OF part.nse_cm_data FOR VALUES IN ('ACC');
CREATE TABLE part."nse_cm_data_aubank" PARTITION OF part.nse_cm_data FOR VALUES IN ('AUBANK');
CREATE TABLE part."nse_cm_data_aartiind" PARTITION OF part.nse_cm_data FOR VALUES IN ('AARTIIND');
CREATE TABLE part."nse_cm_data_abbotindia" PARTITION OF part.nse_cm_data FOR VALUES IN ('ABBOTINDIA');
CREATE TABLE part."nse_cm_data_adanient" PARTITION OF part.nse_cm_data FOR VALUES IN ('ADANIENT');
CREATE TABLE part."nse_cm_data_adanigreen" PARTITION OF part.nse_cm_data FOR VALUES IN ('ADANIGREEN');
CREATE TABLE part."nse_cm_data_adaniports" PARTITION OF part.nse_cm_data FOR VALUES IN ('ADANIPORTS');
CREATE TABLE part."nse_cm_data_atgl" PARTITION OF part.nse_cm_data FOR VALUES IN ('ATGL');
CREATE TABLE part."nse_cm_data_adanitrans" PARTITION OF part.nse_cm_data FOR VALUES IN ('ADANITRANS');
CREATE TABLE part."nse_cm_data_abcapital" PARTITION OF part.nse_cm_data FOR VALUES IN ('ABCAPITAL');
CREATE TABLE part."nse_cm_data_abfrl" PARTITION OF part.nse_cm_data FOR VALUES IN ('ABFRL');
CREATE TABLE part."nse_cm_data_ajantpharm" PARTITION OF part.nse_cm_data FOR VALUES IN ('AJANTPHARM');
CREATE TABLE part."nse_cm_data_aplltd" PARTITION OF part.nse_cm_data FOR VALUES IN ('APLLTD');
CREATE TABLE part."nse_cm_data_alkem" PARTITION OF part.nse_cm_data FOR VALUES IN ('ALKEM');
CREATE TABLE part."nse_cm_data_amarajabat" PARTITION OF part.nse_cm_data FOR VALUES IN ('AMARAJABAT');
CREATE TABLE part."nse_cm_data_ambujacem" PARTITION OF part.nse_cm_data FOR VALUES IN ('AMBUJACEM');
CREATE TABLE part."nse_cm_data_apollohosp" PARTITION OF part.nse_cm_data FOR VALUES IN ('APOLLOHOSP');
CREATE TABLE part."nse_cm_data_apollotyre" PARTITION OF part.nse_cm_data FOR VALUES IN ('APOLLOTYRE');
CREATE TABLE part."nse_cm_data_ashokley" PARTITION OF part.nse_cm_data FOR VALUES IN ('ASHOKLEY');
CREATE TABLE part."nse_cm_data_asianpaint" PARTITION OF part.nse_cm_data FOR VALUES IN ('ASIANPAINT');
CREATE TABLE part."nse_cm_data_auropharma" PARTITION OF part.nse_cm_data FOR VALUES IN ('AUROPHARMA');
CREATE TABLE part."nse_cm_data_dmart" PARTITION OF part.nse_cm_data FOR VALUES IN ('DMART');
CREATE TABLE part."nse_cm_data_axisbank" PARTITION OF part.nse_cm_data FOR VALUES IN ('AXISBANK');
CREATE TABLE part."nse_cm_data_bajaj-auto" PARTITION OF part.nse_cm_data FOR VALUES IN ('BAJAJ-AUTO');
CREATE TABLE part."nse_cm_data_bajfinance" PARTITION OF part.nse_cm_data FOR VALUES IN ('BAJFINANCE');
CREATE TABLE part."nse_cm_data_bajajfinsv" PARTITION OF part.nse_cm_data FOR VALUES IN ('BAJAJFINSV');
CREATE TABLE part."nse_cm_data_bajajhldng" PARTITION OF part.nse_cm_data FOR VALUES IN ('BAJAJHLDNG');
CREATE TABLE part."nse_cm_data_balkrisind" PARTITION OF part.nse_cm_data FOR VALUES IN ('BALKRISIND');
CREATE TABLE part."nse_cm_data_bandhanbnk" PARTITION OF part.nse_cm_data FOR VALUES IN ('BANDHANBNK');
CREATE TABLE part."nse_cm_data_bankbaroda" PARTITION OF part.nse_cm_data FOR VALUES IN ('BANKBARODA');
CREATE TABLE part."nse_cm_data_bankindia" PARTITION OF part.nse_cm_data FOR VALUES IN ('BANKINDIA');
CREATE TABLE part."nse_cm_data_bataindia" PARTITION OF part.nse_cm_data FOR VALUES IN ('BATAINDIA');
CREATE TABLE part."nse_cm_data_bergepaint" PARTITION OF part.nse_cm_data FOR VALUES IN ('BERGEPAINT');
CREATE TABLE part."nse_cm_data_bel" PARTITION OF part.nse_cm_data FOR VALUES IN ('BEL');
CREATE TABLE part."nse_cm_data_bharatforg" PARTITION OF part.nse_cm_data FOR VALUES IN ('BHARATFORG');
CREATE TABLE part."nse_cm_data_bhel" PARTITION OF part.nse_cm_data FOR VALUES IN ('BHEL');
CREATE TABLE part."nse_cm_data_bpcl" PARTITION OF part.nse_cm_data FOR VALUES IN ('BPCL');
CREATE TABLE part."nse_cm_data_bhartiartl" PARTITION OF part.nse_cm_data FOR VALUES IN ('BHARTIARTL');
CREATE TABLE part."nse_cm_data_biocon" PARTITION OF part.nse_cm_data FOR VALUES IN ('BIOCON');
CREATE TABLE part."nse_cm_data_bbtc" PARTITION OF part.nse_cm_data FOR VALUES IN ('BBTC');
CREATE TABLE part."nse_cm_data_boschltd" PARTITION OF part.nse_cm_data FOR VALUES IN ('BOSCHLTD');
CREATE TABLE part."nse_cm_data_britannia" PARTITION OF part.nse_cm_data FOR VALUES IN ('BRITANNIA');
CREATE TABLE part."nse_cm_data_cesc" PARTITION OF part.nse_cm_data FOR VALUES IN ('CESC');
CREATE TABLE part."nse_cm_data_cadilahc" PARTITION OF part.nse_cm_data FOR VALUES IN ('CADILAHC');
CREATE TABLE part."nse_cm_data_canbk" PARTITION OF part.nse_cm_data FOR VALUES IN ('CANBK');
CREATE TABLE part."nse_cm_data_castrolind" PARTITION OF part.nse_cm_data FOR VALUES IN ('CASTROLIND');
CREATE TABLE part."nse_cm_data_cholafin" PARTITION OF part.nse_cm_data FOR VALUES IN ('CHOLAFIN');
CREATE TABLE part."nse_cm_data_cipla" PARTITION OF part.nse_cm_data FOR VALUES IN ('CIPLA');
CREATE TABLE part."nse_cm_data_cub" PARTITION OF part.nse_cm_data FOR VALUES IN ('CUB');
CREATE TABLE part."nse_cm_data_coalindia" PARTITION OF part.nse_cm_data FOR VALUES IN ('COALINDIA');
CREATE TABLE part."nse_cm_data_coforge" PARTITION OF part.nse_cm_data FOR VALUES IN ('COFORGE');
CREATE TABLE part."nse_cm_data_colpal" PARTITION OF part.nse_cm_data FOR VALUES IN ('COLPAL');
CREATE TABLE part."nse_cm_data_concor" PARTITION OF part.nse_cm_data FOR VALUES IN ('CONCOR');
CREATE TABLE part."nse_cm_data_coromandel" PARTITION OF part.nse_cm_data FOR VALUES IN ('COROMANDEL');
CREATE TABLE part."nse_cm_data_crompton" PARTITION OF part.nse_cm_data FOR VALUES IN ('CROMPTON');
CREATE TABLE part."nse_cm_data_cumminsind" PARTITION OF part.nse_cm_data FOR VALUES IN ('CUMMINSIND');
CREATE TABLE part."nse_cm_data_dlf" PARTITION OF part.nse_cm_data FOR VALUES IN ('DLF');
CREATE TABLE part."nse_cm_data_dabur" PARTITION OF part.nse_cm_data FOR VALUES IN ('DABUR');
CREATE TABLE part."nse_cm_data_dalbharat" PARTITION OF part.nse_cm_data FOR VALUES IN ('DALBHARAT');
CREATE TABLE part."nse_cm_data_deepakntr" PARTITION OF part.nse_cm_data FOR VALUES IN ('DEEPAKNTR');
CREATE TABLE part."nse_cm_data_dhani" PARTITION OF part.nse_cm_data FOR VALUES IN ('DHANI');
CREATE TABLE part."nse_cm_data_divislab" PARTITION OF part.nse_cm_data FOR VALUES IN ('DIVISLAB');
CREATE TABLE part."nse_cm_data_dixon" PARTITION OF part.nse_cm_data FOR VALUES IN ('DIXON');
CREATE TABLE part."nse_cm_data_lalpathlab" PARTITION OF part.nse_cm_data FOR VALUES IN ('LALPATHLAB');
CREATE TABLE part."nse_cm_data_drreddy" PARTITION OF part.nse_cm_data FOR VALUES IN ('DRREDDY');
CREATE TABLE part."nse_cm_data_eichermot" PARTITION OF part.nse_cm_data FOR VALUES IN ('EICHERMOT');
CREATE TABLE part."nse_cm_data_emamiltd" PARTITION OF part.nse_cm_data FOR VALUES IN ('EMAMILTD');
CREATE TABLE part."nse_cm_data_endurance" PARTITION OF part.nse_cm_data FOR VALUES IN ('ENDURANCE');
CREATE TABLE part."nse_cm_data_escorts" PARTITION OF part.nse_cm_data FOR VALUES IN ('ESCORTS');
CREATE TABLE part."nse_cm_data_exideind" PARTITION OF part.nse_cm_data FOR VALUES IN ('EXIDEIND');
CREATE TABLE part."nse_cm_data_federalbnk" PARTITION OF part.nse_cm_data FOR VALUES IN ('FEDERALBNK');
CREATE TABLE part."nse_cm_data_fortis" PARTITION OF part.nse_cm_data FOR VALUES IN ('FORTIS');
CREATE TABLE part."nse_cm_data_gail" PARTITION OF part.nse_cm_data FOR VALUES IN ('GAIL');
CREATE TABLE part."nse_cm_data_gmrinfra" PARTITION OF part.nse_cm_data FOR VALUES IN ('GMRINFRA');
CREATE TABLE part."nse_cm_data_glenmark" PARTITION OF part.nse_cm_data FOR VALUES IN ('GLENMARK');
CREATE TABLE part."nse_cm_data_godrejagro" PARTITION OF part.nse_cm_data FOR VALUES IN ('GODREJAGRO');
CREATE TABLE part."nse_cm_data_godrejcp" PARTITION OF part.nse_cm_data FOR VALUES IN ('GODREJCP');
CREATE TABLE part."nse_cm_data_godrejind" PARTITION OF part.nse_cm_data FOR VALUES IN ('GODREJIND');
CREATE TABLE part."nse_cm_data_godrejprop" PARTITION OF part.nse_cm_data FOR VALUES IN ('GODREJPROP');
CREATE TABLE part."nse_cm_data_grasim" PARTITION OF part.nse_cm_data FOR VALUES IN ('GRASIM');
CREATE TABLE part."nse_cm_data_gujgasltd" PARTITION OF part.nse_cm_data FOR VALUES IN ('GUJGASLTD');
CREATE TABLE part."nse_cm_data_gspl" PARTITION OF part.nse_cm_data FOR VALUES IN ('GSPL');
CREATE TABLE part."nse_cm_data_hcltech" PARTITION OF part.nse_cm_data FOR VALUES IN ('HCLTECH');
CREATE TABLE part."nse_cm_data_hdfcamc" PARTITION OF part.nse_cm_data FOR VALUES IN ('HDFCAMC');
CREATE TABLE part."nse_cm_data_hdfcbank" PARTITION OF part.nse_cm_data FOR VALUES IN ('HDFCBANK');
CREATE TABLE part."nse_cm_data_hdfclife" PARTITION OF part.nse_cm_data FOR VALUES IN ('HDFCLIFE');
CREATE TABLE part."nse_cm_data_havells" PARTITION OF part.nse_cm_data FOR VALUES IN ('HAVELLS');
CREATE TABLE part."nse_cm_data_heromotoco" PARTITION OF part.nse_cm_data FOR VALUES IN ('HEROMOTOCO');
CREATE TABLE part."nse_cm_data_hindalco" PARTITION OF part.nse_cm_data FOR VALUES IN ('HINDALCO');
CREATE TABLE part."nse_cm_data_hal" PARTITION OF part.nse_cm_data FOR VALUES IN ('HAL');
CREATE TABLE part."nse_cm_data_hindpetro" PARTITION OF part.nse_cm_data FOR VALUES IN ('HINDPETRO');
CREATE TABLE part."nse_cm_data_hindunilvr" PARTITION OF part.nse_cm_data FOR VALUES IN ('HINDUNILVR');
CREATE TABLE part."nse_cm_data_hindzinc" PARTITION OF part.nse_cm_data FOR VALUES IN ('HINDZINC');
CREATE TABLE part."nse_cm_data_hdfc" PARTITION OF part.nse_cm_data FOR VALUES IN ('HDFC');
CREATE TABLE part."nse_cm_data_icicibank" PARTITION OF part.nse_cm_data FOR VALUES IN ('ICICIBANK');
CREATE TABLE part."nse_cm_data_icicigi" PARTITION OF part.nse_cm_data FOR VALUES IN ('ICICIGI');
CREATE TABLE part."nse_cm_data_icicipruli" PARTITION OF part.nse_cm_data FOR VALUES IN ('ICICIPRULI');
CREATE TABLE part."nse_cm_data_isec" PARTITION OF part.nse_cm_data FOR VALUES IN ('ISEC');
CREATE TABLE part."nse_cm_data_idfcfirstb" PARTITION OF part.nse_cm_data FOR VALUES IN ('IDFCFIRSTB');
CREATE TABLE part."nse_cm_data_itc" PARTITION OF part.nse_cm_data FOR VALUES IN ('ITC');
CREATE TABLE part."nse_cm_data_ibulhsgfin" PARTITION OF part.nse_cm_data FOR VALUES IN ('IBULHSGFIN');
CREATE TABLE part."nse_cm_data_indiamart" PARTITION OF part.nse_cm_data FOR VALUES IN ('INDIAMART');
CREATE TABLE part."nse_cm_data_indhotel" PARTITION OF part.nse_cm_data FOR VALUES IN ('INDHOTEL');
CREATE TABLE part."nse_cm_data_ioc" PARTITION OF part.nse_cm_data FOR VALUES IN ('IOC');
CREATE TABLE part."nse_cm_data_irctc" PARTITION OF part.nse_cm_data FOR VALUES IN ('IRCTC');
CREATE TABLE part."nse_cm_data_igl" PARTITION OF part.nse_cm_data FOR VALUES IN ('IGL');
CREATE TABLE part."nse_cm_data_industower" PARTITION OF part.nse_cm_data FOR VALUES IN ('INDUSTOWER');
CREATE TABLE part."nse_cm_data_indusindbk" PARTITION OF part.nse_cm_data FOR VALUES IN ('INDUSINDBK');
CREATE TABLE part."nse_cm_data_naukri" PARTITION OF part.nse_cm_data FOR VALUES IN ('NAUKRI');
CREATE TABLE part."nse_cm_data_infy" PARTITION OF part.nse_cm_data FOR VALUES IN ('INFY');
CREATE TABLE part."nse_cm_data_indigo" PARTITION OF part.nse_cm_data FOR VALUES IN ('INDIGO');
CREATE TABLE part."nse_cm_data_ipcalab" PARTITION OF part.nse_cm_data FOR VALUES IN ('IPCALAB');
CREATE TABLE part."nse_cm_data_jswenergy" PARTITION OF part.nse_cm_data FOR VALUES IN ('JSWENERGY');
CREATE TABLE part."nse_cm_data_jswsteel" PARTITION OF part.nse_cm_data FOR VALUES IN ('JSWSTEEL');
CREATE TABLE part."nse_cm_data_jindalstel" PARTITION OF part.nse_cm_data FOR VALUES IN ('JINDALSTEL');
CREATE TABLE part."nse_cm_data_jublfood" PARTITION OF part.nse_cm_data FOR VALUES IN ('JUBLFOOD');
CREATE TABLE part."nse_cm_data_kotakbank" PARTITION OF part.nse_cm_data FOR VALUES IN ('KOTAKBANK');
CREATE TABLE part."nse_cm_data_l&tfh" PARTITION OF part.nse_cm_data FOR VALUES IN ('L&TFH');
CREATE TABLE part."nse_cm_data_ltts" PARTITION OF part.nse_cm_data FOR VALUES IN ('LTTS');
CREATE TABLE part."nse_cm_data_lichsgfin" PARTITION OF part.nse_cm_data FOR VALUES IN ('LICHSGFIN');
CREATE TABLE part."nse_cm_data_lti" PARTITION OF part.nse_cm_data FOR VALUES IN ('LTI');
CREATE TABLE part."nse_cm_data_lt" PARTITION OF part.nse_cm_data FOR VALUES IN ('LT');
CREATE TABLE part."nse_cm_data_lauruslabs" PARTITION OF part.nse_cm_data FOR VALUES IN ('LAURUSLABS');
CREATE TABLE part."nse_cm_data_lupin" PARTITION OF part.nse_cm_data FOR VALUES IN ('LUPIN');
CREATE TABLE part."nse_cm_data_mrf" PARTITION OF part.nse_cm_data FOR VALUES IN ('MRF');
CREATE TABLE part."nse_cm_data_mgl" PARTITION OF part.nse_cm_data FOR VALUES IN ('MGL');
CREATE TABLE part."nse_cm_data_m&mfin" PARTITION OF part.nse_cm_data FOR VALUES IN ('M&MFIN');
CREATE TABLE part."nse_cm_data_m&m" PARTITION OF part.nse_cm_data FOR VALUES IN ('M&M');
CREATE TABLE part."nse_cm_data_manappuram" PARTITION OF part.nse_cm_data FOR VALUES IN ('MANAPPURAM');
CREATE TABLE part."nse_cm_data_marico" PARTITION OF part.nse_cm_data FOR VALUES IN ('MARICO');
CREATE TABLE part."nse_cm_data_maruti" PARTITION OF part.nse_cm_data FOR VALUES IN ('MARUTI');
CREATE TABLE part."nse_cm_data_mfsl" PARTITION OF part.nse_cm_data FOR VALUES IN ('MFSL');
CREATE TABLE part."nse_cm_data_mindtree" PARTITION OF part.nse_cm_data FOR VALUES IN ('MINDTREE');
CREATE TABLE part."nse_cm_data_mothersumi" PARTITION OF part.nse_cm_data FOR VALUES IN ('MOTHERSUMI');
CREATE TABLE part."nse_cm_data_mphasis" PARTITION OF part.nse_cm_data FOR VALUES IN ('MPHASIS');
CREATE TABLE part."nse_cm_data_muthootfin" PARTITION OF part.nse_cm_data FOR VALUES IN ('MUTHOOTFIN');
CREATE TABLE part."nse_cm_data_natcopharm" PARTITION OF part.nse_cm_data FOR VALUES IN ('NATCOPHARM');
CREATE TABLE part."nse_cm_data_nmdc" PARTITION OF part.nse_cm_data FOR VALUES IN ('NMDC');
CREATE TABLE part."nse_cm_data_ntpc" PARTITION OF part.nse_cm_data FOR VALUES IN ('NTPC');
CREATE TABLE part."nse_cm_data_navinfluor" PARTITION OF part.nse_cm_data FOR VALUES IN ('NAVINFLUOR');
CREATE TABLE part."nse_cm_data_nestleind" PARTITION OF part.nse_cm_data FOR VALUES IN ('NESTLEIND');
CREATE TABLE part."nse_cm_data_nam-india" PARTITION OF part.nse_cm_data FOR VALUES IN ('NAM-INDIA');
CREATE TABLE part."nse_cm_data_oberoirlty" PARTITION OF part.nse_cm_data FOR VALUES IN ('OBEROIRLTY');
CREATE TABLE part."nse_cm_data_ongc" PARTITION OF part.nse_cm_data FOR VALUES IN ('ONGC');
CREATE TABLE part."nse_cm_data_oil" PARTITION OF part.nse_cm_data FOR VALUES IN ('OIL');
CREATE TABLE part."nse_cm_data_piind" PARTITION OF part.nse_cm_data FOR VALUES IN ('PIIND');
CREATE TABLE part."nse_cm_data_pageind" PARTITION OF part.nse_cm_data FOR VALUES IN ('PAGEIND');
CREATE TABLE part."nse_cm_data_petronet" PARTITION OF part.nse_cm_data FOR VALUES IN ('PETRONET');
CREATE TABLE part."nse_cm_data_pfizer" PARTITION OF part.nse_cm_data FOR VALUES IN ('PFIZER');
CREATE TABLE part."nse_cm_data_pidilitind" PARTITION OF part.nse_cm_data FOR VALUES IN ('PIDILITIND');
CREATE TABLE part."nse_cm_data_pel" PARTITION OF part.nse_cm_data FOR VALUES IN ('PEL');
CREATE TABLE part."nse_cm_data_polycab" PARTITION OF part.nse_cm_data FOR VALUES IN ('POLYCAB');
CREATE TABLE part."nse_cm_data_pfc" PARTITION OF part.nse_cm_data FOR VALUES IN ('PFC');
CREATE TABLE part."nse_cm_data_powergrid" PARTITION OF part.nse_cm_data FOR VALUES IN ('POWERGRID');
CREATE TABLE part."nse_cm_data_prestige" PARTITION OF part.nse_cm_data FOR VALUES IN ('PRESTIGE');
CREATE TABLE part."nse_cm_data_pghh" PARTITION OF part.nse_cm_data FOR VALUES IN ('PGHH');
CREATE TABLE part."nse_cm_data_pnb" PARTITION OF part.nse_cm_data FOR VALUES IN ('PNB');
CREATE TABLE part."nse_cm_data_rblbank" PARTITION OF part.nse_cm_data FOR VALUES IN ('RBLBANK');
CREATE TABLE part."nse_cm_data_recltd" PARTITION OF part.nse_cm_data FOR VALUES IN ('RECLTD');
CREATE TABLE part."nse_cm_data_reliance" PARTITION OF part.nse_cm_data FOR VALUES IN ('RELIANCE');
CREATE TABLE part."nse_cm_data_sbicard" PARTITION OF part.nse_cm_data FOR VALUES IN ('SBICARD');
CREATE TABLE part."nse_cm_data_sbilife" PARTITION OF part.nse_cm_data FOR VALUES IN ('SBILIFE');
CREATE TABLE part."nse_cm_data_srf" PARTITION OF part.nse_cm_data FOR VALUES IN ('SRF');
CREATE TABLE part."nse_cm_data_sanofi" PARTITION OF part.nse_cm_data FOR VALUES IN ('SANOFI');
CREATE TABLE part."nse_cm_data_shreecem" PARTITION OF part.nse_cm_data FOR VALUES IN ('SHREECEM');
CREATE TABLE part."nse_cm_data_srtransfin" PARTITION OF part.nse_cm_data FOR VALUES IN ('SRTRANSFIN');
CREATE TABLE part."nse_cm_data_siemens" PARTITION OF part.nse_cm_data FOR VALUES IN ('SIEMENS');
CREATE TABLE part."nse_cm_data_sbin" PARTITION OF part.nse_cm_data FOR VALUES IN ('SBIN');
CREATE TABLE part."nse_cm_data_sail" PARTITION OF part.nse_cm_data FOR VALUES IN ('SAIL');
CREATE TABLE part."nse_cm_data_sunpharma" PARTITION OF part.nse_cm_data FOR VALUES IN ('SUNPHARMA');
CREATE TABLE part."nse_cm_data_suntv" PARTITION OF part.nse_cm_data FOR VALUES IN ('SUNTV');
CREATE TABLE part."nse_cm_data_syngene" PARTITION OF part.nse_cm_data FOR VALUES IN ('SYNGENE');
CREATE TABLE part."nse_cm_data_tvsmotor" PARTITION OF part.nse_cm_data FOR VALUES IN ('TVSMOTOR');
CREATE TABLE part."nse_cm_data_tatachem" PARTITION OF part.nse_cm_data FOR VALUES IN ('TATACHEM');
CREATE TABLE part."nse_cm_data_tcs" PARTITION OF part.nse_cm_data FOR VALUES IN ('TCS');
CREATE TABLE part."nse_cm_data_tataconsum" PARTITION OF part.nse_cm_data FOR VALUES IN ('TATACONSUM');
CREATE TABLE part."nse_cm_data_tataelxsi" PARTITION OF part.nse_cm_data FOR VALUES IN ('TATAELXSI');
CREATE TABLE part."nse_cm_data_tatamotors" PARTITION OF part.nse_cm_data FOR VALUES IN ('TATAMOTORS');
CREATE TABLE part."nse_cm_data_tatapower" PARTITION OF part.nse_cm_data FOR VALUES IN ('TATAPOWER');
CREATE TABLE part."nse_cm_data_tatasteel" PARTITION OF part.nse_cm_data FOR VALUES IN ('TATASTEEL');
CREATE TABLE part."nse_cm_data_techm" PARTITION OF part.nse_cm_data FOR VALUES IN ('TECHM');
CREATE TABLE part."nse_cm_data_ramcocem" PARTITION OF part.nse_cm_data FOR VALUES IN ('RAMCOCEM');
CREATE TABLE part."nse_cm_data_titan" PARTITION OF part.nse_cm_data FOR VALUES IN ('TITAN');
CREATE TABLE part."nse_cm_data_torntpharm" PARTITION OF part.nse_cm_data FOR VALUES IN ('TORNTPHARM');
CREATE TABLE part."nse_cm_data_torntpower" PARTITION OF part.nse_cm_data FOR VALUES IN ('TORNTPOWER');
CREATE TABLE part."nse_cm_data_trent" PARTITION OF part.nse_cm_data FOR VALUES IN ('TRENT');
CREATE TABLE part."nse_cm_data_upl" PARTITION OF part.nse_cm_data FOR VALUES IN ('UPL');
CREATE TABLE part."nse_cm_data_ultracemco" PARTITION OF part.nse_cm_data FOR VALUES IN ('ULTRACEMCO');
CREATE TABLE part."nse_cm_data_unionbank" PARTITION OF part.nse_cm_data FOR VALUES IN ('UNIONBANK');
CREATE TABLE part."nse_cm_data_ubl" PARTITION OF part.nse_cm_data FOR VALUES IN ('UBL');
CREATE TABLE part."nse_cm_data_mcdowell-n" PARTITION OF part.nse_cm_data FOR VALUES IN ('MCDOWELL-N');
CREATE TABLE part."nse_cm_data_vguard" PARTITION OF part.nse_cm_data FOR VALUES IN ('VGUARD');
CREATE TABLE part."nse_cm_data_vbl" PARTITION OF part.nse_cm_data FOR VALUES IN ('VBL');
CREATE TABLE part."nse_cm_data_vedl" PARTITION OF part.nse_cm_data FOR VALUES IN ('VEDL');
CREATE TABLE part."nse_cm_data_idea" PARTITION OF part.nse_cm_data FOR VALUES IN ('IDEA');
CREATE TABLE part."nse_cm_data_voltas" PARTITION OF part.nse_cm_data FOR VALUES IN ('VOLTAS');
CREATE TABLE part."nse_cm_data_whirlpool" PARTITION OF part.nse_cm_data FOR VALUES IN ('WHIRLPOOL');
CREATE TABLE part."nse_cm_data_wipro" PARTITION OF part.nse_cm_data FOR VALUES IN ('WIPRO');
CREATE TABLE part."nse_cm_data_yesbank" PARTITION OF part.nse_cm_data FOR VALUES IN ('YESBANK');
CREATE TABLE part."nse_cm_data_zeel" PARTITION OF part.nse_cm_data FOR VALUES IN ('ZEEL');
