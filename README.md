# Gekko BacktestTool
CLI tool that enhances the features of [Gekko's Trading Bot](https://github.com/askmike/gekko). The tool performs a test with multiple pairs on a single run. Suppose you have a strategy that you want to test on more currency pairs. You enter all the pairs on which you want to test the strategy for the BacktestTool's configuration file. You start the application and everything happens automatically. You are just waiting for the results that appear on the screen. You will see how your strategy falls on other pairs, where it works the best, and where the worst. More detailed data is available in the .CSV file, which you can open in a spreadsheet or text editor.

You can do the same with many strategies and CandleSize values. You can test all your strategies on eg BTC-USD pair and compare results, which will allow you to choose the best strategy you will use in live trade.

# DEMO
Backtest machine
![Alt text](images/backtest.gif?raw=true "GekkoBacktestTool running demo")

Database file
![Alt text](images/csv.gif?raw=true "GekkoBacktestTool CSV file demo")

# Features
- **Backtest** for multiple strategies and pairs with one command
- **Backtests results** are exporting to CSV file [(see sample)](https://github.com/xFFFFF/Gekko-BacktestTool/blob/master/sample_output.csv)
- **Import** multiple datasets with one command
- **Ergonomy** - support both TOML and JSON strategy config files in CLI mode
- **Performance** - support multithreading - in contrast to raw Gekko backtest this tool can uses 100% of your processor
- **Extended statistics** - 40 variables from single backtest result, such as: volume, price volality, average price, percentage wins/loss trades, median profit for wins/loss trades, average exposed duration, overall pair trades from exchange, etc.

# Requirements
- [Gekko Trading Bot](https://github.com/askmike/gekko)
- Perl - installed by default on most unix-like systems. For MS Windows install [Strawberry Perl](http://strawberryperl.com/)

# Installation
**"Binaries": Easiest install way for Linuxes**
1. Download latest version from repository's [releases](https://github.com/xFFFFF/Gekko-BacktestTool/releases):  
`$ wget https://github.com/xFFFFF/Gekko-BacktestTool/releases/download/v0.5/Gekko-BacktestTool-v0.5-Ubuntu-x64.zip`
2. Extract zip:   
`$ unzip Gekko-BacktestTool-v0.5-Ubuntu-x64.zip`
3. Copy all extrated files to main Gekko's directory:    
`$ cp backtest backtest-config.pl /home/f/gekko`

**Open Source: Debian, Ubuntu, Linux Mint**
1. Clone git https://github.com/xFFFFF/Gekko-BacktestTool
2. Copy files to Gekko's main directory
3. Install dependies:   
`$ sudo cpan install Parallel::ForkManager Time::ParseDate Time::Elapsed Getopt::Long List::MoreUtils File::chdir Statistics::Basic DBI  DBD::SQLite JSON::XS TOML File::Basename File::Find::Wanted Template LWP::UserAgent LWP::Protocol::https`   

**Open Source: Other Unix-like OS**   
1. Clone git https://github.com/xFFFFF/Gekko-BacktestTool
2. Copy files to Gekko's main directory
3. Install dependies:   
`$ su`   
`$ cpan install Parallel::ForkManager Time::ParseDate Time::Elapsed Getopt::Long List::MoreUtils File::chdir Statistics::Basic DBI  DBD::SQLite JSON::XS TOML File::Basename File::Find::Wanted Template LWP::UserAgent LWP::Protocol::https`   
   
**MS Windows**   
1. Install [Strawberry Perl](http://strawberryperl.com/)
2. Download Gekko BacktestTool from [here](https://github.com/xFFFFF/Gekko-BacktestTool/archive/master.zip)
3. Uncompress files from master.zip to Your main Gekko's folder
4. Find *Run...* in Menu Start
5. Enter cmd.exe and press enter
6. In appeared Window with black background enter command:
`cpan install Parallel::ForkManager Time::ParseDate Time::Elapsed Getopt::Long List::MoreUtils File::chdir Statistics::Basic DBI  DBD::SQLite JSON::XS TOML File::Basename File::Find::Wanted Template LWP::UserAgent LWP::Protocol::https`   

# Run 
1. Edit backtest-config.pl in text editor.  
2. In terminal/cmd go to Your main Gekko's folder ex:   
Windows - `cd C:\Users\xFFFFF\Desktop\gekko`   
Linux - `cd /home/xFFFFF/gekko`
3. If You are using Open Source version go to next step. For "binaries" add execution privilege: `chmod +x backtest"
4. Run BacktestTool by command:   
a) Open Source version: `perl backtest.pl`   
b) Binaries: `./backtest` 

**All available commands**
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
  -f, --from             - From time range for backtest datasets or import. Example: backtest.pl --from="2018-01-01 09:10" --to="2018-01-05 12:23"
  -f last		 - Start import from last candle available in DB. If pair not exist in DB then start from 24h ago.
  -t, --to		 - Time range for backtest datasets or import. Example: backtest.pl --from="2018-01-01 09:10" --to="2018-01-05 12:23"
  -t now 	  	 - 'now' is current time in GMT.
  -o, --output FILENAME  - CSV file name.
```

**Some examples**    
Backtests of all available pairs for Binance Exchange in Gekko's scan datarange mode:   
`$ perl backtest.pl -p binance:ALL`

Backtest on all pairs and strategies defined in backtest-config.pl with candles 5, 10, 20, 40 and 12 hours warmup period:   
`$ perl backtest.pl -n 5:144,10:73,20:36,40:15`

Import all new candles for all BNB pairs:   
`$ perl backtest.pl -i -p binance:BNB:ALL -f last -t now`

Import all candles for pairs defined in backtest-config.pl from 2017-01-02 to now:   
`$ perl backtest.pl -i -f 2017-01-02 -t now`

# ToDo
- comparing results of backtest on terminal output
- parameter `ALL` for exchanges and strategies
- parameter `--info`  for print data like strats names, available datasets etc
- printing Gekko's output without buffering
- more descriptive and readable cmd output (text bold?)
- Import sqlite file dumps (full history)
- GUI   

# Change Log
v0.5
- price: *open*, *close*, *high*, *low*, *average* for dataset period in CSV output
- [coinmarketcap.com](https://coinmarketcap.com) data in CSV output: *current marketcap*, *current rank*, *last 24h global volume*
- CSV's template - now You can choose which columns will be add to CSV file
- temporary GBT's files are in tmp directory now.
- MS Windows compatibility fix (tested on W7x64 and StrawberryPerl)
- backtest-config.pl file updated

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

# See also
- [Gekko's Datasets](https://github.com/xFFFFF/Gekko-Datasets)   
- [Gekko's Strategies](https://github.com/xFFFFF/Gekko-Strategies)    

# Donate
If you liked my work, you can buy me coffee.   
BTC: `32G2cYTNFJ8heKUbALWSgGvYQikyJ9dHZp`   
BCH: `qrnp70u37r96ddun2guwrg6gnq45yrxuwu3gyewsgq`   
ETH: `0x50b7611b6dC8a4073cB4eF12A6b045f644c3a3Aa`   
LTC: `M9xT3mcxskjbvowoFa15hbKXShLNTuwr6n`   
