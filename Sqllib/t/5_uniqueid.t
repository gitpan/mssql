#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/sqllib/t/5_uniqueid.t 1     99-01-30 16:36 Sommar $
#
# This test script test usage of the new datatype uniqueidentifier.
# It can only run against SQL Server 7.
#
# $History: 5_uniqueid.t $
# 
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 16:36
# Created in $/Perl/MSSQL/sqllib/t
#---------------------------------------------------------------------

use strict;

use MSSQL::Sqllib qw(:DEFAULT :consts);
use Filehandle;
use File::Basename qw(dirname);


$^W = 1;

$| = 1;

my($sql, $sql_version);

use vars qw($Srv $Uid $Pwd);
require &dirname($0) . '\sqllogin.pl';
$sql = sql_init($Srv, $Uid, $Pwd, "tempdb");

$sql_version = sql_one('SELECT @@VERSION', SCALAR);
$sql_version =~ /\d+\.\d+\.\d+/;
$sql_version = $&;

if (not $sql_version or $sql_version =~ /^[0-6]/) {
   print "Skipping this test; uniqueidentifier not available\n";
   print "1..0\n";
   exit;
}

print "1..7\n";

my ($GUID1, $GUID2, $GUID3);

$GUID1 = "7223C906-2CF2-11D0-AFB8-00A024A82C78";
$GUID2 = "D702042E-18AB-11D0-B16A-0080C7920B88";
$GUID3 = "4662DAAA-D393-11D0-9A56-00C04FB68BF7";

sql(<<SQLEND);
CREATE TABLE #nisse (a uniqueidentifier NULL,
                     b int              NOT NULL)
INSERT #nisse (a, b) VALUES ("$GUID1", 1)
SQLEND

sql(<<SQLEND);
CREATE PROCEDURE #nisse_sp \@a uniqueidentifier OUTPUT,
                           \@b int AS
INSERT #nisse (a, b) VALUES (\@a, \@b)
SELECT \@a = a FROM #nisse WHERE b = 1
SELECT * FROM #nisse ORDER BY b
SQLEND

my (@x, $expect, $par, $tbl);

@x = sql("SELECT * FROM #nisse");
$x[0]{'a'} = MSSQL::DBlib::reformat_uniqueid($x[0]{'a'});
$expect = [{'a' => $GUID1, 'b' => 1}];
if (compare($expect, \@x)) {
   print "ok 1\n";
}
else {
   print "not ok 1\n";
}

$par = $GUID2;
@x = sql_sp("#nisse_sp", [\$par, 2]);
push(@$expect, {'a' => $GUID2, 'b' => 2});
$x[0]{'a'} = MSSQL::DBlib::reformat_uniqueid($x[0]{'a'});
$x[1]{'a'} = MSSQL::DBlib::reformat_uniqueid($x[1]{'a'});
if (compare($expect, \@x)) {
   print "ok 2\n";
}
else {
   print "not ok 2\n";
}
if ($par eq $GUID1) {
   print "ok 3\n";
}
else {
   print "not ok 3\n";
}

$tbl = {'a' => $GUID3, 'b' => 3};
sql_insert('#nisse', $tbl);
@x = sql("SELECT * FROM #nisse ORDER BY b");
$x[0]{'a'} = MSSQL::DBlib::reformat_uniqueid($x[0]{'a'});
$x[1]{'a'} = MSSQL::DBlib::reformat_uniqueid($x[1]{'a'});
$x[2]{'a'} = MSSQL::DBlib::reformat_uniqueid($x[2]{'a'});
push(@$expect, {'a' => $GUID3, 'b' => 3});
if (compare($expect, \@x)) {
   print "ok 4\n";
}
else {
   print "not ok 4\n";
}

$par = undef;
@x = sql_sp("#nisse_sp", [\$par, 4]);
push(@$expect, {'a' => undef, 'b' => 4});
$x[0]{'a'} = MSSQL::DBlib::reformat_uniqueid($x[0]{'a'});
$x[1]{'a'} = MSSQL::DBlib::reformat_uniqueid($x[1]{'a'});
$x[2]{'a'} = MSSQL::DBlib::reformat_uniqueid($x[2]{'a'});
if (compare($expect, \@x)) {
   print "ok 5\n";
}
else {
   print "not ok 5\n";
}
if ($par eq $GUID1) {
   print "ok 6\n";
}
else {
   print "not ok 6\n";
}

if ($par eq MSSQL::DBlib::reformat_uniqueid($par)) {
   print "ok 7\n";
}
else {
   print "not ok 7\n";
}


exit;


sub compare {
   my ($x, $y) = @_;

   my ($refx, $refy, $ix, $key, $result);

   $refx = ref $x;
   $refy = ref $y;

   if (not $refx and not $refy) {
      if (defined $x and defined $y) {
         warn "<$x> ne <$y>" if $x ne $y;
         return ($x eq $y);
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

