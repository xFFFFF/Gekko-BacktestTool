#!/usr/bin/perl -w
no warnings qw(uninitialized);
use strict;
use Parallel::ForkManager;
use POSIX qw(strftime);
use Time::Elapsed qw( elapsed );
use List::MoreUtils qw/ minmax uniq /;
use File::chdir;
use Time::Local;
use Getopt::Long qw(GetOptions);
use Statistics::Basic qw(:all);
use DBI;
use JSON::XS;
use TOML qw(from_toml);
use File::Basename;
use File::Temp qw/ tempfile tempdir mkdtemp /;
use File::Find::Wanted;
use Template qw( );
use LWP::UserAgent ();
use LWP::Protocol::https;

$| = 1;

our (@strategies, @pairs, @warmup, $from, $to, $csv, $print_roundtrips, $threads, $stratsettings, $keep_logs, $asset_c, $currency_c, $fee_maker, $fee_taker, $fee_using, $slippage, $riskFreeReturn, $use_toml_files, $toml_directory, $note, $tocsv, $csv_columns, $debug, $cmc_data);
my ($oconfigfile, $ostrat, $opairs, $owarmup, $oimport, $opaper, $ohelp, $oconvert, $ofrom, $oto, $ocsv, %datasets, $json, $gconfig, $currency, $asset, $exchange, $strategy, $profit, $profit_day, $profit_year, $sharpe_ratio, $market_change, $profit_market, $trades, $trades_day, $winning_trades, $lost_trades, $percentage_wins, $best_win, $median_wins, $worst_loss, $median_losses, $avg_exposed_duration, $candlesize, $historysize, $dataset_days, $backtest_start, $dataset_from, $dataset_to, $price_volality, $volume, $volume_day, $overall_trades, $overall_trades_day, $template);
$backtest_start = strftime "%Y-%m-%d %H:%M:%S", localtime;
my ($open_price, $close_price, $highest_price, $lowest_price, $avg_price);

GetOptions(
  'config|c=s' => \$oconfigfile,
  'output|o=s' => \$ocsv,
  'from|f=s' => \$ofrom,
  'to|t=s' => \$oto,
  'import|i' => \$oimport,
  'paper|g' => \$opaper,
  'help|h' => \$ohelp,
  'convert|v=s' => \$oconvert,
  'strat|s=s' => \$ostrat,
  'pair|p=s' => \$opairs,
  'candle|n=s' => \$owarmup
) or die "Example: $0 --import --pair=bitfinex:USD:BTC --from=\"2018-01-01 09:10\" --to=\"2018-01-05 12:23\"\nUse backtest.pl --help for more details.\n";

