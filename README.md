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
`$ sudo cpan install Parallel::ForkManager Time::ParseDate Time::Elapsed Getopt::Long List::MoreUtils File::chdir Statistics::Basic DBI  DBD::SQLite JSON TOML File::Basename File::Find::Wanted
4. Edit backtest-config.pl in text editor.
5. For backtest:
`$ perl backtest.pl`
For import:
`$ perl backtest.pl -i`
For start multiple paperTraders:
`$ perl backtest.pl -p`
For more information:
`$perl backtest.pl -h`

# Known Bugs
- Dont working if pair has two or more datasets
- If empty datasets > threads amount then app freeze up. Temporary fix: ctrl + c

# ToDo
- volume info for datasets - min, max, avarage and current from coinmarketcap
- Comparing results of backtest on terminal output
- define columns added to csv
- price standard deviatiom for datasets
- parameter ALL for exchanges
- print data like strats names, avaible datasets etc
- temp config w osobnym katalogu
- binance:ALL not working at bitfinex datasets - fix
- Import datasets from Bittrex
- Import sqlite file dumps (full history)
- GUI

# Change Log
v0.3 
- Gekko BacktestTool external config file support. Default config is backtest-config.pl, but You can create own and use backtest.pl 
- using TOML files for strategies configuration as default. Can be changed in backtest-config.pl
- percentage wins, best win, worst loss, median win, median lost, average exposed duration added to csv file.
- parameter --covert TOML_FILE. Convert toml file and print strategy settings in Gekko's config file format
- parameter exchange:ALL and exchange:asset:ALL for backtest pairs. Do backtest for all available pairs. Based on non empty tables from sqlite database.
- parameter exchange:ALL and exchange:asset:ALL for import pairs. Import all available pairs from exchange. Based on exchange/exchange-markets.json file
- parameter --import --from=last --to=now. The 'last' value checks in the database the time of the last candle for each pair and assign this value to --from. 'now' assign current time in GMT time zone. In short: with this command you can import from the last candle from datasets to current time.
- parameter --config BACKTESTTOOL_CONFIG_FILENAME.

v0.2
- winning/losses trades in csv file
- command line parameters support (--import, --paper, --strat, --pair, --candles, --output --from, --to, --help)
- showing roundtrips in terminal output (can be disabled in configuration)
- bugfixes/code clean

v0.1
- multiple datasets import (perl backtest.pl -i)
- start multiple paperTraders in background (perl backtest.pl -p) (need improvement)
- support for multiple CandleSize and CandleHistory
- logs is moved to logs directory
- performance improvement
- bugfixes


