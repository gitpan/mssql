#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/Sqllib/t/4_errors.t 3     00-05-08 22:22 Sommar $
#
# Tests sql_message_handler and sql_error_handler.
#
# $History: 4_errors.t $
# 
# *****************  Version 3  *****************
# User: Sommar       Date: 00-05-08   Time: 22:22
# Updated in $/Perl/MSSQL/Sqllib/t
# Fixed problem that could cause test to fail if @@servername was not
# defined.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 00-02-19   Time: 20:46
# Updated in $/Perl/MSSQL/Sqllib/t
# Modified tests to cover errFileHandle as well.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 16:36
# Created in $/Perl/MSSQL/sqllib/t
#---------------------------------------------------------------------

use strict;
use MSSQL::Sqllib qw(:DEFAULT :consts);
use MSSQL::DBlib::Const::Severity;
use MSSQL::DBlib::Const::Errors;

use FileHandle;
use IO::Handle;
use File::Basename qw(dirname);


$^W = 1;
$| = 1;

print "1..24\n";

my($X, $sql, $sql_call, $sp_call, $sql_callback, $msg_part, $sp_sql,
   $msgtext, $linestart, $expect_print, $expect_msgs, $errno, $sev, $state);

use vars qw($Srv $Uid $Pwd);
require &dirname($0) . '\sqllogin.pl';

$X = sql_init($Srv, $Uid, $Pwd, 'tempdb');



# Set up some templates and other stuff that we'll use throughout.
$errno     = 50000;
$state     = 12;
$sev       = 11;
$msgtext   = "Er geht an die Ecke.";
$sql       = qq!RAISERROR("$msgtext", $sev, $state)!;
$sql_call  = "sql(q!$sql!, undef, NORESULT)";
$sp_call   = "sql_sp('##nisse_sp', ['$msgtext', $sev])";
$msg_part  = "SQL Server message $errno, Severity $sev, State $state(, Server .+)?";
$linestart = '\s\s\s+1>\s+';
$sp_sql    = "EXEC ##nisse_sp (\\\@msgtext = '$msgtext', \\\@sev = $sev|\\\@sev = $sev, \\\@msgtext = '$msgtext')";
$X->sql(<<SQLEND);
   CREATE PROCEDURE ##nisse_sp \@msgtext varchar(25), \@sev int AS
   RAISERROR(\@msgtext, \@sev, $state)
SQLEND


# First test. Should die and print it all.
$sev   = 11;
$expect_print = ["=~ /^$msg_part\\n/i",
                 "=~ /Procedure\\s+##nisse_sp\\s+Line 2/",
                 "eq '$msgtext\n'",
                 "=~ /$linestart$sp_sql\E\n/"];
do_test($sp_call, 1, 1, $expect_print);

# Second test. Should not print lines, and not abort.
$X->{errInfo}{neverStopOn}{$errno}++;
$X->{errInfo}{printLines} = $sev + 1;
$expect_print = ["=~ /^$msg_part\n/i",
                 "eq 'Line 1\n'",
                 "eq '$msgtext\n'"];
do_test($sql_call, 4, 0, $expect_print);

# Third test. Uses SP. Should print full text. Should not abort. Should return messages.
$X->{errInfo}{neverStopOn}{$errno} = 0;
$X->{errInfo}{maxSeverity} = $sev;
$X->{errInfo}{alwaysPrint}{$errno}++;
$X->{errInfo}{saveMessages}++;
$expect_print = ["=~ /^$msg_part\n/i",
                 "eq 'Line 1\n'",
                 "eq '$msgtext\n'",
                 "=~ /$linestart\Q$sql\E\n/"];
$expect_msgs = [{state    => "== $state",
                 errno    => "== $errno",
                 severity => "== $sev",
                 text     => "eq '$msgtext'",
                 line     => "== 1"},
                {state    => "== -1",
                 errno    => "== " . SQLESMSG,
                 severity => "== " . EXSERVER,
                 text     => "=~ /General SQL Server error/i",
                 oserr    => "== -1"}];
do_test($sql_call, 7, 0, $expect_print, $expect_msgs);

# Fourth test. Should abort. Should not print. Should not return messages.
$X->{errInfo}{alwaysStopOn}{$errno}++;
$X->{errInfo}{alwaysPrint} = 0;
$X->{errInfo}{neverPrint}{$errno}++;
$X->{errInfo}{saveMessages} = 0;
delete $X->{errInfo}{messages};
do_test($sp_call, 10, 1, []);

# Fifth test. Should abort. Should only print the text. Should print DB-err text.
# Should not return messages.
delete $X->{errInfo}{alwaysPrint};
delete $X->{errInfo}{neverPrint};
$X->{errInfo}{printMsg} = $sev + 1;
$expect_print = ["eq '$msgtext\n'",
                 "=~ /^DB-Library error " . SQLESMSG . ", severity " . EXSERVER . ": General/"];
do_test($sp_call, 13, 1, $expect_print);


# Set up a callback, for testing DB-Library errors.
$sql_callback = <<PERLEND;
sql("SELECT * FROM sysobjects WHERE name = 'sysobjects'", HASH, \\&callback)
PERLEND
sub callback {
    # This is illegal, because we have a open result set.
    sql("SELECT * FROM sysobjects WHERE name = 'syscolumns'");
    RETURN_NEXTROW;
}

