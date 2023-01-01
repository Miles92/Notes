import MetaTrader5 as mt5
import datetime as dt
import matplotlib.pyplot as plt
from matplotlib.pyplot import rcParams
import telegram

# set the default font family to "Arial" using the rcParams function
rcParams["font.family"] = "Calibri"

def sum_profit(deals, type_str):
  # initialize the profit variable to 0
  profit = 0
  # iterate over the deals
  for deal in deals:
    # check if the deal was executed in the market
    # and has a non-zero profit
    if deal.type != -1 and deal.profit != 0.0 and deal.type == type_str:
      # add the profit to the total profit
      profit += round(deal.profit, 2)
  # return the total profit
  return profit

# connect to the MetaTrader 5 terminal
if not mt5.initialize():
    print("initialize() failed, error code =", mt5.last_error())
    quit()

try:
  # retrieve the number of days to go back
  days_back = 5
  # calculate the date range
  today = dt.datetime.now()
  date_from = today - dt.timedelta(days=days_back)
  date_to = today

  deals = mt5.history_deals_get(date_from, date_to)

  # check if there was an error
  if deals is None:
      error_code = mt5.last_error()
      print("history_deals_get() failed, error code =", error_code)
      print("error message:", (error_code))
      mt5.shutdown()

  # calculate the total profit for each deal type
  buy_profit = round(sum_profit(deals, 1), 2)
  sell_profit = round(sum_profit(deals, 0), 2)


  # create a table that shows the total profit for each deal type
  # as well as a list of the individual deals
  # specify the size of the plot using the figsize parameter
  fig, ax = plt.subplots(dpi=300, figsize=(8, 6))
  plt.subplots_adjust(top=0.9)
  ax.axis("off")
  deal_text = []
  for deal in deals:
    # only add deals with non-zero profit and that were executed in the market
    if deal.profit != 0.0 and deal.type != -1:
      # convert the Unix timestamp to a datetime object
      deal_time = dt.datetime.fromtimestamp(deal.time)
      # format the date and time in a human-readable format
      deal_time_str = deal_time.strftime("%Y-%m-%d %H:%M:%S")

      # check the value of the TradeDeal.type attribute
      if deal.type == 1:
        # if the deal type is 1, set the
        # if the deal type is 1, set the deal type string to "Buy"
        deal_type_str = "Buy"
      else:
        # if the deal type is not 1, set the deal type string to "Sell"
        deal_type_str = "Sell"

      # add the deal type string, symbol, profit, and close date to the deal text
      deal_text.append([deal_type_str, deal.symbol, deal.profit, deal_time_str])

  # calculate the total profit of all trades
  total_profit = round(sum_profit(deals, 1) + sum_profit(deals, 0), 2)

  ax.table(cellText=deal_text, colLabels=["Deal type", "Symbol", "Profit (USD)", "Close time"], loc="center", cellLoc="left")
  ax.set_title(f"Profit from the last {days_back} days", fontsize=20)

  # add the total profit text to the plot using the text() function
  # specify the position, font size, and font weight of the text
  ax.text(0.65, 0.05, "Total profit: " + str(total_profit) + " USD", fontsize=15, fontweight="bold")

  # save the plotted output to an image file
  plt.savefig(r"C:\Users\stefan.mueller\Downloads\Results\plot.png", dpi=300)

  plt.show()

  # create a bot using the API key
  bot = telegram.Bot(token="123456789:ABCDEFWEFHWEFWEf")

  # open the image file in binary mode
  with open(r"C:\Users\stefan.mueller\Downloads\Results\plot.png", "rb") as f:
    # send the image to the test results chat
    bot.send_photo(chat_id="-123456789", photo=f, caption=f"Total profit for the last {days_back} days: {total_profit} USD 💰")
  
    # send the image to the real results channel
    #bot.send_photo(chat_id="-112233445566", photo=f, caption=f"Total profit for the last {days_back} days: {total_profit} USD 💰")

  # shut down the MetaTrader 5 terminal
  mt5.shutdown()

except Exception as e:
  # print an error message if there was an exception
  print("An error occurred:", e)
  # shut down the MetaTrader 5 terminal
  mt5.shutdown()

