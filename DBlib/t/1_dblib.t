#-----------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/t/1_dblib.t 2     99-01-30 16:55 Sommar $
#
# Basic test suite for DB-lib. Includes of RPC:
#
# $History: 1_dblib.t $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:55
# Updated in $/Perl/MSSQL/DBlib/t
# Added tests for sqlsend, RPC and reduced the number of "ok 12".
#
# *****************  Version 1  *****************
# User: Sommar       Date: 98-01-19   Time: 22:28
# Created in $/Perl/MSSQL/eg
#-----------------------------------------------------------------------

use strict;

print "1..34\n";

use MSSQL::DBlib qw(1);
use MSSQL::DBlib::Const;

use File::Basename qw(dirname);

# This test file is still under construction...
printf "MSSQL::DBlib Version %6.3f\n\n", $MSSQL::DBlib::VERSION;
print "$MSSQL::DBlib::Version\n";

my ($X, $i,@row, $row, $rows, $count);

$i = 1;

dbmsghandle ("main::message_handler"); # Some user defined error handlers
dberrhandle ("main::error_handler");

# Get data for logging into the server.
use vars qw($Srv $Uid $Pwd);
require &dirname($0) . '\sqllogin.pl';


( $X = MSSQL::DBlib->dblogin($Uid, $Pwd, $Srv)),
    and print("ok 1\n")
    or die "not ok 1
-- The supplied login id/password combination may be invalid\n";

( $X->dbuse('tempdb') == SUCCEED )
    and print("ok 2\n")
    or die "not ok 2\n";

($X->dbcmd("select count(*) from systypes") == SUCCEED)
    and print("ok 3\n")
    or die "not ok 3\n";
($X->dbsqlexec == SUCCEED)
    and print("ok 4\n")
    or die "not ok 4\n";
($X->dbresults == SUCCEED)
    and print("ok 5\n")
    or die "not ok 5\n";
$count = $X->dbnextrow;
($X->{DBstatus} == REG_ROW and $count > 5)
    and print "ok 6\n"
    or die "not ok 6\n";
$X->dbnextrow;
($X->{DBstatus} == NO_MORE_ROWS)
    and print "ok 7\n"
    or die "not ok 7\n";
($X->dbresults == NO_MORE_RESULTS)
    and print("ok 8\n")
    or die "not ok 8\n";

($X->dbcmd("select * from systypes") == SUCCEED)
    and print("ok 9\n")
    or die "not ok 9\n";
($X->dbsqlsend == SUCCEED)
    and print("ok 10\n")
    or die "not ok 10\n";
($X->dbsqlok == SUCCEED)
    and print("ok 11\n")
    or die "not ok 11\n";
($X->dbresults == SUCCEED)
    and print("ok 12\n")
    or die "not ok 12\n";
while (@row = $X->dbnextrow) {
    $rows++;
    ($X->{DBstatus} == REG_ROW)
            or die "not ok 13\n";
}

($count == $rows)
    and print "ok 13\n"
    or die "not ok13\n";

# Now we make a syntax error, to test the callbacks:
my($old_handler) = dbmsghandle (\&msg_handler); # different handler to check callbacks

($X->dbcmd("select * from systypes\nwhere") == SUCCEED)
    and print("ok 14\n")
    or die "not ok 14\n";
sub msg_handler
{
   my ($db, $message, $state, $severity, $text, $server, $procedure, $line) = @_;

   if ($severity > 0) {
       print "$message   $text\n";
       ($message == 170) and print("ok 15\n") or print("not ok 15\n");
    }
    0;
}
($X->dbsqlexec == FAIL)
    and print("ok 16\n")
    or die "not ok 16\n";

# Back to the regular handler.
dbmsghandle ($old_handler);


# Test RPC. First create an SP.
my $SP = <<'SPEND';
CREATE PROCEDURE #nisse @x int OUT, @y varchar(8) OUT, @z datetime OUT, @w int OUT AS
   SELECT @x = @x * 2, @y = @y + "TEST", @z = dateadd(YEAR, 1, @z), @w = NULL
   RETURN 789
SPEND
($X->dbcmd($SP) == SUCCEED)
    and print("ok 17\n")
    or die "not ok 17\n";
($X->dbsqlexec == SUCCEED)
    and print("ok 18\n")
    or die "not ok 18\n";
