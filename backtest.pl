#!/usr/bin/perl -w
use strict;
use Parallel::ForkManager;
use Time::ParseDate qw(parsedate);
use POSIX qw(strftime);
use Time::Elapsed qw( elapsed );
use List::MoreUtils qw/ uniq /;
use File::chdir;
use Getopt::Long qw(GetOptions);
no warnings qw(uninitialized);

############################# START OF CONFIGURATION #############################
# Put your strategy names between brackets in line below. Strategy seperate with space or newline.
my @strategies = qw(neuralnet RSI_BULL_BEAR );
# Put your pairs between brackets in line below. Use exchange:currency:asset format. Seperate pair using space or newline.
my @pairs = qw(
bitfinex:USD:ETP
binance:USDT:BTC
binance:BNB:XLM
binance:BNB:NANO
binance:BNB:VEN
binance:BNB:NCASH
);
# Put your candleSizes and warmups between brackets in line below. Use candleSize:warmup format. Seperate pair using space or newline.
my @warmup = qw(10:73 11:70 12:69 13:65 9:75 8:80 7:90 6:100);
# To specify time range for import or backtest uncomment lines below, but instead this you can use command line input ex.: backtest.pl --from "2018-01-01 00:00:00" --to "2018-01-05 00:00:00". If below lines are commented Gekko is using scan datasets feature in backtest mode. 
my $from;
my $to;
#my $from = '2018-03-01 00:00:00';
#my $to = '2018-03-15 00:00:00';
# CSV file name. You don't need change this. All new data will append to exist without deleting or replacing.
my $csv = 'database.csv';
# You can add note to project below. Note will be add in CSV file. Its can be useful when You are developing strategy.
my $note = 'first run';
# Do you want see roundtrips report in terminal output?
my $print_roundtrips = 'yes';
# Threads amount, for 4xcpu cores is recommended to set 5-6 value.
my $threads = 5;
# Between brackets place strategy settings in Gekko's config.js format.
my $stratsettings = q(
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
);
############################# END OF CONFIGURATION #############################

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
  slippage: 0.5,
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
  daterange:  'scan',
  batchSize: 50
}

config['I understand that Gekko only automates MY OWN trading strategies'] = true;
module.exports = config;
);

$gconfig =~ s/}(?=\nconfig.performanceAnalyzer)/}\n$stratsettings/m;
my ($ostrat, $opairs, $owarmup, my $oimport, my $opaper, my $ohelp, my $oconvert);
GetOptions(
  'output|o=s' => \$csv,
  'from|f=s' => \$from,
  'to|t=s' => \$to,
  'import|i' => \$oimport,
  'paper|g' => \$opaper,
  'help|h' => \$ohelp,
  'convert|v' => \$oconvert,
  'strat|s=s' => \$ostrat,
  'pair|p=s' => \$opairs,
  'candle|n=s' => \$owarmup
) or die "Example: $0 --import --pair=bitfinex:USD:BTC --from=\"2018-01-01 09:10\" --to=\"2018-01-05 12:23\"\nUse backtest.pl --help for more details.\n";

if ($ostrat) {
  @strategies = ();
  @strategies = split /,/, $ostrat;
}
if ($opairs) {
  @pairs = ();
  @pairs = split /,/, $opairs;
}
if ($owarmup) {
  @warmup = ();
  @warmup = split /,/, $owarmup;
}

if (defined $from) {
  $gconfig =~ s/daterange:  'scan',/daterange: {\n    from: \"$from\",\n    to: "$to"\n  },/g;
  $gconfig =~ s/(?<=batchSize: 50\n)(.*)(?=\n)/}\nconfig.importer = {\n  daterange: {\n    from: \"$from\",\n    to: \"$to\"\n  }\n}/m;  
}

# IMPORT
if ($oimport) {

  my $startapp = time();
  my @match;
  foreach (@pairs) {
    push @match, $_
  }
  foreach (@match) {
    $_ =~ s/:.*//g;
  }
  @match = uniq @match;
    {
    local $CWD = 'util/genMarketFiles';
    foreach (@match) {
    print "Updating Gekko's $_ market data...\n";
    system("node update-$_.js");
    }
  }
  # Log file name.
  my $logfile = "logs/import-$startapp.log";
  print "Loging to $logfile file\nStart importing...\n";
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
      if($grun !~ m/Done importing/){
        print "Importing $sets[0] $sets[1]-$sets[2] is failed. Check $logfile file for more details.\n";
      }
      else {
        my $endthread = time();
        my $elapsedthread = $endthread - $startthread;
        $elapsedthread = elapsed( $elapsedthread );
        print "Importing $sets[0] $sets[1]-$sets[2] is done. Elapsed time: $elapsedthread \n";
      }
    }
  my $endapp = time();
  my $elapsedapp = $endapp - $startapp;
  $elapsedapp = elapsed( $elapsedapp );
  print "\nAll jobs are done. Elapsed time: $elapsedapp\nFor more info check check $logfile\n";
  exit
  
}
if ($opaper) {
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
        #system("node gekko -c $configfile >> $logfile &");
      }
    }
  }
