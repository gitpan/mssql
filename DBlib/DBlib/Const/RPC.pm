#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/RPC.pm 2     99-01-30 16:57 Sommar $
#
# $History: RPC.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::RPC;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(DBRPCRECOMPILE DBRPCRESET DBRPCCURSOR DBRPCRETURN
             DBRPCDEFAULT);

@ISA = qw(Exporter);

# dbrpcinit flags
sub DBRPCRECOMPILE {   0x0001}
sub DBRPCRESET {       0x0004}
sub DBRPCCURSOR {      0x0008}

# dbrpcparam flags
sub DBRPCRETURN {      0x1}
sub DBRPCDEFAULT {     0x2}

1;
