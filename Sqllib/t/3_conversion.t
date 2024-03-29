#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/Sqllib/t/3_conversion.t 2     01-05-01 22:50 Sommar $
#
# Tests that it's possible to set up a conversion based on the local
# OEM character set and the server charset. Mainly is this is test that
# we can access Win32::Registry properly.
#
# $History: 3_conversion.t $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 01-05-01   Time: 22:50
# Updated in $/Perl/MSSQL/Sqllib/t
# Now also tests for CP437.
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

my($shrimp, $shrimp_850, $shrimp_twoway, $shrimp_bogus, @data, $data, %data);

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

# Get client char-set.
my $client_cs = get_codepage_from_reg('OEMCP');

# These are the constants we use to test. It's all about shrimp sandwiches.
$shrimp       = 'r�ksm�rg�s';  # The way it should be in Latin-1.
if ($client_cs == 850) {
   $shrimp_850    = 'r�ksm�rg�s';  # It's in CP850.
   $shrimp_twoway = 'r�ksm�rg�s'; # Latin-1 -> CP850 and back.
   $shrimp_bogus  = 'r�ksm�rg�s';  # Converted to Latin-1 as if it was CP850 but it wasn't.
}
elsif ($client_cs == 437) {
   $shrimp_850    = 'r�ksm�rg�s';  # It's in CP437.
   $shrimp_twoway = 'r_ksm�rg_s';  # Latin-1 -> Cp437 and back. Not round-trip.
   $shrimp_bogus  = 'r_ksm�rg_s';  # Converted to Latin-1 as if it was CP437 but it wasn't.
}
else {
   print "Skipping this test; no test defined for code-page $client_cs\n";
   print "1..0\n";
   exit;
}


# Now add first set of data with no conversion in effect.
sql("INSERT #nisse (i, shrimp) VALUES (1, 'r�ksm�rg�s')");
sql_insert("#nisse", {i => 2, 'shrimp' => 'r�ksm�rg�s'});
sql_sp("#nisse_ins_sp", [3, 'r�ksm�rg�s']);

# Now set up default, bilateral conversion.
sql_set_conversion;
print "ok 1\n";   # We wouldn't come back if it's not ok...

# Add second set of data.
sql("INSERT #nisse (i, shrimp) VALUES (11, 'r�ksm�rg�s')");
sql_insert("#nisse", {i => 12, 'shrimp' => 'r�ksm�rg�s'});
sql_sp("#nisse_ins_sp", [13, 'r�ksm�rg�s']);

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
if (compare(\@data, [$shrimp_twoway, $shrimp_twoway, $shrimp_twoway])) {
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
if ($data eq $shrimp_twoway) {
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
sql_set_conversion("CP$client_cs", "iso_1", TO_CLIENT_ONLY);
{
   my %ref;
   $ref{$shrimp_850} = $shrimp_850;

   %data = sql("SELECT 'r�ksm�rg�s' = 'r�ksm�rg�s'", HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 10\n";
   }
   else {
      print "not ok 10\n";
   }

   %data = sql_one("SELECT 'r�ksm�rg�s' = 'r�ksm�rg�s'");
   if (compare(\%ref, \%data)) {
      print "ok 11\n";
   }
   else {
      print "not ok 11\n";
   }
}

# After this we have conversion both directions
sql_set_conversion("CP$client_cs", "iso_1", TO_SERVER_ONLY);
{
   my %ref;
   $ref{$shrimp_twoway} = $shrimp_twoway;

   %data = sql("SELECT 'r�ksm�rg�s' = 'r�ksm�rg�s'", HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 12\n";
   }
   else {
      print "not ok 12\n";
   }

   %data = sql_one("SELECT 'r�ksm�rg�s' = 'r�ksm�rg�s'");
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

   %data = sql("SELECT 'r�ksm�rg�s' = 'r�ksm�rg�s'", HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 14\n";
   }
   else {
      print "not ok 14\n";
      print '<' . (keys(%ref))[0] . '> <' . (keys(%data))[0] . ">\n";
   }

   %data = sql_one("SELECT 'r�ksm�rg�s' = 'r�ksm�rg�s'");
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

   %data = sql("SELECT 'r�ksm�rg�s' = 'r�ksm�rg�s'", HASH, SINGLEROW);
   if (compare(\%ref, \%data)) {
      print "ok 16\n";
   }
   else {
      print "not ok 16\n";
   }

   %data = sql_one("SELECT 'r�ksm�rg�s' = 'r�ksm�rg�s'");
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

#--------------------------------- Copied from Sqllib.pm
sub get_codepage_from_reg {
    my($cp_value) = shift @_;
    # Reads the code page for OEM or ANSI. This is one specific key in
    # in the registry.

    my($REGKEY) = 'SYSTEM\CurrentControlSet\Control\Nls\CodePage';
    my($regref, $dummy, $result);

    # We need this module to read the registry, but as this is the only
    # place we need it in, we don't C<use> it.
    require 'Win32\Registry.pm';

    $dummy = $main::HKEY_LOCAL_MACHINE;  # Resolve "possible typo" with AS Perl.
    $main::HKEY_LOCAL_MACHINE->Open($REGKEY, $regref) or
         die "Could not open registry key: '$REGKEY'\n";

    # This is where stuff is getting really ugly, as I have found no code
    # that works both with the ActiveState Perl and the native port.
    if ($] < 5.004) {
       Win32::RegQueryValueEx($regref->{'handle'}, $cp_value, 0,
                              $dummy, $result) or
             die "Could not read '$REGKEY\\$cp_value' from registry\n";
    }
    else {
       $regref->QueryValueEx($cp_value, $dummy, $result);
    }
    $regref->Close or warn "Could not close registry key.\n";

    $result;
}
