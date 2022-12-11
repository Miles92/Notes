# Import the MetaTrader5 package
import MetaTrader5 as mt5

# Connect to your MetaTrader5 account
if not mt5.initialize():
    print("initialize() failed, error code =", mt5.last_error())
    quit()

# Get account information
account_info = mt5.account_info()

# Use the __dict__ attribute of the type object to get a dictionary of all attributes and their values of the account_info object
attributes = type(account_info).__dict__

# Iterate over the dictionary and access the attributes of the account_info object using the getattr() function
for name, value in attributes.items():
    # Check if the attribute name starts with "__" (double underscore)
    if not name.startswith("__"):
        print(f"{name}: {getattr(account_info, name)}")

# Disconnect from the MetaTrader5 account
mt5.shutdown()

