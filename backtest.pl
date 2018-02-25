#!/usr/bin/perl -w
use strict;
use Parallel::ForkManager;
use Time::ParseDate qw(parsedate);
use POSIX qw(strftime);
use Time::Elapsed qw( elapsed );

# Put your strategy names between brackets in line below. Strategy seperate with space.
my @strategies = qw( neuralnet superT );
# Put your pairs between brackets in line below. Use exchange:currency:asset format. Seperate pair using space or newline.
my @pairs = qw( 
bitfinex:USD:ETP
binance:USDT:BTC
);
# Set Gekkos candleSize value
my $candlesize = 15;
# Set Gekkos candleHistory
my $candlehistory = 20;
# Between brackets bellow You can change threads amount.
my $pm = Parallel::ForkManager->new(5);
# CSV file name
my $csv = 'database.csv';
# You can add note to project below. Note will be add in CSV file. Its can be useful when You are developing strategy.
my $note = 'first project';
# Gekko config file is below. Change what You need.
my $gconfig = q(
var config = {};
config.debug = false; // for additional logging / debugging
config.watch = {
	exchange: 'unchangable',
	currency: 'unchangable',
	asset: 'unchangable',
}
config.tradingAdvisor = {
	enabled: true,
	method: 'unchanable',
	candleSize: unchangable,
	historySize: unchangable,
}

// Strategies settings. If you add new strategy You must add values from .toml file below!
config.neuralnet = {
	threshold_buy:1.0,
	threshold_sell:-1.0,
	price_buffer_len:100,
	learning_rate:0.01,
	scale:1,
	momentum:0.1,
	decay:0.1,
	min_predictions:1000
};
config.saichovsky = {
	profitLimit: 1.05,
	stopLossLimit: 0,
	buyAtDrop: 0.98,
	buyAtRise: 1.01
};
config.superT = {
	history:20,
	constant: 0.015,
	up: 100,
	down: -100,
	persistence: 1,
	short: 12,
	long: 26,
	signal: 9,
	optInTimePeriod: 14,
	interval: 6,
	thresholds: {
	sell_at: 1.0095,
	buy_at: 0.995,
	buy_at_up: 1.003,
	stop_loss_pct: 0.95,
	down: -0.025,
	up: 0.025,
	low: 25,
	high: 70,
	persistence: 1 }
};
config.bestone_updated_hardcoded = {
	myStoch: {
		highThreshold: 80,
		lowThreshold: 20,
		optInFastKPeriod: 14,
		optInSlowKPeriod: 5,
		optInSlowDPeriod: 5 
	},
	myLongEma: {
		optInTimePeriod: 100 
	},
	myShortEma: {
		optInTimePeriod: 50 
	},
	stopLoss: {
		percent: 0.9 }
};
config.BodhiDI_public = { 
	optInTimePeriod: 14,
	diplus: 23.5,
	diminus: 23
};
config.buyatsellat_ui = { 
	buyat: 1.20,
	sellat: 0.98,
	stop_loss_pct: 0.85,
	sellat_up: 1.01
};
config.mounirs_esto = { 
	rsi:  {
		interval: 6 },
	ema: {
		ema1: 10 }
};
config.RSI_BULL_BEAR = { 
	SMA_long: 1000,
	SMA_short: 50,
	BULL_RSI: 10,
	BULL_RSI_high: 80,
	BULL_RSI_low: 60,
	BEAR_RSI: 15,
	BEAR_RSI_high: 50,
	BEAR_RSI_low: 20
};
config.RSI_BULL_BEAR_ADX = { 
	SMA_long: 1000,
	SMA_short: 50, 
	BULL_RSI: 10, 
	BULL_RSI_high: 80, 
	BULL_RSI_low: 60, 
	BEAR_RSI: 15, 
	BEAR_RSI_high: 50, 
	BEAR_RSI_low: 20,
	BULL_MOD_high: 5,
	BULL_MOD_low: -5,
	BEAR_MOD_high: 15,
	BEAR_MOD_low: -5,
	ADX: 3, 
	ADX_high: 70, 
	ADX_low: 50
};
config.rsidyn = { 
	interval: 8,
	sellat: 0.4,
	buyat: 1.5 ,
	stop_percent: 0.96,
	stop_enabled: true
};
config.TEMA = {
	short: 10,
	long: 80,
	SMA_long: 200
};
config.paperTrader = {
	enabled: true,
	reportInCurrency: true,
	simulationBalance: {
		asset: 0,
		currency: 400,
	},
	feeMaker: 0.1,
	feeTaker: 0.1,
	feeUsing: 'maker',
	slippage: 0.05,
}
config.performanceAnalyzer = {
	enabled: true,
	riskFreeReturn: 5
}
config.trader = {
	enabled: false,
	key: '',
	secret: '',
	username: '', // your username, only required for specific exchanges.
	passphrase: '', // GDAX, requires a passphrase.
	orderUpdateDelay: 1, // Number of minutes to adjust unfilled order prices
}
config.adviceLogger = {
	enabled: false,
	muteSoft: true // disable advice printout if it's soft
}
config.candleWriter = {
	enabled: false
}
config.adviceWriter = {
	enabled: false,
	muteSoft: true,
}
config.adapter = 'sqlite';
config.sqlite = {
	path: 'plugins/sqlite',
	dataDirectory: 'history',
	version: 0.1,
	journalMode: require('./web/isWindows.js') ? 'DELETE' : 'WAL',
	dependencies: []
}
config.backtest = {
	daterange:  'scan',
// coment above line and uncoment bellow lines to using definied datarange
//	daterange: {
//		from: "2018-02-17 00:00:00",
//		to: "2018-02-20 14:00:00"
//	},
batchSize: 50
}
config['I understand that Gekko only automates MY OWN trading strategies'] = true;
module.exports = config;
);