my $endapp = time();
my $elapsedapp = $endapp - $startapp;
$elapsedapp = elapsed( $elapsedapp );
print "All jobs are done. Elapsed time: $elapsedapp\n";
exit
}
if ($ohelp) {
  print "usage: perl backtest.pl \nTo run backtests machine\nusage: perl backtest2.pl [parameter] [optional parameter]\nFor others features\n\nParameters:\n  -i, --import\t - Import new datasets\n  -g, --paper\t - Start multiple sessions of PaperTrader\n\nOptional parameters:\n  -s, --strat STRATEGY_NAME - Define strategies for backtests. You can add multiple strategies seperated by commas example: perl backtest.pl --strat=MACD,CCI\n  -p, --pair PAIR\t - Define pairs to backtest in exchange:currency:asset format ex: perl backtest.pl --p bitfinex:USD:AVT. You can add multiple pairs seperated by commas.\n  -n, --candle CANDLE\t - Define candleSize and warmup period for backtest in candleSize:warmup format, ex: perl backtest.pl -n 5:144,10:73. You can add multiple values seperated by commas.\n  -f, --from \n  -t, --to\t\t - Time range for backtest datasets or import. Example: perl backtest.pl --from=\"2018-01-01 09:10\" --to=\"2018-01-05 12:23\"\n  -o, --output FILENAME - CSV file name.\n";
  exit
}
else {
  my $pm = Parallel::ForkManager->new($threads);
  my $startapp = time();
  # Lets start!
  foreach (@warmup) {
    if (@warmup >= @strategies && @warmup >= @pairs && @warmup > 1) {
      my $pid = $pm->start and next;
    }
    my @warms = split /:/, $_;
    foreach (@pairs) {
      if (@pairs >= @strategies && @pairs >= @warmup && @pairs > 1) {
        my $pid = $pm->start and next;
      }
      my @sets = split /:/, $_;
      foreach (@strategies) {
        if (@strategies >= @pairs && @strategies >= @warmup && @strategies > 1) {
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
        $| = 1;
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
        my @roundtrips = $grun =~ /ROUNDTRIP\)\s+\d{4}-\d{2}-\d{2}.*?\K-?\d+\.\d+/g;
        my @wins = grep($_ > 0, @roundtrips);
        my @loss = grep($_ <= 0, @roundtrips);
        my $wins = scalar @wins;
        my $losses = scalar @loss;
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
          if ($print_roundtrips eq 'yes') {
            print "---------\n";
            my @trips;
            @trips = $grun =~ /(?<=ROUNDTRIP\) )[0-9a-z].*/g;
            foreach (@trips) {
            print "$_\n";
            }
          }          
          print "$sets[1]-$sets[2]  $_\tprofit:\t$profit%\tprofit-market: $diff%\tprofit/d: $dailyprofit%\ttrades/d: $dailytrades\t candle:$warms[0]:$warms[1]\tdays: $days\tbacktest time: ";
          if ( ! -e $csv) {
            open my $fh3, '>>', $csv or die "Cannot open $csv!";
            print $fh3 join ("\n","currency,asset,exchange,strategy,profit[%],\"profit/day[%]\",\"yearly profit[%]\",\"market change[%]\",profit-market,\"trade amount\",\"trades/day\",\"wining trades\", \"losses trades\",\"candle size\",\"warmup period\",\"days of dataset\",\"backtest start\",\"dataset from\",\"dataset to\",\"strategy values\",note\n");
            close $fh3;
          }
          open my $fh3, '>>', $csv or die "Cannot open $csv!";
          my $tocsv = "$sets[1]\,$sets[2]\,$sets[0]\,$_\,$profit\,$dailyprofit\,$yearly\,$market\,$diff\,$trades[0]\,$dailytrades\,$wins\,$losses\,$warms[0]\,$warms[1]\,$days\,$ctime\,$start[0]\,$end[0]\,$strat[0],$note\n";
          print $fh3 join ("\n",$tocsv);
          close $fh3;
          
          my $endthread = time();
          my $elapsedthread = $endthread - $startthread;
          $elapsedthread = elapsed( $elapsedthread );
          print "$elapsedthread\n";
        }
        else {
          print "$sets[1]-$sets[2] Backtest is fail. Check $logfile file for more details.\n";
        }
        unlink $configfile;
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


