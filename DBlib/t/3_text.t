#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/t/3_text.t 1     99-01-30 16:56 Sommar $
#
# Test suite for text/image routines.
#
# $History: 3_text.t $
# 
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 16:56
# Created in $/Perl/MSSQL/DBlib/t
#
#---------------------------------------------------------------------

use strict;
use MSSQL::Sqllib;
use File::Basename qw(dirname);

$^W = 1;
$| = 1;

use vars qw($Srv $Uid $Pwd);
require &dirname($0) . '\sqllogin.pl';

my ($d, $d2, @data, $x, $text);

print "1..2\n";

$d  = sql_init($Srv, $Uid, $Pwd, "tempdb");
$d2 = sql_init($Srv, $Uid, $Pwd, "tempdb");

# Create a table.
$d->sql("CREATE TABLE ##text_table (t_index int, the_text text)");

# Write a column it.
$d->sql ('INSERT INTO ##text_table (t_index, the_text) VALUES (5,"")');

# To use writetext, we must make the row current with the main handle.
$d->dbcmd('SELECT the_text, t_index FROM ##text_table WHERE t_index = 5');
$d->dbsqlexec;
$d->dbresults;
$d->dbnextrow;

$text = "I repeat myself when under stress" x 20;

# Add the text.
$d2->dbwritetext ("##text_table.the_text", $d, 1, $text)
  and print "ok 1\n" or print "not ok 1\n";

# If don't send in a new query on the main handle, we get "results pending".
$d->dbcancel;

@data = $d->sql('SELECT t_index, the_text FROM ##text_table WHERE t_index = 5',
                 MSSQL::Sqllib::LIST);
($data[0][1] eq $text) and print "ok 2\n" or print "not ok 2\n";

$d->dbclose;
$d2->dbclose;
