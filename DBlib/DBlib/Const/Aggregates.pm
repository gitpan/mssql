#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Aggregates.pm 2     99-01-30 16:57 Sommar $
#
# $History: Aggregates.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Aggregates;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(SQLAOPCNT SQLAOPSUM SQLAOPAVG SQLAOPMIN
             SQLAOPMAX SQLAOPANY SQLAOPNOOP);

@ISA = qw(Exporter);

# Ag op tokens
sub SQLAOPCNT {     0x4b}
sub SQLAOPSUM {     0x4d}
sub SQLAOPAVG {     0x4f}
sub SQLAOPMIN {     0x51}
sub SQLAOPMAX {     0x52}
sub SQLAOPANY {     0x53}
sub SQLAOPNOOP {    0x56}

1;
