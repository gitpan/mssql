#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Severity.pm 2     99-01-30 16:57 Sommar $
#
# $History: Severity.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Severity;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(EXINFO EXUSER EXNONFATAL EXCONVERSION
             EXSERVER EXTIME EXPROGRAM EXRESOURCE EXCOMM
             EXFATAL EXCONSISTENCY);

@ISA = qw(Exporter);

# The severity levels are defined here
sub EXINFO {           1}  # Informational, non-error
sub EXUSER {           2}  # User error
sub EXNONFATAL {       3}  # Non-fatal error
sub EXCONVERSION {     4}  # Error in DB-LIBRARY data conversion
sub EXSERVER {         5}  # The Server has returned an error flag
sub EXTIME {           6}  # We have exceeded our timeout period while
                        # waiting for a response from the Server - the
                        # DBPROCESS is still alive
sub EXPROGRAM {        7}  # Coding error in user program
sub EXRESOURCE {       8}  # Running out of resources - the DBPROCESS may be dead
sub EXCOMM {           9}  # Failure in communication with Server - the DBPROCESS is dead
sub EXFATAL {          10} # Fatal error - the DBPROCESS is dead
sub EXCONSISTENCY {    11} # Internal software error  - notify MS Technical Supprt

1;
