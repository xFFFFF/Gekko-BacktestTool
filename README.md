Tool for Gekko trading bot. The tool performs a test with multiple pairs and/or multiple strategies on a single run. This is useful when creating a strategy or when you want to compare a few to choose the best one. Thanks to the tool, you will notice your time in comparison to traditional testing.

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
