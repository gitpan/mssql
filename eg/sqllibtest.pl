#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/eg/sqllibtest.pl 2     99-01-30 16:46 Sommar $
#
# $History: sqllibtest.pl $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:46
# Updated in $/Perl/MSSQL/eg
# Can take arguments. Rewritten queries so that they run on SQL Server 7.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 98-01-19   Time: 22:28
# Created in $/Perl/MSSQL/eg
#---------------------------------------------------------------------

use strict;

sub blurb{
    print "------ Testing @_ ------\n";
}

my($sql, %x, @x, $x, $y, $z, $ix, $kol, %tbl);

use MSSQL::Sqllib qw(:DEFAULT :consts);
use FileHandle;

my ($server) = shift;
my ($pw)     = shift;

$sql = sql_init($server, "sa", $pw, "master");

#$sql->{'logHandle'} = new FileHandle ">sql.log" or
#   die "Cannot open 'sql.log': $!\n";
#$sql->{'noExec'} = 0;

sql_set_conversion(undef, undef, TO_SERVER_CLIENT);

$SQLSEP = "@!@";

# Go directly to test of sql_insert and sql_sp.
goto INSERT if $ARGV[0];

&blurb('&sql, LIST, SINGLESET');
$x = &sql(<<SQLEND, MSSQL::Sqllib::LIST);
SELECT * FROM sysdatabases
SELECT * FROM syssegments
SELECT  name, length, type, usertype FROM systypes
ORDER   BY length
COMPUTE sum(type) BY length
SQLEND

foreach $y (@$x) {
   print join("<->", @$y), "\n";
}

&blurb('&sql, HASH, SINGLESET');
@x = &sql(<<SQLEND);
SELECT  name, length, type, usertype FROM systypes
ORDER   BY length, name
COMPUTE sum(type) BY length, name
COMPUTE sum(type) BY length
COMPUTE sum(type)
SQLEND

foreach $x (@x) {
  foreach $kol (keys %$x) {
     print "$kol: $$x{$kol} ";
  }
  print "\n";
}

&blurb('&sql, SCALAR, SINGLESET');
@x = &sql("SELECT name, dbid FROM sysdatabases", MSSQL::Sqllib::SCALAR);
foreach $x (@x) {
   print "$x\n";
}

&blurb('&sql_one, HASH');
%x = &sql_one("SELECT * FROM sysdatabases WHERE dbid = 1");
foreach $kol (keys %x) {
  print "$kol: $x{$kol} ";
}
print "\n";

&blurb('&sql, HASH, SINGLEROW');
%x = &sql("SELECT * FROM sysdatabases WHERE dbid = 1", undef, SINGLEROW);
foreach $kol (keys %x) {
  print "$kol: $x{$kol} ";
}
print "\n";

&blurb('&sql_one, LIST');
@x = &sql_one("SELECT * FROM sysdatabases WHERE dbid = 1", LIST);
print join("<->", @x ). "\n";

&blurb('&sql, LIST, SINGLEROW');
$x = &sql("SELECT * FROM sysdatabases WHERE dbid = 1", LIST, SINGLEROW);
print join("<->", @$x ). "\n";

&blurb('&sql_one, SCALAR');
$x = &sql_one("SELECT name FROM sysdatabases WHERE dbid = 1");
print "$x\n";

&blurb('&sql, SCALAR, SINGLEROW');
$x = &sql("SELECT name, dbid FROM sysdatabases", SCALAR, SINGLEROW);
print "$x\n";

&blurb('&sql_one, failure no match');
eval q!&sql_one("SELECT name FROM sysdatabases WHERE dbid = -1")!;
print "eval failed (or at least it should): $@\n";

&blurb('&sql_one, failure too many');
eval q!&sql_one("SELECT name FROM sysdatabases")!;
print "eval failed (or at least it should): $@\n";

&blurb('$sql, LIST, MULTISET');
$x = &sql(<<SQLEND, LIST, MULTISET);
SELECT length, sum(type), avg(type) FROM systypes GROUP BY length
SELECT * FROM syssegments
SQLEND

$ix = 0;
foreach $y (@$x) {
   print "Result ", $ix++, "\n";
   foreach $z (@$y) {
      print join("<->", @$z), "\n";
   }
}

