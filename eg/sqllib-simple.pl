#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/eg/sqllib-simple.pl 1     98-01-19 22:28 Sommar $
#
# $History: sqllib-simple.pl $
# 
# *****************  Version 1  *****************
# User: Sommar       Date: 98-01-19   Time: 22:28
# Created in $/Perl/MSSQL/eg
#---------------------------------------------------------------------

use strict qw(vars subs);

my($sql, @x, $x, $kol);

use MSSQL::Sqllib;

# Log into the server.
sql_init("", "sa", "", "master");

# Run a query.
@x = &sql("SELECT dbid, name, crdate FROM sysdatabases");

# Just print the results, it's a list of hashes.
foreach $x (@x) {
  foreach $kol (keys %$x) {
     print "$kol: $$x{$kol}   ";
  }
  print "\n";
}