# Sixth test. Should abort in error handler. Should print the text. Should return messages.
$X->{errInfo}{saveMessages} = 1;
$expect_print = ["=~ /^DB-Library error " . SQLERPND . ", severity " . EXPROGRAM .
                     ": Attempt/"];
$expect_msgs = [{state    => "== -1",
                 errno    => "== " . SQLERPND,
                 severity => "== " . EXPROGRAM,
                 text     => "=~ /Attempt/i",
                 oserr    => "== -1"}];
do_test($sql_callback, 16, 1, $expect_print, $expect_msgs);

# Seventh test. Should print, should not abort. Should push message at end.
push(@$expect_msgs, $$expect_msgs[0]);
$X->{errInfo}{maxLibSeverity} = EXPROGRAM;
do_test($sql_callback, 19, 0, $expect_print, $expect_msgs);

# Eighth test. Should not print. Should abort. No new message returned, but the old remain.
$X->{errInfo}{saveMessages} = 0;
$X->{errInfo}{alwaysStopOn}{-SQLERPND()}++;
$X->{errInfo}{neverPrint}{-SQLERPND()}++;
do_test($sql_callback, 22, 1, [], $expect_msgs);

# That's enough!
exit;


sub do_test{
   my($test, $test_no, $expect_die, $expect_print, $expect_msgs) = @_;

   my($savestderr, $errfile, $fh);

   # Get file name.
   $errfile = &dirname($0) . "\\error.$test_no";

   if ($test_no % 2 == 0) {
      delete $X->{errInfo}{errFileHandle};

      # Save STDERR so we can reopen.
      $savestderr = FileHandle->new_from_fd(*main::STDERR, "w") or die "Can't dup STDERR: $!\n";

      # Redirect STDERR to a file.
      open(STDERR, ">$errfile") or die "Can't redriect STDERR to '$errfile': $!\n";
      STDERR->autoflush;
   }
   else {
      # Test errFileHandle
      $fh = new FileHandle;
      $fh->open($errfile, "w") or die "Can't write to '$errfile': $!\n";
      $X->{errInfo}{errFileHandle} = $fh;
   }

   # Run the test. Must eval, it may die.
   eval($test);

   if ($test_no % 2 == 0) {
      # Put STDERR back to were it was.
      open(STDERR, ">&" . $savestderr->fileno) or (print "Can't reopen STDERR: $!\n" and die);
      STDERR->autoflush;
   }
   else {
      $fh->close;
   }

   # Now, read the error file.
   $fh = new FileHandle;
   $fh->open($errfile, "r") or die "Cannot read $errfile: $!\n";
   my @errfile = <$fh>;
   $fh->close;

   # We have to weed out Perl warnings. These fall into two kinds: script failure,
   # which we dismiss, and the rest which we warn about.
   my @perlwarns   = grep(/at \S+\.(t|pm) /, @errfile);
   my @mssqlprint = grep($_ !~ /at \S+\.(t|pm) /, @errfile);

   my $warn;
   foreach $warn (@perlwarns) {
      print STDERR "$warn" unless $warn =~ /failed/;
   }

   # Now, evaluate the tests. First the dieFlag.
   if ($X->{errInfo}{dieFlag} == $expect_die) {
      print "ok $test_no\n"
   }
   else {
      print "not ok $test_no\n";
   }
   $test_no++;

   # Compare output.
   if (compare(\@mssqlprint, $expect_print)) {
      print "ok $test_no\n"
   }
   else {
      print "not ok $test_no\n";
   }
   $test_no++;

   # Then the messages.
   if (compare($X->{errInfo}{'messages'}, $expect_msgs)) {
      print "ok $test_no\n"
   }
   else {
      print "not ok $test_no\n";
   }
   $test_no++;
}



sub compare {
   my ($x, $y) = @_;

   my ($refx, $refy, $ix, $key, $result);

   $refx = ref $x;
   $refy = ref $y;

   if (not $refx and not $refy) {
      if (defined $x and defined $y) {
         $result = eval("q!$x! $y");
         warn "no match: <$x> <$y>" if not $result;
         return $result;
      }
      else {
         return (not defined $x and not defined $y);
      }
   }
   elsif ($refx ne $refy) {
      return 0;
   }
   elsif ($refx eq "ARRAY") {
      if ($#$x != $#$y) {
         return 0;
      }
      elsif ($#$x >= 0) {
         foreach $ix (0..$#$x) {
            $result = compare($$x[$ix], $$y[$ix]);
            last if not $result;
         }
         return $result;
      }
      else {
         return 1;
      }
   }
   elsif ($refx eq "HASH") {
      my $nokeys_x = scalar(keys %$x);
      my $nokeys_y = scalar(keys %$y);
      if ($nokeys_x == $nokeys_y and $nokeys_x == 0) {
         return 1;
      }
      if ($nokeys_x > 0) {
         foreach $key (keys %$x) {
            if (not exists $$y{$key} and defined $$x{$key}) {
                return 0;
            }
            $result = compare($$x{$key}, $$y{$key});
            last if not $result;
         }
      }
      return 0 if not $result;
      foreach $key (keys %$y) {
         if (not exists $$x{$key} and defined $$y{$key}) {
             return 0;
         }
      }
      return $result;
   }
   elsif ($refx eq "SCALAR") {
      return compare($$x, $$y);
   }
   else {
      return ($x eq $y);
   }
}
