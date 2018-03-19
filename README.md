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
`$ sudo cpan install Parallel::ForkManager Time::ParseDate Time::Elapsed Getopt::Long List::MoreUtils File::chdir`
4. For backtest:
`$ perl backtest.pl`
For import:
`$ perl backtest.pl -i`
For start multiple paperTraders:
`$ perl backtest.pl -p`

# Known Bugs
- Dont working if pair has two or more datasets
- If empty datasets > threads amount then app freeze up. Temporary fix: ctrl + c

# ToDo
- Import datasets from Bittrex
- highest/lowest roundtrip profit, avarage or median of roundtrips
- Userfriendly configuration file
- Comparing results of backtest on terminal output
- GUI

# Change Log
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


