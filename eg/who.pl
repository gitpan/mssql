#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/eg/who.pl 1     98-01-19 22:28 Sommar $
#
# $History: who.pl $
# 
# *****************  Version 1  *****************
# User: Sommar       Date: 98-01-19   Time: 22:28
# Created in $/Perl/MSSQL/eg
#---------------------------------------------------------------------

format STDOUT_TOP=
                    Sysprocesses Report

Spid Kpid     Engine Status Suid Hostname Program    Hostpid Cmd            Cpu  IO   Mem Bk Dbid Uid Gid
---------------------------------------------------------------------------------------------------------
.
format STDOUT=
@### @########## @# @<<<<<<< @## @<<<<<<< @<<<<<<<<<< @##### @<<<<<<<<<<<<< @### @### @### @# @# @### @###
$dat{spid}, $dat{kpid}, $dat{engine}, $dat{status}, $dat{suid}, $dat{hostname}, $dat{program_name}, $dat{hostprocess}, $dat{cmd}, $dat{cpu}, $dat{physical_io}, $dat{memusage}, $dat{blocked}, $dat{dbid}, $dat{uid}, $dat{gid}
.

use MSSQL::DBlib;

$x = MSSQL::DBlib->dblogin("sa");
$x->dbcmd("select * from master..sysprocesses\n");
$x->dbsqlexec();
$x->dbresults();
while(%dat = $x->dbnextrow(1))
{
#   foreach (keys(%dat))
#   {
#       print "$_: $dat{$_}\n";
#   }
#   print "-------------------\n";
    write;
}