&blurb('$sql, HASH, MULTISET');
@x = &sql(<<SQLEND, HASH, MULTISET);
SELECT length, sum(type), avg(type) FROM systypes GROUP BY length
SELECT * FROM syssegments
SQLEND

$ix = 0;
foreach $y (@x) {
   print "Result ", $ix++, "\n";
   foreach $z (@$y) {
     foreach $kol (keys %$z) {
        print "$kol: $$z{$kol} ";
     }
     print "\n";
   }
}

&blurb('$sql, SCALAR, MULTISET');
$x = &sql(<<SQLEND, SCALAR, MULTISET);
SELECT name FROM syslogins
SELECT name FROM sysdatabases
SQLEND
$ix = 0;
foreach $y (@$x) {
   print "Result ", $ix++, "\n";
   foreach $z (@$y) {
      print "$z\n";
   }
}

&blurb('$sql, LIST, callback');
sub print_list {print "$_[1]: ", join("<->", @{$_[0]}), "\n"; RETURN_NEXTROW};
&sql(<<SQLEND, LIST, \&print_list);
SELECT length, sum(type), avg(type) FROM systypes GROUP BY length
SELECT * FROM syssegments
SQLEND


&blurb('$sql, HASH, callback');
sub print_hash {
   my($hash, $ressetno) = @_;
   my ($col);
   print "$ressetno: ";
   foreach $col (keys %$hash) {
      print "$col: <" . (defined $$hash{$col} ? $$hash{$col} : "NULL") . ">  ";
   }
   print "\n";
   RETURN_NEXTROW;
}
$x = &sql(<<SQLEND, HASH, \&print_hash);
SELECT length, sum(type), avg(type) FROM systypes GROUP BY length
SELECT * FROM syssegments
SQLEND
print "Returned $x\n";

&blurb('$sql, SCALAR, callback');
$x = &sql(<<SQLEND, SCALAR, sub {print "$_[1]: $_[0]\n"; RETURN_NEXTROW});
SELECT name FROM syslogins
SELECT name FROM sysdatabases
SQLEND
print "Returned $x\n";

INSERT:
# The only time you need both these two, is when you have noExec and a
# LogHandle.
&sql("USE tempdb");
$sql->dbuse("tempdb");

&blurb('$sql_insert');
&sql(<<SQLEND);
IF EXISTS (SELECT *
           FROM   sysobjects
           WHERE  name = "nisse"
             AND  uid  = user_id()
             AND  type = "U")
   DROP TABLE nisse
SQLEND
&sql(<<SQLEND);
CREATE TABLE nisse  (intcol       int           NULL,
                     smallintcol  smallint      NULL,
                     tinyintcol   int           NULL,
                     bincol       binary(80)    NOT NULL,
                     varbincol    varbinary(80) NULL,
                     datecol      datetime      NULL,
                     smalldatecol smalldatetime NULL,
                     charcol      char(80)      NOT NULL,
                     varcharcol   varchar(80)   NULL,
                     deccol       decimal(18,6) NOT NULL,
                     numcol       numeric(12,2) NOT NULL,
                     floatcol     float         NULL,
                     realcol      real          NULL,
                     moneycol     money         NULL,
                     dimecol      smallmoney    NULL,
                     bitcol       bit           NOT NULL,
                     tstamp       timestamp     NOT NULL,
                     textcol      text          NULL,
                     imagecol     image         NULL)
SQLEND
%tbl = (intcol        =>   47114711,
        smallintcol   =>   4711,
        tinyintcol    =>   253,
        bincol        =>   "0x47111267ABCD47111267ABCD",
        varbincol     =>   "0xABCD4711",
        datecol       =>   "21010501 13:27:30.050",
        smalldatecol  =>   "Apr 4 1960 3:15pm",
        charcol       =>   "Räksmörgås",
        varcharcol    =>   "Naïve clichés have no rôle",
        deccol        =>   123456789.123456,
        numcol        =>   123456789.123456,
        floatcol      =>   123456789.123456,
        realcol       =>   123456789.123456,
        moneycol      =>   123456789.123456,
        dimecol       =>   123456.123456,
        bitcol        =>   1,
        textcol       =>   "Hej på dej!" x 10,
        imagecol      =>   "0x" . "47119600" x 5);
