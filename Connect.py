"""
    Connect.py
    modified by adding UDFs 
    API wrapper for XTS Connect REST APIs.

    :copyright:
    :license: see LICENSE for details.
"""
from six.moves.urllib.parse import urljoin
import json
import logging
import requests
import XTConnect.Exception as ex
from requests.adapters import HTTPAdapter
import configparser
from datetime import datetime,date
import pandas as pd
from pathlib import Path
from dateutil.relativedelta import relativedelta, TH , WE
from XTConnect.retry import retry
import time

#log = logging.getLogger(__name__)
logger = logging.getLogger('__main__')


class XTSCommon:
    """
    Base variables class
    """

    def __init__(self, token=None, userID=None, isInvestorClient=None):
        """Initialize the common variables."""
        self.token = token
        self.userID = userID
        self.isInvestorClient = isInvestorClient


class XTSConnect(XTSCommon):
    """
    The XTS Connect API wrapper class.
    In production, you may initialise a single instance of this class per `api_key`.
    """
    """Get the configurations from config.ini"""
    cfg = configparser.ConfigParser()
    cfg.read(r'D:\Users\lmahendran\Anaconda3\Lib\site-packages\xts-0.1-py3.7.egg\XTConnect\config.ini')

    # Default root API endpoint. It's possible to
    # override this by passing the `root` parameter during initialisation.
    _default_root_uri = cfg.get('root_url', 'root')
    _default_login_uri = _default_root_uri + "/user/session"
    _default_timeout = 7  # In seconds

    # SSL Flag
    _ssl_flag = cfg.get('SSL', 'disable_ssl')

    # Constants
    # Products
    PRODUCT_MIS = "MIS"
    PRODUCT_NRML = "NRML"

    # Order types
    ORDER_TYPE_MARKET = "MARKET"
    ORDER_TYPE_LIMIT = "LIMIT"

    # Transaction type
    TRANSACTION_TYPE_BUY = "BUY"
    TRANSACTION_TYPE_SELL = "SELL"

    # Squareoff mode
    SQUAREOFF_DAYWISE = "DayWise"
    SQUAREOFF_NETWISE = "Netwise"

    # Squareoff position quantity types
    SQUAREOFFQUANTITY_EXACTQUANTITY = "ExactQty"
    SQUAREOFFQUANTITY_PERCENTAGE = "Percentage"

    # Validity
    VALIDITY_DAY = "DAY"

    # Exchange Segments
    EXCHANGE_NSECM = "NSECM"
    EXCHANGE_NSEFO = "NSEFO"
    EXCHANGE_NSECD = "NSECD"
    EXCHANGE_MCXFO = "MCXFO"
    EXCHANGE_BSECM = "BSECM"
    
    #current date
    CDATE = datetime.strftime(datetime.now(), "%d-%m-%Y")
    # URIs to various calls
    _routes = {
        # Interactive API endpoints
        "interactive.prefix": "interactive",
        "user.login": "/interactive/user/session",
        "user.logout": "/interactive/user/session",
        "user.profile": "/interactive/user/profile",
        "user.balance": "/interactive/user/balance",

        "orders": "/interactive/orders",
        "trades": "/interactive/orders/trades",
        "order.status": "/interactive/orders",
        "order.place": "/interactive/orders",
        "order.place.cover": "/interactive/orders/cover",
        "order.exit.cover": "/interactive/orders/cover",
        "order.modify": "/interactive/orders",
        "order.cancel": "/interactive/orders",
        "order.history": "/interactive/orders",

        "portfolio.positions": "/interactive/portfolio/positions",
        "portfolio.holdings": "/interactive/portfolio/holdings",
        "portfolio.positions.convert": "/interactive/portfolio/positions/convert",
        "portfolio.squareoff": "/interactive/portfolio/squareoff",

        # Market API endpoints
        "marketdata.prefix": "marketdata",
        "market.login": "/marketdata/auth/login",
        "market.logout": "/marketdata/auth/logout",

        "market.config": "/marketdata/config/clientConfig",

        "market.instruments.master": "/marketdata/instruments/master",
        "market.instruments.subscription": "/marketdata/instruments/subscription",
        "market.instruments.unsubscription": "/marketdata/instruments/subscription",
        "market.instruments.ohlc": "/marketdata/instruments/ohlc",
        "market.instruments.indexlist": "/marketdata/instruments/indexlist",
        "market.instruments.quotes": "/marketdata/instruments/quotes",

        "market.search.instrumentsbyid": '/marketdata/search/instrumentsbyid',
        "market.search.instrumentsbystring": '/marketdata/search/instruments',

        "market.instruments.instrument.series": "/marketdata/instruments/instrument/series",
        "market.instruments.instrument.equitysymbol": "/marketdata/instruments/instrument/symbol",
        "market.instruments.instrument.futuresymbol": "/marketdata/instruments/instrument/futureSymbol",
        "market.instruments.instrument.optionsymbol": "/marketdata/instruments/instrument/optionsymbol",
        "market.instruments.instrument.optiontype": "/marketdata/instruments/instrument/optionType",
        "market.instruments.instrument.expirydate": "/marketdata/instruments/instrument/expiryDate"
    }

    def __init__(self,
                 apiKey,
                 secretKey,
                 source,
                 root=None,
                 debug=False,
                 timeout=None,
                 pool=None,
                 disable_ssl=_ssl_flag):
        """
        Initialise a new XTS Connect client instance.

        - `api_key` is the key issued to you
        - `token` is the token obtained after the login flow. Pre-login, this will default to None,
        but once you have obtained it, you should persist it in a database or session to pass
        to the XTS Connect class initialisation for subsequent requests.
        - `root` is the API end point root. Unless you explicitly
        want to send API requests to a non-default endpoint, this
        can be ignored.
        - `debug`, if set to True, will serialise and print requests
        and responses to stdout.
        - `timeout` is the time (seconds) for which the API client will wait for
        a request to complete before it fails. Defaults to 7 seconds
        - `pool` is manages request pools. It takes a dict of params accepted by HTTPAdapter
        - `disable_ssl` disables the SSL verification while making a request.
        If set requests won't throw SSLError if its set to custom `root` url without SSL.
        """
        self.debug = debug
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.source = source
        self.disable_ssl = disable_ssl
        self.root = root or self._default_root_uri
        self.timeout = timeout or self._default_timeout

        super().__init__()

        # Create requests session only if pool exists. Reuse session
        # for every request. Otherwise create session for each request
        if pool:
            self.reqsession = requests.Session()
            reqadapter = requests.adapters.HTTPAdapter(**pool)
            self.reqsession.mount("https://", reqadapter)
        else:
            self.reqsession = requests

        # disable requests SSL warning
        requests.packages.urllib3.disable_warnings()

    def _set_common_variables(self, access_token, userID, isInvestorClient=None):
        """Set the `access_token` received after a successful authentication."""
        super().__init__(access_token, userID, isInvestorClient)

    def _login_url(self):
        """Get the remote login url to which a user should be redirected to initiate the login flow."""
        return self._default_login_uri

    def interactive_login(self):
        """Send the login url to which a user should receive the token."""
        try:
            params = {
                "appKey": self.apiKey,
                "secretKey": self.secretKey,
                "source": self.source
            }

            response = self._post("user.login", params)

            if "token" in response['result']:
                self._set_common_variables(response['result']['token'], response['result']['userID'],
                                           response['result']['isInvestorClient'])
            return response
        except Exception as e:
            return response['description']

    def get_order_book(self):
        """Request Order book gives states of all the orders placed by an user"""
        try:
            params = {}
            if not self.isInvestorClient:
                params['clientID'] = self.userID
            response = self._get("order.status", params)
            return response
        except Exception as e:
            return response['description']

    def place_order(self,
                    exchangeSegment,
                    exchangeInstrumentID,
                    productType,
                    orderType,
                    orderSide,
                    timeInForce,
                    disclosedQuantity,
                    orderQuantity,
                    limitPrice,
                    stopPrice,
                    orderUniqueIdentifier
                    ):
        """To place an order"""
        try:

            params = {
                "exchangeSegment": exchangeSegment,
                "exchangeInstrumentID": exchangeInstrumentID,
                "productType": productType,
                "orderType": orderType,
                "orderSide": orderSide,
                "timeInForce": timeInForce,
                "disclosedQuantity": disclosedQuantity,
                "orderQuantity": orderQuantity,
                "limitPrice": limitPrice,
                "stopPrice": stopPrice,
                "orderUniqueIdentifier": orderUniqueIdentifier
            }

            if not self.isInvestorClient:
                params['clientID'] = self.userID

            response = self._post('order.place', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def get_profile(self):
        """Using session token user can access his profile stored with the broker, it's possible to retrieve it any
        point of time with the http: //ip:port/interactive/user/profile API. """
        try:
            params = {}
            if not self.isInvestorClient:
                params['clientID'] = self.userID

            response = self._get('user.profile', params)
            return response
        except Exception as e:
            return response['description']

    def get_balance(self):
        """Get Balance API call grouped under this category information related to limits on equities, derivative,
        upfront margin, available exposure and other RMS related balances available to the user."""
        if self.isInvestorClient:
            try:
                params = {}
                if not self.isInvestorClient:
                    params['clientID'] = self.userID
                response = self._get('user.balance', params)
                return response
            except Exception as e:
                return response['description']
        else:
            print("Balance : Balance API available for retail API users only, dealers can watch the same on dealer "
                  "terminal")

    def modify_order(self,
                     appOrderID,
                     modifiedProductType,
                     modifiedOrderType,
                     modifiedOrderQuantity,
                     modifiedDisclosedQuantity,
                     modifiedLimitPrice,
                     modifiedStopPrice,
                     modifiedTimeInForce,
                     orderUniqueIdentifier
                     ):
        """The facility to modify your open orders by allowing you to change limit order to market or vice versa,
        change Price or Quantity of the limit open order, change disclosed quantity or stop-loss of any
        open stop loss order. """
        try:
            appOrderID = int(appOrderID)
            params = {
                'appOrderID': appOrderID,
                'modifiedProductType': modifiedProductType,
                'modifiedOrderType': modifiedOrderType,
                'modifiedOrderQuantity': modifiedOrderQuantity,
                'modifiedDisclosedQuantity': modifiedDisclosedQuantity,
                'modifiedLimitPrice': modifiedLimitPrice,
                'modifiedStopPrice': modifiedStopPrice,
                'modifiedTimeInForce': modifiedTimeInForce,
                'orderUniqueIdentifier': orderUniqueIdentifier
            }

            if not self.isInvestorClient:
                params['clientID'] = self.userID

            response = self._put('order.modify', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def get_trade(self):
        """Trade book returns a list of all trades executed on a particular day , that were placed by the user . The
        trade book will display all filled and partially filled orders. """
        try:
            params = {}
            if not self.isInvestorClient:
                params['clientID'] = self.userID
            response = self._get('trades', params)
            return response
        except Exception as e:
            return response['description']

    def get_holding(self):
        """Holdings API call enable users to check their long term holdings with the broker."""
        try:
            params = {}
            if not self.isInvestorClient:
                params['clientID'] = self.userID

            response = self._get('portfolio.holdings', params)
            return response
        except Exception as e:
            return response['description']

    def get_position_daywise(self):
        """The positions API returns positions by day, which is a snapshot of the buying and selling activity for
        that particular day."""
        try:
            params = {'dayOrNet': 'DayWise'}
            if not self.isInvestorClient:
                params['clientID'] = self.userID

            response = self._get('portfolio.positions', params)
            return response
        except Exception as e:
            return response['description']

    def get_position_netwise(self):
        """The positions API positions by net. Net is the actual, current net position portfolio."""
        try:
            params = {'dayOrNet': 'NetWise'}
            if not self.isInvestorClient:
                params['clientID'] = self.userID
            response = self._get('portfolio.positions', params)
            return response
        except Exception as e:
            return response['description']

    def convert_position(self, exchangeSegment, exchangeInstrumentID, targetQty, isDayWise, oldProductType,
                         newProductType):
        """Convert position API, enable users to convert their open positions from NRML intra-day to Short term MIS or
        vice versa, provided that there is sufficient margin or funds in the account to effect such conversion """
        try:
            params = {
                'exchangeSegment': exchangeSegment,
                'exchangeInstrumentID': exchangeInstrumentID,
                'targetQty': targetQty,
                'isDayWise': isDayWise,
                'oldProductType': oldProductType,
                'newProductType': newProductType
            }
            if not self.isInvestorClient:
                params['clientID'] = self.userID
            response = self._put('portfolio.positions.convert', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def cancel_order(self, appOrderID, orderUniqueIdentifier):
        """This API can be called to cancel any open order of the user by providing correct appOrderID matching with
        the chosen open order to cancel. """
        try:
            params = {'appOrderID': int(appOrderID), 'orderUniqueIdentifier': orderUniqueIdentifier}
            if not self.isInvestorClient:
                params['clientID'] = self.userID
            response = self._delete('order.cancel', params)
            return response
        except Exception as e:
            return response['description']

    def place_cover_order(self, exchangeSegment, exchangeInstrumentID, orderSide,orderType, orderQuantity, disclosedQuantity,
                          limitPrice, stopPrice, orderUniqueIdentifier):
        """A Cover Order is an advance intraday order that is accompanied by a compulsory Stop Loss Order. This helps
        users to minimize their losses by safeguarding themselves from unexpected market movements. A Cover Order
        offers high leverage and is available in Equity Cash, Equity F&O, Commodity F&O and Currency F&O segments. It
        has 2 orders embedded in itself, they are Limit/Market Order Stop Loss Order """
        try:

            params = {'exchangeSegment': exchangeSegment, 'exchangeInstrumentID': exchangeInstrumentID,
                      'orderSide': orderSide, "orderType": orderType,'orderQuantity': orderQuantity, 'disclosedQuantity': disclosedQuantity,
                      'limitPrice': limitPrice, 'stopPrice': stopPrice, 'orderUniqueIdentifier': orderUniqueIdentifier}
            if not self.isInvestorClient:
                params['clientID'] = self.userID
            response = self._post('order.place.cover', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def exit_cover_order(self, appOrderID):
        """Exit Cover API is a functionality to enable user to easily exit an open stoploss order by converting it
        into Exit order. """
        try:

            params = {'appOrderID': appOrderID}
            if not self.isInvestorClient:
                params['clientID'] = self.userID
            response = self._put('order.exit.cover', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def squareoff_position(self, exchangeSegment, exchangeInstrumentID, productType, squareoffMode,
                           positionSquareOffQuantityType, squareOffQtyValue, blockOrderSending, cancelOrders):
        """User can request square off to close all his positions in Equities, Futures and Option. Users are advised
        to use this request with caution if one has short term holdings. """
        try:

            params = {'exchangeSegment': exchangeSegment, 'exchangeInstrumentID': exchangeInstrumentID,
                      'productType': productType, 'squareoffMode': squareoffMode,
                      'positionSquareOffQuantityType': positionSquareOffQuantityType,
                      'squareOffQtyValue': squareOffQtyValue, 'blockOrderSending': blockOrderSending,
                      'cancelOrders': cancelOrders
                      }
            if not self.isInvestorClient:
                params['clientID'] = self.userID
            response = self._put('portfolio.squareoff', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def get_order_history(self, appOrderID):
        """Order history will provide particular order trail chain. This indicate the particular order & its state
        changes. i.e.Pending New to New, New to PartiallyFilled, PartiallyFilled, PartiallyFilled & PartiallyFilled
        to Filled etc """
        try:
            params = {'appOrderID': appOrderID}
            if not self.isInvestorClient:
                params['clientID'] = self.userID
            response = self._get('order.history', params)
            return response
        except Exception as e:
            return response['description']

    def interactive_logout(self):
        """This call invalidates the session token and destroys the API session. After this, the user should go
        through login flow again and extract session token from login response before further activities. """
        try:
            params = {}
            if not self.isInvestorClient:
                params['clientID'] = self.userID
            response = self._delete('user.logout', params)
            return response
        except Exception as e:
            return response['description']

    @retry(n_tries=2, delay=2)
    def get_order_list(self):
        #logger.info('Checking OrderBook for order status..')
        oBook_resp = self.get_order_book()
        if oBook_resp['type'] != "error":
            orderList =  oBook_resp['result']
            #logger.info('OrderBook result retreived success')
            return orderList
        else:
            logger.info("error in get_order_list func")
            logger.info(oBook_resp['description'])
            raise ex.XTSDataException('Issue in retreiving orderbook')
            return 0


    def place_order_id(self,symbol,txn_type,qty,xseg='fo'):
        logger.info('UDF: Placing Orders..')
        # Place an intraday stop loss order on NSE
        order_id = None
        
        segment = self.EXCHANGE_NSEFO if xseg.upper() == 'FO' else self.EXCHANGE_NSECM
        if txn_type == "buy":
            t_type = self.TRANSACTION_TYPE_BUY
        elif txn_type == "sell":
            t_type = self.TRANSACTION_TYPE_SELL
        try:
            order_resp = self.place_order(exchangeSegment=segment,
                             exchangeInstrumentID= symbol ,
                             productType=self.PRODUCT_MIS,
                             orderType=self.ORDER_TYPE_MARKET,
                             orderSide=t_type,
                             timeInForce=self.VALIDITY_DAY,
                             disclosedQuantity=0,
                             orderQuantity=qty,
                             limitPrice=0,
                             stopPrice=0,
                             orderUniqueIdentifier="FC_MarketOrder"
                             )
            #print(order_resp)
            if order_resp['type'] != 'error':
                order_id = order_resp['result']['AppOrderID']            #extracting the order id from response
                logger.info(f'UDF: Order ID for {t_type} {symbol} is: {order_id}')
            elif order_resp['type'] == 'error':
                logger.error(f"Error Response: {order_resp['description']}")
                raise ex.XTSDataException('UDF : Issue in placing orders')
        except Exception:
            logger.exception('UDF: Unable to place order')
        
        return order_id


    def get_traded_price(self,order_id):
        tradedPrice = None
        dateTime = None
        try:
            a=0
            while a<12:
                order_lists = self.get_order_list()
                if order_lists:
                    new_orders = [ol for ol in order_lists if ol['AppOrderID'] == order_id and ol['OrderStatus'] != 'Filled']
                    if not new_orders:
                        tradedPrice = float(next((orderList['OrderAverageTradedPrice'] \
                                            for orderList in order_lists \
                                                if orderList['AppOrderID'] == order_id and\
                                                    orderList['OrderStatus'] == 'Filled'),None).replace(',', ''))
                        LastUpdateDateTime=datetime.fromisoformat(next((orderList['LastUpdateDateTime'] for orderList in order_lists if orderList['AppOrderID'] == order_id and orderList['OrderStatus'] == 'Filled'))[0:19])
                        dateTime = LastUpdateDateTime.strftime("%Y-%m-%d %H:%M:%S")
                        logger.info(f"traded price is: {tradedPrice} and ordered  time is: {dateTime}")
                        # return tradedPrice, dateTime
                        break
                        # loop = False
                    else:
                        logger.info(f' Placed order {order_id} might be in Open or New Status, Hence retrying..{a}')
                        a+=1
                        time.sleep(2.5)
                        if a==11:
                            logger.info('Placed order is still in New or Open Status..Hence Cancelling the placed order')
                            self.cancel_order_id(order_id)
                            # return None, None
                            break
        except Exception as e:
            logger.exception(f'Unable to get traded price and time : {e}')
        return tradedPrice, dateTime

    def cancel_order_id(self,OrderID):
        try:
            logger.info(f'Cancelling order: {OrderID} ')
            cancel_resp = self.cancel_order(
                                            appOrderID=OrderID,
                                            orderUniqueIdentifier='FC_Cancel_Orders_1')
            if cancel_resp['type'] != 'error':
                cancelled_SL_orderID = cancel_resp['result']['AppOrderID']
                logger.info(f'Cancelled SL order id : {cancelled_SL_orderID}')
                return cancelled_SL_orderID
            elif cancel_resp['type'] == 'error':
                logger.error(f'Cancel order not processed for : {OrderID}')
        except:
            return None

        
    def strike_price(self,idx=None):
        strikePrice = None
        if idx == 'NIFTY':
            base = 50
            ids = 'NIFTY 50'
        elif idx == 'NIFTYBANK':
            base = 100
            ids = 'NIFTY BANK'
        # if idx in idxs:
            # base,ids = [50,'Nifty 50'] if idx == 'NIFTY' else [100,'NIFTY BANK']
        else:
            logger.info(f'Invalid Index name {idx}, try NIFTY or NIFTYBANK')
        try:
            idx_instruments = [{'exchangeSegment': 1, 'exchangeInstrumentID': ids}]
            spot_resp = self.get_quote(
                        Instruments=idx_instruments,
                        xtsMessageCode=1504,
                        publishFormat='JSON')
            if spot_resp['type'] !='error':
                listQuotes = json.loads(spot_resp['result']['listQuotes'][0])
                spot=listQuotes['IndexValue']
            else:
                logger.error(spot_resp['description'])
                raise Exception()
        except Exception:
            logger.exception(f'Unable to getSpot from index {ids}')
            # exit()
        else:
            strikePrice = base * round(spot/base)
            logger.info(f'StrikePrice computed as : {strikePrice}')
            
        return strikePrice
    
    
    def get_expiry(self):
        weekly_exp = None
        monthly_exp = None
        try:
            now = datetime.today()
            cmon = now.month
            xpry_resp = self.get_expiry_date(exchangeSegment=2, series='OPTIDX', symbol='NIFTY')
            if 'result' in xpry_resp:
                expiry_dates = xpry_resp['result']
            else:
                logger.error(f"UDF: Error getting Expiry dates. Reason:{xpry_resp['description']}")
                raise ex.XTSDataException('No response received: ')
        
            thu = (now + relativedelta(weekday=TH(1))).strftime('%d%b%Y')
            wed = (now + relativedelta(weekday=WE(1))).strftime('%d%b%Y')
        
            weekly_exp = thu if thu in expiry_dates else wed
            logger.info(f'UDF: {weekly_exp} is the week expiry')
        
            nxtmon = (now + relativedelta(weekday=TH(1))).month
            if (nxtmon != cmon):
                month_last_thu_expiry = now + relativedelta(weekday=TH(5))
                mon_thu = (now + relativedelta(weekday=TH(5))).strftime('%d%b%Y')
                mon_wed = (now + relativedelta(weekday=WE(5))).strftime('%d%b%Y')
                if (month_last_thu_expiry.month!= nxtmon):
                    mon_thu = (now + relativedelta(weekday=TH(4))).strftime('%d%b%Y')
                    mon_wed = (now + relativedelta(weekday=WE(4))).strftime('%d%b%Y')
            else:
                for i in range(1, 7):
                    t = now + relativedelta(weekday=TH(i))
                    if t.month != cmon:
                        # since t is exceeded we need last one  which we can get by subtracting -2 since it is already a Thursday.
                        mon_thu = (t + relativedelta(weekday=TH(-2))).strftime('%d%b%Y')
                        mon_wed = (t + relativedelta(weekday=WE(-2))).strftime('%d%b%Y')
                        break
            monthly_exp = mon_thu if mon_thu in expiry_dates else mon_wed
            logger.info(f'UDF: {monthly_exp} is the month expiry')
        except Exception as e:
            logger.exception(f'Error in Expiry date function - {e}')
            
        return weekly_exp, monthly_exp
        
    
    def master_fo_dump(self):
        instrument_df = None
        try:
            filename = f'../ohlc/NSE_FO_Instruments_{self.CDATE}.csv'
            file = Path(filename)
            if file.exists() and (date.today() == date.fromtimestamp(file.stat().st_mtime)):
                logger.info('UDF: MasterDump already exists.. reading directly')
                mstr_df = pd.read_csv(filename,header='infer')
            else:
                logger.info('UDF: Creating FO MasterDump..')
                exchangesegments = [self.EXCHANGE_NSEFO]
                mastr_resp = self.get_master(exchangeSegmentList=exchangesegments)
                # print("Master: " + str(mastr_resp))
                master=mastr_resp['result']
                spl=master.split('\n')
                mstr_df = pd.DataFrame([sub.split("|") for sub in spl],columns=(['ExchangeSegment','ExchangeInstrumentID','InstrumentType','Name','Description','Series','NameWithSeries','InstrumentID','PriceBand.High','PriceBand.Low','FreezeQty','TickSize',' LotSize','UnderlyingInstrumentId','UnderlyingIndexName','ContractExpiration','StrikePrice','OptionType']))
                # instrument_df = mstr_df[mstr_df.Series == 'OPTIDX']
                mstr_df.to_csv(f"../ohlc/NSE_FO_Instruments_{self.CDATE}.csv",index=False)
        except Exception as e:
            logger.exception(f"Error Response : {e}")
        
        return mstr_df
    
        
    def master_eq_dump(self):
        instrument_df = None
        try:
            filename=f'../ohlc/NSE_EQ_Instruments_{self.CDATE}.csv'
            file = Path(filename)
            if file.exists() and (date.today() == date.fromtimestamp(file.stat().st_mtime)):
                logger.info('UDF: MasterDump already exists.. reading directly')
                instrument_df = pd.read_csv(filename,header='infer')
            else:
                logger.info('UDF: Creating EQ MasterDump..')
                #xt = xts_init(market=True)
                exchangesegments = [self.EXCHANGE_NSECM]
                mastr_resp = self.get_master(exchangeSegmentList=exchangesegments)
                # print("Master: " + str(mastr_resp))
                master = mastr_resp['result']
                spl=master.split('\n')
                mstr_df = pd.DataFrame([sub.split("|") for sub in spl],columns=(['ExchangeSegment','ExchangeInstrumentID','InstrumentType','Name','Description','Series','NameWithSeries','InstrumentID','PriceBand.High','PriceBand.Low','FreezeQty','TickSize',' LotSize']))
                instrument_df = mstr_df[mstr_df.Series == 'EQ']
                instrument_df.to_csv(f"../ohlc/NSE_EQ_Instruments_{self.CDATE}.csv",index=False)
        except Exception as e:
            logger.exception(f"Error Response : {e}")
            
        return instrument_df
            
    
    def fo_lookup(self, symbol, instrument_df=[]):
        """Looks up instrument token for a given script from instrument dump"""
        df = self.master_fo_dump() if len(instrument_df) == 0 else instrument_df
        try:
            return int(df[df.Description==symbol].ExchangeInstrumentID.values[0])
        except:
            return -1
    
    
    def eq_lookup(self, symbol, instrument_df=[]):
        """Looks up instrument token for a given script from instrument dump"""
        df = self.master_eq_dump() if len(instrument_df) == 0 else instrument_df
        try:
            return int(df[df.Name==symbol].ExchangeInstrumentID.values[0])
        except:
            return -1


    def ltp_eq(self, symbol=None, ltp=None):
        try:
            if symbol != None:
                id1 = symbol if str(symbol).isdigit() else self.eq_lookup(symbol)
                if id1 != -1:
                    instruments=[]
                    instruments.append({'exchangeSegment': 1, 'exchangeInstrumentID': id1})
                    # xt = xts_init(market=True)
                    quote_resp = self.get_quote(Instruments=instruments,xtsMessageCode=1501,
                        publishFormat='JSON')
                    ltp = json.loads(quote_resp['result']['listQuotes'][0])['LastTradedPrice']
            else:
                logger.error('UDF: pass valid symbol or id')
        except Exception as e:
            logger.exception(f'Error in fetching ltp - {e}')
        
        return ltp
    
    
    def ltp_fo(self, symbol=None, ltp=None):
        try:
            if symbol != None:
                id1 = symbol if str(symbol).isdigit() else self.fo_lookup(symbol)
                if id1 != -1:
                    instruments=[]
                    instruments.append({'exchangeSegment': 1, 'exchangeInstrumentID': int(id1)})
                    # xt = xts_init(market=True)
                    quote_resp = self.get_quote(Instruments=instruments,xtsMessageCode=1501,
                        publishFormat='JSON')
                    ltp = json.loads(quote_resp['result']['listQuotes'][0])['LastTradedPrice']
            else:
                logger.error('UDF: pass valid symbol or id')
        except Exception as e:
            logger.exception(f'Error in fetching ltp - {e}')
        
        return ltp
    
    
    ########################################################################################################
    # Market data API
    ########################################################################################################

    def marketdata_login(self):
        try:
            params = {
                "appKey": self.apiKey,
                "secretKey": self.secretKey,
                "source": self.source
            }
            response = self._post("market.login", params)

            if "token" in response['result']:
                self._set_common_variables(response['result']['token'], response['result']['userID'])
            return response
        except Exception as e:
            return response['description']

    def get_config(self):
        try:
            params = {}
            response = self._get('market.config', params)
            return response
        except Exception as e:
            return response['description']

    def get_quote(self, Instruments, xtsMessageCode, publishFormat):
        try:

            params = {'instruments': Instruments, 'xtsMessageCode': xtsMessageCode, 'publishFormat': publishFormat}
            response = self._post('market.instruments.quotes', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def send_subscription(self, Instruments, xtsMessageCode):
        try:
            params = {'instruments': Instruments, 'xtsMessageCode': xtsMessageCode}
            response = self._post('market.instruments.subscription', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def send_unsubscription(self, Instruments, xtsMessageCode):
        try:
            params = {'instruments': Instruments, 'xtsMessageCode': xtsMessageCode}
            response = self._put('market.instruments.unsubscription', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def get_master(self, exchangeSegmentList):
        try:
            params = {"exchangeSegmentList": exchangeSegmentList}
            response = self._post('market.instruments.master', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def get_ohlc(self, exchangeSegment, exchangeInstrumentID, startTime, endTime, compressionValue):
        try:
            params = {
                'exchangeSegment': exchangeSegment,
                'exchangeInstrumentID': exchangeInstrumentID,
                'startTime': startTime,
                'endTime': endTime,
                'compressionValue': compressionValue}
            response = self._get('market.instruments.ohlc', params)
            return response
        except Exception as e:
            return response['description']

    def get_series(self, exchangeSegment):
        try:
            params = {'exchangeSegment': exchangeSegment}
            response = self._get('market.instruments.instrument.series', params)
            return response
        except Exception as e:
            return response['description']

    def get_equity_symbol(self, exchangeSegment, series, symbol):
        try:

            params = {'exchangeSegment': exchangeSegment, 'series': series, 'symbol': symbol}
            response = self._get('market.instruments.instrument.equitysymbol', params)
            return response
        except Exception as e:
            return response['description']

    def get_expiry_date(self, exchangeSegment, series, symbol):
        try:
            params = {'exchangeSegment': exchangeSegment, 'series': series, 'symbol': symbol}
            response = self._get('market.instruments.instrument.expirydate', params)
            return response
        except Exception as e:
            return response['description']

    def get_future_symbol(self, exchangeSegment, series, symbol, expiryDate):
        try:
            params = {'exchangeSegment': exchangeSegment, 'series': series, 'symbol': symbol, 'expiryDate': expiryDate}
            response = self._get('market.instruments.instrument.futuresymbol', params)
            return response
        except Exception as e:
            return response['description']

    def get_option_symbol(self, exchangeSegment, series, symbol, expiryDate, optionType, strikePrice):
        try:
            params = {'exchangeSegment': exchangeSegment, 'series': series, 'symbol': symbol, 'expiryDate': expiryDate,
                      'optionType': optionType, 'strikePrice': strikePrice}
            response = self._get('market.instruments.instrument.optionsymbol', params)
            return response
        except Exception as e:
            return response['description']

    def get_option_type(self, exchangeSegment, series, symbol, expiryDate):
        try:
            params = {'exchangeSegment': exchangeSegment, 'series': series, 'symbol': symbol, 'expiryDate': expiryDate}
            response = self._get('market.instruments.instrument.optiontype', params)
            return response
        except Exception as e:
            return response['description']

    def get_index_list(self, exchangeSegment):
        try:
            params = {'exchangeSegment': exchangeSegment}
            response = self._get('market.instruments.indexlist', params)
            return response
        except Exception as e:
            return response['description']

    def search_by_instrumentid(self, Instruments):
        try:
            params = {'source': self.source, 'instruments': Instruments}
            response = self._post('market.search.instrumentsbyid', json.dumps(params))
            return response
        except Exception as e:
            return response['description']

    def search_by_scriptname(self, searchString):
        try:
            params = {'searchString': searchString}
            response = self._get('market.search.instrumentsbystring', params)
            return response
        except Exception as e:
            return response['description']

    def marketdata_logout(self):
        try:
            params = {}
            response = self._delete('market.logout', params)
            return response
        except Exception as e:
            return response['description']

    ########################################################################################################
    # Common Methods
    ########################################################################################################

    def _get(self, route, params=None):
        """Alias for sending a GET request."""
        return self._request(route, "GET", params)

    def _post(self, route, params=None):
        """Alias for sending a POST request."""
        return self._request(route, "POST", params)

    def _put(self, route, params=None):
        """Alias for sending a PUT request."""
        return self._request(route, "PUT", params)

    def _delete(self, route, params=None):
        """Alias for sending a DELETE request."""
        return self._request(route, "DELETE", params)

    def _request(self, route, method, parameters=None):
        """Make an HTTP request."""
        params = parameters if parameters else {}

        # Form a restful URL
        uri = self._routes[route].format(params)
        url = urljoin(self.root, uri)
        headers = {}

        if self.token:
            # set authorization header
            headers.update({'Content-Type': 'application/json', 'Authorization': self.token})

        try:
            r = self.reqsession.request(method,
                                        url,
                                        data=params if method in ["POST", "PUT"] else None,
                                        params=params if method in ["GET", "DELETE"] else None,
                                        headers=headers,
                                        verify=not self.disable_ssl)

        except Exception as e:
            raise e

        if self.debug:
            logger.debug("Response: {code} {content}".format(code=r.status_code, content=r.content))

        # Validate the content type.
        if "json" in r.headers["content-type"]:
            try:
                data = json.loads(r.content.decode("utf8"))
            except ValueError:
                raise ex.XTSDataException("Couldn't parse the JSON response received from the server: {content}".format(
                    content=r.content))

            # api error
            if data.get("type"):

                if r.status_code == 400 and data["type"] == "error" and data["description"] == "Invalid Token":
                    raise ex.XTSTokenException(data["description"])

                if r.status_code == 400 and data["type"] == "error" and data["description"] == "Bad Request":
                    message = "Description: " + data["description"] + " errors: " + data['result']["errors"]
                    raise ex.XTSInputException(str(message))

            return data
        else:
            raise ex.XTSDataException("Unknown Content-Type ({content_type}) with response: ({content})".format(
                content_type=r.headers["content-type"],
                content=r.content))
