#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/eg/dbtext.pl 1     98-01-19 22:28 Sommar $
# Example code showing the MSSQLPerl usage of dbwritetext().
#
# $History: dbtext.pl $
# 
# *****************  Version 1  *****************
# User: Sommar       Date: 98-01-19   Time: 22:28
# Created in $/Perl/MSSQL/eg
#---------------------------------------------------------------------


use MSSQL::Sqllib;

### Add appropriate passwords...
$d  = sql_init("", "sa", "", "tempdb");
$d2 = sql_init("", "sa", "", "tempdb");

# Create a table if needed.
if (! $d->sql_one("SELECT COUNT(*) FROM sysobjects WHERE name = 'text_table'")) {
   $d->sql("CREATE TABLE text_table (t_index int, the_text text)");
}

# Write column into it.
$d->sql ('DELETE FROM text_table');
$d->sql ('INSERT INTO text_table (t_index, the_text) VALUES (5,"")');

# To use writetext, we must make the row current with the main handle.
$d->dbcmd('SELECT the_text, t_index FROM text_table WHERE t_index = 5');
$d->dbsqlexec;
$d->dbresults;
$d->dbnextrow;

# Add the text.
$d2->dbwritetext ("text_table.the_text", $d, 1, "This is text which was added with MSSQL::DBlib");

# If send in a new query on the main handle, we get "results pending".
$d->dbcancel;

@data = $d->sql('SELECT t_index, the_text FROM text_table WHERE t_index = 5',
                 MSSQL::Sqllib::LIST);
foreach $x (@data) {
   print "@$x\n";
}

$d->dbclose;
