#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/t/2_bcp.t 1     99-01-30 16:56 Sommar $
#
# Test suite for the BCP routines.
#
# $History: 2_bcp.t $
# 
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 16:56
# Created in $/Perl/MSSQL/DBlib/t
#---------------------------------------------------------------------
use strict;

use MSSQL::DBlib;
use MSSQL::Sqllib;
use MSSQL::DBlib::Const::BCP;
use MSSQL::DBlib::Const::General;
use MSSQL::DBlib::Const::Datatypes;

use File::Basename qw(dirname);


my($X, @bcp_data, $row, @ret_data, $count, $stat, $rows_copied, $sendrow_ok);

# Our test data.
@bcp_data = (["Alpha",   1,     "19980101 01:01:01.010",  1.11],
             ["Beta",    2,     "19980202 02:02:02.020",  2.22],
             ["Gamma",   3,     "19980303 03:03:03.030",  3.33],
             ["Delta",   4,     "19980404 04:04:04.030",  4.44],
             ["Epsilon", 5,     undef,                    5.55],
             ["Theta",   undef, "19980606 06:06:06.060",  6.66],
             ["Zeta",    7,     "19980707 07:07:07.070",  7.77],
             ["Eta",     8,     "19980808 08:08:08.080",  8.88],
             ["Iota",    9,     "19980909 09:09:09.090",  9.99],
             ["Kappa",  10,     "19981010 10:10:10.100", 10.10],
             ["Lamdba", 11,     "19981111 11:11:11.110", 11.11],
             ["Mu",     12,     "19981212 12:12:12.120", 12.12]);


$^W = 1;
$| = 1;

print "1..18\n";

BCP_SETL(1) and print "ok 1\n" or die "not ok 1\n";

# Get data for logging into the server.
use vars qw($Srv $Uid $Pwd);
require &dirname($0) . '\sqllogin.pl';
$X = sql_init($Srv, $Uid, $Pwd, "tempdb");

# Create a test table.
$X->sql(<<SQLEND);
   CREATE TABLE #bcp_test(
       charcol  varchar(10) NOT NULL,
       intcol   int         NULL,
       datecol  datetime    NULL,
       floatcol float       NOT NULL)
SQLEND

# Initiate for bcp from variables.
$X->bcp_init("#bcp_test", undef, undef, DB_IN)
    and print "ok 2\n" or print "not ok 2\n";
$X->bcp_meminit(4) and print "ok 3\n" or print "not ok 3\n";

# We will write the data to file, for use later on.
open(F, ">bcp.data") or die "Cannot write 'bcp.data'!\n";
binmode(F);

$sendrow_ok = 1;
foreach $row (@bcp_data) {
    $stat = $X->bcp_sendrow(@$row);
    $sendrow_ok = 0 if $stat != SUCCEED;

    # Write to file. Format agree with what we give to bcp_colfmt below.
    print F  $$row[0] . ' ' x (10 - length($$row[0])) .
             (defined $$row[1] ? pack("cl", 4, $$row[1]) : "\0") .
             (defined $$row[2] ? $$row[2] : "") . '@!@' .
             pack("d", $$row[3]);

    ++$count;
    if (($count % 10) == 0) {
        ($X->bcp_batch == 10) and print "ok 4\n" or print "not ok 4\n";
    }
}
close F;
$sendrow_ok and print "ok 5\n" or print "not ok 5\n";

($X->bcp_done == 2) and print "ok 6\n" or print "not ok 6\n";

@ret_data = sql("SELECT * FROM #bcp_test", MSSQL::Sqllib::LIST);
compare(\@bcp_data, \@ret_data) and print "ok 7\n" or print "not ok 7\n";

# Flush table to set up for testing bcp from file.
sql("TRUNCATE TABLE #bcp_test");

$X->bcp_init("#bcp_test", "bcp.data", undef, DB_IN)
   and print "ok 8\n" or print "not ok 8\n";
$X->bcp_columns(4) and print "ok 9\n" or print "not ok 9\n";

# Define the column format.
$X->bcp_colfmt(1, SQLCHAR, 0, 10, "", 0, 1)
   and print "ok 10\n" or print "not ok 10\n";
$X->bcp_colfmt(2, 0, 1, -1, "", 0, 2)
   and print "ok 11\n" or print "not ok 11\n";
$X->bcp_colfmt(3, SQLCHAR, 0, -1, '@!@', 3, 3)
   and print "ok 12\n" or print "not ok 12\n";
$X->bcp_colfmt(4, 0, -1, -1, "", 0, 4)
   and print "ok 13\n" or print "not ok 13\n";

# Some control flags. We skip the first two lines.
$X->bcp_control(BCPBATCH, 6) and print "ok 14\n" or print "not ok 14\n";
$X->bcp_control(BCPFIRST, 3) and print "ok 15\n" or print "not ok 15\n";

# A special error handler to catch the message "sent to server".
dberrhandle(\&bcp_error_handler);

# Send it!
($stat, $rows_copied) = $X->bcp_exec;
($rows_copied == 10 and $stat == SUCCEED)
   and print "ok 17\n" or print "not ok 17\n";

shift(@bcp_data); shift(@bcp_data);
@ret_data = sql("SELECT * FROM #bcp_test", MSSQL::Sqllib::LIST);
compare(\@bcp_data, \@ret_data) and print "ok 18\n" or print "not ok 18\n";

#foreach $row (@ret_data) {
#   @$row = map {defined $_ ? $_ : "NULL"} @$row;
#   print join("<->", @$row), "\n";
#}

unlink("bcp.data");

exit;


sub bcp_error_handler {
    my($db, $severity, $error, $os_error, $error_msg, $os_error_msg) = @_;

    if ($error != 10050) {
       print STDERR "DB-Library error $error: $error_msg\n";
       print STDERR "OS error $os_error: $os_error_msg\n" if defined $os_error_msg;
       print "not ok 16\n";
    }
    print "ok 16\n";

    INT_CANCEL;
}




sub compare {
   my ($x, $y) = @_;

   my ($refx, $refy, $ix, $key, $result);

   $refx = ref $x;
   $refy = ref $y;

   if (not $refx and not $refy) {
      if (defined $x and defined $y) {
         $result = ($x eq $y);
         warn "$x <> $y\n" if not $result;
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
      if ($nokeys_x != $nokeys_y) {
         return 0;
      }
      elsif ($nokeys_x > 0) {
         foreach $key (keys %$x) {
            if (not exists $$y{$key}) {
                return 0;
            }
            $result = compare($$x{$key}, $$y{$key});
            last if not $result;
         }
         return $result;
      }
      else {
         return 1;
      }
   }
   elsif ($refx eq "SCALAR") {
      return compare($$x, $$y);
   }
   else {
      return ($x eq $y);
   }
}


