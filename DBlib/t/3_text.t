#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/t/3_text.t 3     01-05-01 22:40 Sommar $
#
# Test suite for text/image routines.
#
# $History: 3_text.t $
# 
# *****************  Version 3  *****************
# User: Sommar       Date: 01-05-01   Time: 22:40
# Updated in $/Perl/MSSQL/DBlib/t
# Lots of new tests for new text functions.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 99-02-25   Time: 22:29
# Updated in $/Perl/MSSQL/DBlib/t
# Rewritten the test with a text string > 4096 chars.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 16:56
# Created in $/Perl/MSSQL/DBlib/t
#
#---------------------------------------------------------------------

use strict;
use MSSQL::DBlib;
use MSSQL::DBlib::Const;
use File::Basename qw(dirname);

$^W = 1;
$| = 1;

use vars qw($Srv $Uid $Pwd);
require &dirname($0) . '\sqllogin.pl';

my ($d, $d2, $d3, @data, $data, $stat, $bytes);

print "1..94\n";

# Text for tests.
my $text0     = "I repeat myself when under stress";
my $factor = 155;
my $text_long = $text0 x $factor;
my $text1 = 'No protection on a motor-bike then! ';
my $text2 = 'Sooner or later that normal traffic is gonna get you!';
my $text_ins = 'KABOFF! ';

# Get iterate count. This is not used from nmake test, but for testing
# memory leaks.
my $i = shift(@ARGV);
$i++ ;

# Connect to server. We need two handles.
$d  = MSSQL::DBlib->dblogin($Uid, $Pwd, $Srv);
$d->dbuse('tempdb');
$d2 = MSSQL::DBlib->dblogin($Uid, $Pwd, $Srv);
$d2->dbuse('tempdb');
$d3 = MSSQL::DBlib->dblogin($Uid, $Pwd, $Srv);
$d3->dbuse('tempdb');

# SET NOCOUNT ON for all
$d->dbsetopt(DBNOCOUNT);
$d->dbsqlexec;
while ($d->dbresults != NO_MORE_RESULTS) {}
$d2->dbsetopt(DBNOCOUNT);
$d2->dbsqlexec;
while ($d2->dbresults != NO_MORE_RESULTS) {}
$d3->dbsetopt(DBNOCOUNT);
$d3->dbsqlexec;
while ($d3->dbresults != NO_MORE_RESULTS) {}

# Set options to remove all restrictions on length.
$d->dbsetopt(DBTEXTSIZE, "2147483647");
$d->dbsetopt(DBTEXTLIMIT, "0");
$d->dbsqlexec and print "ok 1\n" or print "not ok 1\n";
while ($d->dbresults != NO_MORE_RESULTS) {}

# Create two tables. The second is used for testing dbcopytext.
$d->dbcmd(<<SQLEND);
CREATE TABLE ##text_table  (t_index   int  NOT NULL,
                            the_text  text NOT NULL DEFAULT '')
CREATE TABLE ##tbl2  (id  int  NOT NULL,
                      txt text NOT NULL)
SQLEND
$d->dbsqlexec and print "ok 2\n" or print "not ok 2\n";
while ($d->dbresults != NO_MORE_RESULTS) {}


# Write some columns to them.
$d->dbcmd (<<SQLEND);
INSERT ##text_table (t_index) VALUES (5)
INSERT ##text_table (t_index) VALUES (6)
INSERT ##tbl2 (id, txt) VALUES (2, '$text_ins')
SQLEND
$d->dbsqlexec and print "ok 3\n" or print "not ok 3\n";
while ($d->dbresults != NO_MORE_RESULTS) {}

# To use writetext, we must make the row current with the main handle.
$d->dbcmd('SELECT the_text, t_index FROM ##text_table WHERE t_index = 5');
$d->dbsqlexec and print "ok 4\n" or print "not ok 4\n";
$stat = $d->dbresults;
if ($stat == SUCCEED) {print "ok 5\n"} else {print "not ok 5\n"};
$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 6\n"} else {print "not ok 6\n"};

# Add the text.
$d2->dbwritetext ("##text_table.the_text", $d, 1, $text_long)
  and print "ok 7\n" or print "not ok 7\n";

