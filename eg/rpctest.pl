#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/eg/rpctest.pl 2     99-01-30 16:44 Sommar $
#
# $History: rpctest.pl $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:44
# Updated in $/Perl/MSSQL/eg
# Output @charcol in uppercase.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 98-01-19   Time: 22:28
# Created in $/Perl/MSSQL/eg
#---------------------------------------------------------------------
use strict qw(vars subs);

my($stat, $X, %tbl, %result, $col, %x);

use MSSQL::DBlib;
use MSSQL::DBlib::Const::Datatypes;
use MSSQL::DBlib::Const::General;
use MSSQL::DBlib::Const::RPC;

# You may want to add a password.
$X = MSSQL::DBlib->dblogin("sa");
$X->dbuse("tempdb");

# This creates the table and stored procedure we're using.
create_table_and_sp($X);

# These are the values we send in. We're only using a hash to make
# printing of the results easier.
%tbl = (intcol        =>   47114711,
        smallintcol   =>   4711,
        tinyintcol    =>   253,
        bincol        =>   "47111267ABCD47111267ABCD",
        varbincol     =>   "0xABCD4711",
        datecol       =>   "21010501 13:27:30:050",
        smalldatecol  =>   "5 Apr 1960 15:15",
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


# Initiate the operations.
$stat = $X->dbrpcinit("nisse_sp", DBRPCRESET);

# Send in all parameters.
$stat = $X->dbrpcparam('@intcol', 1, SQLINT4, -1, -1, $tbl{intcol});
$stat = $X->dbrpcparam('@smallintcol', 1, SQLINT2, -1, -1, $tbl{smallintcol});
$stat = $X->dbrpcparam('@tinyintcol', 1, SQLINT1, -1, -1, $tbl{tinyintcol});
$stat = $X->dbrpcparam('@bincol', 1, SQLBINARY, -1,
                       length($tbl{bincol}), $tbl{bincol});
$stat = $X->dbrpcparam('@varbincol', 1, SQLVARBINARY, -1,
                       length($tbl{varbincol}), $tbl{varbincol});
$stat = $X->dbrpcparam('@datecol', 1, SQLDATETIME, -1,
                       length($tbl{datecol}), $tbl{datecol});
$stat = $X->dbrpcparam('@smalldatecol', 1, SQLDATETIM4, -1,
                       -1, $tbl{smalldatecol});
$stat = $X->dbrpcparam('@charcol', 1, SQLCHAR, -1,
                       length($tbl{charcol}), $tbl{charcol});
$stat = $X->dbrpcparam('@varcharcol', 1, SQLVARCHAR, -1,
                       length($tbl{varcharcol}), $tbl{varcharcol});
$stat = $X->dbrpcparam('@deccol', 1, SQLDECIMAL, -1, -1, $tbl{deccol});
$stat = $X->dbrpcparam('@numcol', 1, SQLNUMERIC, -1, -1, $tbl{numcol});
$stat = $X->dbrpcparam('@floatcol', 1, SQLFLT8, -1, -1, $tbl{floatcol});
$stat = $X->dbrpcparam('@realcol', 1, SQLFLT4, -1, -1, $tbl{realcol});
$stat = $X->dbrpcparam('@moneycol', 1, SQLMONEY, -1, -1, $tbl{moneycol});
$stat = $X->dbrpcparam('@dimecol', 1, SQLMONEY4, -1, -1, $tbl{dimecol});
$stat = $X->dbrpcparam('@bitcol', 1, SQLBIT, -1, -1, $tbl{bitcol});
$stat = $X->dbrpcparam('@tstamp', 1, SQLVARBINARY, -1, 0, undef);
# Text and image are not output, as this kills the server process.
$stat = $X->dbrpcparam('@textcol', 0, SQLTEXT, 2000,
                       length($tbl{textcol}), $tbl{textcol});
$stat = $X->dbrpcparam('@imagecol', 0, SQLIMAGE, -1,
                       length($tbl{imagecol}), $tbl{imagecol});

# And now, send the command.
$stat = $X->dbrpcsend();

# Get the result set.
while (($stat = $X->dbresults) != NO_MORE_RESULTS) {
   die "dbresults failed\n" if $stat == FAIL;
   while (%result = $X->dbnextrow(1)) {
      print_data (\%tbl, \%result, 0);
      print "\n";
   }

   # And the the output parameters
   %result = $X->dbretdata(1);
   print_data (\%tbl, \%result, 1);
   print "\n";
   print "Returned: ", $X->dbretstatus(), "\n";
}

exit;

# This is a procedure that prints the data we got back from SQL Server
# in parallel with the original values.
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
printf "deccol:       %-18.6f %-18.6f  %s\n", $tbl{deccol},   $x{deccol},   $x{deccol};
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

# Create the table nisse and the procedure nisse_sp.
sub create_table_and_sp {
   my ($X) = @_;

$X->dbcmd(<<SQLEND);
IF EXISTS (SELECT *
           FROM   sysobjects
           WHERE  name = "nisse"
             AND  uid  = user_id()
             AND  type = "U")
   DROP TABLE nisse
IF EXISTS (SELECT * FROM sysobjects WHERE name = "nisse_sp")
   DROP PROCEDURE nisse_sp
SQLEND
$X->dbsqlexec; $X->dbcancel;

$X->dbcmd(<<SQLEND);
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
$X->dbsqlexec; $X->dbcancel;

$X->dbcmd(<<'SQLEND');
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
 @charcol = upper(nullif(charcol, ' ')),
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
$X->dbsqlexec; $X->dbcancel;
}


