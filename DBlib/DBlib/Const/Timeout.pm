#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Timeout.pm 2     99-01-30 16:57 Sommar $
#
# $History: Timeout.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Timeout;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(TIMEOUT_IGNORE TIMEOUT_INFINITE TIMEOUT_MAXIMUM);

@ISA = qw(Exporter);

sub TIMEOUT_IGNORE {  -1}
sub TIMEOUT_INFINITE {  0}
sub TIMEOUT_MAXIMUM {  1200}  # 20 minutes maximum timeout value

1;
