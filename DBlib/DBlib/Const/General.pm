#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/General.pm 2     99-01-30 16:57 Sommar $
#
# $History: General.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::General;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(CI_REGULAR CI_ALTERNATE CI_CURSOR DBNOERR
             SUCCEED FAIL SUCCEED_ABORT DBUNKNOWN MORE_ROWS
             NO_MORE_ROWS REG_ROW BUF_FULL NO_MORE_RESULTS NO_MORE_RPC_RESULTS
             INT_EXIT INT_CONTINUE INT_CANCEL STDEXIT ERREXIT
             SQLESMSG DBANSItoOEM DBOEMtoANSI);

@ISA = qw(Exporter);

# Used by dbcolinfo
sub CI_REGULAR   {1}
sub CI_ALTERNATE {2}
sub CI_CURSOR    {3}

sub DBNOERR { -1}

sub SUCCEED {   1}
sub FAIL    {   0}
sub SUCCEED_ABORT {  2}

sub DBUNKNOWN {  2}

sub MORE_ROWS    {  -1}
sub NO_MORE_ROWS {  -2}
sub REG_ROW      { -1}
sub BUF_FULL     { -3}

# Status code for dbresults(). Possible return values are
# SUCCEED, FAIL, and NO_MORE_RESULTS.
sub NO_MORE_RESULTS {  2}
sub NO_MORE_RPC_RESULTS {  3}

# Error code returns
sub INT_EXIT {         0}
sub INT_CONTINUE {     1}
sub INT_CANCEL {       2}

# Standard exit and error values
sub STDEXIT {   0}
sub ERREXIT {   -1}

# This one is also in Errors, but it is used in Sqllib,
# so we duplicate it here.
sub SQLESMSG {         10007}

# And these one are duplicated with Options, and also used in Sqllib.
sub DBANSItoOEM  { 14}
sub DBOEMtoANSI  { 15}


1;
