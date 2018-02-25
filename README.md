Tool for Gekko trading bot which help in strategy choosing or developing. Save Your time with Gekko Auto Backtest.

Features
- Test multiple strategies on mulitple pairs on one run
- Results are exporting to CSV file
- Multithreading - do more in this same time
- Extended statistics

Installation and run
1. Clone git https://github.com/xFFFFF/GekkoBacktestTool.git
2. Copy files to Gekko's main directory
3. Install dependies"
`$ sudo cpan install Parallel::ForkManager Time::ParseDate Time::Elapsed`
4. Run with command
`$ perl backtest.pl`

Known Bugs
- Dont working if pair has two or more datasets

ToDo
- Winning/lossing trades
