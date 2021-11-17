import argparse

parser = argparse.ArgumentParser(description='Optionables Script')
parser.add_argument('-t', '--ticker',type=str, required=True, help='NIFTY or BANKNIFTY')
parser.add_argument('-st', '--startTime',type=str, required=True, help='start time of the script')
parser.add_argument('-et', '--endTime',type=str, default="15:05:00", help='end time')
group = parser.add_mutually_exclusive_group()
group.add_argument('-slc', '--stopLossPct',type=float, help='StopLoss in percentage')
group.add_argument('-slp', '--stopLossPoints',type=int, help='stopLoss  points')
# parser.add_argument('-tgt', '--target',type=int, default=3000, help='Target amount')
args = parser.parse_args()
ticker = args.ticker
startTime = args.startTime
endTime = args.endTime
stop_loss_pct = args.stopLossPct
stop_loss_points = args.stopLossPoints



print(ticker)
print(startTime)
print(endTime)
print(stop_loss_pct)
print(stop_loss_points)

final_sl = stop_loss_pct if stop_loss_pct is not None else stop_loss_points
print(final_sl)