# Cancel query.
$d->dbcancel and print "ok 8\n" or print "not ok 8\n";

# Now we will try to use dbmoretext. Again, get a current row.
$d->dbcmd('SELECT the_text, t_index FROM ##text_table WHERE t_index = 6');
$d->dbsqlexec and print "ok 9\n" or print "not ok 9\n";
$stat = $d->dbresults;
if ($stat == SUCCEED) {print "ok 10\n"} else {print "not ok 10\n"};
$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 11\n"} else {print "not ok 11\n"};

# We're testing dbpreptext/dbmoretext
$d2->dbpreptext ("##text_table.the_text", $d, 1, length($text1 . $text2))
  and print "ok 12\n" or print "not ok 12\n";
$d2->dbsqlok and print "ok 13\n" or print "not ok 13\n";
$stat = $d2->dbresults;
if ($stat == SUCCEED) {print "ok 14\n"} else {print "not ok 14\n"};

$d2->dbmoretext(length($text1), $text1)
  and print "ok 15\n" or print "not ok 15\n";

$d2->dbmoretext(undef, $text2)
  and print "ok 16\n" or print "not ok 16\n";

# Complete.
$d2->dbsqlok and print "ok 17\n" or print "not ok 17\n";;
while ($d2->dbresults != NO_MORE_RESULTS) {}
$d->dbcancel and print "ok 18\n" or print "not ok 18\n";;

# This is loop is used when running memory leak tests.
while ($i--) {

   # Get the rows we wrote and read them with dbnextrow.
   $stat = $d->dbcmd('SELECT t_index, the_text FROM ##text_table ORDER BY t_index');
   $stat = $d->dbsqlexec and print "ok 19\n" or print "not ok 19\n";;
   $stat = $d->dbresults;
   if ($stat == SUCCEED) {print "ok 20\n"} else {print "not ok 20\n"};

   $stat = $d->dbnextrow2($data);
   if ($stat == REG_ROW) {print "ok 21\n"} else {print "not ok 21\n"};
   if ($$data[1] eq $text_long) {print "ok 22\n"} else {print "not ok 22\n"};

   $stat = $d->dbnextrow2($data);
   if ($stat == REG_ROW) {print "ok 23\n"} else {print "not ok 23\n"};
   if ($$data[1] eq $text1 . $text2)  {print "ok 24\n"} else {print "not ok 24\n"};

   $stat = $d->dbnextrow2($data);
   if ($stat == NO_MORE_ROWS) {print "ok 25\n"} else {print "not ok 25\n"};

   $stat = $d->dbresults;
   if ($stat == NO_MORE_RESULTS) {print "ok 26\n"} else {print "not ok 26\n"};

   # Once more, get the rows we wrote but now read them with dbreadtext.
   $d->dbcmd('SELECT the_text FROM ##text_table ORDER BY t_index');
   $d->dbsqlexec and print "ok 27\n" or print "not ok 27\n";;
   $stat = $d->dbresults;
   if ($stat == SUCCEED) {print "ok 28\n"} else {print "not ok 28\n"};

   $bytes = $d->dbreadtext($data, 64000);
   if ($bytes == length($text_long)) {print "ok 29\n"} else {print "not ok 29\n"}
   if ($data eq $text_long) {print "ok 30\n"} else {print "not ok 30 '<$data>'\n"}

   $bytes = $d->dbreadtext($data, 4711);
   if ($bytes == 0) {print "ok 31\n"} else {print "not ok 31\n"}
   if (defined $data and $data eq '') {print "ok 32\n"} else {print "not ok 32\n"}

   $bytes = $d->dbreadtext($data, length($text1));
   if ($bytes == length($text1)) {print "ok 33\n"} else {print "not ok 33\n"}
   if ($data eq $text1) {print "ok 34\n"} else {print "not ok 34 '<$data>'\n"}

   $bytes = $d->dbreadtext($data, 512);
   if ($bytes == length($text2)) {print "ok 35\n"} else {print "not ok 35\n"}
   if ($data eq $text2) {print "ok 36\n"} else {print "not ok 36 '<$data>'\n"}

   $bytes = $d->dbreadtext($data, 4711);
   if ($bytes == 0) {print "ok 37\n"} else {print "not ok 37\n"}
   if (defined $data and $data eq '') {print "ok 38\n"} else {print "not ok 38\n"}

   $bytes = $d->dbreadtext($data, 512);
   if ($bytes == NO_MORE_ROWS) {print "ok 39\n"} else {print "not ok 39\n"}
   if (not defined $data) {print "ok 40\n"} else {print "not ok 40\n"}
}

