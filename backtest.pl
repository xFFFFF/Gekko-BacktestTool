#!/usr/bin/perl

# compile commands
# Ubuntu: pp -M Time::Elapsed::Lang::* backtest.pl -o backtest
no warnings qw(uninitialized);
use strict;
use Parallel::ForkManager;
use POSIX qw(strftime);
use Time::Elapsed qw( elapsed );
use Time::Local;
use List::MoreUtils qw/ minmax uniq /;
use File::chdir;
use File::Copy;
use File::Path 'rmtree';
use File::Basename;
use File::Temp qw/ tempfile tempdir mkdtemp /;
use File::Find::Wanted;
use Getopt::Long qw(GetOptions);
use Statistics::Basic qw(:all);
use DBI;
use DBD::CSV;
use Text::Table;
use JSON::XS;
use TOML qw(from_toml to_toml);
use Set::CrossProduct;
use Template qw( );
use LWP::UserAgent ();
use LWP::Protocol::https;

$| = 1;
our (@strategies, @pairs, @warmup, $from, $to, $csv, $print_roundtrips, $threads, $stratsettings, $keep_logs, $asset_c, $currency_c, $fee_maker, $fee_taker, $fee_using, $slippage, $riskFreeReturn, $use_toml_files, $toml_directory, $note, $tocsv, $csv_columns, $debug, $cmc_data, $top_strategy_sort1, $top_strategy_sort2, $all_results_sort, $top_dataset_sort1, $top_dataset_sort2, $print_all_results, $summary_interval, $print_top_strategy, $print_top_dataset, $print_analysis_on_summary, $all_results_limit, $top_strategy_limit, $top_dataset_limit, $dbname, $dbhost, $dbport, $dbuser, $dbpassword, $database, $default_set, $stfu, $all_results_min_profit, $all_results_min_profit_market, $all_results_min_profit_day, $all_results_min_trades_day, $all_results_max_trades_day, $all_results_min_hodl_time, $all_results_max_hodl_time);
my ($oconfigfile, $ostrat, $opairs, $owarmup, $oimport, $operiod, $opaper, $ohelp, $oconvert, $ofrom, $oto, $ocsv, %datasets, $json, $gconfig, $currency, $asset, $exchange, $strategy, $profit, $profit_day, $profit_year, $sharpe_ratio, $market_change, $profit_market, $trades, $trades_day, $winning_trades, $lost_trades, $percentage_wins, $best_win, $median_wins, $worst_loss, $median_losses, $avg_exposed_duration, $candlesize, $historysize, $dataset_days, $backtest_start, $dataset_from, $dataset_to, $price_volality, $volume, $volume_day, $overall_trades, $overall_trades_day, $template, $oanalyze, $oinfo, $dbh);
my ($open_price, $close_price, $highest_price, $lowest_price, $avg_price);

my $configfile = "./backtest-config.pl";
mkdir 'tmp' unless -d 'tmp';

require $configfile;
my $tmpfile = 'tmp';

sub banner {
print q(
                                                                                      █████               ████
                                                                                      █████               ████
           ██                 ██                                                      █████               ████
           ██  █████████████  ██                                                      █████               ████
           █████████████████████                 █████████████        █████████       █████      █████    ████      █████      █████████
           █████████████████████               ███████████████     ██████████████     █████    █████      ████    ██████     ██████████████
           █████████████████████              █████      █████    █████      █████    █████  █████        ████  ██████      █████      █████
         █████████████████████████           █████       █████   █████        ████    █████ █████         ██████████       █████        █████
         █████████████████████████           ████        █████   ██████████████████   █████████           ████████         ████         █████
         ██████    ██████    █████           ████        █████   ██████████████████   ███████████         ██████████       ████         █████
           ████   ███████   ████             █████       █████   █████                █████  █████        ████  ██████     █████        █████
            ███████████████████               ████████████████    ██████              █████   ██████      ████    █████     █████      █████
             █████████████████                  ██████████████     ██████████████     █████     ██████    ████     █████     ██████████████
               █████████████                             █████        ███████████     █████       █████   ████       █████      ████████
                   ██████                                ████
                                              ███████████████
                                              █████████████


                 ████████                      ███         ███                            ██     █████████                     █████
                 ███   ███   ████              ███         ███                  ██        ██        ███                           ██
                 ████████   █    ██   ███████  ███ ███   ████████   ███████   ██████   █████████    ███     ███████   ███████     ██
                 ████████    ███████  ██       ██████      ███     █████████  █████       ██        ███     ██   ███  ██   ███    ██
                 ███   ███ ███   ███  ██       ███ ███     ███     ███            ███     ██        ███     ██   ███  ██   ███    ██
                 █████████ █████████   ██████  ███  ███     █████   ████████ ████████     ██████    ███     ███████   ███████     ██████

                                                                                                        Gekko BacktestTool v0.7
                                                                                              https://github.com/xFFFFF/Gekko-BacktestTool


) if $stfu eq 'no';
}
banner();

