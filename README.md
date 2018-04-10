# Gekko BacktestTool
Tool for Gekko trading bot. The tool performs a test with multiple pairs and/or multiple strategies on a single run. Suppose you have a strategy that you want to test on more currency pairs. You enter all the pairs on which you want to test the strategy for the application configuration. You start the application and everything happens automatically. You are just waiting for the results that appear on the screen. You will see how your strategy falls on other pairs, where it works the best, and where the worst. More detailed data is available in the .CSV file, which you can open in a spreadsheet or text editor.

You can do the same with many strategies and CandleSize values. You can test all your strategies on eg BTC-USD pair and compare results, which will allow you to choose the best strategy you will use in live trade.

# DEMO
Backtest machine
![Alt text](images/backtest.gif?raw=true "GekkoBacktestTool running demo")

Database file
![Alt text](images/csv.gif?raw=true "GekkoBacktestTool CSV file demo")

# Features
- Test multiple candleSize, strategies and mulitple pairs on one run
- Start multiple PaperTraders
- Multiple datasets import
- Backtests results are exporting to CSV file
- Multithreading - in contrast to raw Gekko backtest this tool uses 100% of your processor
- Extended statistics

# Installation and run
1. Clone git https://github.com/xFFFFF/GekkoBacktestTool.git
2. Copy files to Gekko's main directory
3. Install dependies:
`$ sudo cpan install Parallel::ForkManager Time::ParseDate Time::Elapsed Getopt::Long List::MoreUtils File::chdir Statistics::Basic DBI  DBD::SQLite JSON TOML File::Basename File::Find::Wanted`
4. Edit backtest-config.pl in text editor.
5. Available commands:
```
usage: perl backtest.pl
To run backtests machine

usage: perl backtest.pl [parameter] [optional parameter]
Parameters:
  -i, --import	 - Import new datasets
  -g, --paper	 - Start multiple sessions of PaperTrader
  -v, --convert	 - Convert TOML file to Gekko's CLI config format, ex: backtest.pl -v MACD.toml
  
Optional parameters:
  -c, --config		 - BacktestTool config file. Default is backtest-config.pl
  -s, --strat STRATEGY_NAME - Define strategies for backtests. You can add multiple strategies seperated by commas example: backtest.pl --strat=MACD,CCI
  -p, --pair PAIR	 - Define pairs to backtest in exchange:currency:asset format ex: backtest.pl --p bitfinex:USD:AVT. You can add multiple pairs seperated by commas.
  -p exchange:ALL	 - Perform action on all available pairs. Other usage: exchange:USD:ALL to perform action for all USD pairs.
  -n, --candle CANDLE	 - Define candleSize and warmup period for backtest in candleSize:warmup format, ex: backtest.pl -n 5:144,10:73. You can add multiple values seperated by commas.
  -f, --from
  -f last		- Start import from last candle available in DB. If pair not exist in DB then start from 24h ago.
  -t, --to		 - Time range for backtest datasets or import. Example: backtest.pl --from="2018-01-01 09:10" --to="2018-01-05 12:23"
  -t now		- 'now' is current time in GMT.
  -o, --output FILENAME - CSV file name.
```

# Some examples
Backtests of all available pairs for Binance Exchange in Gekko's scan datarange mode:
`$ perl backtest.pl -p binance:ALL`

Backtest on all pairs and strategies defined in backtest-config.pl with candles 5, 10, 20, 40 and 12 hours warmup period:
`$ perl backtest.pl -n 5:144,10:73,20:36,40:15`

Import all new candles for all BNB pairs:
`$ perl backtest.pl -i -p binance:BNB:ALL -f last -t now`

Import all candles for pairs defined in backtest-config.pl from 2017-01-02 to now:
`$ perl backtest.pl -i -f 2017-01-02 -t now`

# Known Bugs
- Dont working if pair has two or more datasets
- If empty datasets > threads amount then app freeze up. Temporary fix: ctrl + c

# ToDo
- comparing results of backtest on terminal output
- define columns added to csv
- parameter ALL for exchanges
- parameter --info  for data like strats names, avaible datasets etc
- temp configs in seperated directory
- Import datasets from Bittrex
- Import sqlite file dumps (full history)
- GUI

# Change Log
v0.4
- price *volality* (based on relative standard deviation) in CSV output
- sum of *volume* and *volume/day* for dataset period in CSV output
- sum of *overall exchange trades* and sum of *overall trades/day* for dataset period in CSV output
- if pair not exist in DB on parameter `-f last` then create table and import from last 24 hours.
- update parameter `--help`
- README update
- some code clean
- some fixes

v0.3 
- Gekko BacktestTool external config file support. Default config file is backtest-config.pl, but You can create own and use `backtest.pl --config BACKTESTTOOL_CONFIG_FILENAME parameter`
- using TOML files for strategies configuration as default. Can be changed in backtest-config.pl
- *percentage wins, best win, worst loss, median win, median lost, average exposed* duration added to csv file.
- parameter `--covert TOML_FILE`. Convert toml file and print strategy settings in Gekko's config file format
- parameter `-p exchange:ALL` and `-p exchange:asset:ALL` for backtest pairs. Do backtest for all available pairs. Based on non empty tables from sqlite database.
- parameter `-p exchange:ALL` and `-p exchange:asset:ALL` for import pairs. Import all available pairs from exchange. Based on exchange/exchange-markets.json file
- parameter `--import --from=last --to=now`. The `last` value checks in the database the time of the last candle for each pair and assign this value to `--from`. `now` assign current time in GMT time zone. In short: with this command you can import from the last candle from datasets to current time.

v0.2
- *winning/losses* trades in csv file
- command line parameters support (`--import (-i)`, `--paper (-g)`, `--strat (-s)`, `--pair (-p)`, `--candles (-n)`, `--output (-o)` `--from (-f)`, `--to (-t)`, `--help (-h)`)
- showing roundtrips in terminal output (can be disabled in configuration)
- bugfixes/code clean

v0.1
- multiple datasets import (`perl backtest.pl -i`)
- start multiple paperTraders in background (`perl backtest.pl -p`) (need improvement)
- support for multiple CandleSize and CandleHistory
- logs is moved to logs directory
- performance improvement
- bugfixes
