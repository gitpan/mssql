#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/sqllib/t/3_conversion.t 1     99-01-30 16:36 Sommar $
#
# Tests that it's possible to set up a conversion based on the local
# OEM character set and the server charset. Mainly is this is test that
# we can access Win32::Registry properly.
#
# $History: 3_conversion.t $
# 
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 16:36
# Created in $/Perl/MSSQL/sqllib/t
#---------------------------------------------------------------------

use strict;
use MSSQL::Sqllib qw(:DEFAULT :consts);
use File::Basename qw(dirname);

$^W = 1;
$| = 1;

print "1..17\n";

my($shrimp, $shrimp_850, $shrimp_bogus, @data, $data, %data);

use vars qw($Srv $Uid $Pwd);
require &dirname($0) . '\sqllogin.pl';

sql_init($Srv, $Uid, $Pwd, "tempdb");

# First create a table to two procedures to read and write to the table.
sql(<<SQLEND);
   CREATE TABLE #nisse (i       int      NOT NULL PRIMARY KEY,
                        shrimp  char(10) NOT NULL)
SQLEND

sql(<<'SQLEND');
   CREATE PROCEDURE #nisse_ins_sp @i      int,
                                  @shrimp char(10) AS
      INSERT #nisse (i, shrimp) VALUES (@i, @shrimp)
SQLEND

sql(<<'SQLEND');
   CREATE PROCEDURE #nisse_get_sp @i int,
                                  @shrimp char(10) OUTPUT AS

      SELECT @shrimp = shrimp FROM #nisse WHERE @i = i
SQLEND

# These are the constants we use to test. It's all about shrimp sandwiches.
$shrimp       = 'räksmörgås';  # The way it should be in Latin-1.
$shrimp_850   = 'r„ksm”rg†s';  # It's in CP850.
$shrimp_bogus = 'rõksm÷rgÕs';  # Converted to Latin-1 as if it was CP850 but it wasn't.


# Now add first set of data with no conversion in effect.
sql("INSERT #nisse (i, shrimp) VALUES (1, 'räksmörgås')");
sql_insert("#nisse", {i => 2, 'shrimp' => 'räksmörgås'});
sql_sp("#nisse_ins_sp", [3, 'räksmörgås']);

# Now set up default, bilateral conversion.
sql_set_conversion;
print "ok 1\n";   # We wouldn't come back if it's not ok...

# Add second set of data.
sql("INSERT #nisse (i, shrimp) VALUES (11, 'räksmörgås')");
sql_insert("#nisse", {i => 12, 'shrimp' => 'räksmörgås'});
sql_sp("#nisse_ins_sp", [13, 'räksmörgås']);

# Now retrieve data and see what we get. The first should give the shrimp in CP850.
@data = sql("SELECT shrimp FROM #nisse WHERE i BETWEEN 1 AND 3", SCALAR);
if (compare(\@data, [$shrimp_850, $shrimp_850, $shrimp_850])) {
   print "ok 2\n";
}
else {
   print "not ok 2\n--" . join(' ', @data) . "\n";
}

# This should give the real McCoy - it's been converted in both directions.
@data = sql("SELECT shrimp FROM #nisse WHERE i BETWEEN 11 AND 13", SCALAR);
if (compare(\@data, [$shrimp, $shrimp, $shrimp])) {
   print "ok 3\n";
}
else {
   print "not ok 3\n--" . join(' ', @data) . "\n";
}

# Again, a CP850 shrimp is expected.
sql_sp("#nisse_get_sp", [1, \$data]);
if ($data eq $shrimp_850) {
   print "ok 4\n";
}
else {
   print "not ok 4\n--$data\n";
}

# Again, in Latin-1.
sql_sp("#nisse_get_sp", [11, \$data]);
if ($data eq $shrimp) {
   print "ok 5\n";
}
else {
   print "not ok 5\n--$data\n";
}

# Turn off conversion. This just can't fail. :-)
sql_unset_conversion;

# Now we should get Latin-1.
@data = sql("SELECT shrimp FROM #nisse WHERE i BETWEEN 1 AND 3", SCALAR);
if (compare(\@data, [$shrimp, $shrimp, $shrimp])) {
   print "ok 6\n";
}
else {
   print "not ok 6\n--" . join(' ', @data) . "\n";
}

# This is the bogus conversion, we converted Latin-1 to Latin-1.
@data = sql("SELECT shrimp FROM #nisse WHERE i BETWEEN 11 AND 13", SCALAR);
if (compare(\@data, [$shrimp_bogus, $shrimp_bogus, $shrimp_bogus])) {
   print "ok 7\n";
}
else {
   print "not ok 7\n--" . join(' ', @data) . "\n";
}

# Again, a Latin-1 shrimp is expected.
sql_sp("#nisse_get_sp", [1, \$data]);
if ($data eq $shrimp) {
   print "ok 8\n";
}
else {
   print "not ok 8\n--$data\n";
}

# Again, it's bogus.
sql_sp("#nisse_get_sp", [11, \$data]);
if ($data eq $shrimp_bogus) {
   print "ok 9\n";
}
else {
   print "not ok 9\n--$data\n";
}


# Now we will make a test that we convert hash keys correctly. We will also
# test asymmetric conversion and that sql_one converts properly.
sql_set_conversion("CP850", "iso_1", TO_CLIENT_ONLY);
{
   my %ref;
   $ref{$shrimp_850} = $shrimp_850;

   %data = sql("SELECT 'räksmörgås' = 'räksmörgås'", HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 10\n";
   }
   else {
      print "not ok 10\n";
   }

   %data = sql_one("SELECT 'räksmörgås' = 'räksmörgås'");
   if (compare(\%ref, \%data)) {
      print "ok 11\n";
   }
   else {
      print "not ok 11\n";
   }
}

# After this we have conversion both directions
sql_set_conversion("CP850", "iso_1", TO_SERVER_ONLY);
{
   my %ref;
   $ref{$shrimp} = $shrimp;

   %data = sql("SELECT 'räksmörgås' = 'räksmörgås'", HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 12\n";
   }
   else {
      print "not ok 12\n";
   }

   %data = sql_one("SELECT 'räksmörgås' = 'räksmörgås'");
   if (compare(\%ref, \%data)) {
      print "ok 13\n";
   }
   else {
      print "not ok 13\n";
   }
}

# After now only to server.
sql_unset_conversion(TO_CLIENT_ONLY);
{
   my %ref;
   $ref{$shrimp_bogus} = $shrimp_bogus;

   %data = sql("SELECT 'räksmörgås' = 'räksmörgås'", HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 14\n";
   }
   else {
      print "not ok 14\n";
   }

   %data = sql_one("SELECT 'räksmörgås' = 'räksmörgås'");
   if (compare(\%ref, \%data)) {
      print "ok 15\n";
   }
   else {
      print "not ok 15\n";
   }
}

# And now in no direction at all.
sql_unset_conversion(TO_SERVER_ONLY);
{
   my %ref;
   $ref{$shrimp} = $shrimp;

   %data = sql("SELECT 'räksmörgås' = 'räksmörgås'", HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 16\n";
   }
   else {
      print "not ok 16\n";
   }

   %data = sql_one("SELECT 'räksmörgås' = 'räksmörgås'");
   if (compare(\%ref, \%data)) {
      print "ok 17\n";
   }
   else {
      print "not ok 17\n";
   }
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