# command parameters
GetOptions(
  'config|c=s' => \$oconfigfile,
  'output|o=s' => \$ocsv,
  'from|f=s' => \$ofrom,
  'to|t=s' => \$oto,
  'period|ft=s' => \$operiod,
  'import|i' => \$oimport,
  'paper|g' => \$opaper,
  'help|h' => \$ohelp,
  'convert|v=s' => \$oconvert,
  'strat|s=s' => \$ostrat,
  'pair|p=s' => \$opairs,
  'candle|n=s' => \$owarmup,
  'analyze|a=s' => \$oanalyze,
  'info|q=s' => \$oinfo
) or die "Example: $0 --import --pair=bitfinex:USD:BTC --from=\"2018-01-01 09:10\" --to=\"2018-01-05 12:23\"\nUse backtest.pl --help for more details.\n";
sub convert {
  my $toml;
  my $stratname = basename($_[0]);
  $stratname  =~ s/\.toml$//i;
  open(my $fh, '<:encoding(UTF-8)', $_[0]) or die "cannot open file $_[0]";
  {
  local $/;
  $toml = <$fh>;
  }
 # print $toml;
  close($fh);
  my ($data, $err) = from_toml($toml);
  unless ($data) {
    die "Error parsing toml $stratname: $err";
  }
 # print $data;
  my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
  $json = $coder->encode ($data);
  $stratname =~ /-/ ? $json =~ s/^{/config['$stratname'] = {\n/ : $json =~ s/^{/config.$stratname = {\n/;
  return $json;
}
sub convert_json_toml {
  my $toml;
  if (defined $_[0]) {
  my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
  my $json = $coder->decode ($_[0]);
  $toml = to_toml($json);
  }
  else {
    $toml = 'N/A';
  }
  return $toml;
}
sub dbcon {
  if ($database eq 'sqlite') {
    $dbh = DBI->connect("dbi:SQLite:dbname=$_[1]"."_0.1.db", "", "",) or die $DBI::errstr;
  }
  elsif ($database eq 'postgresql') {
    $dbh = DBI->connect("dbi:pg:$dbname;host=$dbhost;port=$dbport;, $dbuser, $dbpassword");
  }
  elsif ($_[0] eq 'csv'){
  }
  else {
    print 'Your Mongo DB is not supported\n';
  }
  return $dbh;
}
# generate tables
sub analyze {
  if ($print_all_results eq 'yes') {
    print "\n\n[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] Creating ALL RESULTS table (sorted profit/day)...\n" if $stfu eq 'no';
    $dbh = DBI->connect ("dbi:CSV:", "", "", {RaiseError => 1, PrintError => 1, csv_eol => "\n"});
    my $query = "SELECT currency, asset, strategy, profit___, profit_market, profit_day___, trades_day, best_win, worst_loss, avg_HODL_min_, avg_price, overall_trades_day, volume_day FROM $_[0]";
    my $stc   = $dbh->prepare ($query);
    $stc->execute();
    my @all_results;
    while (my @row = $stc->fetchrow_array) {
      if ($row[3] >= $all_results_min_profit && $row[4] >= $all_results_min_profit_market && $row[5] >=  $all_results_min_profit_day && $row[6] >= $all_results_min_trades_day && $row[6] <= $all_results_max_trades_day && $row[9] >= $all_results_min_hodl_time && $row[9] <=$all_results_max_hodl_time) {
        push @all_results, [@row];
      }
    }
    my $table = Text::Table->new(  { align_title => 'left', align => 'left', title => "Curr.\n----" }, { align_title => 'left', align => 'left', title => "Asset\n-----"}, { align_title => 'left', align => 'left', title => "Strat\n-----"}, { align_title => 'right', align => 'right', title => "Profit\n------"}, { align_title => 'right', align => 'right', title => "Profit-market\n-------------"}, { align_title => 'right', align => 'right', title => "Profit/day\n------------" },  { align_title => 'right', align => 'right', title => "Trades/day\n----------"}, { align_title => 'right', align => 'right', title => "Best win\n--------"}, { align_title => 'right', align => 'right', title => "Worst loss\n----------"}, { align_title => 'right', align => 'right', title => "Avg.Hodl\n--------"}, { align_title => 'right', align => 'right', title => "Avg.price\n---------"}, { align_title => 'right', align => 'right', title => "Ov.trades/day\n-------------"}, { align_title => 'right', align => 'right', title => "Volume/day\n---------"} );
    my @sorted_all_results = sort {$b->[5] <=> $a->[5]} @all_results;
    for my $i (0 .. $all_results_limit - 1) {
      $table->load($sorted_all_results[$i])
    };
    my $table_name = ' A L L     R E S U L T S ';
    my $rule_len = (($table->width - length $table_name) / 2);
    print "\n".'=' x $rule_len.$table_name.'=' x ($rule_len + 1)."\n";
    print $table;
    print $table->rule('=', '=');
    print "\n";
  }
  if ($print_top_strategy eq 'yes') {
    print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] Creating TOP STRATEGY table...\n" if $stfu eq 'no';
    my $stratdata;
    my %top_strategies;
    my $query = "SELECT DISTINCT strategy, strategy_settings FROM $_[0]";
    my $stc   = $dbh->prepare ($query);
    $stc->execute();
    while (my @row = $stc->fetchrow_array) {
      $stratdata = "$row[0];$row[1]";
      $top_strategies{"$stratdata"}{nprofit} = 0;
      $top_strategies{"$stratdata"}{best} = 0;
      $query = "SELECT AVG(avg_HODL_min_), AVG(profit___), MAX(profit___), MIN(profit___), AVG(trades_day), AVG(wins___), SUM(profit___), MAX(best_win), AVG(median_wins), MIN(worst_loss), AVG(median_losses) FROM $_[0] WHERE strategy='$row[0]' AND strategy_settings='$row[1]' AND trades_day > 0";
      my $stc   = $dbh->prepare ($query);
      $stc->execute();
      while (my @row2 = $stc->fetchrow_array) {
        $top_strategies{"$stratdata"}{hodl_time} = sprintf("%d", $row2[0]);
        $top_strategies{"$stratdata"}{avg_profit} = sprintf("%.2f", $row2[1]);
        $top_strategies{"$stratdata"}{worst_PL} = sprintf("%.1f", $row2[3]);
        $top_strategies{"$stratdata"}{best_PL} = sprintf("%.1f", $row2[2]);
        $top_strategies{"$stratdata"}{trades_day} = sprintf("%.1f", $row2[4]);
        $top_strategies{"$stratdata"}{trades_win} = sprintf("%.1f", $row2[5]);
        $top_strategies{"$stratdata"}{profits_sum} = sprintf("%d", $row2[6]);
        $top_strategies{"$stratdata"}{best_win_trade} = sprintf("%.2f", $row2[7]);
        $top_strategies{"$stratdata"}{avg_win_trade} = sprintf("%.2f", $row2[8]);
        $top_strategies{"$stratdata"}{worst_loss_trade} = sprintf("%.2f", $row2[9]);
        $top_strategies{"$stratdata"}{avg_loss_trade} = sprintf("%.2f", $row2[10]);
        #}
      }
      $query = "SELECT profit___, profit_market  FROM $_[0] WHERE strategy='$row[0]' AND strategy_settings='$row[1]'";
      my $stc   = $dbh->prepare ($query);
      $stc->execute();
      my $counter = 1;
      while (my @row2 = $stc->fetchrow_array) {
        $counter++;
        if ($row2[0] > 0) {
          ++$top_strategies{"$stratdata"}{profitable};
        }
        if ($row2[1] > 0) {
          ++$top_strategies{"$stratdata"}{profit_above_market};
        }
      }
      $top_strategies{"$stratdata"}{profitable} = sprintf("%d", ($top_strategies{"$stratdata"}->{profitable} * 100 / $counter));
      $top_strategies{"$stratdata"}{profit_above_market} = sprintf("%d", ($top_strategies{"$stratdata"}->{profit_above_market} * 100 / $counter));
    }
    $query = qq(SELECT DISTINCT currency, asset, dataset_from, to FROM $_[0]);
    my $stc   = $dbh->prepare ($query);
    $stc->execute();
    while (my @row = $stc->fetchrow_array) {
      $query = "SELECT strategy, profit_day___, strategy_settings FROM $_[0] WHERE currency='$row[0]' AND asset='$row[1]' AND dataset_from='$row[2]' AND to='$row[3]' ORDER by profit_day___ desc limit 1";
      my $stc   = $dbh->prepare ($query);
      $stc->execute();
      while (my @row = $stc->fetchrow_array) {
        $stratdata = "$row[0];$row[2]";
        ++$top_strategies{"$stratdata"}{best};
      }
    }
    my $table = Text::Table->new( "Strat\n\n-----",  { align_title => 'center', align => 'right', title => "Best\n\n----"}, { align_title => 'right', align => 'right', title => "%     \nprofitable\n----------"}, { align_title => 'right', align => 'right', title => "% profit > \nmarket   \n----------"}, { align_title => 'right', align => 'right', title => "Best \n% P/L\n-----"}, { align_title => 'right', align => 'right', title => "Worst\n% P/L\n-----"}, { align_title => 'right', align => 'right', title => "Sum %\nprofit\n-----"}, { align_title => 'right', align => 'right', title => "Avg %\nprofit\n------"}, { align_title => 'right', align => 'right', title => "% Avg win\n trades \n---------"}, { align_title => 'right', align => 'right', title => "Best \ntrade\n-----"}, { align_title => 'right', align => 'right', title => "Avg trade\nprofit \n---------"}, { align_title => 'right', align => 'right', title => "Worst\ntrade\n-----"}, { align_title => 'right', align => 'right', title => "Avg trade\nloss   \n---------"}, { align_title => 'right', align => 'right', title => "Avg   \ntrades/day\n----------"}, { align_title => 'right', align => 'right', title => "Avg   \nHODL min\n---------"});
    my $count = 1;
    for my $keys (sort {$top_strategies{$b}{$top_strategy_sort1}<=>$top_strategies{$a}{$top_strategy_sort1} or $top_strategies{$b}{$top_strategy_sort2}<=>$top_strategies{$a}{$top_strategy_sort2}} keys %top_strategies) {
      my @strathuman = split /;/, $keys;
      $table->add($strathuman[0], $top_strategies{$keys}->{best}, $top_strategies{$keys}->{profitable}, $top_strategies{$keys}->{profit_above_market}, $top_strategies{$keys}->{best_PL}, $top_strategies{$keys}->{worst_PL}, $top_strategies{$keys}->{profits_sum}, $top_strategies{$keys}->{avg_profit}, $top_strategies{$keys}->{trades_win}, $top_strategies{"$keys"}->{best_win_trade}, $top_strategies{"$keys"}->{avg_win_trade}, $top_strategies{"$keys"}->{worst_loss_trade}, $top_strategies{"$keys"}->{avg_loss_trade}, $top_strategies{$keys}->{trades_day}, $top_strategies{$keys}->{hodl_time});
      last if $count++ >= $top_strategy_limit;
    }
    # top strat
    my $table_name = ' T O P    S T R A T E G Y ';
    my $rule_len = (($table->width - length $table_name) / 2);
    print "\n".'=' x $rule_len.$table_name.'=' x ($rule_len + 1)."\n";
    print $table;
    print $table->rule('=', '=');
    print "\n";
  }
  my $dataset_limit = 5;
  if ($print_top_dataset eq 'yes') {
    #TOP D
    print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] Creating TOP DATASET table...\n" if $stfu eq 'no';
    my %top_dataset;
    my $pairdata;
    my $query = "SELECT DISTINCT currency, asset, dataset_from, to FROM $_[0]";
    my $stc   = $dbh->prepare ($query);
    $stc->execute();
    while (my @row = $stc->fetchrow_array) {
      $pairdata = "$row[0]:$row[1];$row[2]$row[3]";
      $top_dataset{$pairdata}{nprofit} = 0;
      $top_dataset{$pairdata}{best} = 0;
      $query = "SELECT AVG(avg_HODL_min_), AVG(profit___), MAX(profit___), MIN(profit___), AVG(trades_day), AVG(wins___), SUM(profit___) FROM $_[0] WHERE currency='$row[0]' AND asset='$row[1]' AND dataset_from='$row[2]' AND to='$row[3]' ";
      my $stc   = $dbh->prepare ($query);
      $stc->execute();
      while (my @row2 = $stc->fetchrow_array) {
          $top_dataset{$pairdata}{hodl_time} = sprintf("%d", $row2[0]);
          $top_dataset{$pairdata}{avg_profit} = sprintf("%.1f", $row2[1]);
          $top_dataset{$pairdata}{worst_PL} = sprintf("%.1f", $row2[3]);
          $top_dataset{$pairdata}{best_PL} = sprintf("%.1f", $row2[2]);
          $top_dataset{$pairdata}{trades_day} = sprintf("%.1f", $row2[4]);
          $top_dataset{$pairdata}{trades_win} = sprintf("%.1f", $row2[5]);
          $top_dataset{$pairdata}{profits_sum} = sprintf("%d", $row2[6]);
      }
      $query = "SELECT profit___, profit_market, volatility, cur_CMC_rank, cur_marketcap, cur_CMC_volume, days, market_change___ FROM $_[0] WHERE currency='$row[0]' AND asset='$row[1]' AND dataset_from='$row[2]' AND to='$row[3]' ";
      $stc   = $dbh->prepare ($query);
      $stc->execute();
      my $counter = 0;
      $top_dataset{$pairdata}{profitable} = 0;
      $top_dataset{$pairdata}{profit_above_market} = 0;
      while (my @row2 = $stc->fetchrow_array) {
        ++$counter;
        if ($row2[0] > 0) {
          ++$top_dataset{$pairdata}{profitable};
        }
        if ($row2[1] > 0) {
          ++$top_dataset{$pairdata}{profit_above_market};
        }
        $top_dataset{$pairdata}{price_volatility} = $row2[2];
        $top_dataset{$pairdata}{cmc_rank} = $row2[3];
        $top_dataset{$pairdata}{cmc_marketcap} = $row2[4];
        $top_dataset{$pairdata}{cmc_volume} = $row2[5];
        $top_dataset{$pairdata}{days} = $row2[6];
        $top_dataset{$pairdata}{market_change} = $row2[7];
      }
      if ($counter > 0) {
        $top_dataset{$pairdata}{profitable} = sprintf("%d", ($top_dataset{$pairdata}->{profitable} * 100 / $counter));
        $top_dataset{$pairdata}{profit_above_market} = sprintf("%d", ($top_dataset{$pairdata}->{profit_above_market} * 100 / $counter));
      }
    }
    $query = qq(SELECT DISTINCT strategy, strategy_settings FROM $_[0]);
    my $stc   = $dbh->prepare ($query);
    $stc->execute();
    while (my @row = $stc->fetchrow_array) {
      $query = "SELECT currency, asset, profit_day___, dataset_from, to FROM $_[0] WHERE strategy='$row[0]' AND strategy_settings='$row[1]' ORDER by profit_day___ desc limit 1";
      my $stc   = $dbh->prepare ($query);
      $stc->execute();
      while (my @row = $stc->fetchrow_array) {
        $pairdata = "$row[0]:$row[1];$row[3]$row[4]";
        ++$top_dataset{$pairdata}{best};
      }
    }
    my $aligntable = "{ align_title => 'right', align => 'right', title => ";
    my $table = Text::Table->new( "Pair\n\n-----", { align_title => 'right', align => 'right', title => "Best\n\n----"}, { align_title => 'right', align => 'right', title => "%     \nprofitable\n----------"}, { align_title => 'right', align => 'right', title => "% profit > \nmarket  \n----------"}, { align_title => 'right', align => 'right', title => "% Market\nchange \n--------"}, { align_title => 'right', align => 'right', title => "Best \n% P/L\n-----"}, { align_title => 'right', align => 'right', title => "Worst \n% P/L\n-----"}, { align_title => 'right', align => 'right', title => "Sum %\nprofit\n-----"}, { align_title => 'right', align => 'right', title => "Avg %\nprofit\n------"}, { align_title => 'right', align => 'right', title => "% Avg win\ntrades \n---------"}, { align_title => 'right', align => 'right', title => "Avg   \ntrades/day\n----------"}, { align_title => 'right', align => 'right', title => "Avg  \nHODL min\n---------"}, { align_title => 'right', align => 'right', title => "Price  \nvolatility\n----------"}, { align_title => 'right', align => 'right', title => " CMC \nRank\n----"}, { align_title => 'right', align => 'right', title => " Current \nmarketcap\n---------"}, { align_title => 'right', align => 'right', title => "Current  \nCMC volume\n----------"}, { align_title => 'right', align => 'right', title => "Days\n\n----"});
    $table->rule( sub { my ($index, $len) = @_; }, sub { my ($index, $len) = @_; },);
    my $count = 1;
    for my $keys (sort {$top_dataset{$b}{$top_dataset_sort1}<=>$top_dataset{$a}{$top_dataset_sort1} or $top_dataset{$b}{$top_dataset_sort2}<=>$top_dataset{$a}{$top_dataset_sort2}} keys %top_dataset) {
      my @pairhuman = split /;/, $keys;
      $table->add($pairhuman[0], $top_dataset{$keys}->{best}, $top_dataset{$keys}->{profitable}, $top_dataset{$keys}->{profit_above_market}, $top_dataset{$keys}->{market_change}, $top_dataset{$keys}->{best_PL}, $top_dataset{$keys}->{worst_PL}, $top_dataset{$keys}->{profits_sum}, $top_dataset{$keys}->{avg_profit}, $top_dataset{$keys}->{trades_win}, $top_dataset{$keys}->{trades_day}, $top_dataset{$keys}->{hodl_time}, $top_dataset{$keys}->{price_volatility}, $top_dataset{$keys}->{cmc_rank}, $top_dataset{$keys}->{cmc_marketcap}, $top_dataset{$keys}->{cmc_volume}, $top_dataset{$keys}->{days});
      last if $count++ >= $top_dataset_limit;
    }
    # Top dataset table
    my $table_name = ' T O P    D A T A S E T ';
    my $rule_len = (($table->width - length $table_name) / 2);
    print "\n".'=' x $rule_len.$table_name.'=' x ($rule_len + 1)."\n";
    print $table;
    print $table->rule('=', '=');
    print "\n";
  }
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
if ($oconfigfile) {
  $configfile = $oconfigfile;
}
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
if ($default_set) {
  foreach (@pairs) {
    if ($_ !~ /:/) {
      $_ =~ s/^/$default_set:/g;
    }
  }
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
if ($oinfo) {
  my $dbh = DBI->connect("dbi:SQLite:dbname=history/binance_0.1.db", "", "",{ RaiseError => 0 },);
  my $stmt = qq(SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%candles%';);
  my $sth = $dbh->prepare( $stmt );
  my $rv = $sth->execute();
  my @row;
  while (@row = $sth->fetchrow_array()) {
    $stmt = qq(SELECT datetime(start, 'unixepoch') FROM `main`.@row order by start ASC LIMIT 1;);
    my $sth = $dbh->prepare( $stmt );
    my $rv = $sth->execute();
    my @row2;
    while (@row2 = $sth->fetchrow_array()) {
      print "@row\nstart: @row2\n";
    }
    $stmt = qq(SELECT datetime(start, 'unixepoch') FROM `main`.@row order by start DESC LIMIT 1;);
    my $sth = $dbh->prepare( $stmt );
    my $rv = $sth->execute();
    my @row2;
    while (@row2 = $sth->fetchrow_array()) {
      print "end: @row2\n";
    }
    $stmt = qq(select count(*) FROM @row;);
    my $sth = $dbh->prepare( $stmt );
    my $rv = $sth->execute();
    while (@row2 = $sth->fetchrow_array()) {
      print "candles: @row2\n";
    }
  }
}
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
        my $json = JSON::XS->new;
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
      if ($operiod) {
        $to = strftime "%Y-%m-%d %H:%M:%S", gmtime;
        $from = strftime "%Y-%m-%d %H:%M:%S", gmtime($to - $operiod*86400);
      }
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
      open my $fh, '>:encoding(UTF-8)', $configfile or die "Cannot open $configfile!";
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
        open my $fh2, '>>:encoding(UTF-8)', $logfile or die "Cannot open $logfile!";
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
        open my $fh8, '>:encoding(UTF-8)', $configfile or die "Cannot open $configfile!";
        print $fh8 join ("\n",$gconfig);
        close $fh8;
        system("node gekko -c $configfile >> $logfile &");
      }
    }
  }
  my $endapp = time;
  my $elapsedapp = $endapp - $startapp;
  $elapsedapp = elapsed( $elapsedapp );
  print "All jobs are done. Elapsed time: $elapsedapp\n";
}
if ($ohelp) {
  print qq{usage: perl backtest.pl
To run backtests machine
usage: perl backtest.pl [mode] [optional parameter]
To run other features
Mode:
  -i, --import\t - Import new datasets
  -g, --paper\t - Start multiple sessions of PaperTrader
  -v, --convert TOMLFILE - Convert TOML file to Gekko's CLI config format, ex: backtest.pl -v MACD.toml
  -a, --analyze CSVFILE\t - Perform comparision of strategies and pairs from csv file, ex: backtest.pl -a database.csv
Optional parameters:
  -c, --config\t\t - BacktestTool config file. Default is backtest-config.pl
  -s, --strat STRAT_NAME - Define strategies for backtests. You can add multiple strategies seperated by commas example: backtest.pl --strat=MACD,CCI
  -p, --pair PAIR\t - Define pairs to backtest in exchange:currency:asset format ex: backtest.pl --p bitfinex:USD:AVT. You can add multiple pairs seperated by commas.
  -p exchange:ALL\t - Perform action on all available pairs. Other usage: exchange:USD:ALL to perform action for all USD pairs.
  -n, --candle CANDLE\t - Define candleSize and warmup period for backtest in candleSize:warmup format, ex: backtest.pl -n 5:144,10:73. You can add multiple values seperated by commas.
  -ft, --period DAYS - Time range in days - perform action on period from last x days ex: backtest.pl -ft 7
  -f, --from\t\t- Time range for backtest datasets or import. Example: backtest.pl --from="2018-01-01 09:10" --to="2018-01-05 12:23"
  -t, --to
  -f last\t\t- Start import from last candle available in DB. If pair not exist in DB then start from 24h ago.
  -t now\t\t- 'now' is current time in GMT.
  -o, --output FILENAME - CSV file name.
};
}
if ($oconvert) {
  &convert($oconvert);
  print "Input: $oconvert\nOutput:\n";
  print $json;
}
if ($oanalyze) {
  &analyze($oanalyze);
  print "\n";
}
else {
  my $row = 0;
  my $pm = Parallel::ForkManager->new($threads);
  my (%paircalc, %lookup, $req, $pairname);
     my (%cmcvolume, %cmcrank, %cmcmarketcap);
  my $tmpcsv = lc (File::Temp->new(TEMPLATE => "tmp_dataXXXXX",SUFFIX => ".csv",DIR => $tmpfile));
  #my $tmpcsv = File::Temp->new(TEMPLATE => "tmp_dataXXXXX",SUFFIX => ".csv",DIR => $tmpfile);
  $pm->run_on_finish(sub {
    my $data = pop @_;
    %paircalc = (%paircalc, %$data);
  });
  if ($ocsv) {
    $csv = $ocsv
  }
  my $vars = {
    'currency' => 'currency',
    'asset' => 'asset',
    'exchange' => 'exchange',
    'strategy' => 'strategy',
    'profit' => 'profit[%]',
    'profit_day' => 'profit/day[%]',
    'profit_year' => 'profit/year[%]',
    'sharpe_ratio' => 'sharpe ratio',
    'market_change' => 'market change[%]',
    'profit_market' => 'profit-market',
    'trades' => 'trades',
    'trades_day' => 'trades/day',
    'winning_trades' => 'winning trades',
    'lost_trades' => 'lost trades',
    'percentage_wins' => 'wins[%]',
    'best_win' => 'best win',
    'median_wins' => 'median wins',
    'worst_loss' => 'worst loss',
    'median_losses' => 'median losses',
    'avg_exposed_duration' => 'avg HODL[min]',
    'candle_size' => 'candleSize',
    'warmup_period' => 'historySize',
    'dataset_days' => 'days',
    'backtest_start' => 'start',
    'dataset_from' => 'dataset from',
    'dataset_to' => 'to',
    'CMC_Rank' => 'cur CMC rank',
    'current_marketcap' => 'cur marketcap',
    'open_price' => 'open price',
    'close_price' => 'close',
    'lowest_price' => 'low',
    'highest_price' => 'high',
    'avg_price' => 'avg price',
    'price_volality' => 'volatility',
    'volume' => 'volume',
    'volume_day' => 'volume/day',
    'volume_CMC' => 'cur CMC volume',
    'overall_trades' => 'overall trades',
    'overall_trades_day' => 'overall trades/day',
    'strategy_settings' => 'strategy settings',
    'note' => 'note'
  };
  if ( ! -e $csv) {
    sub columns {
      my $out;
      $tocsv = Template->new({ });
      $tocsv->process($_[0], $vars, \$out);
      open my $fh3, '>>:encoding(UTF-8)', $csv or die "Cannot open $csv!";
      print $fh3 join ("\n","$out\n");
      close $fh3;
    }
    &columns($csv_columns);
  }
  my ($tocsvtmp, $varstmp, $csvouttmp);
  my $csv_columns_tmp = \ "[% currency %],[% asset %],[% exchange %],[% strategy %],[% profit %],[% profit_day %],[% profit_market %],[% trades_day %],[% percentage_wins %],[% best_win %],[% worst_loss %],[% avg_exposed_duration %],[% avg_price %],[% price_volality %],[% volume_day %],[% overall_trades_day %],[% strategy_settings %],[% dataset_from %],[% dataset_to %],[% price_volality %],[% CMC_Rank %],[% current_marketcap %],[% volume_CMC %],[% dataset_days %],[% market_change %],[% best_win %],[% median_wins %],[% worst_loss %],[% median_losses %]";
  my $outtmp;
  $tocsvtmp = Template->new({ });
  $tocsvtmp->process($csv_columns_tmp, $vars, \$outtmp);
  open my $fh11, '>:encoding(UTF-8)', $tmpcsv or die "Cannot open $tmpcsv!";
  print $fh11 join ("\n","$outtmp\n");
  close $fh11;
  if ($cmc_data eq 'yes') {
    print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] Collect data from coinmarketcap.com\n" if $stfu eq 'no';
    $req = LWP::UserAgent->new;
    $req->agent("Gekko BacktestTool");
    $req->timeout(10);
    my $response = $req->get("https://api.coinmarketcap.com/v1/ticker/?limit=800");
    if ($response->is_success) {
      if ($response) {
        $response = decode_json($response->content);
      }
      else {
        $response = '   ';
      }
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
  if ($owarmup) {
    @warmup = ();
    $owarmup =~ s/ //g;
    @warmup = split /,/, $owarmup;
  }
  if (grep /ALL/, @pairs || grep /ALL/, @strategies) {
  print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] Parameter ALL detected. Prepare data\n" if $stfu eq 'no';
  }
  if (grep /^ALL$/, @pairs) {
    my @exchanges_list = <history/*_0.1.db>;
    @pairs = ();
    foreach (@exchanges_list) {
      print "Exchange list: $_\n";
      $_ = basename($_);
      $_ =~ s/_0.1.db$/:ALL/g;
      push @pairs, $_;
    }
  }
  @pairs = grep ! /(?<!:)(ALL)/, @pairs;
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
    }
  }
  @pairs = grep !/ALL/, @pairs;
  if (grep /ALL/, @strategies) {
    my @strategies_list = <strategies/*.js>;
    foreach (@strategies_list) {
      $_ = basename($_);
      $_ =~ s/.js$//g;
      push @strategies, $_;
    }
  }
  @strategies = grep ! /ALL/, @strategies;
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
  my %stratconfig;
  my %stratconfigtemp;
  my $strat;
  my $bftriger;
  # Strat conf manipulation
  if ($use_toml_files eq 'yes') {
    foreach $strat (@strategies) {
      my @file_list = <config/strategies/$strat.*>;
      my $substitute;
      if (@file_list) {
        open(my $fh, '<:encoding(UTF-8)', $file_list[0]) or die "cannot open file $_[0]";
        {
          local $/;
          $substitute = <$fh>;
        }
        close($fh);
        if ($substitute =~ /(?:(?:[\d-\.]+[, ]+)+[\d-\.]+)|([-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*)/) {
          $bftriger = 1 if (scalar @pairs >= $threads);
          print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] Generate params combinations for: $strat\n" if $stfu eq 'no';
          if ($substitute =~ /(?<!")\b(?:(?:[\d-\.]+[, ]+)+[\d-\.]+)\b(?!")/) {
            unlink $file_list[0];
            $substitute =~ s/"*(((?!\")[\d-\.]+[, ]+)+[\d-\.]+)"*/"\1"/g;
            open (my $fh, '>>:encoding(UTF-8)', $file_list[0]);
            print $fh $substitute;
            close $fh;
          }
          if ($substitute =~ /(?<!")\b([-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*)/) {
            unlink $file_list[0];
            $substitute =~ s/"*([-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*)"*/"\1"/g;
            open (my $fh, '>>:encoding(UTF-8)', $file_list[0]);
            print $fh $substitute;
            close $fh;
          }
        }
        $stratconfig{$strat} = &convert($file_list[0]);
      }
      else {
        $stratconfig{$strat} = '';
      }
      if ($stratconfig{$strat} =~ /[-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*/ && $stratconfig{$strat} =~ /(?:(?:[\d-\.]+[, ]+)+[\d-\.]+)/) {
        my @match1 = $stratconfig{$strat} =~ /[-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*/g;
        my @match2 = $stratconfig{$strat} =~ /(?:(?:[\d-\.]+[, ]+)+[\d-\.]+)/sg;
        my (@aoa2, @tuples1, $b1);
        foreach (@match2) {
          $_ =~ s/ //g;
          my @bfval = split /\,/, $_;
          push @aoa2, [@bfval];
        }
        if (scalar @aoa2 > 1) {
          my $unlabeled = Set::CrossProduct->new( \@aoa2 );
          @tuples1 = $unlabeled->combinations;
          $b1 = scalar (@{@tuples1[0]});
        }
        else {
          @tuples1 = @aoa2;
          $b1 = scalar (@tuples1);
        }
        my (@arraytmp, @stratconfcalues, @matchcyfra, @stratconfcomb, $stratconffin);
        foreach (@match1) {
          @arraytmp = ();
          @matchcyfra = split /\.\.|:/, $_;
          if ($matchcyfra[0] > $matchcyfra[1]) {
            ($matchcyfra[0], $matchcyfra[1]) = ($matchcyfra[1], $matchcyfra[0]);
          }
          if (($matchcyfra[1] - $matchcyfra[0]) < $matchcyfra[2]) {
            print "Too few possibilities from the expression: $matchcyfra[0]..$matchcyfra[1]:$matchcyfra[2]. Try extend range by first (range start) and/or second (range end) value and/or reduce step - third value. \n\nEg: expression 0..10:2 generate 0, 2, 4, 6, 8, 10 values for strat parameter.\n";
              exit
          }
          for (my $i = $matchcyfra[0]; $i <= $matchcyfra[1]; $i += $matchcyfra[2]) {
            push @arraytmp, $i;
            }
          push @stratconfcalues, [@arraytmp];
        }
        my (@tuples2, $b2);
        if (scalar @stratconfcalues > 1) {
          my $unlabeled = Set::CrossProduct->new( \@stratconfcalues );
          @tuples2 = $unlabeled->combinations;
          $b2 = scalar (@{@tuples2[0]});
        }
        else {
          @tuples2 = @stratconfcalues;
          $b2 = scalar (@tuples2);
        }
        foreach my $taba2 (@tuples2) {
          my $s = $stratconfig{$strat};
          if ($b2 > 1) {
            for (my $i = 0; $i <= ($b2 - 1); $i++) {
              $stratconffin = $taba2->[$i];
              $s =~ s/[-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*/$stratconffin/;
            }
            my $ddd = $strat.' '.join('|', map {"$_"} @{$taba2});
            $stratconfigtemp{$ddd} = $s;
          }
          else {
            foreach (@{$taba2}) {
              $s = $stratconfig{$strat};
              $s =~ s/\"[-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*\"/$_/;
              my $ddd = $strat.' '."$_";
              $stratconfigtemp{$ddd} = $s;
            }
          }
        }
        foreach my $s77 (keys %stratconfigtemp) {
          my $d;
          foreach my $taba1 (@tuples1) {
            if (scalar @{$tuples1[0]} > 1) {
            $d = $stratconfigtemp{$s77};
            foreach (@{$taba1}) {
              $d =~ s/\"([-\d-\.]+[, ]+)+[-\d-\.]+\"/$_/s;
            }
            my $ccc = $b1 > 1 ? "|".join('|', map {"$_"} @{$taba1}) : '|'."$_";
            $stratconfigtemp{$s77.$ccc} = $d;
          }
          else {
            foreach (@{$taba1}) {
              $d = $stratconfigtemp{$s77};
              $d =~ s/\"([-\d-\.]+[, ]+)+[-\d-\.]+\"/$_/s;
              my $ccc = $b1 > 1 ? "|".join('|', map {"$_"} @{$taba1}) : '|'."$_";
              $stratconfigtemp{$s77.$ccc} = $d;
              }
          }
        }
        delete $stratconfigtemp{$s77};
      }
      delete $stratconfig{$strat};
    }
      if ($stratconfig{$strat} =~ /[-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*/) {
        my @match = $stratconfig{$strat} =~ /[-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*/g;
        my (@arraytmp, @stratconfcalues, @matchcyfra, @stratconfcomb, $stratconffin, @tuples);
        foreach (@match) {
          @arraytmp = ();
          @matchcyfra = split /\.\.|:/, $_;
          if ($matchcyfra[0] > $matchcyfra[1]) {
            ($matchcyfra[0], $matchcyfra[1]) = ($matchcyfra[1], $matchcyfra[0]);
          }
          if (($matchcyfra[1] - $matchcyfra[0]) < $matchcyfra[2]) {
            print "Too few possibilities from the expression: $matchcyfra[0]..$matchcyfra[1]:$matchcyfra[2]. Try extend range by first (range start) and/or second (range end) value and/or reduce step - third value. \n\nEg: expression 0..10:2 generate 0, 2, 4, 6, 8, 10 values for strat parameter.\n";
            exit
          }
          for (my $i = $matchcyfra[0]; $i <= $matchcyfra[1]; $i += $matchcyfra[2]) {
            push @arraytmp, $i;
          }
          push @stratconfcalues, [@arraytmp];
        }
        if (scalar @stratconfcalues > 1) {
          my $unlabeled = Set::CrossProduct->new( \@stratconfcalues );
          @tuples = $unlabeled->combinations;
          $b = scalar (@{@tuples[0]});
        }
        else {
          @tuples = @stratconfcalues;
          $b = scalar (@tuples);
        }
        my $tmp;
        foreach (@tuples) {
          $tmp+=scalar @{$_};
        }
        foreach my $taba (@tuples) {
          my $s = $stratconfig{$strat};
          if ($b > 1) {
            for (my $i = 0; $i <= ($b - 1); $i++) {
              $stratconffin = $taba->[$i];
              $s =~ s/[-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*/$stratconffin/;
            }
            my $ddd = $strat.' '.join('|', map {"$_"} @{$taba});
            $stratconfigtemp{$ddd} = $s;
          }
          else {
            foreach (@{$taba}) {
              $s = $stratconfig{$strat};
              $s =~ s/\"[-\d+\.]*\.\.[-\d+\.]*:[-\d+\.]*\"/$_/;
              my $ddd = $strat.' '."$_";
              $stratconfigtemp{$ddd} = $s;
            }
          }
        }
        delete $stratconfig{$strat};
      }
      if ($stratconfig{$strat} =~ /(?:(?:[\d-\.]+[, ]+)+[\d-\.]+)/) {
        my @match = $stratconfig{$strat} =~ /(?:(?:[\d-\.]+[, ]+)+[\d-\.]+)/sg;
        my (@aoa, $b);
        foreach (@match) {
          $_ =~ s/ //g;
          my @dupa = split /,/, $_;
          push @aoa, [@dupa];
        }
        my @tuples;
        if (scalar @aoa > 1) {
          my $unlabeled = Set::CrossProduct->new( \@aoa );
          @tuples = $unlabeled->combinations;
          $b = scalar (@{@tuples[0]});
        }
        else {
          @tuples = @aoa;
          $b = scalar (@tuples);
        }
        my $d;
        if (scalar @aoa > 1) {
          foreach my $taba (@tuples) {
            $d = $stratconfig{$strat};
            foreach (@{$taba}) {
              $d =~ s/\"([-\d-\.]+[, ]+)+[-\d-\.]+\"/$_/s;
            }
            my $ddd = $b > 1 ? $strat.' '.join('|', map {"$_"} @{$taba}) : $strat.' '."$_";
            $stratconfigtemp{$ddd} = $d;
          }
        }
        else {
          foreach my $taba (@tuples) {
            foreach (@{$taba}) {
              $d = $stratconfig{$strat};
              $d =~ s/\"([-\d-\.]+[, ]+)+[-\d-\.]+\"/$_/s;
              my $ddd = $b > 1 ? $strat.' '.join('|', map {"$_"} @{$taba}) : $strat.' '."$_";
              $stratconfigtemp{$ddd} = $d;
            }
          }
        }
        delete $stratconfig{$strat};
        delete $stratconfigtemp{$strat};
      }
      if ($stratconfig{$strat} =~ /#E#/) {
         open(my $fh, '<:encoding(UTF-8)', $file_list[0]) or die "cannot open file $_[0]";
        {
          local $/;
          $substitute = <$fh>;
        }
        close($fh);
        my @configs = split /#E#/, $stratconfig{$strat};
        print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] ".scalar @configs." configuration found for strategy $strat\n";
        for my $i (1 .. $#configs) {
          $stratconfig{"$strat $i"} = $configs[$i];
        }
        delete $stratconfig{$strat};
      }
      %stratconfig = (%stratconfig, %stratconfigtemp);
    }
  }
  my $startapp = time;
  $backtest_start = strftime "%Y-%m-%d %H:%M:%S", localtime;
  my $remain = scalar @pairs * scalar (keys %stratconfig) * scalar @warmup;
  my $palist = join(' ', map {"$_"} @pairs);
  my $stlist = join(' ', map {"$_"} @strategies);
  my $walist = join(' ', map {"$_"} @warmup);
  if (length $palist > 132) {
    $palist =~ s/.{133} \K/\n/g;
  }
    if (length $stlist > 132) {
    $stlist =~ s/.{133} \K/\n/g;
  }
    if (length $walist > 132) {
    $walist =~ s/.{133} \K/\n/g;
  }
  my (%coun, $step);
  if ($remain) {
    $step = 100 / ($remain / $summary_interval);
  }
  else {
    print "You dont add strategy, pairs or warmups to configuration file.\n";
    exit
  }
  if ($step < 85) {
    for (my $i = $step; $i < 100; $i += $step) {
      $coun{$i} = sprintf("%d", ($remain * ($i / 100)));
    }
  }
  #print Dumper \%coun;
  if ($use_toml_files eq 'yes') {
    print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] Use TOML files for strategies configuration\n" if $stfu eq 'no';
  }
  if ($remain > 1000 && $print_analysis_on_summary eq 'yes') {
    print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] WARNING: Printing a table during so many backtests may degrade performance. It is recommended to disable \n".'$print_analysis_on_summary '." for the duration of such a large test.\n";
  }
  print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] Save output to csvfile: $csv\n" if $stfu eq 'no';
  print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] Starting Backtest Machine ($threads threads)...
