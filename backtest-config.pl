############################# START OF CONFIGURATION #############################
# Put your strategy names between brackets in line below. Strategy seperate with space or newline.
@strategies = qw(
BBRSI
neuralnet
RSI_BULL_BEAR 
);
# Put your pairs between brackets in line below. Use exchange:currency:asset format. Seperate pair using space or newline.
@pairs = qw(
binance:BTC:ALL
bitfinex:USD:ETP
binance:USDT:BTC
binance:BNB:XLM
binance:BNB:NANO
binance:BNB:VEN
binance:BNB:NCASH

);

# Put your candle values between brackets in line below. Use CandleSize:WarmupPeriod format. Seperate pair using space or newline.
@warmup = qw(
10:73
11:70
12:69
13:65
9:75
8:80
7:90
6:100
);

# To specify time range for import or backtest uncomment lines below, but instead this you can use command line input ex.: backtest.pl --from "2018-01-01 00:00:00" --to "2018-01-05 00:00:00". If below lines are commented Gekko is using scan datasets feature in backtest mode. 
#$from = '2018-03-18 15:00:00';
#$to = '2018-03-22 08:00:00';

# CSV file name. You don't need change this. All new data will append to exist file without deleting or replacing.
$csv = 'database.csv';

# You can add note to project below. Note will be add in CSV file. Its can be useful when You are developing strategy.
$note = 'first run';

# Template of CSV output columns. Format [% variable_name %], columns MUST be seperated by comma (,) without any space. 
# Below is compact version
$csv_columns = \ "[% currency %],[% asset %],[% strategy %],[% profit %],[% profit_day %],[% sharpe_ratio %],[% market_change %],[% trades %],[% trades_day %],[% percentage_wins %],[% best_win %],[% median_wins %],[% worst_loss %],[% median_losses %],[% avg_exposed_duration %],[% candle_size %],[% warmup_period %],[% dataset_days %],[% CMC_Rank %],[% current_marketcap %],[% open_price %],[% close_price %],[% lowest_price %],[% highest_price %],[% avg_price %],[% price_volality %],[% volume_day %],[% volume_CMC %],[% overall_trades_day %],[% note %]";

# Minimalistic version
#$csv_columns = \ "[% currency %],[% asset %],[% strategy %],[% profit %],[% profit_day %],[% profit_market %],[% trades_day %],[% percentage_wins %],[% best_win %],[% worst_loss %],[% avg_exposed_duration %],[% dataset_days %],[% CMC_Rank %],[% current_marketcap %],[% avg_price %],[% price_volality %],[% volume_day %],[% volume_CMC %],[% overall_trades_day %]";

# Full version - all possible BacktestTool variables.
#$csv_columns = \ "[% currency %],[% asset %],[% exchange %],[% strategy %],[% profit %],[% profit_day %],[% profit_year %],[% sharpe_ratio %],[% market_change %],[% profit_market %],[% trades %],[% trades_day %],[% winning_trades %],[% lost_trades %],[% percentage_wins %],[% best_win %],[% median_wins %],[% worst_loss %],[% median_losses %],[% avg_exposed_duration %],[% candle_size %],[% warmup_period %],[% dataset_days %],[% backtest_start %],[% dataset_from %],[% dataset_to %],[% CMC_Rank %],[% current_marketcap %],[% open_price %],[% close_price %],[% lowest_price %],[% highest_price %],[% avg_price %],[% price_volality %],[% volume %],[% volume_day %],[% volume_CMC %],[% overall_trades %],[% overall_trades_day %],[% note %]";

# Do You want coinmarketcap.com data in CSV output? Warning: It's decrase performance a bit.
$cmc_data = 'yes';

# Do you want see roundtrips report in terminal output?
$print_roundtrips = 'no';

# Use TOML strat's config files instead JSON?
$use_toml_files = 'yes';
$toml_directory = 'config/strategies/';

# Do you need Gekko's log files in log directory?
$keep_logs = 'no';

# Threads amount, for 4xcpu cores is recommended to set 5-6 value.
$threads = 5;

# Do You want see more info?
$debug = 'no';

# If You set $use_toml_files to 'no' then add Your strat's config in JSON format between brackets below.
$stratsettings = q(
config.neuralnet = {
  "threshold_buy": 1,
  "threshold_sell": -1,
  "price_buffer_len": 100,
  "learning_rate": 1,
  "momentum": 0.9,
  "decay": 0.01,
  "min_predictions": 1000,
  "stoploss_enabled": false,
  "stoploss_threshold": 0.95
};

config.neuralnet_BULL_BEAR = { 
  "threshold_sell_bear":-1.0352,
  "threshold_sell_bull":-0.992,
  "momentum":0.0982,
  "decay":0.0076,
  "threshold_buy_bull":1.955,
  "price_buffer_len":88.6,
  "SMA_short":38,
  "SMA_long":712,
  "min_predictions":760,
  "threshold_buy_bear":2.8294,
  "learning_rate":0.2736
};

);

# Other Gekko's settings for backtest
$asset = 0;
$currency = 4;
$fee_maker = 0.05;
$fee_taker = 0.05;
$fee_using = 'maker';
$slippage = 0.5;
$riskFreeReturn = 5;
############################# END OF CONFIGURATION #############################

1;