sql_insert("nisse", \%tbl);
%x = sql_one("SELECT * FROM nisse", HASH);
print_data(\%tbl, \%x, 0);

&blurb("sql_sp, sp_helpdb");
my($retstat);
sql_sp("sp_helpdb", \$retstat, ['tempdb'], HASH, \&print_hash);
print "Return status = ", $retstat, "\n";
print "\n";

blurb("Loading nisse_sp");
load_nisse();

&blurb("sql_sp, nisse_sp");
my($intcol, $smallintcol, $tinyintcol, $bincol, $varbincol,
   $datecol, $smalldatecol, $charcol, $varcharcol, $deccol,
   $numcol, $floatcol, $realcol, $moneycol, $dimecol, $bitcol,
   $tstamp, $textcol, $imagecol);
$intcol       = $tbl{'intcol'};
$smallintcol  = $tbl{'smallintcol'};
$tinyintcol   = $tbl{'tinyintcol'};
$bincol       = $tbl{'bincol'};
$varbincol    = $tbl{'varbincol'};
$datecol      = $tbl{'datecol'};
$smalldatecol = $tbl{'smalldatecol'};
$charcol      = $tbl{'charcol'};
$varcharcol   = $tbl{'varcharcol'};
$deccol       = $tbl{'deccol'};
$numcol       = $tbl{'numcol'};
$floatcol     = $tbl{'floatcol'};
$realcol      = $tbl{'realcol'};
$moneycol     = $tbl{'moneycol'};
$dimecol      = $tbl{'dimecol'};
$bitcol       = $tbl{'bitcol'};
$tstamp       = $tbl{'tstamp'};
$textcol      = $tbl{'textcol'};
$imagecol     = $tbl{'imagecol'};

$sql->{'errInfo'}{retStatOK}{4711}++;

%x = sql_sp("nisse_sp", \$retstat,
            [\$intcol, \$smallintcol, \$tinyintcol, \$bincol],
            {'@varbincol' => \$varbincol,
             '@datecol' => \$datecol,
             '@smalldatecol' => \$smalldatecol,
             '@charcol' => \$charcol,
             '@varcharcol' => \$varcharcol,
             '@deccol' => \$deccol,
             '@numcol' => \$numcol,
             '@floatcol' => \$floatcol,
             '@realcol' => \$realcol,
             '@moneycol' => \$moneycol,
             '@dimecol' => \$dimecol,
             '@bitcol' => \$bitcol,
             '@tstamp' => \$tstamp,
             '@textcol' => $textcol,
             '@imagecol' => $imagecol}, HASH, SINGLEROW);
print "retstat: $retstat\n";
print_data(\%tbl, \%x);
print_data(\%tbl, {'intcol'       => $intcol,
                   'smallintcol'  => $smallintcol,
                   'tinyintcol'   => $tinyintcol,
                   'bincol'       => $bincol,
                   'varbincol'    => $varbincol,
                   'datecol'      => $datecol,
                   'smalldatecol' => $smalldatecol,
                   'charcol'      => $charcol,
                   'varcharcol'   => $varcharcol,
                   'deccol'       => $deccol,
                   'numcol'       => $numcol,
                   'floatcol'     => $floatcol,
                   'realcol'      => $realcol,
                   'moneycol'     => $moneycol,
                   'dimecol'      => $dimecol,
                   'bitcol'       => $bitcol,
                   'tstamp'       => $tstamp,
                   'textcol'      => $textcol,
                   'imagecol'     => $imagecol});

exit;