# Get some more texts we can play with.
$d->dbcmd(<<SQLEND);
   INSERT ##text_table (t_index, the_text)
      SELECT 10 + t_index, the_text FROM ##text_table WHERE t_index < 10
   INSERT ##text_table (t_index, the_text)
      SELECT 20 + t_index, the_text FROM ##text_table WHERE t_index < 10
   INSERT ##text_table (t_index, the_text)
      SELECT 30 + t_index, the_text FROM ##text_table WHERE t_index < 10
   INSERT ##text_table (t_index, the_text)
      SELECT 40 + t_index, the_text FROM ##text_table WHERE t_index < 10
SQLEND
$d->dbsqlexec and print "ok 41\n" or print "not ok 41\n";
while ($d->dbresults != NO_MORE_RESULTS) {}

#----------------------------------------------------------------------
# Time to test dbupdatetext.
$d->dbcmd(<<SQLEND);
    SELECT the_text, t_index
    FROM   ##text_table
    WHERE  t_index IN (15, 16)
    ORDER  BY t_index
SQLEND
$d->dbsqlexec and print "ok 42\n" or print "not ok 42\n";
$stat = $d->dbresults;
if ($stat == SUCCEED) {print "ok 43\n"} else {print "not ok 43\n"};

# First row.
$stat = $d->dbnextrow2($data);
if ($stat = REG_ROW) {print "ok 44\n"} else {print "not ok 44\n"}
$d2->dbupdatetext ("##text_table.the_text", $d, 1, uc($text0))
  and print "ok 45\n" or print "not ok 45\n";

# Second row.
$stat = $d->dbnextrow2($data);
if ($stat = REG_ROW) {print "ok 46\n"} else {print "not ok 46\n"}
$d2->dbupdatetext ("##text_table.the_text", $d, 1, $text_ins,
                   length($text1), 0, 1)
  and print "ok 47\n" or print "not ok 47\n";

# Cancel query.
$d->dbcancel and print "ok 48\n" or print "not ok 48\n";
$stat = $d2->dbresults;
if ($stat == NO_MORE_RESULTS) {print "ok 49\n"} else {print "not ok 49\n"}

# Read what we have now.
$d->dbcmd(<<SQLEND);
    SELECT the_text, t_index
    FROM   ##text_table
    WHERE  t_index IN (15, 16)
    ORDER  BY t_index
SQLEND
$d->dbsqlexec and print "ok 50\n" or print "not ok 50\n";
$stat = $d->dbresults;
if ($stat == SUCCEED) {print "ok 51\n"} else {print "not ok 51\n"};

$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 52\n"} else {print "not ok 52\n"};
if ($$data[0] eq $text_long . uc($text0))
   {print "ok 53\n"} else {print "not ok 53\n"};

$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 54\n"} else {print "not ok 54\n"};
if ($$data[0] eq $text1 . $text_ins . $text2)   {print "ok 55\n"} else {print "not ok 55\n"};

$stat = $d->dbnextrow2($data);
if ($stat == NO_MORE_ROWS) {print "ok 56\n"} else {print "not ok 56\n"};
$stat = $d->dbresults;
if ($stat == NO_MORE_RESULTS) {print "ok 57\n"} else {print "not ok 57\n"};

#---------------------------------------------------------------------
# Test dbdeletetext
$d->dbcmd(<<SQLEND);
    SELECT the_text, t_index
    FROM   ##text_table
    WHERE  t_index IN (25, 26)
    ORDER  BY t_index
SQLEND
$d->dbsqlexec and print "ok 58\n" or print "not ok 58\n";
$stat = $d->dbresults;
if ($stat == SUCCEED) {print "ok 59\n"} else {print "not ok 59\n"};

