#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/eg/bcp.pl 2     99-01-30 16:40 Sommar $
#
# $History: bcp.pl $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:40
# Updated in $/Perl/MSSQL/eg
# Suprefluous declartion of @data removed.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 98-01-19   Time: 22:28
# Created in $/Perl/MSSQL/eg
#---------------------------------------------------------------------
use strict qw(vars subs);

use MSSQL::DBlib;
use MSSQL::Sqllib;
use MSSQL::DBlib::Const::BCP;
use MSSQL::DBlib::Const::General;

my($X, @dat, @data, $count, $stat, $data, $ret);

BCP_SETL(1);

$X = sql_init("", "sa", "", "tempdb");
$X->sql(<<SQLEND);
IF EXISTS (SELECT * FROM sysobjects WHERE name = "bcp_test")
   DROP TABLE bcp_test
SQLEND
$X->sql("CREATE TABLE bcp_test(one char(10), two char(10))");

$X->bcp_init("bcp_test", undef, "bcp.err", DB_IN);
$X->bcp_meminit(2);
open(FILE, "bcp.dat") || die "Can't open bcp.dat: $!\n";

while(<FILE>)
{
    chop;
    @dat = split(' ');

    print "@dat\n";

    $stat = $X->bcp_sendrow(@dat);
    die "bcp_sendrow failed!\n" if $stat == FAIL;

    ++$count;

    if (($count % 5) == 0) {
        $ret = $X->bcp_batch;
        print "Sent $ret rows to the server\n";
    }
}

$ret = $X->bcp_done;
print "$ret rows returned by bcp_done\n";

$MSSQL::Sqllib::SQLSEP = '@!@';
@data = sql("SELECT * FROM bcp_test", MSSQL::Sqllib::SCALAR);
foreach $data (@data) {
   print "$data\n";
}
