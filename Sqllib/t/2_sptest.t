#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/Sqllib/t/2_sptest.t 3     00-07-24 22:10 Sommar $
#
# This test script tests using sql_sp and sql_insert in all possible
# ways and with testing use of all datatypes.
#
# $History: 2_sptest.t $
# 
# *****************  Version 3  *****************
# User: Sommar       Date: 00-07-24   Time: 22:10
# Updated in $/Perl/MSSQL/Sqllib/t
# Changed nullif argument for bincol due to bug(?) in SQL 2000 Beta 2.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 00-05-08   Time: 22:23
# Updated in $/Perl/MSSQL/Sqllib/t
# Enhanced test for text and image to use really big stuff.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 16:36
# Created in $/Perl/MSSQL/sqllib/t
#---------------------------------------------------------------------

use strict;

use vars qw(@tblcols @testres %tbl %expectpar %expectcol %test %comment);

sub blurb{
    push(@testres, "------ Testing @_ ------");
    print "------ Testing @_ ------\n";
}

use MSSQL::Sqllib qw(:DEFAULT :consts);
use MSSQL::DBlib::Const::Options qw(DBTEXTSIZE DBTEXTLIMIT);
use Filehandle;
use File::Basename qw(dirname);

sub create_table {
   sql(<<SQLEND);
      CREATE TABLE #nisse (intcol       int           NULL,
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

   @tblcols = ('intcol', 'smallintcol', 'tinyintcol', 'bincol', 'varbincol',
               'datecol', 'smalldatecol', 'charcol', 'varcharcol',
               'deccol', 'numcol', 'floatcol', 'realcol', 'moneycol',
               'dimecol', 'bitcol', 'tstamp', 'textcol', 'imagecol');
}


sub create_sp {
   sql(<<'SQLEND');
   CREATE PROCEDURE #nisse_sp
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
                   -- No output for text and image, not meaningful anyway.
                   @textcol      text,
                   @imagecol     image         AS

   DELETE #nisse

   INSERT #nisse (intcol, smallintcol, tinyintcol, bincol, varbincol,
                  datecol, smalldatecol, charcol, varcharcol,
                  deccol, numcol, floatcol, realcol, moneycol,
                  dimecol, bitcol, textcol, imagecol)
      SELECT  @intcol, @smallintcol, @tinyintcol, isnull(@bincol, 0), @varbincol,
              @datecol, @smalldatecol, isnull(@charcol, ' '), @varcharcol,
              isnull(@deccol, 0), isnull(@numcol, 0), @floatcol, @realcol,
              @moneycol, @dimecol, isnull(@bitcol, 0), @textcol, @imagecol

   SELECT @intcol       = 2 * intcol,
          @smallintcol  = 2 * smallintcol,
          @tinyintcol   = 2 * tinyintcol,
          @bincol       = nullif(bincol, 0x0),
          @varbincol    = varbincol,
          @datecol      = dateadd(dd, 3, datecol),
          @smalldatecol = dateadd(dd, 2, smalldatecol),
          @charcol      = upper(nullif(charcol, ' ')),
          @varcharcol   = upper(varcharcol),
          @deccol       = 2 * nullif(deccol, 0),
          @numcol       = 2 * nullif(numcol, 0),
          @floatcol     = 2 * floatcol,
          @realcol      = 2 * realcol,
          @moneycol     = 2 * moneycol,
          @dimecol      = dimecol / 2,
          @bitcol       = 1 - bitcol,
          @tstamp       = tstamp
   FROM   #nisse

   SELECT intcol, smallintcol, tinyintcol, bincol = nullif(bincol, 0x0),
          varbincol, datecol, smalldatecol, charcol = nullif(charcol, ' '),
          varcharcol, deccol = nullif(deccol, 0), numcol = nullif(numcol, 0),
          floatcol, realcol, moneycol, dimecol, bitcol, tstamp,
          textcol, imagecol
   FROM   #nisse

   RETURN 4711
SQLEND

sql (<<SQLEND);
   CREATE PROCEDURE #pelle_sp AS
      SELECT 4711
SQLEND
}


