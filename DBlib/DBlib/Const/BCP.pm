#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/BCP.pm 2     99-01-30 16:57 Sommar $
#
# $History: BCP.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::BCP;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(DB_IN DB_OUT BCPMAXERRS BCPFIRST
             BCPLAST BCPBATCH BCPKEEPNULLS BCPABORT);

@ISA = qw(Exporter);

# Bulk Copy Definitions (bcp)
sub DB_IN {   1}         # Transfer from client to server
sub DB_OUT {  2}         # Transfer from server to client

sub BCPMAXERRS {    1}    # bcp_control parameter
sub BCPFIRST {      2}    # bcp_control parameter
sub BCPLAST {       3}    # bcp_control parameter
sub BCPBATCH {      4}    # bcp_control parameter
sub BCPKEEPNULLS {  5}    # bcp_control parameter
sub BCPABORT {      6}    # bcp_control parameter

1;
