#!/usr/bin/perl -w
use strict;
use Parallel::ForkManager;
use Time::ParseDate qw(parsedate);
use POSIX qw(strftime);
use Time::Elapsed qw( elapsed );
use Getopt::Long;
no warnings qw(uninitialized);

# Put your strategy names between brackets in line below. Strategy seperate with space.
my @strategies = qw( 
neuralnet
superT
RSI_BULL_BEAR
);
# Put your pairs between brackets in line below. Use exchange:currency:asset format. Seperate pair using space or newline.
my @pairs = qw( 
bitfinex:USD:ETP
binance:USDT:BTC
binance:BNB:XLM
binance:BNB:NANO
binance:BNB:VEN
binance:BNB:NCASH
);
my @warmup = qw(

10:73
11:70
12:69
13:65
9:75
8:80
7:90
6:100
);
# Between brackets bellow You can change threads amount.
my $threads = 2;
# CSV file name
my $csv = 'database.csv';
# You can add note to project below. Note will be add in CSV file. Its can be useful when You are developing strategy.
my $note = 'first run';
# Gekko config file is below. Change what You need.
my $gconfig = q(
var config = {};
config.debug = true;
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
config.BBRSI = {
  "interval": 14,
  "thresholds": {
    "low": 40,
    "high": 40,
    "persistence": 9
  },
  "bbands": {
    "TimePeriod": 20,
    "NbDevUp": 2,
    "NbDevDn": 2
  }
};

config.n8_v2_BB_RSI_SL = {
  "interval": 14,
  "SL": 1,
  "BULL_RSI": 10,
  "BULL_RSI_high": 80,
  "BULL_RSI_low": 60,
  "BEAR_RSI": 15,
  "BEAR_RSI_high": 50,
  "BEAR_RSI_low": 20,
  "ADX": 3,
  "ADX_high": 70,
  "ADX_low": 50,
  "thresholds": {
    "low": 30,
    "high": 70,
    "down": 0.1,
    "persistence": 1
  }
};
config.NN_ADX_RSI = {
  "SMA_long": 800,
  "SMA_short": 40,
  "interval": 14,
  "SL": 1,
  "BULL_RSI": 10,
  "BULL_RSI_high": 80,
  "BULL_RSI_low": 50,
  "IDLE_RSI": 12,
  "IDLE_RSI_high": 65,
  "IDLE_RSI_low": 39,
  "BEAR_RSI": 15,
  "BEAR_RSI_high": 50,
  "BEAR_RSI_low": 25,
  "ROC": 9,
  "ROC_lvl": 0,
  "ADX": 3,
  "ADX_high": 70,
  "ADX_low": 50,
  "thresholds": {
    "low": 30,
    "high": 70,
    "down": 0.1,
    "persistence": 1
  }
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
    currency: 4,
  },
  feeMaker: 0.05,
  feeTaker: 0.05,
  feeUsing: 'maker',
  slippage: 0.7,
}
config.performanceAnalyzer = {
  enabled: true,
  riskFreeReturn: 5
}
config.trader = {
  enabled: false,
  key: '',
  secret: '',
  username: '',
  passphrase: '',
  orderUpdateDelay: 1,
}
config.adviceLogger = {
  enabled: false,
  muteSoft: true
}
config.candleWriter = {
  enabled: true
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
  dependencies: []
}
config.backtest = {
//  daterange:  'scan',
  daterange: {
  from: "2018-02-14 00:00:00",
  to: "2018-03-14 18:00:00"
  },
batchSize: 50
}
config.importer = {
    daterange: {
    from: "2018-01-01 00:00",
    to: "2018-01-03 00:10"
  }
}
config['I understand that Gekko only automates MY OWN trading strategies'] = true;
module.exports = config;
);

my $pm = Parallel::ForkManager->new($threads);