sub check_data {
   my ($result, $params, $retstat) = @_;

   my ($ix, $col, $valref, $resulttest, $paramtest);

   foreach $ix (0..$#tblcols) {
      $col = $tblcols[$ix];

      if (ref $params) {
         if (ref $params eq "ARRAY") {
            $valref = (ref $$params[$ix] ? $$params[$ix] : \$$params[$ix]);
         }
         else {
            my $par = '@' . $col;
            $valref = (ref $$params{$par} ? $$params{$par} : \$$params{$par});
         }
      }
      else {
         $valref = undef;
      }

      $resulttest = sprintf($test{$col}, '$$result{$col}', '$expectcol{$col}');
      $paramtest  = sprintf($test{$col}, '$$valref', '$expectpar{$col}');

      push(@testres,
           eval($resulttest) ? "ok %d" :
           "not ok %d\n-- result '$col': <$$result{$col}>, expected: <$expectcol{$col}>" .
           "   $comment{$col} $@");
      if ($params and exists $expectpar{$col}) {
         push(@testres,
              eval($paramtest) ? "ok %d" :
              "not ok %d\n-- param '$col': <$$valref>, expected: <$expectpar{$col}>  " .
              "    $comment{$col}");
      }
   }

   if (defined $retstat) {
      push (@testres, $retstat == 4711 ? "ok %d" : "not ok %d\n--Incorrect retstat");
   }
}


