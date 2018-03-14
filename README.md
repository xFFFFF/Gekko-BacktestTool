Tool for Gekko trading bot. The tool performs a test with multiple pairs and/or multiple strategies on a single run. Suppose you have a strategy that you want to test on more currency pairs. You enter all the pairs on which you want to test the strategy for the application configuration. You start the application and everything happens automatically. You are just waiting for the results that appear on the screen. You will see how your strategy falls on other pairs, where it works the best, and where the worst. More detailed data is available in the .CSV file, which you can open in a spreadsheet or text editor.

You can do the same with many strategies and CandleSize values. You can test all your strategies on eg BTC-USD pair and compare results, which will allow you to choose the best strategy you will use in live trade.

Features
- Test multiple candleSize, strategies on mulitple pairs on one run
- Start multiple PaperTraders
- Multiple datasets import
- Results are exporting to CSV file
- Multithreading - do more in this same time
- Extended statistics

Installation and run
1. Clone git https://github.com/xFFFFF/GekkoBacktestTool.git
2. Copy files to Gekko's main directory
3. Install dependies"
`$ sudo cpan install Parallel::ForkManager Time::ParseDate Time::Elapsed`
4. For backtest:
`$ perl backtest.pl`
For import:
`$ perl backtest.pl -i`
For start multiple paperTraders:
`$ perl backtest.pl -p`

Known Bugs
- Dont working if pair has two or more datasets
- If empty datasets > threads amount then app freeze up. Temporary fix: ctrl + c

Change Log
v0.1
- multiple datasets import (perl backtest.pl -i)
- start multiple paperTraders in background (perl backtest.pl -p) (need improvement)
- support for multiple CandleSize and CandleHistory
- logs is moved to logs direcotry
- performance improvement
- bugfixes

ToDo
- Winning/lossing trades
- Import datasets from Bittrex
- Overwriting Gekko values with command line arguments, for example hit from terminal `backtest.pl BTC-USD` will test BTC-USD paid
- Userfriendly configuration file
- Comparing results of backtest on terminal output
- Allow showing roundtrips on output
- GUI
