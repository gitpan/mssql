#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Text.pm 2     99-01-30 16:57 Sommar $
#
# $History: Text.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Text;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(DBTXTSLEN DBTXPLEN UT_TEXTPTR UT_TEXT
             UT_MORETEXT UT_DELETEONLY UT_LOG);

@ISA = qw(Exporter);

sub DBTXTSLEN {        8}     # Timestamp length
sub DBTXPLEN {         16}    # Text pointer length

# Following are values used by dbupdatetext's type parameter
sub UT_TEXTPTR {       0x0001}
sub UT_TEXT {          0x0002}
sub UT_MORETEXT {      0x0004}
sub UT_DELETEONLY {    0x0008}
sub UT_LOG {           0x0010}

1;