if( ! defined $ARGV[0]) {
  my $startapp = time();
  # Lets start!
  foreach (@warmup) {
    if (@warmup >= @strategies && @warmup >= @pairs) {
      my $pid = $pm->start and next;
    }
    my @warms = split /:/, $_;
    foreach (@pairs) {
      if (@pairs >= @strategies && @pairs >= @warmup) {
        my $pid = $pm->start and next;
      }
      my @sets = split /:/, $_;
      foreach (@strategies) {
        if (@strategies >= @pairs && @strategies >= @warmup) {
          my $pid = $pm->start and next;
        }
        my $startthread = time();
        my $configfile = "$sets[1]-$sets[2]-$_-$warms[0]-$warms[1]-config.js";
        # Log file name.
        my $logfile = "logs/$sets[1]-$sets[2]-$_-$warms[0]-$warms[1].log";
        $gconfig =~ s/(?<=config.candleWriter = \{\n  enabled: )(.*)(?=\n)/false/m;
        $gconfig =~ s/(?<=exchange: ')(.*?)(?=',)/$sets[0]/g;
        $gconfig =~ s/(?<=currency: ')(.*?)(?=',)/$sets[1]/g;
        $gconfig =~ s/(?<=asset: ')(.*?)(?=',)/$sets[2]/g;
        $gconfig =~ s/(?<=method: ')(.*?)(?=',)/$_/g;
        $gconfig =~ s/(?<=candleSize: )(.*?)(?=,)/$warms[0]/g;
        $gconfig =~ s/(?<=historySize: )(.*?)(?=,)/$warms[1]/g;
        open my $fh, '>', $configfile or die "Cannot open $configfile!";
        print $fh join ("\n",$gconfig);
        close $fh;
        my $grun = `node gekko -b -c $configfile`;
        my @market = $grun =~ /(?<=Market:\t\t\t\t )(.*?)(?=%)/;
        open my $fh2, '>>', $logfile or die "Cannot open $logfile!";
        print $fh2 join ("\n",$gconfig);
        print $fh2 join ("\n",$grun);
        close $fh2;
        my @profit = $grun =~ /(?<=simulated profit:\t\t )[0-9.\-][0-9.\-]* $sets[1] \((.*)(?=\%\))/;
        my @yearly = $grun =~ /(?<=simulated yearly profit:\t )[0-9.\-][0-9.\-]* $sets[1] \((.*)(?=\%\))/;
        my @trades = $grun =~ /(?<=trades:\t\t )(.*?)(?=\n)/;
        my @period = $grun =~ /(?<=timespan:\t\t\t )(.*?)(?=\n)/;
        my @start = $grun =~ /start time:\s+\K(.*)/;
        my @end = $grun =~ /end time:\s+\K(.*)/;
        my @strat = $gconfig =~ /(?<=config.$_ = \{)(.*?)(?=};)/s;
        $strat[0] =~ s/[\n\t]/ /g;
        $strat[0] =~ s/^/"/;
        $strat[0] =~ s/$/"/;
        $strat[0] =~ s/  / /g;
        $strat[0] =~ s/^\s+//;
        $strat[0] =~ s/\s+$//;
        my $losses = 'NA';
        my $wins = 'NA';
        my $market = sprintf("%.2f", $market[0]); 
        my $profit = sprintf("%.2f", $profit[0]);
        my $yearly = sprintf("%d", $yearly[0]);
        my $diff = sprintf("%.2f", $profit[0]-$market[0]);
        my $ctime = strftime "%Y-%m-%d %H:%M:%S", localtime;
        my $days = -1;
        my $dailytrades = -1;
        my $dailyprofit = -1;
        if(defined $end[0] && $start[0]) {
           $days = sprintf("%d",(parsedate($end[0]) - parsedate($start[0])) /86400);
           if ($days > 0) {
            $dailytrades = sprintf("%.2f", $trades[0] / $days);
            $dailyprofit = sprintf("%.2f", $profit[0] / $days);
          }
        }
        print "$sets[1]-$sets[2]  $_\tprofit:\t$profit%\tdiff: $diff%\tyearly: $dailyprofit%\ttrades/d: $dailytrades\t candle:$warms[0]:$warms[1]\t backtest time: ";
        if ( ! -e $csv) {
          open my $fh3, '>>', $csv or die "Cannot open $csv!";
          print $fh3 join ("\n","currency,asset,exchange,strategy,profit[%],\"profit/day[%]\",\"yearly profit[%]\",\"market change[%]\",profit-market,\"trade amount\",\"trades/day\",\"wining trades\", \"losses trades\",\"candle size\",\"warmup period\",\"days of dataset\",\"backtest start\",\"dataset from\",\"dataset to\",\"strategy values\",note\n");
          close $fh3;
        }
        open my $fh3, '>>', $csv or die "Cannot open $csv!";
        my $tocsv = "$sets[1]\,$sets[2]\,$sets[0]\,$_\,$profit\,$dailyprofit\,$yearly\,$market\,$diff\,$trades[0]\,$dailytrades\,$wins\,$losses\,$warms[0]\,$warms[1]\,$days\,$ctime\,$start[0]\,$end[0]\,$strat[0],$note\n";
        print $fh3 join ("\n",$tocsv);
        close $fh3;
        unlink $configfile;
        my $endthread = time();
        my $elapsedthread = $endthread - $startthread;
        $elapsedthread = elapsed( $elapsedthread );
        print "$elapsedthread\n";
    
        if (@strategies >= @pairs && @strategies >= @warmup) {
            $pm->finish;
        }
    }
      if (@pairs >= @strategies && @pairs >= @warmup) {
        $pm->finish;
      }
    }
    if (@warmup >= @strategies && @warmup >= @pairs) {
      $pm->finish;
    }
  $pm->wait_all_children;
  }
  my $endapp = time();
  my $elapsedapp = $endapp - $startapp;
  $elapsedapp = elapsed( $elapsedapp );
  print "All jobs are done. Elapsed time: $elapsedapp\n";
  
  exit
}
# IMPORT
if ($ARGV[0] eq "-i") {
  my $startapp = time();
  # Log file name.
  my $logfile = "logs/import-$startapp.log";
    foreach (@pairs) {
      my @sets = split /:/, $_;
      my $startthread = time();
      my $configfile = "import-$sets[1]-$sets[2].js";
      
      $gconfig =~ s/(?<=config.performanceAnalyzer = \{\n  enabled: )(.*)(?=,)/false/m;  
      $gconfig =~ s/(?<=config.tradingAdvisor = \{\n  enabled: )(.*)(?=,)/false/m;  
      $gconfig =~ s/(?<=config.trader = \{\n  enabled: )(.*)(?=,)/false/m;
      $gconfig =~ s/(?<=config.paperTrader = \{\n  enabled: )(.*)(?=,)/false/m;
      $gconfig =~ s/(?<=config.candleWriter = \{\n  enabled: )(.*)(?=,)/true/m;
      $gconfig =~ s/(?<=exchange: ')(.*?)(?=',)/$sets[0]/g;
      $gconfig =~ s/(?<=currency: ')(.*?)(?=',)/$sets[1]/g;
      $gconfig =~ s/(?<=asset: ')(.*?)(?=',)/$sets[2]/g;
      $gconfig =~ s/(?<=method: ')(.*?)(?=',)/$strategies[0]/g;
      $gconfig =~ s/(?<=candleSize: )(.*?)(?=,)/1/g;
      $gconfig =~ s/(?<=historySize: )(.*?)(?=,)/2/g;
      $gconfig =~ s/(?<=config.candleWriter = \{\n  enabled: )(.*)(?=\n)/true/m;
      
      open my $fh, '>', $configfile or die "Cannot open $configfile!";
      print $fh join ("\n",$gconfig);
      #print $fh join ("\n",$impstr);
      close $fh;
      
      
      my $grun = `node gekko -i -c $configfile`;
      open my $fh2, '>>', $logfile or die "Cannot open $logfile!";
      print $fh2 join ("\n",$grun);
      close $fh2;
      unlink $configfile;
        
      my $endthread = time();
      my $elapsedthread = $endthread - $startthread;
      $elapsedthread = elapsed( $elapsedthread );
      print "Importing $sets[0] $sets[1]-$sets[2] is done. Elapsed time: $elapsedthread \n";
      
    }
  my $endapp = time();
  my $elapsedapp = $endapp - $startapp;
  $elapsedapp = elapsed( $elapsedapp );
  print "\nAll jobs are done. Elapsed time: $elapsedapp\nFor more info check check $logfile\n";
  exit
  
}
if (defined($ARGV[0] eq "-p")) {
  my $startapp = time();
  foreach (@warmup) {
    my @warms = split /:/, $_;
    foreach (@pairs) {
      my @sets = split /:/, $_;
      foreach (@strategies) {
        my $configfile = "$sets[1]-$sets[2]-$_-$warms[0]-$warms[1]-config.js";
        # Log file name.
        my $logfile = "logs/paper-$sets[1]-$sets[2]-$_-$warms[0]-$warms[1].log";
        $gconfig =~ s/(?<=config.candleWriter = \{\n  enabled: )(.*)(?=\n)/false/m;
        $gconfig =~ s/(?<=exchange: ')(.*?)(?=',)/$sets[0]/g;
        $gconfig =~ s/(?<=currency: ')(.*?)(?=',)/$sets[1]/g;
        $gconfig =~ s/(?<=asset: ')(.*?)(?=',)/$sets[2]/g;
        $gconfig =~ s/(?<=method: ')(.*?)(?=',)/$_/g;
        $gconfig =~ s/(?<=candleSize: )(.*?)(?=,)/$warms[0]/g;
        $gconfig =~ s/(?<=historySize: )(.*?)(?=,)/$warms[1]/g;
        open my $fh, '>', $configfile or die "Cannot open $configfile!";
        print $fh join ("\n",$gconfig);
        close $fh;
        system("node gekko -c $configfile >> $logfile &");
      }
    }
  }
my $endapp = time();
my $elapsedapp = $endapp - $startapp;
$elapsedapp = elapsed( $elapsedapp );
print "All jobs are done. Elapsed time: $elapsedapp\n";
exit
}
if (defined($ARGV[0] eq "-h")) {
  print "perl backtest.pl - run backtest\nperl backtest.pl -i - run import\nperl backtest.pl -p - run multiple paperTraders in background\n";
  exit
}
