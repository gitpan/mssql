#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/MaxValues.pm 2     99-01-30 16:57 Sommar $
#
# $History: MaxValues.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::MaxValues;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(DBMAXCHAR MAXNUMERICLEN MAXNUMERICDIG DEFAULTPRECISION
             DEFAULTSCALE MAXCOLNAMELEN MAXTABLENAME MAXSERVERNAME MAXNETLIBNAME
             MAXNETLIBCONNSTR MAXNAME);

@ISA = qw(Exporter);

sub DBMAXCHAR {  256} # Max length of DBVARBINARY and DBVARCHAR, etc.

sub MAXNUMERICLEN {  16}
sub MAXNUMERICDIG {  38}

sub DEFAULTPRECISION {  18}
sub DEFAULTSCALE {      0}

sub MAXCOLNAMELEN {  30}
sub MAXTABLENAME {   30}

sub MAXSERVERNAME {  30}
sub MAXNETLIBNAME {  255}
sub MAXNETLIBCONNSTR {  255}

sub MAXNAME {          31}


1;