sub do_tests {

   my ($result, $retstat, @params, %params, @paramrefs, %paramrefs,
       @copy1, @copy2, $col);

   # Fill up parameter arrays. As the arrays are changed on each test,
   # fill up copies to refresh with as well.
   foreach $col (@tblcols) {
       if (defined $tbl{$col}) {
          push(@params, $tbl{$col});
          $params{'@' . $col} = $tbl{$col};
          push(@copy1, $tbl{$col});
          push(@copy2, $tbl{$col});
       }
       else {
          push(@params, undef);
          $params{'@' . $col} = undef;
          push(@copy1, undef);
          push(@copy2, undef);
       }
       push(@paramrefs,\$copy1[$#copy1]);
       $paramrefs{'@' . $col}    = \$copy2[$#copy2];
   }

   # Run test for combination.
   blurb("sql_sp unnamed params, no refs");
   $result = sql_sp("#nisse_sp", \$retstat, \@params, HASH, SINGLEROW);
   check_data($result, \@params, $retstat);

   blurb("sql_sp named params, no refs");
   $result = sql_sp("#nisse_sp", \%params, HASH, SINGLEROW);
   check_data($result, \%params, $retstat);

   blurb("sql_sp unnamed params, refs");
   $result = sql_sp("#nisse_sp", \$retstat, \@paramrefs, HASH, SINGLEROW);
   check_data($result, \@paramrefs, $retstat);

   blurb("sql_sp named params, refs");
   $result = sql_sp("#nisse_sp", \%paramrefs, HASH, SINGLEROW);
   check_data($result, \%paramrefs, $retstat);

   # Also test sql_insert.
   blurb("sql_insert");
   sql("TRUNCATE TABLE #nisse");
   sql_insert("#nisse", \%tbl);
   check_data($result, 0);


   # Finally test parameterless SP.
   blurb("parameterless SP");
   undef $result;
   $result = sql_sp('#pelle_sp', SCALAR, SINGLEROW);
   push(@testres, ($result == 4711 ? "ok %d" : "not ok %d"));
}



$^W = 1;

$| = 1;

my($sql, $line);

use vars qw($Srv $Uid $Pwd);
require &dirname($0) . '\sqllogin.pl';
$sql = sql_init($Srv, $Uid, $Pwd, "tempdb");


$sql->{'errInfo'}{retStatOK}{4711}++;
$sql->{'errInfo'}{noWhine}++;

$sql->dbsetopt(MSSQL::DBlib::Const::Options::DBTEXTSIZE,  "2000000000");
$sql->dbsetopt(MSSQL::DBlib::Const::Options::DBTEXTLIMIT, "2000000000");

create_table;
create_sp;


%tbl = (intcol        =>   47114711,
        smallintcol   =>   -4711,
        tinyintcol    =>   111,
        bincol        =>   "0x47111267ABCD47111267ABCD",
        varbincol     =>   "0xABCD4711",
        datecol       =>   "21010501 13:27:30.050",
        smalldatecol  =>   "Apr 5 1960 15:15",
        charcol       =>   "char coal",
        varcharcol    =>   "La vie en rose",
        deccol        =>   123456789.456789,
        numcol        =>   123456789.456789,
        floatcol      =>   123456789.456789,
        realcol       =>   123456789.456789,
        moneycol      =>   123456789.456789,
        dimecol       =>   123456.456789,
        bitcol        =>   1,
        tstamp        =>   undef,
        textcol       =>   "Hello world!" x 10000,
        imagecol      =>   "0x" . "47119600" x 10000);

%expectcol =
       (intcol        =>   $tbl{intcol},
        smallintcol   =>   $tbl{smallintcol},
        tinyintcol    =>   $tbl{tinyintcol},
        bincol        =>   substr("\L$tbl{bincol}\E", 2) .
                           '0' x (160 - (length($tbl{bincol}) - 2)),
        varbincol     =>   substr("\L$tbl{varbincol}\E", 2),
        datecol       =>   $tbl{datecol},
        smalldatecol  =>   "19600405 15:15",
        charcol       =>   $tbl{charcol} . ' ' x (80 - length($tbl{charcol})),
        varcharcol    =>   $tbl{varcharcol},
        deccol        =>   sprintf("%1.6f", $tbl{deccol}),
        numcol        =>   sprintf("%1.2f", $tbl{numcol}),
        floatcol      =>   sprintf("%1.6f", $tbl{floatcol}),
        realcol       =>   $tbl{realcol},
        moneycol      =>   sprintf("%1.4f", $tbl{moneycol}),
        dimecol       =>   sprintf("%1.4f", $tbl{dimecol}),
        bitcol        =>   $tbl{bitcol},
        tstamp        =>   "*",
        textcol       =>   $tbl{textcol},
        imagecol      =>   pack("H*", substr($tbl{imagecol}, 2)));

%expectpar =
       (intcol        =>   2 * $tbl{intcol},
        smallintcol   =>   2* $tbl{smallintcol},
        tinyintcol    =>   2* $tbl{tinyintcol},
        bincol        =>   substr("\L$tbl{bincol}\E", 2) . '(' .
                           '0' x (160 - (length($tbl{bincol}) - 2)) . ')?',
        varbincol     =>   substr("\L$tbl{varbincol}\E", 2),
        datecol       =>   "21010504 13:27:30.050",
        smalldatecol  =>   "19600407 15:15",
        charcol       =>   "\U$tbl{charcol}\E(" . ' ' x (80 - length($tbl{charcol})) . ')?',
        varcharcol    =>   $tbl{varcharcol},
        deccol        =>   sprintf("%1.6f", 2 * sprintf("%1.6f", $tbl{deccol})),
        numcol        =>   sprintf("%1.2f", 2 * sprintf("%1.2f", $tbl{numcol})),
        floatcol      =>   sprintf("%1.6f", 2 * $tbl{floatcol}),
        realcol       =>   2 * $tbl{realcol},
        moneycol      =>   sprintf("%1.4f", 2 * sprintf("%1.4f", $tbl{moneycol})),
        dimecol       =>   sprintf("%1.4f", 0.5 * sprintf("%1.4f", $tbl{dimecol})),
        bitcol        =>   1 - $tbl{bitcol},
        tstamp        =>   "*");
$expectpar{varcharcol} =~ tr/a-zåäö/A-ZÅÄÖ/;

%test = (intcol        =>   '%s == %s',
         smallintcol   =>   '%s == %s',
         tinyintcol    =>   '%s == %s',
         bincol        =>   '%s =~ /^%s$/',
         varbincol     =>   '%s eq %s',
         datecol       =>   '%s eq %s',
         smalldatecol  =>   '%s =~ /^%s/',
         charcol       =>   '%s =~ /^%s$/',
         varcharcol    =>   '%s eq %s',
         deccol        =>   'sprintf("%%1.6f", %s) eq %s',
         numcol        =>   'sprintf("%%1.2f", %s) eq %s',
         floatcol      =>   'sprintf("%%1.6f", %s) eq %s',
         realcol       =>   'abs(%s - %s) < 10',
         moneycol      =>   'sprintf("%%1.4f", %s) eq %s',
         dimecol       =>   'sprintf("%%1.4f", %s) eq %s',
         bitcol        =>   '%s == %s',
         tstamp        =>   'defined %s',
         textcol       =>   '%s eq %s',
         imagecol      =>   '%s eq %s');

%comment =
        (intcol        =>   "",
         smallintcol   =>   "",
         tinyintcol    =>   "",
         bincol        =>   "",
         varbincol     =>   "",
         datecol       =>   "",
         smalldatecol  =>   "May fail if server language is not English",
         charcol       =>   "",
         varcharcol    =>   "",
         deccol        =>   "May fail due to rounding errors",
         numcol        =>   "May fail due to rounding errors",
         floatcol      =>   "May fail due to rounding errors",
         realcol       =>   "May fail due to rounding errors",
         moneycol      =>   "May fail due to rounding errors",
         dimecol       =>   "May fail due to rounding errors",
         bitcol        =>   "",
         tstamp        =>   "",
         textcol       =>   "",
         imagecol      =>   "");



do_tests();

&blurb("DA CAPO! NOW WITH TEST OF NULLS!");

# Next set of tests is mainly to test null values, but we also test two fairly
# weird MSSQL::DBlib flags in their non-normal position.
$sql->{dbKeepNumeric} = 0;
$sql->{dbBin0x}       = 1;

# Redo the tests, now will as many null values we can have.
%tbl = (intcol        =>   undef,
        smallintcol   =>   undef,
        tinyintcol    =>   112,
        bincol        =>   "47111267ABCD47111267ABCD",
        varbincol     =>   undef,
        datecol       =>   undef,
        smalldatecol  =>   undef,
        charcol       =>   "char coal",
        varcharcol    =>   undef,
        deccol        =>   123456789.456789,
        numcol        =>   123456789.456789,
        floatcol      =>   undef,
        realcol       =>   undef,
        moneycol      =>   undef,
        dimecol       =>   undef,
        bitcol        =>   1,
        tstamp        =>   undef,
        textcol       =>   undef,
        imagecol      =>   undef);

%expectcol =
       (intcol        =>   undef,,
        smallintcol   =>   undef,
        tinyintcol    =>   "112",
        bincol        =>   "0x" . "\L$tbl{bincol}\E" .
                           '0' x (160 - (length($tbl{bincol}))),
        varbincol     =>   undef,
        datecol       =>   undef,
        smalldatecol  =>   undef,
        charcol       =>   $tbl{charcol} . ' ' x (80 - length($tbl{charcol})),
        varcharcol    =>   undef,
        deccol        =>   sprintf("%1.6f", $tbl{deccol}),
        numcol        =>   sprintf("%1.2f", $tbl{numcol}),
        floatcol      =>   undef,
        realcol       =>   undef,
        moneycol      =>   undef,
        dimecol       =>   undef,
        bitcol        =>   $tbl{bitcol},
        tstamp        =>   "*",
        textcol       =>   undef,
        imagecol      =>   undef);

%expectpar =
       (intcol        =>   undef,
        smallintcol   =>   undef,
        tinyintcol    =>   "224",
        bincol        =>   "0x" . "\L$tbl{bincol}\E(" .
                           '0' x (160 - (length($tbl{bincol}))) . ')?',
        varbincol     =>   undef,
        datecol       =>   undef,
        smalldatecol  =>   undef,
        charcol       =>   "\U$tbl{charcol}\E(" . ' ' x (80 - length($tbl{charcol})) . ')?',
        varcharcol    =>   undef,
        deccol        =>   sprintf("%1.6f", 2 * sprintf("%1.6f", $tbl{deccol})),
        numcol        =>   sprintf("%1.2f", 2 * sprintf("%1.2f", $tbl{numcol})),
        floatcol      =>   undef,
        realcol       =>   undef,
        moneycol      =>   undef,
        dimecol       =>   undef,
        bitcol        =>   1 - $tbl{bitcol},
        tstamp        =>   "*");

%test = (intcol        =>   'not defined %s',
         smallintcol   =>   'not defined %s',
         tinyintcol    =>   '%s eq %s',
         bincol        =>   '%s =~ /^%s$/',
         varbincol     =>   'not defined %s',
         datecol       =>   'not defined %s',
         smalldatecol  =>   'not defined %s',
         charcol       =>   '%s =~ /^%s$/',
         varcharcol    =>   'not defined %s',
         deccol        =>   '%s =~ /^%s0*$/',
         numcol        =>   '%s =~ /^%s0*$/',
         floatcol      =>   'not defined %s',
         realcol       =>   'not defined %s',
         moneycol      =>   'not defined %s',
         dimecol       =>   'not defined %s',
         bitcol        =>   '%s == %s',
         tstamp        =>   'defined %s',
         textcol       =>   'not defined %s',
         imagecol      =>   'not defined %s');

%comment =
        (intcol        =>   "",
         smallintcol   =>   "",
         tinyintcol    =>   "",
         bincol        =>   "",
         varbincol     =>   "",
         datecol       =>   "",
         smalldatecol  =>   "",
         charcol       =>   "",
         varcharcol    =>   "",
         deccol        =>   "May fail due to rounding errors",
         numcol        =>   "May fail due to rounding errors",
         floatcol      =>   "",
         realcol       =>   "",
         moneycol      =>   "",
         dimecol       =>   "",
         bitcol        =>   "",
         tstamp        =>   "",
         textcol       =>   "",
         imagecol      =>   "");

do_tests();


my $no_of_test = 2* (scalar(@tblcols) * 9 - 4*2 + 4 + 1);

print "1..$no_of_test\n";

my $no = 1;
foreach $line (@testres) {
   printf "$line\n", $no;
   $no++ if $line =~ /^(not )?ok/;
}


