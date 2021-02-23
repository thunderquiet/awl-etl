

import datetime

import boto3
from boto3.dynamodb.conditions import Key, Attr


def run():
    client = boto3.client('dynamodb', region_name='ap-northeast-1')

    # we already specified all this in terraform -> can't we just expose it via env vars or something???
    transaction_list = client.scan( TableName='wtb_api_events-test', Limit=100 ) #take random 100 entries

    # Sample record:
    # 'hash': 'b97a9eda2609b514d2b9940fdd067f1c194c4ad0ce1d42c37b059068e6a0a03a'
    # 'blockchain': 'bitcoin' 
    # 'transaction_count': '1'
    # 'from': {'owner': 'coinbase', 'owner_type': 'exchange', 'address': '3Qzi9GCXoEJSc45CCDn1ig1ATrssDVzYsk'},
    # 'symbol': 'btc',
    # 'timestamp': '1610145610',
    # 'amount': '26.383205',
    # 'amount_usd': '1074988.6',
    # 'id': '1238024820',
    # 'to': {'owner_type': 'unknown', 'address': '3NV5KNTaJfmHPNXthMTaXHq6ADUDdmPhX1'},
    # 'transaction_type': 'transfer'

    # we are going to get the timestamp and date and sum the amounts per each period
    # Note that timestamp is when the transaction was written to the block - each block contains multiple transactions
    #   hence a bunch of transactions will have exact same timestamp

    date_sums = {}
    timestamp_sums = {}
    for tran in transaction_list["Items"]:
        timestamp = tran["timestamp"]["N"]
        date = datetime.datetime.fromtimestamp( int(timestamp) ).strftime("%Y%m%d")
        amount = float(tran["amount"]["N"])

        if not timestamp in timestamp_sums:
            timestamp_sums[timestamp] = 0;
        if not date in date_sums:
            date_sums[date] = 0

        timestamp_sums[timestamp] += amount
        date_sums[date] += amount


    print("Aggregated Data")
    print( date_sums )
    print( timestamp_sums )


if __name__ == '__main__':
    run()