============================================================== I N P U T    D A T A ===============================================================
Pairs
-----
$palist
Total: ".scalar @pairs."
===================================================================================================================================================
Strategies
----------
$stlist
Total: ".scalar (@strategies)."\n";
if (scalar (keys %stratconfig) > scalar (@strategies)) {
print " (".scalar (keys %stratconfig)." different settings)";
}
print "
===================================================================================================================================================
Candles
-------
$walist
Total: ".scalar @warmup."
===================================================================================================================================================
[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] $remain backtests remain
============================================================= L A S T    R E S U L T S ============================================================\n" if $stfu eq 'no';
  my ($outformat, $columns, $columns_title, $columns_end);
  if (scalar @warmup > 1) {
    $outformat = "%-9s %+40s %+12s %+15s %+11s %+11s %+9s %+11s %+7s %+5s %+6s";
    printf $outformat, "Pair","Strategy","Profit","Profit-market","Trades/day","Win trades","Best win","Worst loss", "Candle","Days","Time";
    $columns_end = "\n----                                      --------       ------   -------------  ----------  ----------  --------  ----------  ------  ----   ----\n";
  }
  else {
    $outformat = "%-9s %+40s %+12s %+15s %+11s %+11s %+9s %+11s %+7s %+5s %+6s";
    printf $outformat, "Pair","Strategy","Profit","Profit-market","Trades/day","Win trades","Best win","Worst loss", "HODL","Days","Time";
    $columns_end = "\n----                                      --------       ------   -------------  ----------  ----------  --------  ----------    ----  ----   ----\n";
  }
  print $columns_end;
  unlink "backtest.dat";
  my $pid;
  my $startbacktesttime = time;
  foreach (@warmup) {
    if (@warmup >= scalar (keys %stratconfig) && @warmup >= @pairs && @warmup > 1) {
      $pid = $pm->start and next;
    }
    my @warms = split /:/, $_;
    foreach (@pairs) {
      if (@pairs > scalar (keys %stratconfig) && @pairs >= @warmup && @pairs > 1 || $bftriger) {
        $pid = $pm->start and next;
      }
      my @sets = split /:/, $_;
      foreach my $stratn (keys %stratconfig) {
        #print "\n\n+++++++++++++++++++++++++++++++++\nDEBUG\nStrat name: $stratn \nConfig: \n$stratconfig{$stratn}\n++++++++++++++++++++++++++++++++++++++++++\n\n";
        if (scalar (keys %stratconfig) >= @pairs && scalar (keys %stratconfig) >= @warmup && scalar (keys %stratconfig) > 1 && ! defined $bftriger) {
          $pid = $pm->start and next;
        }
        # Log file name.
        my $logfile = "logs/$sets[1]-$sets[2]-$stratn-$warms[0]-$warms[1].log";
        $gconfig = $gconfig1;
        my $startthread = time;
        $configfile = File::Temp->new(TEMPLATE => "tmp_configXXXXX",SUFFIX => ".js",DIR => $tmpfile);
        if ($operiod) {
          my $tablename = "candles_$sets[1]_$sets[2]";
          my $dbh = DBI->connect("dbi:SQLite:dbname=history/$sets[0]_0.1.db", "", "", { RaiseError => 1 },) or die $DBI::errstr;
          my $stmt = qq{SELECT start FROM \'$tablename\' ORDER BY start DESC LIMIT 0,1;};
          my $sth = $dbh->prepare( $stmt );
          my $rv = $sth->execute() or die $DBI::errstr;
          if($rv < 0) {
            print $DBI::errstr;
          }
          $to = $sth->fetchrow_array();
          if (! defined $to) {
            print "Haven't datasets in this period for $sets[0]:$sets[1]:$sets[2]\n";
          }
          else {
            $from = strftime "%Y-%m-%d %H:%M:%S", gmtime($to - $operiod*86400);
            $to = strftime "%Y-%m-%d %H:%M:%S", gmtime($to);
          }
        }
        if (defined $sets[3]) {
          $gconfig =~ s/daterange:  'scan',/daterange: {\n    from: \"$sets[3]\",\n    to: "$sets[4]"\n  },/g;
        }
        elsif (defined $from) {
          $gconfig =~ s/daterange:  'scan',/daterange: {\n    from: \"$from\",\n    to: "$to"\n  },/g;
        }
        $gconfig =~ s/(?<=feeMaker: )(.*)(?=,)/$fee_maker/;
        $gconfig =~ s/(?<=feeTaker: )(.*)(?=,)/$fee_taker/;
        $gconfig =~ s/(?<=feeUsing: ')(.*)(?=',)/$fee_using/;
        $gconfig =~ s/(?<=slippage: )(.*)(?=,)/$slippage/;
        $gconfig =~ s/(?<=riskFreeReturn: )(.*)(?=,)/$riskFreeReturn/;
        $gconfig =~ s/(?<=config.candleWriter = \{\n  enabled: )(.*)(?=\n)/false/m;
        $gconfig =~ s/(simulationBalance: \{)\s+asset:\s+\d,\s+currency:\s\d,/simulationBalance: \{\n    asset: $asset_c,\n    currency: $currency_c,/g;
        my $stratcvs = 'NA';
        if ($use_toml_files eq 'yes') {
          $gconfig =~ s/}(?=\nconfig.performanceAnalyzer)/}\n$stratconfig{$stratn}/m;
          if (length $stratconfig{$stratn} > 3) {
            $stratcvs = $stratconfig{$stratn};
            my $toml;
            $stratcvs =~ s/config..*= //g;
            $stratcvs = &convert_json_toml($stratcvs);
            $stratcvs =~ s/[\n\t]/ /g;
            $stratcvs =~ s/  / /g;
            $stratcvs =~ s/^\s+//;
            $stratcvs =~ s/\s+$//;
            $stratcvs =~ s/"//g;
            $stratcvs =~ s/'//;
          }
        }
        else {
          $gconfig =~ s/}(?=\nconfig.performanceAnalyzer)/}\n$stratsettings/m;
          my @strat = $gconfig =~ /(?<=config.$stratn = \{)(.*?)(?=};)/s;
          $strat[0] =~ s/[\n\t]/ /g;
          $strat[0] =~ s/  / /g;
          $strat[0] =~ s/^\s+//;
          $strat[0] =~ s/\s+$//;
          $strat[0] =~ s/"/\'/g;
          $strat[0] =~ s/^/"/;
          $strat[0] =~ s/$/"/;
          $stratcvs = $strat[0];
        }
         #stratconfig = na
       #  zrobic else przy brute force toml
        # if match config.$strat  wtedy rob match do zmiennej, a potem do hasha
        #print "$stratcvs \n ---- \n $stratconfig{$stratn} \n";
        #sleep;
        my @tmps = split / /, $stratn;
        $gconfig =~ s/(?<=config.candleWriter = \{\n  enabled: )(.*)(?=\n)/false/m;
        $gconfig =~ s/(?<=exchange: ')(.*?)(?=',)/$sets[0]/g;
        $gconfig =~ s/(?<=currency: ')(.*?)(?=',)/$sets[1]/g;
        $gconfig =~ s/(?<=asset: ')(.*?)(?=',)/$sets[2]/g;
        $gconfig =~ s/(?<=method: ')(.*?)(?=',)/$tmps[0]/g;
        $gconfig =~ s/(?<=candleSize: )(.*?)(?=,)/$warms[0]/g;
        $gconfig =~ s/(?<=historySize: )(.*?)(?=,)/$warms[1]/g;
        open my $fh15, '>:encoding(UTF-8)', $configfile or die "Cannot open $configfile!";
        print $fh15 join ("\n",$gconfig);
        close $fh15;
        my $grun = `node gekko -b -c $configfile`;
        my @market = $grun =~ /(?<=Market:\t\t\t\t )(.*?)(?=%)/;
        if ($keep_logs eq 'yes') {
          open my $fh2, '>>:encoding(UTF-8)', $logfile or die "Cannot open $logfile!";
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
        my @roundtrips = $grun =~ /ROUNDTRIP\)\s+\d{4}-\d{2}-\d{2}.*?-?\d+\.\d+\s+\K-?\d+.\d+/g;
        my ($worst_loss, $best_win) = minmax @roundtrips;
        my @wins = grep($_ > 0, @roundtrips);
        $percentage_wins = '';
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
        $avg_exposed_duration = 0;
        my @exposed = $grun =~ /(?<=ROUNDTRIP\) )([-:\t \d]+)/g;
        my @exposed_min;
        foreach (@exposed) {
          my @exposed =  split /\t/, $_;
          my $roznica =( &toepoch ($exposed[1]) - &toepoch ($exposed[0]) ) / 60 ;
          push @exposed_min, $roznica;
        }
        $avg_exposed_duration = sprintf("%d", (avg (@exposed_min)));
        $avg_exposed_duration =~ s/,/\./g;
        $market_change = sprintf("%.2f", $market[0]);
        $profit = sprintf("%.2f", $profit[0]);
        $profit_year = sprintf("%d", $yearly[0]);
        $profit_market = sprintf("%.2f", $profit[0]-$market[0]);
        $dataset_days = 0;
        $trades_day = 0;
        $profit_day = 0;
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
          my $vars = {
            'currency' => $sets[1],
            'asset' => $sets[2],
            'exchange' => $sets[0],
            'strategy' => $stratn,
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
            'strategy_settings' => $stratcvs,
            'note' => $note
          };
          # if ($trades[0] > 0) {
            my ($tocsvtmp, $csvout, $csvouttmp);
            $tocsv = Template->new({ });
            $tocsv->process($csv_columns, $vars, \$csvout);
            open my $fh4, '>>:encoding(UTF-8)', $csv or die "Cannot open $csv!";
            print $fh4 join ("\n", "$csvout\n");
            close $fh4;
            $tocsvtmp = Template->new({ });
            $tocsvtmp->process($csv_columns_tmp, $vars, \$csvouttmp);
            open my $fh5, '>>:encoding(UTF-8)', $tmpcsv or die "Cannot open $tmpcsv!";
            print $fh5 join ("\n", "$csvouttmp\n");
            close $fh5;
          # }
          if ($print_roundtrips eq 'yes') {
            print "---------\n";
            my @trips;
            @trips = $grun =~ /(?<=ROUNDTRIP\) )[0-9a-z].*/g;
            foreach (@trips) {
              print "$_\n";
            }
          }
          my $endthread = time;
          if (scalar @warmup > 1) {
            printf $outformat, "$sets[1]:$sets[2]",$stratn,"$profit%",$profit_market,$trades_day,"$percentage_wins%","$best_win%","$worst_loss%","$warms[0]:$warms[1]",$dataset_days,strftime("\%M:\%S", gmtime($endthread - $startthread));
          }
          else {
            printf $outformat, "$sets[1]:$sets[2]",$stratn,"$profit%",$profit_market,$trades_day,"$percentage_wins%","$best_win%","$worst_loss%","$avg_exposed_duration",$dataset_days,strftime("\%M:\%S", gmtime($endthread - $startthread));
          }
          print "\n";
        }
        else {
          my @error = $grun =~ /(?<=Error:\n\n).*/g;
          print "$sets[1]-$sets[2] Backtest is failed. @error\n";
        }
        if (-e "backtest.dat") {
          open(my $fh, '<:encoding(UTF-8)', "backtest.dat") or die "Could not open file '!";
          my $row = <$fh>;
          close $fh;
          $row++;
          open my $fh3, '>:encoding(UTF-8)', 'backtest.dat' or die "Cannot open $csv!";
          print $fh3 $row;
          close $fh3;
          my $key;
          if (grep { $coun{$_} eq $row } keys %coun) {
            my %rhash = reverse %coun;
            $key = $rhash{$row};
            print ("=" x 147);
            $print_analysis_on_summary eq 'yes' ? &analyze($tmpcsv) : print "\n\n";
            print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] ";
            printf "%d", $key;
            print "% complete. Elapsed: ".strftime ("%H:%M:%S", gmtime((time - $startbacktesttime))).", average backtest duration: ".strftime ("%M:%S", gmtime((time - $startbacktesttime) / $row * $threads)).", backtests remain: ".($remain - $row).", ETA: ".strftime ("%H:%M:%S", gmtime((time - $startbacktesttime) * 100 / $key - (time - $startbacktesttime)))."\n\n============================================================= L A S T    R E S U L T S ============================================================\n" if $stfu eq 'no';
            if (scalar @warmup > 1) {
              $outformat = "%-9s %+40s %+12s %+15s %+11s %+11s %+9s %+11s %+7s %+5s %+6s";
              printf $outformat, "Pair","Strategy","Profit","Profit-market","Trades/day","Win trades","Best win","Worst loss", "Candle","Days","Time";
              $columns_end = "\n----                                      --------       ------   -------------  ----------  ----------  --------  ----------  ------  ----   ----\n";
            }
            else {
              $outformat = "%-9s %+40s %+12s %+15s %+11s %+11s %+9s %+11s %+7s %+5s %+6s";
              printf $outformat, "Pair","Strategy","Profit","Profit-market","Trades/day","Win trades","Best win","Worst loss", "HODL","Days","Time";
              $columns_end = "\n----                                      --------       ------   -------------  ----------  ----------  --------  ----------    ----  ----   ----\n";
            }
            print $columns_end;
          }
        }
        else {
          open my $fh3, '>:encoding(UTF-8)', 'backtest.dat' or die "Cannot open $csv!";
          print $fh3 "1";
          close $fh3;
        }
        if (scalar (keys %stratconfig) >= @pairs && scalar (keys %stratconfig) >= @warmup && scalar (keys %stratconfig) > 1 && ! $bftriger) {
          $pm->finish(0, \%paircalc);
        }
      }
      if (@pairs >= scalar (keys %stratconfig) && @pairs >= @warmup && @pairs > 1 || $bftriger) {
        $pm->finish(0, \%paircalc);
      }
    }
    if (@warmup >= scalar (keys %stratconfig) && @warmup >= @pairs && @warmup > 1) {
      $pm->finish(0, \%paircalc);
    }
  $pm->wait_all_children;
  }
  print ("=" x 147);
  print "\n\n[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] 100% complete. Elapsed: ".strftime ("%H:%M:%S", gmtime((time - $startbacktesttime))).", average backtest duration: ".strftime ("%M:%S", gmtime((time - $startbacktesttime) / $remain * ($remain / $threads))) if $stfu eq 'no';
  print "\n";
  &analyze($tmpcsv);
  print "\n";
  my $endapp = time;
  my $elapsedapp = $endapp - $startapp;
  $elapsedapp = elapsed( $elapsedapp );
  print "[".strftime ("%Y-%m-%d %H:%M:%S", localtime)."] All jobs are done. Elapsed time: $elapsedapp\n\n" if $stfu eq 'no';
}
rmtree 'tmp';
