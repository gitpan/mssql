#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/ServerInfo.pm 2     99-01-30 16:57 Sommar $
#
# $History: ServerInfo.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::ServerInfo;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(SERVTYPE_UNKNOWN SERVTYPE_MICROSOFT NET_SEARCH LOC_SEARCH
             ENUM_SUCCESS MORE_DATA NET_NOT_AVAIL OUT_OF_MEMORY NOT_SUPPORTED
             ENUM_INVALID_PARAM);

@ISA = qw(Exporter);

# Used for ServerType in dbgetprocinfo
sub SERVTYPE_UNKNOWN {    0}
sub SERVTYPE_MICROSOFT {  1}

# The following values are passed to dbserverenum for searching criteria.
sub NET_SEARCH {   0x0001}
sub LOC_SEARCH {   0x0002}

# These constants are the possible return values from dbserverenum.
sub ENUM_SUCCESS {          0x0000}
sub MORE_DATA {             0x0001}
sub NET_NOT_AVAIL {         0x0002}
sub OUT_OF_MEMORY {         0x0004}
sub NOT_SUPPORTED {         0x0008}
sub ENUM_INVALID_PARAM {    0x0010}

1;