($X->dbresults == SUCCEED)
    and print("ok 19\n")
    or die "not ok 19\n";


# Set date format, so we know what we get.
$X->{dateFormat} = "%Y%m%d %H:%M:%S";
$X->{msecFormat} = ".%3.3d";

# Then call it. To make it more tricky, we send @y and @z reversed.
($X->dbrpcinit("#nisse", DBRPCRESET) == SUCCEED)
    and print("ok 20\n")
    or die "not ok 20\n";
($X->dbrpcparam(undef, DBRPCRETURN, SQLINT4, -1, -1, 4711) == SUCCEED)
    and print("ok 21\n")
    or die "not ok 21\n";
($X->dbrpcparam(undef, DBRPCRETURN, SQLVARCHAR, -1, 4, "TEST") == SUCCEED)
    and print("ok 22\n")
    or die "not ok 22\n";
($X->dbrpcparam(undef, DBRPCRETURN, SQLDATETIMN, -1, -1, "19980101 12:12:12") == SUCCEED)
    and print("ok 23\n")
    or die "not ok 23\n";
($X->dbrpcparam(undef, DBRPCRETURN, SQLINT4, -1, -1, 7411) == SUCCEED)
    and print("ok 24\n")
    or die "not ok 24\n";
($X->dbrpcsend(0) == SUCCEED)
    and print("ok 25\n")
    or die "not ok 25\n";
($X->dbsqlok == SUCCEED)
    and print("ok 26\n")
    or die "not ok 26\n";

($X->dbresults == SUCCEED)
    and print("ok 27\n")
    or die "not ok 27\n";
(not $X->dbnextrow and $X->{DBstatus} == NO_MORE_ROWS)
    and print("ok 28\n")
    or die "not ok 28\n";
($X->dbresults == NO_MORE_RESULTS)
    and print("ok 29\n")
    or die "not ok 29\n";


my(%result) = $X->dbretdata(1);
(scalar(keys %result) == 4)
    and print("ok 30\n")
    or die "not ok 30\n";
($result{'Par 1'} == 9422 and $result{'Par 2'} eq "TESTTEST" and
 $result{'Par 3'} eq "19990101 12:12:12.000" and not defined $result{'Par 4'})
    and print("ok 31\n")
    or die "not ok 31\n";


($X->dbretstatus == 789)
    and print("ok 32\n")
    or die "not ok 32\n";

$X->{dbNullIsUndef} = 0;
my(@result) = $X->dbretdata(0);
(scalar(@result) == 4)
    and print("ok 33\n")
    or die "not ok 33\n";
($result[0] == 9422 and $result[1] eq "TESTTEST" and
 $result[2] eq "19990101 12:12:12.000" and $result[3] eq "NULL")
    and print("ok 34\n")
    or die "not ok 34\n";



sub message_handler
{
    my ($db, $message, $state, $severity, $text, $server, $procedure, $line)
        = @_;

    if ($severity > 0)
    {
        print STDERR ("MSSQL message ", $message, ", Severity ", $severity,
               ", state ", $state);
        print STDERR ("\nServer `", $server, "'") if defined ($server);
        print STDERR ("\nProcedure `", $procedure, "'") if defined ($procedure);
        print STDERR ("\nLine ", $line) if defined ($line);
        print STDERR ("\n    ", $text, "\n\n");

# &dbstrcpy returns the command buffer.

        if(defined($db))
        {
            my ($lineno, $cmdbuff) = (1, undef);

            $cmdbuff = MSSQL::DBlib::dbstrcpy($db);

            foreach $row (split (/\n/, $cmdbuff))
            {
                print STDERR (sprintf ("%5d", $lineno ++), "> ", $row, "\n");
            }
        }
    }
    elsif ($message == 0)
    {
        print STDERR ($text, "\n");
    }

    0;
}

sub error_handler {
    my ($db, $severity, $error, $os_error, $error_msg, $os_error_msg)
        = @_;
    # Check the error code to see if we should report this.
    if ($error != SQLESMSG) {
        print STDERR ("DBLIB error $error: ", $error_msg, "\n");
        print STDERR ("OS Error: ", $os_error_msg, "\n") if defined ($os_error_msg);
    }

    INT_CANCEL;
}




