# Gekko BacktestTool
![Logo](https://i.imgur.com/G3Dcv7i.png)

## Change Log
### v0.7
- "progress bar", ETA, avg backtest duration, TOP tables after each X backtests results
- limits and filters for TOP tables
- the possibility of defining a period for individual pairs ex: binance:USDT:BTC:2018-04-01:2018-04-05
- parameter `--period 7 days` perform action for last 7 days without typing dates
- default exchange and/or currency in configuration file for shorter pairs typing
- strats config are back to csv file
- stfu mode can be enabled in configuration file
- some layout changes
- bugfixes: [#8](https://github.com/xFFFFF/Gekko-BacktestTool/pull/8), [#17](https://github.com/xFFFFF/Gekko-BacktestTool/pull/17)
- backtest-config.pl updated
- new binaries are done

### v0.6
- after completion of the backtests, the analysis module displays three tables with data: *ALL RESULTS*, *TOP STRATEGIES*, *TOP DATASET*
- parameter `--analyze mycsvfile.csv` for analyze any results from BacktestTool's external file
- searching optimal strategy parameters by brute force method with syntax `start..end:step` or `value1, value2, value3` in strat's toml file
- value `ALL` for exchanges and strategies for backtest machine - do backtests on all available exchanges, currencies, assets or strategies. Based on filenames in history and strategies directories.
- add binaries for Linux and FreeBSD to [releases](https://github.com/xFFFFF/Gekko-BacktestTool/releases)
- backtest-config.pl updated
- README.MD updated

### v0.5
- price: *open*, *close*, *high*, *low*, *average* for dataset period in CSV output
- [coinmarketcap.com](https://coinmarketcap.com) data in CSV output: *current marketcap*, *current rank*, *last 24h global volume*
- CSV's template - now You can choose which columns will be add to CSV file
- temporary GBT's files are in tmp directory now.
- MS Windows compatibility fix (tested on W7x64 and StrawberryPerl)
- backtest-config.pl file updated

### v0.4
- price *volality* (based on relative standard deviation) in CSV output
- sum of *volume* and *volume/day* for dataset period in CSV output
- sum of *overall exchange trades* and sum of *overall trades/day* for dataset period in CSV output
- if pair not exist in DB on parameter `-f last` then create table and import from last 24 hours.
- update parameter `--help`
- README update
- some code clean
- some fixes

### v0.3
- Gekko BacktestTool external config file support. Default config file is backtest-config.pl, but You can create own and use `backtest.pl --config BACKTESTTOOL_CONFIG_FILENAME parameter`
- using TOML files for strategies configuration as default. Can be changed in backtest-config.pl
- *percentage wins, best win, worst loss, median win, median lost, average exposed* duration added to csv file.
- parameter `--covert TOML_FILE`. Convert toml file and print strategy settings in Gekko's config file format
- parameter `-p exchange:ALL` and `-p exchange:asset:ALL` for backtest pairs. Do backtest for all available pairs. Based on non empty tables from sqlite database.
- parameter `-p exchange:ALL` and `-p exchange:asset:ALL` for import pairs. Import all available pairs from exchange. Based on exchange/exchange-markets.json file
- parameter `--import --from=last --to=now`. The `last` value checks in the database the time of the last candle for each pair and assign this value to `--from`. `now` assign current time in GMT time zone. In short: with this command you can import from the last candle from datasets to current time.

### v0.2
- *winning/losses* trades in csv file
- command line parameters support (`--import (-i)`, `--paper (-g)`, `--strat (-s)`, `--pair (-p)`, `--candles (-n)`, `--output (-o)` `--from (-f)`, `--to (-t)`, `--help (-h)`)
- showing roundtrips in terminal output (can be disabled in configuration)
- bugfixes/code clean

### v0.1
- multiple datasets import (`perl backtest.pl -i`)
- start multiple paperTraders in background (`perl backtest.pl -p`) (need improvement)
- support for multiple CandleSize and CandleHistory
- logs is moved to logs directory
- performance improvement
- bugfixes
