#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const/Cursor.pm 2     99-01-30 16:57 Sommar $
#
# $History: Cursor.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:57
# Updated in $/Perl/MSSQL/DBlib/DBlib/Const
# use strict(vars, subs) ==> use strict.
#---------------------------------------------------------------------
package MSSQL::DBlib::Const::Cursor;

use Exporter;
use strict;
use vars qw (@EXPORT @ISA);

@EXPORT = qw(CUR_READONLY CUR_LOCKCC CUR_OPTCC CUR_OPTCCVAL
             CUR_FORWARD CUR_KEYSET CUR_DYNAMIC CUR_INSENSITIVE FETCH_FIRST
             FETCH_NEXT FETCH_PREV FETCH_RANDOM FETCH_RELATIVE FETCH_LAST
             FTC_EMPTY FTC_SUCCEED FTC_MISSING FTC_ENDOFKEYSET FTC_ENDOFRESULTS
             CRS_UPDATE CRS_DELETE CRS_INSERT CRS_REFRESH CRS_LOCKCC
             NOBIND CU_CLIENT CU_SERVER CU_KEYSET CU_MIXED
             CU_DYNAMIC CU_FORWARD CU_INSENSITIVE CU_READONLY CU_LOCKCC
             CU_OPTCC CU_OPTCCVAL CU_FILLING CU_FILLED);

@ISA = qw(Exporter);

# Cursor related constants

# Following flags are used in the concuropt parameter in the dbcursoropen function
sub CUR_READONLY {  1} # Read only cursor, no data modifications
sub CUR_LOCKCC {    2} # Intent to update, all fetched data locked when
                       # dbcursorfetch is called inside a transaction block
sub CUR_OPTCC {     3} # Optimistic concurrency control, data modifications
                       # succeed only if the row hasn't been updated since
                       # the last fetch.
sub CUR_OPTCCVAL {  4} # Optimistic concurrency control based on selected column values

# Following flags are used in the scrollopt parameter in dbcursoropen
sub CUR_FORWARD {  0}       # Forward only scrolling
sub CUR_KEYSET {   -1}      # Keyset driven scrolling
sub CUR_DYNAMIC {  1}       # Fully dynamic
sub CUR_INSENSITIVE {  -2}  # Server-side cursors only

# Following flags define the fetchtype in the dbcursorfetch function
sub FETCH_FIRST {     1}  # Fetch first n rows
sub FETCH_NEXT {      2}  # Fetch next n rows
sub FETCH_PREV {      3}  # Fetch previous n rows
sub FETCH_RANDOM {    4}  # Fetch n rows beginning with given row #
sub FETCH_RELATIVE {  5}  # Fetch relative to previous fetch row #
sub FETCH_LAST {      6}  # Fetch the last n rows

# Following flags define the per row status as filled by dbcursorfetch and/or dbcursorfetchex
sub FTC_EMPTY {          0x00}  # No row available
sub FTC_SUCCEED {        0x01}  # Fetch succeeded, (failed if not set)
sub FTC_MISSING {        0x02}  # The row is missing
sub FTC_ENDOFKEYSET {    0x04}  # End of the keyset reached
sub FTC_ENDOFRESULTS {   0x08}  # End of results set reached

# Following flags define the operator types for the dbcursor function
sub CRS_UPDATE {    1}  # Update operation
sub CRS_DELETE {    2}  # Delete operation
sub CRS_INSERT {    3}  # Insert operation
sub CRS_REFRESH {   4}  # Refetch given row
sub CRS_LOCKCC {    5}  # Lock given row

# Following value can be passed to the dbcursorbind function for NOBIND type
sub NOBIND {  -2}       # Return length and pointer to data

# Following are values used by DBCURSORINFO's Type parameter
sub CU_CLIENT {         0x00000001}
sub CU_SERVER {         0x00000002}
sub CU_KEYSET {         0x00000004}
sub CU_MIXED {          0x00000008}
sub CU_DYNAMIC {        0x00000010}
sub CU_FORWARD {        0x00000020}
sub CU_INSENSITIVE {    0x00000040}
sub CU_READONLY {       0x00000080}
sub CU_LOCKCC {         0x00000100}
sub CU_OPTCC {          0x00000200}
sub CU_OPTCCVAL {       0x00000400}

# Following are values used by DBCURSORINFO's Status parameter
sub CU_FILLING {        0x00000001}
sub CU_FILLED {         0x00000002}

1;