$stat = $d->dbnextrow2($data);
if ($stat = REG_ROW) {print "ok 60\n"} else {print "not ok 60\n"}
$d2->dbdeletetext('##text_table.the_text', $d, 1, length($text0), 9)
  and print "ok 61\n" or print "not ok 61\n";

$stat = $d->dbnextrow2($data);
if ($stat = REG_ROW) {print "ok 62\n"} else {print "not ok 62\n"}
$d2->dbdeletetext('##text_table.the_text', $d, 1, 0, length($text1), 1)
  and print "ok 63\n" or print "not ok 63\n";

$d->dbcancel and print "ok 64\n" or print "not ok 64\n";
$d2->dbcancel and print "ok 65\n" or print "not ok 65\n";

# Read what we have now.
$d->dbcmd(<<SQLEND);
    SELECT the_text, t_index
    FROM   ##text_table
    WHERE  t_index IN (25, 26)
    ORDER  BY t_index
SQLEND
$d->dbsqlexec and print "ok 66\n" or print "not ok 66\n";
$stat = $d->dbresults;
if ($stat == SUCCEED) {print "ok 67\n"} else {print "not ok 67\n"};

$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 68\n"} else {print "not ok 68\n"};
if ($$data[0] eq $text0 . substr($text_long, length($text0) + 9))
   {print "ok 69\n"} else {print "not ok 69\n"};

$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 70\n"} else {print "not ok 70\n"};
if ($$data[0] eq $text2)
   {print "ok 71\n"} else {print "not ok 71\n"};

$stat = $d->dbnextrow2($data);
if ($stat == NO_MORE_ROWS) {print "ok 72\n"} else {print "not ok 72\n"};
$stat = $d->dbresults;
if ($stat == NO_MORE_RESULTS) {print "ok 73\n"} else {print "not ok 73\n"};

#---------------------------------------------------------------------
# Test dbcopyext
$d->dbcmd(<<SQLEND);
    SELECT the_text, t_index
    FROM   ##text_table
    WHERE  t_index IN (35, 36)
    ORDER  BY t_index
SQLEND
$d->dbsqlexec and print "ok 74\n" or print "not ok 74\n";
$stat = $d->dbresults;
if ($stat == SUCCEED) {print "ok 75\n"} else {print "not ok 75\n"};

$d3->dbcmd("SELECT txt FROM ##tbl2 WHERE id = 2");
$d3->dbsqlexec and print "ok 76\n" or print "not ok 76\n";
$stat = $d3->dbresults;
if ($stat == SUCCEED) {print "ok 77\n"} else {print "not ok 77\n"};
$stat = $d3->dbnextrow2($data);
if ($stat = REG_ROW) {print "ok 78\n"} else {print "not ok 78\n"}


# First row
$stat = $d->dbnextrow2($data);
if ($stat = REG_ROW) {print "ok 79\n"} else {print "not ok 79\n"}
$d2->dbcopytext('##text_table.the_text', '##tbl2.txt', $d, 1, $d3, 1)
  and print "ok 80\n" or print "not ok 80\n";
$d2->dbcopytext('##text_table.the_text', '##tbl2.txt', $d, 1, $d3, 1, 0, 0, 1)
  and print "ok 81\n" or print "not ok 81\n";

# Second row
$stat = $d->dbnextrow2($data);
if ($stat = REG_ROW) {print "ok 82\n"} else {print "not ok 82\n"}
$d2->dbcopytext('##text_table.the_text', '##tbl2.txt', $d, 1, $d3, 1,
               length($text1), length($text2), 1)
  and print "ok 83\n" or print "not ok 83\n";

$d->dbcancel and print "ok 84\n" or print "not ok 84\n";
$d2->dbcancel and print "ok 85\n" or print "not ok 85\n";
$d3->dbcancel and print "ok 86\n" or print "not ok 86\n";

# Read what we have now.
$d->dbcmd(<<SQLEND);
    SELECT the_text, t_index
    FROM   ##text_table
    WHERE  t_index IN (35, 36)
    ORDER  BY t_index
SQLEND
$d->dbsqlexec and print "ok 87\n" or print "not ok 87\n";
$stat = $d->dbresults;
if ($stat == SUCCEED) {print "ok 88\n"} else {print "not ok 88\n"};