sub print_data {
    my ($tbl, $x, $isparam) = @_;

    my (%tbl) = %$tbl;
    my (%x)   = %$x;
    my ($key);

    if ($isparam) {
       foreach $key (keys %x) {
          $x{substr($key, 1, length($key))} = $x{$key};
          delete $x{$key};
       }
    }

    if (not exists $x{bitcol}) {
       foreach $key (keys %x) {
          print "$key: $x{$key}   ";
       }
       print "\n";
       return;
    }

printf "intcol:       %-10d  %-10d\n",    $tbl{intcol},       $x{intcol};
printf "smallintcol:  %-10d  %-10d\n", $tbl{smallintcol},  $x{smallintcol};
printf "tinyintcol:   %-10d  %-10d\n", $tbl{tinyintcol},   $x{tinyintcol};
printf "bincol:       %s     %s\n",    $tbl{bincol},       $x{bincol};
printf "varbincol:    %s     %s\n",    $tbl{varbincol},    $x{varbincol};
printf "datecol:      %s     %s\n",    $tbl{datecol},      $x{datecol};
printf "smalldatecol: %s     %s\n",    $tbl{smalldatecol}, $x{smalldatecol};
printf "charcol:      %s     %s!\n",      $tbl{charcol},   $x{charcol};
printf "varcharcol:   %s     %s\n",       $tbl{varcharcol},$x{varcharcol};
printf "deccol:       %-18.6f %-18.6f  %s\n", $tbl{'deccol'},   $x{'deccol'},   $x{'deccol'};
printf "numcol:       %-18.6f %-18.6f  %s\n", $tbl{numcol},   $x{numcol},   $x{numcol};
printf "floatcol:     %-18.6f %-18.6f  %s\n", $tbl{floatcol}, $x{floatcol}, $x{floatcol} ;
printf "realcol:      %-18.6f %-18.6f  %s\n", $tbl{realcol},  $x{realcol},  $x{realcol};
printf "moneycol:     %-18.6f %-18.6f  %s\n", $tbl{moneycol}, $x{moneycol}, $x{moneycol};
printf "dimecol:      %-18.6f %-18.6f  %s\n", $tbl{dimecol},  $x{dimecol},  $x{dimecol};
printf "bitcol:       %d     %d\n",       $tbl{bitcol},       $x{bitcol};
printf "tstamp:              %s\n",                           $x{tstamp};
printf "textcol:      $tbl{textcol}\n";
printf "              $x{textcol}\n";
printf "imagecol:     $tbl{imagecol}\n";
printf "              $x{imagecol}\n";


}

sub load_nisse {
sql(<<'SQLEND');
IF EXISTS (SELECT * FROM sysobjects WHERE name = "nisse_sp")
   DROP PROCEDURE nisse_sp
SQLEND
sql(<<'SQLEND');
CREATE PROCEDURE nisse_sp
 @intcol       int           OUTPUT,
 @smallintcol  smallint      OUTPUT,
 @tinyintcol   int           OUTPUT,
 @bincol       binary(80)    OUTPUT,
 @varbincol    varbinary(80) OUTPUT,
 @datecol      datetime      OUTPUT,
 @smalldatecol smalldatetime OUTPUT,
 @charcol      char(80)      OUTPUT,
 @varcharcol   varchar(80)   OUTPUT,
 @deccol       decimal(18,6) OUTPUT,
 @numcol       numeric(12,2) OUTPUT,
 @floatcol     float         OUTPUT,
 @realcol      real          OUTPUT,
 @moneycol     money         OUTPUT,
 @dimecol      smallmoney    OUTPUT,
 @bitcol       bit           OUTPUT,
 @tstamp       timestamp     OUTPUT,
 @textcol      text,  -- No output for text and image, not meaningful anyway.
 @imagecol     image         AS

DELETE nisse

INSERT nisse (intcol, smallintcol, tinyintcol, bincol, varbincol,
              datecol, smalldatecol, charcol, varcharcol, deccol,
              numcol, floatcol, realcol, moneycol, dimecol, bitcol,
              textcol, imagecol)
   VALUES (@intcol, @smallintcol, @tinyintcol, @bincol, @varbincol,
           @datecol, @smalldatecol, @charcol, @varcharcol, @deccol,
           @numcol, @floatcol, @realcol, @moneycol, @dimecol, @bitcol,
           @textcol, @imagecol)

SELECT
 @intcol = 2 * intcol,
 @smallintcol = 2* smallintcol,
 @tinyintcol = 2 * tinyintcol,
 @bincol = bincol,
 @varbincol = varbincol,
 @datecol = datecol,
 @smalldatecol = smalldatecol,
 @charcol = charcol,
 @varcharcol = varcharcol,
 @deccol = 2 * deccol,
 @numcol = numcol,
 @floatcol = floatcol,
 @realcol = realcol,
 @moneycol = moneycol,
 @dimecol = dimecol,
 @bitcol = bitcol,
 @tstamp = tstamp
FROM nisse

SELECT * FROM nisse

RETURN 4711
SQLEND

}