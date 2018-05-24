# Gekko BacktestTool
![Logo](https://i.imgur.com/G3Dcv7i.png)   
[![Donate with Bitcoin](https://en.cryptobadges.io/badge/small/32G2cYTNFJ8heKUbALWSgGvYQikyJ9dHZp)](https://en.cryptobadges.io/donate/32G2cYTNFJ8heKUbALWSgGvYQikyJ9dHZp)   
[![Donate with Litecoin](https://en.cryptobadges.io/badge/small/LTJopH7Ko2UkWAUu2QmvKiQs4UPkcx1ion)](https://en.cryptobadges.io/donate/LTJopH7Ko2UkWAUu2QmvKiQs4UPkcx1ion)   
[![Donate with Ethereum](https://en.cryptobadges.io/badge/small/0x50b7611b6dC8a4073cB4eF12A6b045f644c3a3Aa)](https://en.cryptobadges.io/donate/0x50b7611b6dC8a4073cB4eF12A6b045f644c3a3Aa)   
![badge](https://img.shields.io/github/release/xFFFFF/Gekko-BacktestTool.svg) ![GitHub Release Date](https://img.shields.io/github/release-date/xFFFFF/Gekko-BacktestTool.svg) ![badge](https://img.shields.io/github/downloads/xFFFFF/Gekko-BacktestTool/total.svg) ![GitHub last commit](https://img.shields.io/github/last-commit/xFFFFF/Gekko-BacktestTool.svg) ![badge](https://img.shields.io/github/license/mashape/apistatus.svg) ![badge](https://img.shields.io/github/languages/code-size/xFFFFF/Gekko-BacktestTool.svg)  ![GitHub closed issues](https://img.shields.io/github/issues-closed/xFFFFF/Gekko-BacktestTool.svg) [![GA](https://ga-beacon.appspot.com/UA-118674108-3/r)](https://github.com/xFFFFF/Gekko-BacktestTool)    
CLI tool that enhances the features of [Gekko's Trading Bot](https://github.com/askmike/gekko). The tool performs a test with multiple pairs on a single run. Suppose you have a strategy that you want to test on more currency pairs. You enter all the pairs on which you want to test the strategy for the BacktestTool's configuration file. You start the application and everything happens automatically. You are just waiting for the results that appear on the screen. You will see how your strategy falls on other pairs, where it works the best, and where the worst. More detailed data is available in the .CSV file, which you can open in a spreadsheet or text editor.   
![Top Dataset](http://i.imgur.com/U7TCuSn.png)   
You can do the same with many strategies and CandleSize values. You can test all your strategies on eg BTC-USD pair and compare results, which will allow you to choose the best strategy you will use in live trade.

## DEMO
### Backtest machine   
![GBT run](https://i.imgur.com/x1Ryyog.gif)

### Database file
![CSV file](https://i.imgur.com/ENj1ZDM.gif)

## Features
- **Backtest** for multiple strategies and pairs with one command
- **Backtests results** are exporting to CSV file [(see sample)](https://github.com/xFFFFF/Gekko-BacktestTool/blob/master/sample_output.csv)
- **Analysis** and comparing all strategy and pair results in variables such as: *% of profitable backtests for strategy*, *% of results with profit above market*, *% of win trades*, *average P&L for trades* and more!   
- **Import** multiple datasets with one command
- **Strategy config file** - support both TOML and JSON files in CLI mode
- **Strategy optimization** - searching for optimal parameters (brute force method) for the strategy on many datasets
- **Multithreading** - in contrast to raw Gekko backtest this tool can uses 100% of your processor
- **Extended statistics** - 40 variables from single backtest result, such as: *volume*, *price (min, max, avg, volality)*, *percent of win trades*, *median P&L for trades*, *marketcap*, *CoinMarketCap Rank*, etc.   

<img align="center" src=http://i.imgur.com/JXjKVDT.png>   

## Minimal requirements
- [Gekko Trading Bot](https://github.com/askmike/gekko)
- [Binaries of BacktestTool](https://github.com/xFFFFF/Gekko-BacktestTool/releases)

## Installation
### Binaries: Easiest install way
1. Download latest version from repository's [releases](https://github.com/xFFFFF/Gekko-BacktestTool/releases).  
2. Extract downloaded zip.   
3. Copy all extrated files to main Gekko's directory.   

### Open Source: Debian, Ubuntu, Linux Mint
1. Clone git https://github.com/xFFFFF/Gekko-BacktestTool
2. Copy files to Gekko's main directory
3. Install dependies:   
`$ sudo cpan install Parallel::ForkManager Time::Elapsed Getopt::Long List::MoreUtils File::chdir Statistics::Basic DBI  DBD::SQLite JSON::XS TOML File::Basename File::Find::Wanted Template LWP::UserAgent LWP::Protocol::https Set::CrossProduct DBD::CSV Text::Table File::Copy`   

### Open Source: Other Unix-like OS
1. Clone git https://github.com/xFFFFF/Gekko-BacktestTool
2. Copy files to Gekko's main directory
3. Install dependies:   
`$ su`   
`$ cpan install Parallel::ForkManager Time::Elapsed Getopt::Long List::MoreUtils File::chdir Statistics::Basic DBI  DBD::SQLite JSON::XS TOML File::Basename File::Find::Wanted Template LWP::UserAgent LWP::Protocol::https Set::CrossProduct DBD::CSV Text::Table File::Copy`   
   
### Open Source: MS Windows   
1. Install [Strawberry Perl](http://strawberryperl.com/)
2. Download Gekko BacktestTool from [here](https://github.com/xFFFFF/Gekko-BacktestTool/archive/master.zip)
3. Uncompress files from master.zip to Your main Gekko's folder
4. Find *Run...* in Menu Start
5. Enter cmd.exe and press enter
6. In appeared Window with black background enter command:
`cpan install Parallel::ForkManager Time::Elapsed Getopt::Long List::MoreUtils File::chdir Statistics::Basic DBI  DBD::SQLite JSON::XS TOML File::Basename File::Find::Wanted Template LWP::UserAgent LWP::Protocol::https Set::CrossProduct DBD::CSV Text::Table File::Copy`   

### Open Source: Docker container
The installation tutorial by *bald123* can be found in the Wiki: [Docker installation](https://github.com/xFFFFF/Gekko-BacktestTool/wiki/Docker-installation).

## Run 
1. Edit backtest-config.pl in text editor.  
2. In terminal/cmd go to Your main Gekko's folder ex:   
Windows - `cd C:\Users\xFFFFF\Desktop\gekko`   
Linux - `cd /home/xFFFFF/gekko`
3. If You are using Open Source version go to next step. For "binaries" add execution privilege: `chmod +x backtest`
4. Run BacktestTool by command:   
a) Open Source version: `perl backtest.pl`   
b) Binaries: `./backtest` 

### All available commands
```
usage: perl backtest.pl
To run backtests machine

usage: perl backtest.pl [mode] [optional parameter]
To run other features

Mode:
  -i, --import   - Import new datasets
  -g, --paper  - Start multiple sessions of PaperTrader
  -v, --convert TOMLFILE - Convert TOML file to Gekko's CLI config format, ex: backtest.pl -v MACD.toml
  -a, --analyze CSVFILE  - Perform comparision of strategies and pairs from csv file, ex: backtest.pl -a database.csv
  
Optional parameters:
  -c, --config     - BacktestTool config file. Default is backtest-config.pl
  -s, --strat STRAT_NAME - Define strategies for backtests. You can add multiple strategies seperated by commas example: backtest.pl --strat=MACD,CCI
  -p, --pair PAIR  - Define pairs to backtest in exchange:currency:asset format ex: backtest.pl --p bitfinex:USD:AVT. You can add multiple pairs seperated by commas.
  -p exchange:ALL  - Perform action on all available pairs. Other usage: exchange:USD:ALL to perform action for all USD pairs.
  -n, --candle CANDLE  - Define candleSize and warmup period for backtest in candleSize:warmup format, ex: backtest.pl -n 5:144,10:73. You can add multiple values seperated by commas.
  -ft, --period DAYS - Time range in days - perform action on period from last x days ex: backtest.pl -ft 7   
  -f, --from    - Time range for backtest datasets or import. Example: backtest.pl --from="2018-01-01 09:10" --to="2018-01-05 12:23"
  -t, --to
  -f last   - Start import from last candle available in DB. If pair not exist in DB then start from 24h ago.
  -t now    - 'now' is current time in GMT.
  -o, --output FILENAME - CSV file name.
```
<img align="center" src=http://i.imgur.com/OY14rKb.png>     

### Some examples
- **B**acktests of all available pairs for Binance Exchange in Gekko's scan datarange mode:   
`$ perl backtest.pl -p binance:ALL`

- **B**acktest on all pairs and strategies defined in backtest-config.pl with candles 5, 10, 20, 40 and 12 hours warmup period:   
`$ perl backtest.pl -n 5:144,10:73,20:36,40:15`

- **I**mport all new candles for all BNB pairs:   
`$ perl backtest.pl -i -p binance:BNB:ALL -f last -t now`

- **I**mport all candles for pairs defined in backtest-config.pl from 2017-01-02 to now:   
`$ perl backtest.pl -i -f 2017-01-02 -t now`

- **S**earch best parameters for strategy: edit TOML file in config/strategies    
![Strat config example](http://i.imgur.com/OkGPQSm.png)    
The above example will generate 15 backtests with unique configurations. Syntax for brute force is: start..end: step (as in the case of TimePeriod) or value1, value2, value3 (example from interval). The generated values for TimePeriod are 15, 20, 25. After saving the file, run the backtest of the given strategy, eg backtest.pl -s BBRSI.   
![Brute force](http://i.imgur.com/gnywgrA.png)   

## See also
- [Gekko's Datasets](https://github.com/xFFFFF/Gekko-Datasets)   
- [Gekko's Strategies](https://github.com/xFFFFF/Gekko-Strategies)    