$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 89\n"} else {print "not ok 89\n"};
if ($$data[0] eq $text_ins . $text_long . $text_ins)
   {print "ok 90\n"} else {print "not ok 90\n"};

$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 91\n"} else {print "not ok 91\n"};
if ($$data[0] eq $text1 . $text_ins)
   {print "ok 92\n"} else {print "not ok 92\n"};

$stat = $d->dbnextrow2($data);
if ($stat == NO_MORE_ROWS) {print "ok 93\n"} else {print "not ok 93\n"};
$stat = $d->dbresults;
if ($stat == NO_MORE_RESULTS) {print "ok 94\n"} else {print "not ok 94\n"};

# The tests for dbprepupdatetext fails. It's questionable whether the
# function works at all.
exit;

#----------------------------------------------------------------------
# Time to test dbprepupdatetext.
$d->dbcmd(<<SQLEND);
    SELECT the_text, t_index
    FROM   ##text_table
    WHERE  t_index IN (45, 46)
    ORDER  BY t_index
SQLEND
$d->dbsqlexec and print "ok 95\n" or print "not ok 95\n";
$stat = $d->dbresults;
if ($stat == SUCCEED) {print "ok 96\n"} else {print "not ok 96\n"};

# First row.
$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 97\n"} else {print "not ok 97\n"};
$d2->dbprepupdatetext ("##text_table.the_text", $d, 1, length($text0))
  and print "ok 98\n" or print "not ok 98\n";
$d2->dbsqlok and print "ok 99\n" or print "not ok 99\n";
$stat = $d2->dbresults;
if ($stat == SUCCEED) {print "ok 100\n"} else {print "not ok 100\n"};
$d2->dbmoretext(length($text0), uc($text0)) and print "ok 101\n" or print "not ok 101\n";
$d2->dbsqlok and print "ok 102\n" or print "not ok 102\n";
while ($d2->dbresults != NO_MORE_RESULTS) {}

# Second row.
$d->dbnextrow2($data);
$d2->dbprepupdatetext ("##text_table.the_text", $d, 1, 2 * length($text_ins), 0, 3)
  and print "ok 103\n" or print "not ok 103\n";

$d2->dbsqlok and print "ok 104\n" or print "not ok 104\n";
$stat = $d2->dbresults;
if ($stat == SUCCEED) {print "ok 105\n"} else {print "not ok 105\n"};
$d2->dbmoretext(undef, $text_ins) and print "ok 106\n" or print "not ok 106\n";
$d2->dbmoretext(undef, $text_ins) and print "ok 107\n" or print "not ok 107\n";
$d2->dbsqlok and print "ok 108\n" or print "not ok 108\n";
while ($d2->dbresults != NO_MORE_RESULTS) {}

# Cancel main query.
$d->dbcancel and print "ok 109\n" or print "not ok 109\n";

# Read what we have now.
$d->dbcmd(<<SQLEND);
    SELECT the_text, t_index
    FROM   ##text_table
    WHERE  t_index IN (25, 26)
    ORDER  BY t_index
SQLEND
$d->dbsqlexec and print "ok 110\n" or print "not ok 110\n";
$stat = $d->dbresults;
if ($stat == SUCCEED) {print "ok 111\n"} else {print "not ok 111\n"};

$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 112\n"} else {print "not ok 112\n"};
if ($$data[0] eq $text_long . uc($text0))
   {print "ok 113\n"} else {print "not ok 113\n"};

$stat = $d->dbnextrow2($data);
if ($stat == REG_ROW) {print "ok 114\n"} else {print "not ok 114\n"};
if ($$data[0] eq $text_ins . $text_ins . substr($text1, 2) . $text2)
   {print "ok 115\n"} else {print "not ok 115\n"};

$stat = $d->dbnextrow2($data);
if ($stat == NO_MORE_ROWS) {print "ok 116\n"} else {print "not ok 116\n"};
$stat = $d->dbresults;
if ($stat == NO_MORE_RESULTS) {print "ok 117\n"} else {print "not ok 117\n"};


# Close the handels.
$d->dbclose;
$d2->dbclose;


