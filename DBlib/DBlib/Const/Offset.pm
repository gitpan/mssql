#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Offset.pm 2     99-01-30 16:57 Sommar $
#
# $History: Offset.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Offset;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(OFF_SELECT OFF_FROM OFF_ORDER OFF_COMPUTE
             OFF_TABLE OFF_PROCEDURE OFF_STATEMENT OFF_PARAM OFF_EXEC
            );

@ISA = qw(Exporter);

# Offset identifiers
sub OFF_SELECT {       0x16d}
sub OFF_FROM {         0x14f}
sub OFF_ORDER {        0x165}
sub OFF_COMPUTE {      0x139}
sub OFF_TABLE {        0x173}
sub OFF_PROCEDURE {    0x16a}
sub OFF_STATEMENT {    0x1cb}
sub OFF_PARAM {        0x1c4}
sub OFF_EXEC {         0x12c}

1;