sub convert {
  my $toml; 
  my $stratname = basename($_[0]);
  $stratname  =~ s/\.toml$//i;
  open(my $fh, '<', $_[0]) or die "cannot open file $_[0]";
  {
  local $/;
  $toml = <$fh>;
  }
  close($fh);

  my ($data, $err) = from_toml($toml);
  unless ($data) {
    die "Error parsing toml: $err";
  }
  my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
  $json = $coder->encode ($data);
  $json =~ s/^{/config.$stratname = {\n/;
  return $json;
}
sub analyze {
  
  
  #use Text::Table;
  
  #my $tprofitd = Text::Table->new( "Pair\n----", "Strat\n-----", "Profit\n------", "Profit-market\n-------------", "Trades\n------", "% wins\n------", "Best win\n--------", "Worst loss\n----------", "Avg.Hodl\n--------", "Avg.price\n---------", "Ov.trades\n---------", "Volume\n------");
  #my @sorted;
  #foreach (@sorted) {
     #$tprofitd->add(
    #$_->{'currency'}.'-'.$_->{'asset'},
    #$_->{'strategy'},
    #$_->{'profit[%]'},
    #$_->{'"profit-market"'},
    #$_->{'trades_day'},
    #$_->{'wins[%]'},
    #$_->{'"best win"'},
    #$_->{'"worst loss"'},
    #$_->{'"avg HODL[min]"'},
    #$_->{'"avg. price"'},
    #$_->{'"volatility"'},
    #$_->{'"overall trades_day"'},
    #$_->{'volume_day'}
    #)
  #}
  #$tprofitd->add(' ');
  #print $tprofitd;
  
  
}

sub toepoch {
  my @a = split /[- :]/, $_[0];
  $a[0] =~ s/^.{2}//;
  if (! defined $a[5]) {
    $a[5] = 00
  }
  --$a[1];
  if ($a[1] < 0) {
    --$a[0];
    $a[1] += 12;
  }
  my $b = timelocal($a[5], $a[4], $a[3], $a[2], $a[1], $a[0]);
  return $b;
}


my $configfile = "./backtest-config.pl";
$tocsv =~ s/'/"/g;
if ($oconfigfile) {
  $configfile = $oconfigfile;
}
require $configfile;

if ($ofrom) {
  $from=$ofrom;
 }
if ($oto) {
  $to = $oto
}
if ($opairs) {
  @pairs = ();
  $opairs =~ s/ //g;
  @pairs = split /,/, $opairs;
}

my $gconfig1 = q(
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
my $tmpfile = 'tmp';
mkdir $tmpfile unless -d $tmpfile;

if ($oimport) {  
 $gconfig = $gconfig1;
  
  my $startapp = time;
  if (grep /binance|bitfinex|coinfalcon|kraken/, @pairs) {
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
   
    foreach (@pairs) {
      my @sets = split /:/, $_;
      #SPRAWDZIC!!!!!!!!!!!!!!
      if ($sets[1] eq 'ALL' || $sets[2] eq 'ALL') {
        my $filename = "exchanges/$sets[0]-markets.json";
        my $json_text = do {
          open(my $json_fh, "<:encoding(UTF-8)", $filename) or die("Can't open \$filename\": $!\n");
          local $/;
          <$json_fh>
        };
        my $json = JSON->new;
        my $data = $json->decode($json_text);
    
        my $rec = scalar (@{ $data->{markets} }) -1;
        @pairs = ();
        for my $i (0 .. $rec) {
          push @pairs, "$sets[0]:$data->{markets}->[$i]->{pair}->[0]:$data->{markets}->[$i]->{pair}->[1]";
        }
      
        if ($sets[2] eq 'ALL') {
          @pairs = grep /$sets[0]:$sets[1]:/, @pairs;
        }
      }
    }
  }
  
  if (grep !/binance|bitfinex|coinfalcon|kraken/, @pairs && grep /ALL/, @pairs) {
    print "Value ALL is allowed only for binance, bitfinex, coinfalcon, kraken exchanges. You must add your pairs manually.\n";
    exit
  }
  # Log file name.
  my $logfile = "logs/import-$startapp.log";
  if ($keep_logs eq 'yes') {
    print "Loging to $logfile file\n";
  }
  my $remain = scalar @pairs;
  my $errcheck;
  my $palist = join(', ', map {"$_"} @pairs);
  print "Import $remain pairs: $palist.\n";
    foreach (@pairs) {
      my @sets = split /:/, $_;
      my $startthread = time;
      my $configfile = File::Temp->new(TEMPLATE => "tmp_configXXXXX",SUFFIX => ".js", DIR => $tmpfile );
      if ($ofrom eq 'last') {
        my $tablename = "candles_$sets[1]_$sets[2]";
        my $dbh = DBI->connect(          
        "dbi:SQLite:dbname=history/$sets[0]_0.1.db", 
        "",                          
        "",                          
        { RaiseError => 1 },         
        ) or die $DBI::errstr;
        if ($sets[1] eq 'ALL' || $sets[2] eq 'ALL') {
          my $stmt = qq[CREATE TABLE IF NOT EXISTS \'$tablename\' (id INTEGER PRIMARY KEY AUTOINCREMENT, start INTEGER UNIQUE, open REAL NOT NULL, high REAL NOT NULL, low REAL NOT NULL, close REAL NOT NULL, vwp REAL NOT NULL, volume REAL NOT NULL, trades INTEGER NOT NULL);];
          my $sth = $dbh->prepare( $stmt );
          my $rv = $sth->execute() or die $DBI::errstr;
          if($rv < 0) {
            print $DBI::errstr;
          }
        }
          
        my $stmt = qq{SELECT start FROM \'$tablename\' ORDER BY start DESC LIMIT 0,1;};
        my $sth = $dbh->prepare( $stmt );
        my $rv = $sth->execute() or die $DBI::errstr;
        if($rv < 0) {
          print $DBI::errstr;
        }
        $from = $sth->fetchrow_array(); 
        
        if (! defined $from) {
          $from = strftime "%Y-%m-%d %H:%M:%S", gmtime(time - 86400);
        }
        else {
          $from = strftime "%Y-%m-%d %H:%M:%S", gmtime($from - 60);
        }      
      }
      if ($to eq 'now') {
        $to = strftime "%Y-%m-%d %H:%M:%S", gmtime;
      }
      print "$sets[1]:$sets[2] ($from \- $to) is started at $to...\n";
      
      if (defined $from) {
        if ($gconfig !~ /config.importer/) {
          $gconfig =~ s/(?<=batchSize: 50\n)(.*)(?=\n)/}\nconfig.importer = {\n  daterange: {\n    from: \"$from\",\n    to: \"$to\"\n  }\n}/m; 
        }
        else {        
          $gconfig =~ s/(?<=from: \").*(?=\",)/$from/g;
          $gconfig =~ s/(?<=to: \").*(?=\")/$to/g;
        }
      }
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
      my @debug = $grun =~ /DEBUG\):\s+\K(.*)/g;
      foreach (@debug) {
        print "$_\n";
      }
      $configfile->flush;
      if ($keep_logs eq 'yes') {
        open my $fh2, '>>', $logfile or die "Cannot open $logfile!";
        print $fh2 join ("\n",$grun);
        close $fh2;
      } 
      
      if($grun !~ m/Done importing/){
        $errcheck++;
        --$remain;
        my @error;
        @error = $grun =~ /(?<=Error:\n\n).*/g;
        print "Importing $sets[0] $sets[1]-$sets[2] is failed: @error\n";
      }
      else {
        my $endthread = time;
        my $elapsedthread = $endthread - $startthread;
        $elapsedthread = elapsed( $elapsedthread );
        print "Import of $sets[0] $sets[1]-$sets[2] is done. Elapsed time: $elapsedthread. \n".--$remain." from ".scalar @pairs." pairs left.\n"
      }
    }
  my $endapp = time;
  my $elapsedapp = $endapp - $startapp;
  $elapsedapp = elapsed( $elapsedapp );
  
  if ($errcheck) {
    print "Had $errcheck errors on ".scalar @pairs. " jobs. Elapsed time: $elapsedapp\n";
  }
  else {
    print "All jobs are done. Elapsed time: $elapsedapp\n";
  }
  exit
}

if ($opaper) {
  my $startapp = time;
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
  
  my $endapp = time;
  my $elapsedapp = $endapp - $startapp;
  $elapsedapp = elapsed( $elapsedapp );
  print "All jobs are done. Elapsed time: $elapsedapp\n";
  
  exit
}

if ($ohelp) {
  print qq{usage: perl backtest.pl
To run backtests machine

usage: perl backtest.pl [mode] [optional parameter]
To run other features

Mode:
  -i, --import\t - Import new datasets
  -g, --paper\t - Start multiple sessions of PaperTrader
  -v, --convert TOMLFILE\t - Convert TOML file to Gekko's CLI config format, ex: backtest.pl -v MACD.toml
  
Optional parameters:
  -c, --config\t\t - BacktestTool config file. Default is backtest-config.pl
  -s, --strat STRATEGY_NAME - Define strategies for backtests. You can add multiple strategies seperated by commas example: backtest.pl --strat=MACD,CCI
  -p, --pair PAIR\t - Define pairs to backtest in exchange:currency:asset format ex: backtest.pl --p bitfinex:USD:AVT. You can add multiple pairs seperated by commas.
  -p exchange:ALL\t - Perform action on all available pairs. Other usage: exchange:USD:ALL to perform action for all USD pairs.
  -n, --candle CANDLE\t - Define candleSize and warmup period for backtest in candleSize:warmup format, ex: backtest.pl -n 5:144,10:73. You can add multiple values seperated by commas.
  -f, --from
  -f last\t\t- Start import from last candle available in DB. If pair not exist in DB then start from 24h ago.
  -t, --to\t\t - Time range for backtest datasets or import. Example: backtest.pl --from="2018-01-01 09:10" --to="2018-01-05 12:23"
  -t now\t\t- 'now' is current time in GMT.
  -o, --output FILENAME - CSV file name.
};
  exit
}
if ($oconvert) {
  
  &convert($oconvert);
  print "Input: $oconvert\nOutput:\n";
  print $json;
}

else {
  my $pm = Parallel::ForkManager->new($threads);
  my (%paircalc, %lookup, $req, $pairname);
     my (%cmcvolume, %cmcrank, %cmcmarketcap);
  my $tmpcsv = File::Temp->new(UNLINK => 1, TEMPLATE => "tmp_dataXXXXX",SUFFIX => ".csv",DIR => $tmpfile);
  $pm->run_on_finish(sub {
    my $data = pop @_;
    %paircalc = (%paircalc, %$data);
  });
  if ($cmc_data eq 'yes') {
    $req = LWP::UserAgent->new;        
    $req->agent("Gekko BacktestTool");
    $req->timeout(10);
    my $response = $req->get("https://api.coinmarketcap.com/v1/ticker/?limit=800");
    
    if ($response->is_success) {
   
      $response = decode_json($response->content);
      
      
      %cmcvolume = map { $_->{symbol} => $_->{'24h_volume_usd'}} @$response;
      %cmcrank = map { $_->{symbol} => $_->{'rank'}} @$response;
      %cmcmarketcap = map { $_->{symbol} => $_->{'market_cap_usd'}} @$response;
    }
    else {
      print "CMC failed: ".$response->status_line."\n";
    }
  }

  my $endtread;
  
  if ($ostrat) {
    @strategies = ();
    $ostrat =~ s/ //g;
    @strategies = split /,/, $ostrat;
  }

  foreach (@pairs) {
    my @sets = split /:/, $_;
    if ($sets[1] =~ /ALL/ || $sets[2]=~/ALL/) {
      my $dbh = DBI->connect("dbi:SQLite:dbname=history/$sets[0]_0.1.db", "", "", { RaiseError => 1 },) or die $DBI::errstr;
      my $stmt;
      if ($sets[1] =~ /ALL/) {
        $stmt = qq(SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%candles%';);
      }
      else {
        $stmt = qq(SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%candles_$sets[1]%';);
      }
      my $sth = $dbh->prepare( $stmt );
      my $rv = $sth->execute() or die $DBI::errstr;
      if($rv < 0) {
        print $DBI::errstr;
      }
      my @row;
      while (@row = $sth->fetchrow_array()) {
        my $stmt = qq(select count(*) FROM $row[0];);
        my $sth = $dbh->prepare( $stmt );
        my $rv = $sth->execute() or die $DBI::errstr;
        my @row2;
        while (@row2 = $sth->fetchrow_array()) {
          if ($row2[0] > 5) {
          $row[0] =~ s/candles_//g;
          $row[0] =~ s/_/:/g;
          $row[0] = "$sets[0]:$row[0]";
          push @pairs, $row[0];
          }
        }
      }
      @pairs = grep !/ALL/, @pairs;
    }
  }
  
  $paircalc{"cmcvol$pairname"} = 'NA';
  $paircalc{"cmcrank$pairname"} = 'NA';
  $paircalc{"cmccurmarketcap$pairname"} = 'NA';
      
  if ($cmc_data eq 'yes') {
    $lookup{'AIO'} = 'AION';
    $lookup{'DSH'} = 'DASH';
    $lookup{'IOS'} = 'IOST';
    $lookup{'IOTA'} = 'MIOTA';
    $lookup{'IOT'} = 'MIOTA';
    $lookup{'MNA'} = 'MANA';
    $lookup{'QSH'} = 'QASH';
    $lookup{'QTM'} = 'QTUM';
    $lookup{'SNG'} = 'SNGLS';
    $lookup{'SPK'} = 'SPANK';
    $lookup{'YYW'} = 'YOYOW';
    $lookup{'YOYO'} = 'YOYOW';
      
    foreach (@pairs) {
      my @sets = split /:/, $_;
      
      if ($sets[0] eq 'binance' && $sets[2] eq 'BCC') {
        $lookup{'BCC'} = 'BCH';
      }
      
      $pairname = "$sets[0]:$sets[1]:$sets[2]";

      my $cmcasset;
      if ($lookup{$sets[2]}) {
        $cmcasset = $lookup{"$sets[2]"};
      }
      else {
        $cmcasset = $sets[2];
      }

      if (grep /$cmcasset/, %cmcvolume) {
        $paircalc{"cmcvol$pairname"} = sprintf ("%d", $cmcvolume{$cmcasset});
        $paircalc{"cmcrank$pairname"} = $cmcrank{$cmcasset};
        $paircalc{"cmccurmarketcap$pairname"} = sprintf ("%d", $cmcmarketcap{$cmcasset});
      }
    }
  }
  
  my $startapp = time;
  my $remain = scalar @pairs * scalar @strategies * scalar @warmup;
  my $palist = join(', ', map {"$_"} @pairs);
  my $stlist = join(', ', map {"$_"} @strategies);
  my $walist = join(', ', map {"$_"} @warmup);
  print "$remain backtest to do on pairs: $palist, strategies: $stlist, candles: $walist\n";
  foreach (@warmup) {
    if (@warmup >= @strategies && @warmup >= @pairs && @warmup > 1) {
      my $pid = $pm->start and next;
    }
    my @warms = split /:/, $_;
    
    foreach (@pairs) {
      if (@pairs > @strategies && @pairs >= @warmup && @pairs > 1) {
        my $pid = $pm->start and next;
      }
      my @sets = split /:/, $_;

      foreach (@strategies) {
        if (@strategies >= @pairs && @strategies >= @warmup && @strategies > 1) {
          my $pid = $pm->start and next;
        }
     
        my $startthread = time;
  
        $configfile = File::Temp->new(UNLINK => 1, TEMPLATE => "tmp_configXXXXX",SUFFIX => ".js",DIR => $tmpfile);
        $configfile->unlink_on_destroy( 1 );
        File::Temp::cleanup();
        # Log file name.
        my $logfile = "logs/$sets[1]-$sets[2]-$_-$warms[0]-$warms[1].log";
        #$gconfig =~ s/simulationBalance: {/n    asset: 0,/n    currency: 4/$asset/;
        #$gconfig =~ s/(?<=currency: )(.*)(?=,)/$currency/;
        $gconfig = $gconfig1;
        if ($ocsv) {
          $csv = $ocsv
        }
        if (defined $from) {
          $gconfig =~ s/daterange:  'scan',/daterange: {\n    from: \"$from\",\n    to: "$to"\n  },/g; 
        }

        if ($owarmup) {
          @warmup = ();
          $owarmup =~ s/ //g;
          @warmup = split /,/, $owarmup;
        }
        
        $gconfig =~ s/(?<=feeMaker: )(.*)(?=,)/$fee_maker/;
        $gconfig =~ s/(?<=feeTaker: )(.*)(?=,)/$fee_taker/;
        $gconfig =~ s/(?<=feeUsing: ')(.*)(?=',)/$fee_using/;
        $gconfig =~ s/(?<=slippage: )(.*)(?=,)/$slippage/;
        $gconfig =~ s/(?<=riskFreeReturn: )(.*)(?=,)/$riskFreeReturn/;
        
        my $sname = $_;
        if ($use_toml_files eq 'yes') {
          my @file_list = find_wanted( sub { -f && /^$sname\..*$/i }, $toml_directory );
          if (@file_list) {
            &convert($file_list[0]);
          }
          $stratsettings = $json;
        }
        
        $gconfig =~ s/}(?=\nconfig.performanceAnalyzer)/}\n$stratsettings/m;
        my @strat = $gconfig =~ /(?<=config.$sname = \{)(.*?)(?=};)/s;
        $strat[0] =~ s/[\n\t]/ /g;
        $strat[0] =~ s/  / /g;
        $strat[0] =~ s/^\s+//;
        $strat[0] =~ s/\s+$//;
        $strat[0] =~ s/"/\'/g;
        $strat[0] =~ s/^/"/;
        $strat[0] =~ s/$/"/;
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
        if ($keep_logs eq 'yes') {
          open my $fh2, '>>', $logfile or die "Cannot open $logfile!";
          print $fh2 join ("\n",$gconfig);
          print $fh2 join ("\n",$grun);
          close $fh2;
        }
        my @profit = $grun =~ /(?<=simulated profit:\t\t )[0-9.\-][0-9.\-]* $sets[1] \((.*)(?=\%\))/;
        my @yearly = $grun =~ /(?<=simulated yearly profit:\t )[0-9.\-][0-9.\-]* $sets[1] \((.*)(?=\%\))/;
        my @trades = $grun =~ /(?<=trades:\t\t )(.*?)(?=\n)/;
        my @period = $grun =~ /(?<=timespan:\t\t\t )(.*?)(?=\n)/;
        my @start = $grun =~ /start time:\s+\K(.*)/;
        my @end = $grun =~ /end time:\s+\K(.*)/;


        my @roundtrips = $grun =~ /ROUNDTRIP\)\s+\d{4}-\d{2}-\d{2}.*?\K-?\d+\.\d+/g;
        my ($worst_loss, $best_win) = minmax @roundtrips;
        my @wins = grep($_ > 0, @roundtrips);
        $percentage_wins = -1;
        if (@roundtrips > 0) {
          $percentage_wins = sprintf("%.2f", @wins * 100 / @roundtrips);
        }
        $median_wins = median @wins;
        $median_wins =~ s/,/\./;
        my @loss = grep($_ <= 0, @roundtrips);
        $median_losses = median @loss;
        $median_losses =~ s/,/\./;
        $winning_trades = scalar @wins;
        $lost_trades = scalar @loss;
        my @exposed = $grun =~ /(?<=ROUNDTRIP\) )([-:\t \d]+)/g;
        my @exposed_min;
        foreach (@exposed) {
          my @exposed =  split /\t/, $_;
          my $roznica =( &toepoch ($exposed[1]) - &toepoch ($exposed[0]) ) / 60 ;
          push @exposed_min, $roznica;
        }
        $avg_exposed_duration = avg (@exposed_min);
        $avg_exposed_duration =~ s/,/\./g;
        $market_change = sprintf("%.2f", $market[0]); 
        $profit = sprintf("%.2f", $profit[0]);
        $profit_year = sprintf("%d", $yearly[0]);
        $profit_market = sprintf("%.2f", $profit[0]-$market[0]);
        $dataset_days = -1;
        $trades_day = -1;
        $profit_day = -1;
        if(defined $end[0] && $start[0]) {
           $dataset_days = sprintf("%d",(&toepoch($end[0]) - &toepoch($start[0])) /86400);
           if ($dataset_days > 0) {
            $trades_day = sprintf("%.2f", $trades[0] / $dataset_days);
            $profit_day = sprintf("%.2f", $profit[0] / $dataset_days);
          }
          my @sharpe_ratio = $grun =~ /\(PROFIT REPORT\) sharpe ratio:\s+\K.*/g;
          $sharpe_ratio[0] = sprintf("%.2f", $sharpe_ratio[0]);
          
          $pairname = "$sets[0]:$sets[1]:$sets[2]";
          if (! $paircalc{"rsd$pairname"}) {
            $paircalc{"rsd$pairname"} = 1; 
            my $dbtable = "$sets[1]_$sets[2]";
            my $dbh = DBI->connect("dbi:SQLite:dbname=history/$sets[0]_0.1.db", "", "", { RaiseError => 1 }, ) or die $DBI::errstr;
            my $stmt = qq(SELECT high FROM candles_$dbtable WHERE start >= strftime('%s', '$start[0]') AND start <= strftime('%s', '$end[0]'));
            my $sth = $dbh->prepare( $stmt );
            my $rv = $sth->execute() or die $DBI::errstr;
            if($rv < 0) {
              print $DBI::errstr;
            }
            my @row;
            my @ceny;
            while (@row = $sth->fetchrow_array()) {
              push @ceny, @row;
            }
            $stmt = qq(SELECT low FROM candles_$dbtable WHERE start >= strftime('%s', '$start[0]') AND start <= strftime('%s', '$end[0]'));
            $sth = $dbh->prepare( $stmt );
            $rv = $sth->execute() or die $DBI::errstr;
            if($rv < 0) {
              print $DBI::errstr;
            }
            while (@row = $sth->fetchrow_array()) {
              push @ceny, @row;
            }

            foreach (grep /e/, @ceny){ 
              $_ =~ s/(?<=e[-+])0//g;
              $_ = sprintf("%.8f", $_);
            }

            my $avg = avg (@ceny);
            $price_volality = sprintf("%.1f", stddev(@ceny) * 100 / $avg);
            $paircalc{"rsd$pairname"} = $price_volality; 
            
            my ($var, $var2);
            sub sum {
              $stmt = qq(SELECT $_[0] FROM candles_$dbtable WHERE start >= strftime('%s', '$start[0]') AND start <= strftime('%s', '$end[0]'))."$_[1];";
              $sth = $dbh->prepare( $stmt );
              $rv = $sth->execute() or die $DBI::errstr;
              if($rv < 0) {
                print $DBI::errstr;
              }
              while (@row = $sth->fetchrow_array()) {
                
                $var = $row[0];
                if (grep /e/, $var) {
                  $var =~ s/(?<=e[-+])0//g;
                  $var = sprintf("%f", $var);
                }  
                  
              }
              $var2 = sprintf("%d", 86400 * $var / (&toepoch($end[0]) - &toepoch($start[0])));
              return ($var, $var2);
            }
            &sum ('sum(volume)');
            $var = sprintf("%d", $var);
            $paircalc{"vol$pairname"} = sprintf("%d", $var);
            $paircalc{"vold$pairname"} = $var2;
            &sum ('sum(trades)');
            
            $paircalc{"tra$pairname"} = sprintf("%d", $var);
            $paircalc{"trad$pairname"} = $var2;
            
            &sum ('open', ' ORDER BY start ASC LIMIT 1');
            $paircalc{"open$pairname"} = $var;
            &sum ('close', ' ORDER BY start DESC LIMIT 1');
            $paircalc{"close$pairname"} = $var;            
            &sum ('max(high)');
            $paircalc{"high$pairname"} = $var;
            &sum ('min(low)');

            $paircalc{"low$pairname"} = $var;
            &sum ('avg(vwp)');
            if (length($var) > 8) {
              $var = sprintf("%.8f", $var);
            }
            $paircalc{"avg$pairname"} = $var;

   


          }

          if ( ! -e $csv) {
            sub columns {
              my $vars = {
                'currency' => 'currency',
                'asset' => 'asset',
                'exchange' => 'exchange',
                'strategy' => 'strategy',
                'profit' => 'profit[%]',
                'profit_day' => 'profit/day[%]',
                'profit_year' => 'profit/year[%]',
                'sharpe_ratio' => '"sharpe ratio"',
                'market_change' => '"market change[%]"',
                'profit_market' => '"profit-market"',
                'trades' => 'trades',
                'trades_day' => 'trades/day',
                'winning_trades' => '"winning trades"',
                'lost_trades' => '"lost trades"',
                'percentage_wins' => 'wins[%]',
                'best_win' => '"best win"',
                'median_wins' => '"median wins"',
                'worst_loss' => '"worst loss"',
                'median_losses' => '"median losses"',
                'avg_exposed_duration' => '"avg HODL[min]"',
                'candle_size' => 'candleSize',
                'warmup_period' => 'historySize',
                'dataset_days' => 'days',
                'backtest_start' => 'start',
                'dataset_from' => 'from',
                'dataset_to' => 'to',
                'CMC_Rank' => '"cur CMC rank"',
                'current_marketcap' => '"cur marketcap"',
                'open_price' => '"open price"',
                'close_price' => 'close',
                'lowest_price' => 'low',
                'highest_price' => 'high',
                'avg_price' => '"avg. price"',
                'price_volality' => '"volatility"',
                'volume' => 'volume',
                'volume_day' => 'volume/day',
                'volume_CMC' => '"cur CMC volume"',
                'overall_trades' => '"overall trades"',
                'overall_trades_day' => '"overall tradaes/day"',
              };
              my $out;
              $tocsv = Template->new({ });
              $tocsv->process($_[0], $vars, \$out);
              open my $fh3, '>>', $csv or die "Cannot open $csv!";
              print $fh3 join ("\n","$out \r\n");
              close $fh3;
            }
            &columns($csv_columns);
          }

          my $vars = {
            'currency' => $sets[1],
            'asset' => $sets[2],
            'exchange' => $sets[0],
            'strategy' => $_,
            'profit' => $profit,
            'profit_day' => $profit_day,
            'profit_year' => $profit_year,
            'sharpe_ratio' => $sharpe_ratio[0],
            'market_change' => $market_change,
            'profit_market' => $profit_market,
            'trades' => $trades[0],
            'trades_day' => $trades_day,
            'winning_trades' => $winning_trades,
            'lost_trades' => $lost_trades,
            'percentage_wins' => $percentage_wins,
            'best_win' => $best_win,
            'median_wins' => $median_wins,
            'worst_loss' => $worst_loss,
            'median_losses' => $median_losses,
            'avg_exposed_duration' => $avg_exposed_duration,
            'candle_size' => $warms[0],
            'warmup_period' => $warms[1],
            'dataset_days' => $dataset_days,
            'backtest_start' => $backtest_start,
            'dataset_from' => $start[0],
            'dataset_to' => $end[0],
            'CMC_Rank' => $paircalc{"cmcrank$pairname"},
            'current_marketcap' => $paircalc{"cmccurmarketcap$pairname"},
            'open_price' => $paircalc{"open$pairname"},
            'close_price' => $paircalc{"close$pairname"},
            'lowest_price' => $paircalc{"low$pairname"},
            'highest_price' => $paircalc{"high$pairname"},
            'avg_price' => $paircalc{"avg$pairname"},
            'price_volality' => $paircalc{"rsd$pairname"},
            'volume' => $paircalc{"vol$pairname"},
            'volume_day' => $paircalc{"vold$pairname"},
            'volume_CMC' => $paircalc{"cmcvol$pairname"},
            'overall_trades' => $paircalc{"tra$pairname"},
            'overall_trades_day' => $paircalc{"trad$pairname"},
          };

          my $csvout;
          $tocsv = Template->new({ });
          $tocsv->process($csv_columns, $vars, \$csvout);

          open my $fh3, '>>', $csv or die "Cannot open $csv!";
          print $fh3 join ("\n", "$csvout \r\n");
          close $fh3;
          
          sub tempr {

          $csv_columns = \ "[% currency %],[% asset %],[% strategy %],[% profit %],[% profit_day %],[% profit_market %],[% trades_day %],[% percentage_wins %],[% best_win %],[% worst_loss %],[% avg_exposed_duration %],[% avg_price %],[% price_volality %],[% volume_day %],[% overall_trades_day %]";
          $tocsv = Template->new({ });
          $tocsv->process($csv_columns, $vars, \$csvout);

          open my $fh, '>>', $tmpcsv or die "Cannot open $tmpcsv!";
          print $fh join ("\n", "$csvout \r\n");
          close $fh;
  
          }
          &tempr();
                    if ($print_roundtrips eq 'yes') {
            print "---------\n";
            my @trips;
            @trips = $grun =~ /(?<=ROUNDTRIP\) )[0-9a-z].*/g;
            foreach (@trips) {
            print "$_\n";
            }
          }          

          print "$sets[1]-$sets[2]  $_\tprofit:\t$profit%\tprofit-market: $profit_market%\tprofit/d: $profit_day%\ttrades/d: $trades_day\t candle:$warms[0]:$warms[1]\tdays: $dataset_days\tbacktest time: ";
          my $endthread = time;
          my $elapsedthread = $endthread - $startthread;
          $elapsedthread = elapsed( $elapsedthread );
          print "$elapsedthread\n";
        }
        else {
          my @error = $grun =~ /(?<=Error:\n\n).*/g;
          print "$sets[1]-$sets[2] Backtest is failed. @error\n";
        }

        if (@strategies >= @pairs && @strategies >= @warmup && @strategies > 1) {
          $pm->finish(0, \%paircalc);
        }
      }
      if (@pairs >= @strategies && @pairs >= @warmup && @pairs > 1) {
        $pm->finish(0, \%paircalc);
      }
    }
    if (@warmup >= @strategies && @warmup >= @pairs && @warmup > 1) {
      $pm->finish(0, \%paircalc);
    }
 
  $pm->wait_all_children;
  }

  #&analyze($tmpcsv);

  my $endapp = time;
  my $elapsedapp = $endapp - $startapp;
  $elapsedapp = elapsed( $elapsedapp );
  print "All jobs are done. Elapsed time: $elapsedapp\n";
  
}
unlink glob "$tmpfile/*";
rmdir $tmpfile
