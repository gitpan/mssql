#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/eg/statistics.pl 3     01-05-03 22:12 Sommar $
#
# $History: statistics.pl $
# 
# *****************  Version 3  *****************
# User: Sommar       Date: 01-05-03   Time: 22:12
# Updated in $/Perl/MSSQL/eg
# Added dbsqlexec and dbresults are setting options.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:47
# Updated in $/Perl/MSSQL/eg
# Reworked to focus on SHOW STATISTICS when SHOWPLAN is changed in SQL7.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 98-01-19   Time: 22:28
# Created in $/Perl/MSSQL/eg
#---------------------------------------------------------------------
 # Message number 3612-3615 are statistics time / io messages.
 @sh_msgs = (3612 .. 3615);
 @statistics_msg{@sh_msgs} = (1) x scalar(@sh_msgs);

 sub statistics_handler {
    my ($db, $message, $state, $severity, $text,
       $server, $procedure, $line)  = @_;

    # Don't display 'informational' messages:
    if ($severity > 10) {
       print STDERR ("Server message ", $message, ",
          Severity ", $severity, ", state ", $state);
       print STDERR ("\nServer `", $server, "'") if defined ($server);
       print STDERR ("\nProcedure `", $procedure, "'")
       if defined ($procedure);
          print STDERR ("\nLine ", $line) if defined ($line);
          print STDERR ("\n    ", $text, "\n\n");
    }
    elsif( $statistics_msg{$message}) {
    # This is a STATISTICS message, so print it out:
       print STDERR ($text, "\n");
    }
    elsif ($message == 0) {
       print STDERR ($text, "\n");
    }

    0;
}

    use MSSQL::DBlib;
    use MSSQL::DBlib::Const;
    dbmsghandle(\&statistics_handler);

    $dbh = MSSQL::DBlib->dblogin("sa");

    $dbh->dbsetopt(DBSTAT, "IO");
    $dbh->dbsetopt(DBSTAT, "TIME");
    $dbh->dbsqlexec;
    while ($dbh->dbresults != NO_MORE_RESULTS) {}

    $dbh->dbcmd("SELECT * FROM sysdatabases WHERE dbid = 1");
    $dbh->dbsqlexec;
    while ($dbh->dbresults != NO_MORE_RESULTS) {
       while ($dbh->dbnextrow2(\@dat) != NO_MORE_ROWS) {
          print "@dat\n";
       }
    }
