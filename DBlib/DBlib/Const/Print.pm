#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Print.pm 2     99-01-30 16:57 Sommar $
#
# $History: Print.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Print;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(PRINT4 PRINT2 PRINT1 PRFLT8
             PRMONEY PRBIT PRDATETIME PRDECIMAL PRNUMERIC
            );

@ISA = qw(Exporter);

# Print lengths for certain fixed length data types
sub PRINT4 {      11}
sub PRINT2 {      6}
sub PRINT1 {      3}
sub PRFLT8 {      20}
sub PRMONEY {     26}
sub PRBIT {       3}
sub PRDATETIME {  27}
sub PRDECIMAL {  40}
sub PRNUMERIC {  40}

1;