# Lets start!
foreach (@pairs) {
	my $pid = $pm->start and next;
	my @sets = split /:/, $_;
	foreach (@strategies) {
		my $startthread = time();
		my $configfile = "$sets[1]-$sets[2]-$_-config.js";
		# Log file name.
		my $logfile = "$sets[1]-$sets[2]-$_.log";
		$gconfig =~ s/(?<=exchange: ')(.*?)(?=',)/$sets[0]/g;
		$gconfig =~ s/(?<=currency: ')(.*?)(?=',)/$sets[1]/g;
		$gconfig =~ s/(?<=asset: ')(.*?)(?=',)/$sets[2]/g;
		$gconfig =~ s/(?<=method: ')(.*?)(?=',)/$_/g;
		$gconfig =~ s/(?<=candleSize: )(.*?)(?=,)/$candlesize/g;
		$gconfig =~ s/(?<=historySize: )(.*?)(?=,)/$candlehistory/g;
		open my $fh, '>', $configfile or die "Cannot open $configfile!";
		print $fh join ("\n",$gconfig);
		close $fh;
		my $grun = `node gekko -b -c $configfile`;
		open my $fh2, '>>', $logfile or die "Cannot open $logfile!";
		print $fh2 join ("\n",$gconfig);
		print $fh2 join ("\n",$grun);
		close $fh2;

		my @profit = $grun =~ /(?<=simulated profit:\t\t )[0-9.\-][0-9.\-]* $sets[1] \((.*)(?=\%\))/;
		my @yearly = $grun =~ /(?<=simulated yearly profit:\t )[0-9.\-][0-9.\-]* $sets[1] \((.*)(?=\%\))/;
		my @market = $grun =~ /(?<=Market:\t\t\t\t )(.*?)(?=%)/;
		my @trades = $grun =~ /(?<=trades:\t\t )(.*?)(?=\n)/;
		my @period = $grun =~ /(?<=timespan:\t\t\t )(.*?)(?=\n)/;
		my @start = $grun =~ /(?<=start time:\t\t\t )(.*?)(?=\n)/;
		my @end = $grun =~ /(?<=end time:\t\t\t )(.*?)(?=\n)/;
		my @strat = $gconfig =~ /(?<=config.$_ = \{)(.*?)(?=};)/s;
		$strat[0] =~ s/\n/ /g;
		$strat[0] =~ s/^/"/;
		$strat[0] =~ s/$/"/;
		my $losses = 'NA';
		my $wins = 'NA';
		#not working
		#my @lossesar = $grun =~ /(?<=[ ]\t-)(.*?)(?=\t)/g;
		#my $losses= scalar(@lossesar);
		#my $wins = $trades[0] - $losses;
		$market[0] = sprintf("%d", $market[0]);
		$profit[0] = sprintf("%d", $profit[0]);
		$yearly[0] = sprintf("%d", $yearly[0]);
		my $diff = $profit[0]-$market[0];
		my $ctime = strftime "%Y-%m-%e %H:%M:%S", localtime;
		my $days = 2;
		#my $days = sprintf("%d",(parsedate($end[0]) - parsedate($start[0])) /86400);
		my $dailyprofit = sprintf("%.2f", $profit[0] / $days);
		my $dailytrades = sprintf("%.2f", $trades[0] / $days);
		
		print "$sets[1]-$sets[2]\t$_\tprofit:\t$profit[0]%\tdiff: $diff%\tyearly: $yearly[0]%\ttrades: $trades[0]\tperiod: $period[0]\t backtest time: ";
		
		open my $fh3, '>>', $csv or die "Cannot open $csv!";
		# currency,asset,exchange,strategy,profit,"profit daily","yearly profit","market change",profit-market,"trade amount","trades daily","wining trades", "losses trades","candle size","warmup period","days of dataset","backtest start","dataset from","dataset to","strategy config"
		my $tocsv = "$sets[1]\,$sets[2]\,$sets[0]\,$_\,$profit[0]%\,$dailyprofit%\,$yearly[0]%\,$market[0]%\,$diff\,$trades[0]\,$dailytrades\,$wins\,$losses\,$candlesize\,$candlehistory\,$days\,$ctime\,$start[0]\,$end[0]\,$strat[0]\n";
		print $fh3 join ("\n",$tocsv);
		close $fh3;
	
		unlink $configfile;
		
		my $endthread = time();
		my $elapsedthread = $endthread - $startthread;
		$elapsedthread = elapsed( $elapsedthread );
		print "$elapsedthread\n";
		}
	$pm->finish;
	}
$pm->wait_all_children;

print "Goodbye!\n";
