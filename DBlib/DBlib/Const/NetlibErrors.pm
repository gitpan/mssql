#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/NetlibErrors.pm 2     99-01-30 16:57 Sommar $
#
# $History: NetlibErrors.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::NetlibErrors;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(NE_E_NOMAP NE_E_NOMEMORY NE_E_NOACCESS NE_E_CONNBUSY
             NE_E_CONNBROKEN NE_E_TOOMANYCONN NE_E_SERVERNOTFOUND NE_E_NETNOTSTARTED NE_E_NORESOURCE
             NE_E_NETBUSY NE_E_NONETACCESS NE_E_GENERAL NE_E_CONNMODE NE_E_NAMENOTFOUND
             NE_E_INVALIDCONN NE_E_NETDATAERR NE_E_TOOMANYFILES NE_E_CANTCONNECT NE_MAX_NETERROR
            );

@ISA = qw(Exporter);

# Netlib Error problem codes.  ConnectionError() should return one of
# these as the dblib-mapped problem code, so the corresponding string
# is sent to the dblib app's error handler as dberrstr.  Return NE_E_NOMAP
# for a generic DB-Library error string (as in prior versions of dblib).
sub NE_E_NOMAP {               0}   # No string; uses dblib default.
sub NE_E_NOMEMORY {            1}   # Insufficient memory.
sub NE_E_NOACCESS {            2}   # Access denied.
sub NE_E_CONNBUSY {            3}   # Connection is busy.
sub NE_E_CONNBROKEN {          4}   # Connection broken.
sub NE_E_TOOMANYCONN {         5}   # Connection limit exceeded.
sub NE_E_SERVERNOTFOUND {      6}   # Specified SQL server not found.
sub NE_E_NETNOTSTARTED {       7}   # The network has not been started.
sub NE_E_NORESOURCE {          8}   # Insufficient network resources.
sub NE_E_NETBUSY {             9}   # Network is busy.
sub NE_E_NONETACCESS {         10}  # Network access denied.
sub NE_E_GENERAL {             11}  # General network error.  Check your documentation.
sub NE_E_CONNMODE {            12}  # Incorrect connection mode.
sub NE_E_NAMENOTFOUND {        13}  # Name not found in directory service.
sub NE_E_INVALIDCONN {         14}  # Invalid connection.
sub NE_E_NETDATAERR {          15}  # Error reading or writing network data.
sub NE_E_TOOMANYFILES {        16}  # Too many open file handles.
sub NE_E_CANTCONNECT {         17}  # SQL Server does not exist or access denied.

sub NE_MAX_NETERROR {          17}

1;
