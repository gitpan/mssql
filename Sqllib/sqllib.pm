#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/Sqllib/sqllib.pm 7     00-09-14 22:37 Sommar $
# Copyright (c) 1997-1999 Erland Sommarskog
#
#   I don't care under which license you use this, as long as you don't
#   claim that you wrote it yourself.
#
# $History: sqllib.pm $
# 
# *****************  Version 7  *****************
# User: Sommar       Date: 00-09-14   Time: 22:37
# Updated in $/Perl/MSSQL/Sqllib
# Added error 3622 (Domain error) to the default for alwaysPrint.
#
# *****************  Version 6  *****************
# User: Sommar       Date: 00-09-09   Time: 18:12
# Updated in $/Perl/MSSQL/Sqllib
# MSSQL::Sqllib 1.007: Support for SQL2000 and new attribute SQL_version.
#
# *****************  Version 5  *****************
# User: Sommar       Date: 00-07-25   Time: 17:47
# Updated in $/Perl/MSSQL/Sqllib
# Fixed sql_set_conversion, so that default value for the server charset
# is retrieved correctly for SQL Server 2000.
#
# *****************  Version 4  *****************
# User: Sommar       Date: 00-05-03   Time: 21:36
# Updated in $/Perl/MSSQL/Sqllib
# Bugfix: text and image values were truncated to be 255 long.
#
# *****************  Version 3  *****************
# User: Sommar       Date: 00-02-19   Time: 20:45
# Updated in $/Perl/MSSQL/Sqllib
# Added errFileHandle to errInfo.
#
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:36
# Updated in $/Perl/MSSQL/sqllib
# MSSQL 1.005.
#---------------------------------------------------------------------

require 5.003;

package MSSQL::Sqllib;

use strict;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS
            $first_time $def_handle $SQLSEP $globalErrInfo $packname
            %VARLENTYPES %STRINGTYPES %LARGETYPES %QUOTEDTYPES %BINARYTYPES
            $VERSION);

$VERSION = "1.007";

use MSSQL::DBlib;
use MSSQL::DBlib::Const::General;
use MSSQL::DBlib::Const::RPC;
use MSSQL::DBlib::Const::Datatypes;
use Carp;

@ISA = qw(Exporter MSSQL::DBlib);

@EXPORT = qw(sql_init sql_set_conversion sql_unset_conversion sql_one sql sql_sp
             sql_insert sql_string sql_begin_trans sql_commit sql_rollback);
@EXPORT_OK = qw(NORESULT SINGLEROW SINGLESET MULTISET KEYED SCALAR LIST HASH
                $SQLSEP TO_SERVER_ONLY TO_CLIENT_ONLY TO_SERVER_CLIENT
                RETURN_NEXTROW RETURN_NEXTQUERY RETURN_CANCEL RETURN_ERROR
                RETURN_ABORT);
%EXPORT_TAGS = (consts       => \@EXPORT_OK,
                resultstyles => [qw(NORESULT SINGLEROW SINGLESET MULTISET KEYED)],
                rowstyles    => [qw(SCALAR LIST HASH)],
                directions   => [qw(TO_SERVER_ONLY TO_CLIENT_ONLY TO_SERVER_CLIENT)],
                returns      => [qw(RETURN_NEXTROW RETURN_NEXTQUERY RETURN_CANCEL
                                    RETURN_ERROR RETURN_ABORT)]);

# These are completely internal
$first_time = 1;
$packname = "MSSQL::Sqllib";

# Result-style constants.
sub NORESULT  {821}
sub SINGLEROW {741}
sub SINGLESET {643}
sub MULTISET  {139}
sub KEYED     {124}

# Row-style constants.
sub SCALAR    {17}
sub LIST      {89}
sub HASH      {93}

# Separator when rows returned in one string, reconfigurarable.
$SQLSEP = "\022";

# Constants for conversion direction
sub TO_SERVER_ONLY   {8798};
sub TO_CLIENT_ONLY   {3456};
sub TO_SERVER_CLIENT {2402};

# Constants for return values for callbacks
sub RETURN_NEXTROW   {1};
sub RETURN_NEXTQUERY {2};
sub RETURN_CANCEL    {3};
sub RETURN_ERROR     {0};
sub RETURN_ABORT     {-1};

# Constant hashes for datatype combinations, for internal use only.
%VARLENTYPES = (&SQLTEXT    => 1, &SQLIMAGE  => 1, &SQLCHAR => 1,
                &SQLUNIQUEIDENTIFIER => 1, &SQLVARCHAR => 1, &SQLBINARY => 1,
                &SQLVARBINARY => 1);
%STRINGTYPES = (&SQLTEXT => 1, &SQLCHAR => 1, &SQLVARCHAR => 1,
                &SQLUNIQUEIDENTIFIER => 1);
%LARGETYPES  = (&SQLTEXT => 1, &SQLIMAGE => 1);
%QUOTEDTYPES = (&SQLTEXT     => 1, &SQLCHAR     => 1, &SQLVARCHAR  => 1,
                &SQLDATETIME => 1, &SQLDATETIMN => 1, &SQLDATETIM4 => 1,
                &SQLUNIQUEIDENTIFIER => 1);
%BINARYTYPES = (&SQLBINARY => 1, &SQLVARBINARY => 1, &SQLIMAGE => 1);


#--------------------  sql_init  ----------------------------------------
sub sql_init {
# Logs into SQL Server and returns an object to use for further communication
# with the module.
    my ($server, $user, $pw, $db) = @_;

    my ($X);

    # Default values. "sa" gets tempdb as default db to avoid disasters.
    $server = $server || "";
    $user = $user || "sa";
    $db   = $db || "tempdb" if $user eq "sa";
    $pw = "" if not defined $pw;

    # Set upp error handlers unless this has been done already.
    if ($first_time) {
       $first_time = 0;
       dbmsghandle("${packname}::sql_message_handler");
       dberrhandle("${packname}::sql_error_handler");
    }

    # Get an error handling array for use during the long phase. This
    # variable is module global, so that it can be visible in the
    # error handler.
    $globalErrInfo = new_err_info();

    # Login into the server. We permit no errors here. dblogin will succeed
    # if we can't set the user's database, but we're are not taking the risk
    # that we're running in any other database than the intended, and least
    # of all in master!
    $X = MSSQL::Sqllib->dblogin($user, $pw, $server) or
         croak "Login into SQL Server failed";
    if ($globalErrInfo->{dieFlag}) {
       croak "Login to SQL Server failed";
    }

    # Set the default datetime format.
    $X->{dateFormat} = "%Y%m%d %H:%M:%S";
    $X->{msecFormat} = ".%3.3d";

    # Initiate error handling.
    $X->{errInfo} = new_err_info();

    # Set the database if desired
    if ($db) {
       $X->dbuse($db) or croak "dbuse '$db' failed";
       if ($X->{dieFlag}) {
          croak "Login to SQL Server failed.";
       }
    }

    # Get SQL version. First check for a really antique version:
    my $has_msver = $X->sql_one("SELECT COUNT(*) FROM master..sysobjects WHERE " .
                                "name = 'xp_msver'");
    if ($has_msver) {
       my %sqlversion = $X->sql_one("EXEC master..xp_msver 'ProductVersion'");
       $X->{SQL_version} = $sqlversion{'Character_Value'};
    }
    else {
       $X->{SQL_version} = "4.21";
    }


    # Turn off ANSI -> OEM
    $X->dbclropt(DBANSItoOEM);
    $X->dbclropt(DBOEMtoANSI);

    # If the global default handle is undefined, give the recently created
    # connection.
    if (not defined $def_handle) {
       $def_handle = $X;
    }

    $X;
}

sub new {
    shift @_;
    sql_init(@_);
}

#-------------------------- sql_set_conversion --------------------------
sub sql_set_conversion
{
    my($X) = (ref @_[$[] eq $packname ? shift @_ : $def_handle);
    my($client_cs, $server_cs, $direction) = @_;

    # First validate the $direction parameter.
    if (! $direction) {
       $direction = TO_SERVER_CLIENT;
    }
    if (! grep($direction == $_,
              (TO_SERVER_ONLY, TO_CLIENT_ONLY, TO_SERVER_CLIENT))) {
       croak "Illegal direction value: $direction";
    }

    # Normalize parameters and get defaults. The client charset.
    if (not $client_cs or $client_cs =~ /^OEM/i) {
       # No value or OEM, read actual OEM codepage from registry.
       $client_cs = get_codepage_from_reg('OEMCP');
    }
    elsif ($client_cs =~ /^ANSI$/i) {
       # Read ANSI code page.
       $client_cs = get_codepage_from_reg('ACP');
    }
    $client_cs =~ s/^cp_?//i;             # Strip CP[_]
    if ($client_cs =~ /^\d{3,3}$/) {
       $client_cs = "0$client_cs";       # Add leading zero.
    }

    # Now the server charset. If no charset given, query the server.
    if (not $server_cs) {
       my($clone) = $X->clone_for_internal_call();

       if ($X->{SQL_version} =~ /^[467]\./) {
          # SQL Server 7.0 or earlier.
          $server_cs = $clone->sql_one(<<SQLEND);
               SELECT chs.name
               FROM   master..syscharsets sor, master..syscharsets chs,
                      master..syscurconfigs cfg
               WHERE  cfg.config = 1123
                 AND  sor.id     = cfg.value
                 AND  chs.id     = sor.csid
SQLEND
       }
       else {
          # Modern stuff, SQL 2000 or later.
          $server_cs = $clone->sql_one(<<SQLEND);
             SELECT collationproperty(
                    CAST(serverproperty ("collation") as nvarchar(255)),
                    "CodePage")
SQLEND
       }
    }
    if ($server_cs =~ /^iso_1$/i) {    # iso_1 is how SQL6&7 reports Latin-1.
       $server_cs = "1252";            # CP1252 is the Latin-1 code page.
    }
    $server_cs =~ s/^cp_?//i;
    if ($server_cs =~ /^\d{3,3}$/) {
       $server_cs = "0$server_cs";
    }

    # If client and server charset are the same, we should only remove any
    # current conversion, and then quit.
    if ("\U$client_cs\E" eq "\U$server_cs\E") {
       $X->sql_unset_conversion($direction);
       return;
    }

    # Now we try to find a file in System32.
    my($server_first) = 1;
    my($server_first_name) = "$ENV{'SYSTEMROOT'}\\System32\\$server_cs$client_cs.cpx";
    my($client_first_name) = "$ENV{'SYSTEMROOT'}\\System32\\$client_cs$server_cs.cpx";
    if (not open(F, $server_first_name)) {
       open(F, $client_first_name) or
          croak "Can't open neither '$server_first_name' nor '$client_first_name'";
       $server_first = 0;
    }

    # First read translations from the first charset. But the chars into
    # a string. When used the strings will be fed to tr.
    my($server_repl, $server_with) = ("", "");
    my($line);
    #while (($line = $F->getline) !~ m!^/!) {
    while (($line = <F>) !~ m!^/!) {
       chop $line;
       next if $line !~ /:/;
       my($a, $b) = split(/:/, $line);
       $server_repl .= chr($a);
       $server_with .= chr($b);
    }

    # The other half.
    my($client_repl, $client_with) = ("", "");
    #while ($line = $F->getline) {
    while (defined ($line = <F>)) {
       chop $line;
       next if $line !~ /:/;
       my($a, $b) = split(/:/, $line);
       $client_repl .= chr($a);
       $client_with .= chr($b);
    }

    close F;

    # Swap the strings if client's charset was first in the file.
    if (! $server_first) {
       ($client_repl, $server_repl) = ($server_repl, $client_repl);
       ($client_with, $server_with) = ($server_with, $client_with);
    }

    # Store the charset converstions into the handle. We store these as
    # subroutines ready to use. We need to use eval, as tr is static.
    if ($direction == TO_SERVER_ONLY or $direction == TO_SERVER_CLIENT) {
       $X->{'to_server'} = eval("sub { foreach (\@_) {
                                  tr/\Q$client_repl\E/\Q$client_with\E/ if \$_}
                                 return \@_}") or
           die "eval of client-to-server conversion: $@";
    }
    if ($direction == TO_CLIENT_ONLY or $direction == TO_SERVER_CLIENT) {
    # For server-to-client we need a return value for hashes.
       $X->{'to_client'} = eval("sub { foreach (\@_) {
                                  tr/\Q$server_repl\E/\Q$server_with\E/ if \$_}
                                 return \@_}") or
           die "eval of server-to-client conversion failed: $@";
    }
}

#-------------------------- sql_unset_conversion -------------------------
sub sql_unset_conversion
{
    my($X) = (ref @_[$[] eq $packname ? shift @_ : $def_handle);
    my($direction) = @_;

    # First validate the $direction parameter.
    if (! $direction) {
       $direction = TO_SERVER_CLIENT;
    }
    if (! grep($direction == $_,
              (TO_SERVER_ONLY, TO_CLIENT_ONLY, TO_SERVER_CLIENT))) {
       croak "Illegal direction value: $direction";
    }

    # Now remove as ordered.
    if ($direction == TO_SERVER_ONLY or $direction == TO_SERVER_CLIENT) {
       delete $X->{'to_server'};
    }
    if ($direction == TO_CLIENT_ONLY or $direction == TO_SERVER_CLIENT) {
       delete $X->{'to_client'};
    }
}

#-----------------------------  sql_one-------------------------------------
sub sql_one
{
    my($X) = (ref @_[$[] eq $packname ? shift @_ : $def_handle);
    my($sql, $rowstyle) = @_;

    my ($dataref, $stat, $dummy);

    # Make sure $rowstyle has a legal value.
    $rowstyle = $rowstyle || (wantarray ? HASH : SCALAR);
    check_style_params($rowstyle);

    # Apply conversion and do logging and check noExec.
    $X->do_conversion('to_server', $sql);
    $X->do_logging($sql);
    if ($X->{'noExec'}) {
       return;
    }

    # Run the command and check outcome. Note that we don't care about
    # $stat, only the dieFlag matters.
    delete $X->{errInfo}{SP_call};
    $X->{errInfo}{dieFlag} = 0;
    $X->dbcmd($sql);
    croak "dbcmd failed" if $X->{errInfo}{dieFlag};
    $stat = $X->dbsqlexec;
    croak "${packname}::sql_one failed" if $X->{errInfo}{dieFlag};

    $stat = $X->dbresults;
    croak "${packname}::sql_one failed" if $X->{errInfo}{dieFlag};
    croak "Single-row query '$sql' returned no result set." if $stat != SUCCEED;

    $X->dbnextrow2($dataref, $rowstyle == HASH);
    croak "${packname}::sql_one failed" if $X->{errInfo}{dieFlag};
    if (not $dataref) {
        $X->dbcancel;
        croak "Single-row query '$sql' returned no row.";
    }

    if ($X->dbnextrow2($dummy) != NO_MORE_ROWS) {
       $X->dbcancel;
       croak "Single-row query '$sql' returned more than one row.";
    }

    if ($X->dbresults != NO_MORE_RESULTS) {
       $X->dbcancel;
       croak "Single-row query '$sql' returned more than one result-set.";
    }

    # Apply server-to-client conversion
    $X->do_conversion('to_client', $dataref);

    if (wantarray) {
       return (($rowstyle == HASH) ? %$dataref : @$dataref);
    }
    else {
       return (($rowstyle == SCALAR) ? list_to_scalar($dataref) : $dataref);
    }
}

#-----------------------  sql  --------------------------------------
sub sql
{
    my($X) = (ref @_[$[] eq $packname ? shift @_ : $def_handle);
    my($sql, $rowstyle, $resultstyle, $keys) = @_;

    my ($stat);

    # Check that style parameters are legal and get default if needed.
    check_style_params($rowstyle, $resultstyle, $keys);

    # Apply conversion, do logging and check noExec.
    $X->do_conversion('to_server', $sql);
    $X->do_logging($sql);
    if ($X->{'noExec'}) {
       return;
    }

    # Run the command and check outcome. Again, only the dieFlag matters.
    delete $X->{errInfo}{SP_call};
    $X->{errInfo}{dieFlag} = 0;
    $X->dbcmd($sql);
    croak "dbcmd failed" if $X->{errInfo}{dieFlag};
    $stat = $X->dbsqlexec;
    croak "${packname}::sql failed" if $X->{errInfo}{dieFlag};

    return $X->get_result_sets($rowstyle, $resultstyle, $keys);
}

#-------------------------- sql_sp ------------------------------------
sub sql_sp {
    my($X) = (ref @_[$[] eq $packname ? shift @_ : $def_handle);

    # In this one we're not taking all parameters at once, but one by one,
    # as the variable is quite variable.
    my ($SP, $retstatref, $unnamed, $named, $rowstyle, $resultstyle, $keys);

    # The name of the SP, mandatory.
    $SP = shift @_;

    # Reference to scalar to receive the return status.
    if (ref $_[0] eq "SCALAR") {
       $retstatref = shift @_;
    }

    # Reference to a array with named parameters.
    if (ref $_[0] eq "ARRAY") {
       $unnamed = shift @_;
    }

    # Reference to a hash with named parameters.
    if (ref $_[0] eq "HASH") {
       $named = shift @_;
    }

    # The usual row- and result-style parameters.
    ($rowstyle, $resultstyle, $keys) = @_;
    check_style_params($rowstyle, $resultstyle, $keys);

    # Remaining variables we need.
    my ($name, $params_by_col, $params_by_name, %output_params, $output_from_sp,
        $stat, @results, $resultref);

    # If we have the parameter profile for this SP, we can reuse it.
    if (exists $X->{procs}{$SP}) {
       $params_by_name = $X->{'procs'}{$SP}{'params_by_name'};
       $params_by_col  = $X->{'procs'}{$SP}{'params_by_col'};
    }
    else {
       # No we don't. We must retrieve from the server.
       my($clone, @paraminfo, $ref, $objid, $objdb);

       # First we need a clone of the db handle for our own calls.
       $clone = $X->clone_for_internal_call();

       # Get the object id for the table and it's database
       ($objid, $objdb) = $clone->get_object_id($SP);
       if (! $objid) {
          croak "Could not get object id for procedure '$SP'";
       }

       # Now, inquire about all the columns in the table and their type.
       # Different handling for different SQL Versions.
       my ($typecol) = ($X->{SQL_version} =~ /^[46]\./ ? "type" :
                        "CASE WHEN xtype = 36 THEN xtype ELSE type END");
       my($DBRPCRETURN) = DBRPCRETURN;
       @paraminfo = $clone->sql(<<SQLEND, HASH);
           SELECT name, colid, type = $typecol,
                  is_output = CASE status & 0x40
                                 WHEN 0 THEN 0
                                 ELSE $DBRPCRETURN
                              END
           FROM   $objdb..syscolumns
           WHERE  id = $objid
SQLEND

       # Unpack the info and store it both in a list and a hash.
       foreach $ref (@paraminfo) {
          %{$$params_by_name{$$ref{'name'}}} = ('type'   => $$ref{'type'},
                                                'output' => $$ref{'is_output'});
          %{$$params_by_col[$$ref{'colid'}]} = ('name'   => $$ref{'name'},
                                                'type'   => $$ref{'type'},
                                                'output' => $$ref{'is_output'});
       }

       # Store the profile in the handle.
       $X->{'procs'}{$SP}{'params_by_name'} = $params_by_name;
       $X->{'procs'}{$SP}{'params_by_col'}  = $params_by_col;
    }

    # Convert the procedure name to the server client charset and initiate
    # the operation.
    $X->{errInfo}{dieFlag} = 0;
    $X->do_conversion('to_server', $SP);
    $X->dbrpcinit($SP, DBRPCRESET);
    die "dbrpcinit failed" if $X->{errInfo}{dieFlag};
    $X->{errInfo}{SP_call} = "EXEC $SP ";

    # Handle the unnamed parameters. In order not to repeat a lot of code,
    # we only do what is specific, and then put over the parameters to the
    # named ones.
    if ($unnamed) {
       my($par_ix, $is_ref, $value, $name, $is_output);
       unshift(@$unnamed, "");    # To get in sync with @sp_params.
       foreach $par_ix (1..$#$unnamed) {
          # Reference or value?
          $is_ref = ref $$unnamed[$par_ix] eq "SCALAR";

          # Get attributes for the parameters.
          $name      = $$params_by_col[$par_ix]{'name'};
          $is_output = $$params_by_col[$par_ix]{'output'};

          # Put the parameter into the named array.
          $$named{$name} = $$unnamed[$par_ix];

          # We need to save a reference into the array here though.
          if ($is_output) {
             if ($is_ref) {
                $output_params{$name} = $$unnamed[$par_ix];
             }
             else {
                $output_params{$name} = \$$unnamed[$par_ix];
                carp "Unnamed parameter #$par_ix is output but is not a reference!"
                   if $^W and not $X->{errInfo}{noWhine};

             }
          }
       }
       shift(@$unnamed);    # Drop the dummy.
    }

    # And now named parameters.
    if ($named) {
       my($is_ref, $value, $isnull, $maxlen, $datalen, $name, $type, $is_output);
       foreach $name (keys %$named) {
          $is_ref = ref $$named{$name} eq "SCALAR";

          # Check that there is such a parameter
          if (not exists $$params_by_name{$name}) {
             croak "SP '$SP' does not have a parameter '$name'";
          }

          # Get attributes for the parameters.
          $type      = $$params_by_name{$name}{'type'};
          $is_output = $$params_by_name{$name}{'output'};

          # Save reference to store output parameter unless done already.
          if ($is_output and not $output_params{$name}) {
             if ($is_ref) {
                $output_params{$name} = $$named{$name};
             }
             else {
                $output_params{$name} = \$$named{$name};
                carp "Parameter $name is output but is not a reference!"
                   if $^W and not $X->{errInfo}{noWhine};
             }
          }

          # Get the value
          $value = ($is_ref ? ${$$named{$name}} : $$named{$name});
          $isnull = (defined $value ? 0 : 1);
          unless ($isnull) {
             $X->do_conversion('to_server', $value);
          }
          else {
             $value = "";   # To avoid "unitialized value" warning later on.
          }
          $X->do_conversion('to_server', $name);

          # And length.
          if ($VARLENTYPES{$type}) {
             if (not $isnull and length($value) == 0 and $STRINGTYPES{$type}) {
             # SQL Server 6.x thinks an empty string and NULL is the same.
                $value = " ";
             }
             $datalen = ($isnull ? 0 : length($value));
             $datalen = 255 if $datalen > 255 and not $LARGETYPES{$type};
          }
          else {
             $datalen = ($isnull ? 0 : -1);
          }

          # Length of the result.
          $maxlen = -1;
          if ($LARGETYPES{$type} and $isnull) {
             $maxlen = 0;
          }

          # Add to the log string.
          $X->{errInfo}{SP_call} .= $name . ' = ';
          if ($isnull) {
             $X->{errInfo}{SP_call} .= "NULL";
          }
          else {
             $X->{errInfo}{SP_call} .= ($QUOTEDTYPES{$type} ?
                                        $X->sql_string($value) : $value);
          }
          $X->{errInfo}{SP_call} .= ', ';

          # At last, send the parameter.
          $X->dbrpcparam($name, $is_output, $type, $maxlen, $datalen, $value);
          croak "dbrpcparam failed" if $X->{errInfo}{dieFlag};
       }
    }

    # Do logging.
    $X->{errInfo}{SP_call} =~ s/,\s*$//;
    $X->do_logging($X->{errInfo}{SP_call});

    # Check if noExec is on.
    if ($X->{'noExec'}) {
       $X->dbrpcinit(undef, DBRPCRESET);
       return;
    }

    # Execute the procedure and let dieFlag alone determine out fate.
    $X->{errInfo}{dieFlag} = 0;
    $X->dbrpcsend();
    croak "${packname}::sql_sp failed" if $X->{errInfo}{dieFlag};

    # Retrieve the result sets.
    if (wantarray) {
       @results = $X->get_result_sets($rowstyle, $resultstyle, $keys);
    }
    else {
       $resultref = $X->get_result_sets($rowstyle, $resultstyle, $keys);
    }

    # Retrieve output parameters
    $output_from_sp = $X->dbretdata2(1);
    $X->do_conversion('to_client', $output_from_sp);

    # And map values to the input parameters.
    foreach $name (keys %output_params) {
       ${$output_params{$name}} = $$output_from_sp{$name};
    }

    # Check the return status and return it if required.
    my($retstat) = $X->dbretstatus();
    if ($retstat ne 0 and $X->{errInfo}{checkRetStat} and
        not $X->{errInfo}{retStatOK}{$retstat}) {
        croak "Stored procedure $SP return status $retstat";
    }
    $$retstatref = $retstat if $retstatref;

    # Remove the faked call from errInfo
    delete $X->{errInfo}{SP_call};

    # Return the result sets.
    return (wantarray ? @results : $resultref);
}


#-------------------------  sql_insert  -------------------------------
sub sql_insert {
    my($X) = (ref @_[$[] eq $packname ? shift @_ : $def_handle);
    my($tblspec) = shift @_;
    my(%values) = %{shift @_};  # Take a copy, we'll be modifying.

    my($tbldef, $col);

    # If have a column profile saved, reuse it.
    if (exists $X->{'tables'}{$tblspec}) {
       $tbldef = $X->{'tables'}{$tblspec};
    }
    else {
       # We don't about this one. Get data about the table from the server.
       my ($clone, $objdb, $objid, @columns, $colref);

       # Clone the db handle for our internal use.
       $clone = $X->clone_for_internal_call();

       # Get the object id for the table and it's database
       ($objid, $objdb) = $clone->get_object_id($tblspec);
       if (! $objid) {
          croak "Could not get object id for table '$tblspec'";
       }

       # Now, inquire about all the columns in the table and their type
       my ($typecol) = ($X->{SQL_version} =~ /^[46]\./ ? "type" :
                        "CASE WHEN xtype = 36 THEN xtype ELSE type END");
       $tbldef = $clone->sql(<<SQLEND, SCALAR, KEYED, [1]);
           SELECT name, type = $typecol
           FROM   $objdb..syscolumns
           WHERE  id = $objid
SQLEND

       # Save it for future calls.
       $X->{'tables'}{$tblspec} = $tbldef;
    }

    # Now we can find out which colunms in %values we must quote.
    foreach $col (keys %values) {
       next if not exists $$tbldef{$col};   # Error, but let the server handle it.
       if (not defined $values{$col}) {
          $values{$col} = "NULL";
       }
       elsif ($QUOTEDTYPES{$$tbldef{$col}}) {
          $values{$col} = $X->sql_string($values{$col});
       }
       elsif ($BINARYTYPES{$$tbldef{$col}}) {
          $values{$col} = "0x" . $values{$col} unless $values{$col} =~ /^0x/i;
       }
    }

    # Produce the SQL and run it.
    $X->sql("INSERT $tblspec (" . join(', ', keys %values) . ') VALUES (' .
            join(', ', values %values) . ')');
}


#-------------------------  sql_string  -------------------------------
sub sql_string {
    my($X) = (ref @_[$[] eq $packname ? shift @_ : $def_handle);
    my($str) = @_;
    if (defined $str) {
       $str =~ s/'/''/g;
       "'$str'";
    }
    else {
       "NULL";
    }
}

#------------------------- transaction routines -----------------------
sub sql_begin_trans {
    my($X) = (ref @_[$[] eq $packname ? shift @_ : $def_handle);
    $X->sql("BEGIN TRANSACTION");
}

sub sql_commit {
    my($X) = (ref @_[$[] eq $packname ? shift @_ : $def_handle);
    $X->sql("COMMIT TRANSACTION");
}

sub sql_rollback {
    my($X) = (ref @_[$[] eq $packname ? shift @_ : $def_handle);
    $X->sql("ROLLBACK TRANSACTION");
}

#--------------------- sql_message_handler ----------------------------
sub sql_message_handler {
    my($db, $errno, $state, $severity, $text, $server,
       $procedure, $line) = @_;

    my($errInfo, $print_msg, $print_text, $print_lines, $fh);

    # First get a reference to an errInfo hash. If $db is not a proper
    # object (this happen during sql_init), use the global errInfo hash.
    $errInfo = (exists $db->{errInfo} ? $db->{errInfo} : $globalErrInfo);

    # Determine where to write the messages.
    $fh = ($errInfo->{errFileHandle} or \*STDERR);

    # Save messages if requested.
    if ($errInfo->{saveMessages}) {
       push(@{$errInfo->{'messages'}}, {errno    => $errno,
                                        state    => $state,
                                        severity => $severity,
                                        text     => $text,
                                        proc     => $procedure,
                                        line     => $line});
    }

    # Find out whether we should stop on this error unless die flag
    # already set.
    unless ($errInfo->{dieFlag}) {
       if ($severity > $errInfo->{maxSeverity}) {
          $errInfo->{dieFlag} = 1 unless $errInfo->{neverStopOn}{$errno};
       }
       else {
          $errInfo->{dieFlag} = $errInfo->{alwaysStopOn}{$errno};
       }
    }

    # Then determine if to print and what.
    unless ($errInfo->{neverPrint}{$errno}) {
       # Not in neverPrint. If in alwaysPrint, print it all.

       if (not $errInfo->{alwaysPrint}{$errno}) {
          # Nope. Check each part.
          $print_msg = $severity >= $errInfo->{printMsg};
          $print_text = $severity >= $errInfo->{printText};
          $print_lines = $severity >= $errInfo->{printLines};
       }
       else {
          $print_msg = $print_text = $print_lines = 1;
       }


       # Here goes printing for each part. First message info.
       if ($print_msg) {
          print $fh "SQL Server message $errno, Severity $severity, ",
                    "State $state";
          print $fh ", Server $server" if $server;
          if ($procedure) {
             print $fh "\nProcedure $procedure  Line $line";
          }
          else {
             print $fh "\nLine $line" if $line;
          }
          print $fh "\n";
       }

       # The text.
       if ($print_text) {
          print $fh "$text\n" if $text;
       }

       # The lines. This is slightly more tricky.
       if ($print_lines) {
          unless ($errInfo->{SP_call}) {
             my $linetxt = MSSQL::DBlib::dbstrcpy($db);
             if ($linetxt) {
                my ($lineno, $row);
                foreach $row (split (/\n/, $linetxt)) {
                   print $fh sprintf("%5d", ++$lineno), "> $row\n";
                }
             }
          }
          else {
             print $fh sprintf("%5d> ", 1) . $errInfo->{SP_call} . "\n";
          }
       }
    }

    0;
}

#--------------------- sql_error_handler ----------------------------
sub sql_error_handler {
    my($db, $severity, $dberr, $os_error, $dberr_text, $os_error_text) = @_;

    # First get a reference to an errInfo hash. If $db is not a proper
    # object (this happen during sql_init), use the global errInfo hash.
    my $errInfo = (exists $db->{errInfo} ? $db->{errInfo} : $globalErrInfo);

    # Determine where to write the messages.
    my $fh = ($errInfo->{errFileHandle} or \*STDERR);

    # Print unless silence is called.
    unless ($errInfo->{neverPrint}{-$dberr}) {
       print $fh "DB-Library error $dberr, severity $severity: $dberr_text\n";
       print $fh "OS error $os_error: $os_error_text\n" if $os_error != DBNOERR;
    }

    # Save message if requested.
    if ($errInfo->{saveMessages}) {
       push(@{$errInfo->{'messages'}}, {errno     => $dberr,
                                        state     => -1,
                                        severity  => $severity,
                                        text      => $dberr_text,
                                        oserr     => $os_error,
                                        oserrtext => $os_error_text});
    }

    # See whether to set the die Flag.
    unless ($errInfo->{dieFlag}) {
       if ($severity > $errInfo->{maxLibSeverity}) {
          $errInfo->{dieFlag} = 1 unless $errInfo->{neverStopOn}{-$dberr};
       }
       else {
          $errInfo->{dieFlag} = $errInfo->{alwaysStopOn}{-$dberr};
       }
    }

    INT_CANCEL;
}


#--------------------- new_err_info, internal----------------------------
sub new_err_info {
    # Initiates an err_info hash and returns a reference to it. We
    # set default to print everything but two messages (changed db
    # and language) and to stop on everything above severity 10.

    my(%errInfo);

    # Initiate default error handling: stop on severity > 10, and print
    # both messages and lines.
    $errInfo{printMsg}       = 1;
    $errInfo{printText}      = 0;
    $errInfo{printLines}     = 11;
    $errInfo{neverPrint}     = {'5701' => 1, '5703' => 1, -SQLESMSG() => 1};
    $errInfo{alwaysPrint}    = {'3606' => 1, '3607' => 1, '3622' => 1};
    $errInfo{maxSeverity}    = 10;
    $errInfo{maxLibSeverity} = 1;
    $errInfo{neverStopOn}    = {-SQLESMSG() => 1};
    $errInfo{checkRetStat}   = 1;
    $errInfo{saveMessages}   = 0;

    \%errInfo;
}

#----------------------- get_codepage_from_reg, internal -------------
sub get_codepage_from_reg {
    my($cp_value) = shift @_;
    # Reads the code page for OEM or ANSI. This is one specific key in
    # in the registry.

    my($REGKEY) = 'SYSTEM\CurrentControlSet\Control\Nls\CodePage';
    my($regref, $dummy, $result);

    # We need this module to read the registry, but as this is the only
    # place we need it in, we don't C<use> it.
    require 'Win32\Registry.pm';

    $dummy = $main::HKEY_LOCAL_MACHINE;  # Resolve "possible typo" with AS Perl.
    $main::HKEY_LOCAL_MACHINE->Open($REGKEY, $regref) or
         die "Could not open registry key: '$REGKEY'\n";

    # This is where stuff is getting really ugly, as I have found no code
    # that works both with the ActiveState Perl and the native port.
    if ($] < 5.004) {
       Win32::RegQueryValueEx($regref->{'handle'}, $cp_value, 0,
                              $dummy, $result) or
             die "Could not read '$REGKEY\\$cp_value' from registry\n";
    }
    else {
       $regref->QueryValueEx($cp_value, $dummy, $result);
    }
    $regref->Close or warn "Could not close registry key.\n";

    $result;
}

#-------------------- do_conversion, internal ----------------
sub do_conversion{
    my ($X) = shift @_;
    my ($direction) = shift @_;
    if (defined $X->{$direction}) {
       if (ref $_[0] eq "HASH") {
          %{$_[0]} = &{$X->{$direction}}(%{$_[0]});
       }
       elsif (ref $_[0] eq "ARRAY") {
          &{$X->{$direction}}(@{$_[0]});
       }
       elsif (ref $_[0] eq "SCALAR") {
          &{$X->{$direction}}(${$_[0]});
       }
       else {
          &{$X->{$direction}}(@_);
       }
    }
}

#------------------------ do_logging, internal ----------------------
sub do_logging {
   my($X, $sql) = @_;

   if ($X->{logHandle}) {
      my ($F) = $X->{logHandle};
      print $F "$sql\ngo\n";
   }
}

#--------------------- clone_for_internal_call, internal -------------
sub clone_for_internal_call {
   my ($X) = @_;
   # returns a clone of $X that we use for internal calls. The point with
   # it, is that it has all SQLLIB options turned off.

   my($clone) = {dbproc        => $X->{dbproc},
                 to_server     => $X->{to_server},
                 to_client     => $X->{to_client},
                 dbNullIsUndef => 1,
                 dbKeepNumeric => 1,
                 cloneFlag     => 1,
                 errInfo       => {maxSeverity => 10,
                                   printLines  => 1,
                                   printMsg    => 1,
                                   printPrints => 1}};
   bless $clone, $packname;
}

#--------------------- check_style_params, internal -------------------
sub check_style_params {
# Checks that row- and resultstyle parameters are correct, and provides
# defaults.
    my($rowstyle) = \$_[0];
    my($resultstyle) = \$_[1];
    my($keys)        = $_[2];

    # Default values for style parameters
    $$rowstyle    = $$rowstyle    || HASH;
    $$resultstyle = $$resultstyle || SINGLESET;

    # Check that style parameters are legal
    unless (grep ($_ == $$rowstyle, (SCALAR, LIST, HASH))) {
       croak "$packname: Illegal rowstyle value: $$rowstyle";
    }
    unless (grep ($_ == $$resultstyle,
                 (NORESULT, SINGLEROW, SINGLESET, MULTISET, KEYED))
            or ref $$resultstyle eq "CODE") {
       croak "$packname: Illegal resultstyle value: $$resultstyle";
    }

    # If result style is KEYED, check that we have a sensible keys.
    if ($$resultstyle == KEYED) {
       croak "$packname: No keys given for result style KEYED" unless $keys;
       croak "$packname: \$keys is not a list reference" unless ref $keys eq "ARRAY";
       croak "$packname: Empty key array given for resultstyle KEYED" if @$keys == 0;
       if ($$rowstyle != HASH) {
          croak "$packname: \@\$keys must be numeric for rowstyle LIST/SCALAR"
             if grep(/\D/, @$keys);
       }
    }
}

#------------------- get_object_id, internal ---------------------------
sub get_object_id {
   my($X, $objspec) = @_;
# Retrieves the object id for a database object.

    my(@objspec, $objdb, $owner, $object, $objid);

    # First split the table spec into db, owner and object
    @objspec = split(/\./, $objspec);
    unshift(@objspec, "") while (@objspec < 3);
    ($objdb, $owner, $object) = @objspec;

    # A temporary object is per definition in tempdb.
    if ($object =~ /^#/) {
       $objdb = "tempdb";
    }

    # Now we can reconstruct the object specification.
    $objspec = "$objdb.$owner.$object";

    # Get the object-id.
    $objid = $X->sql_one("SELECT object_id('$objspec')");

    # If no luck, it might still be a system procedure.
    if (! $objid && $objspec =~ /^\.\.sp_/) {
       $objdb = "master";
       $objspec = "master..$object";
       $objid = $X->sql_one("SELECT object_id('$objspec')");
    }

    # Return id and database
    ($objid, $objdb);
}

#---------------------- get_result_sets, internal ---------------------------------
sub get_result_sets {
    my($X, $rowstyle, $resultstyle, $keys) = @_;

    my ($stat, $userstat, $is_callback, $isregular, $ix, $ressetno, $dataref,
        $resref, $keyed_res);

    $is_callback = ref $resultstyle eq "CODE";
    $isregular   = grep ($_ == $resultstyle, (MULTISET, SINGLESET, SINGLEROW));

    $X->{errInfo}{dieFlag} = 0;
    $ix = $ressetno = 0;
    $keyed_res = {};
    $userstat = RETURN_NEXTROW;
    while ($X->dbresults != NO_MORE_RESULTS) {
       die "dbresults failed" if $X->{errInfo}{dieFlag};

       $ressetno++;

       # He said NORESULT? Cancel the query, and proceed to next.
       if ($resultstyle == NORESULT) {
          $X->dbcanquery();
          die "dbcanquery failed" if $X->{errInfo}{dieFlag};
          next;
       }

       # For the regular resultstyles create an empty array, if there is none at
       # the current index.
       if ($isregular) {
          @{$$resref[$ix]} = () unless defined @{$$resref[$ix]};
       }

       do {
          $stat = $X->dbnextrow2($dataref, $rowstyle == HASH);
          die "dbnextrow failed" if $X->{errInfo}{dieFlag};

          if ($stat != NO_MORE_ROWS and $stat != FAIL and $stat != BUF_FULL) {
             # Convert to client charset before anything else.
             $X->do_conversion('to_client', $dataref);

             # For hash, add extra column for COMPUTE row.
             if ($rowstyle == HASH and $X->{ComputeID}) {
                $$dataref{COMPUTEID} = $X->{ComputeID};
             }

             # For SCALAR convert to joined string. (But for KEYED, this is deferred.)
             if ($rowstyle == SCALAR and $resultstyle != KEYED) {
                $dataref = list_to_scalar($dataref);
             }


             # Save the row if we have a regular resultstyle.
             if ($isregular) {
                push(@{$$resref[$ix]}, $dataref);
             }
             elsif ($resultstyle == KEYED) {
                # This is keyed access.
                store_keyed_result($X, $rowstyle, $keys, $dataref, $keyed_res);
             }
             elsif ($is_callback) {
                $userstat = &$resultstyle($dataref, $ressetno);

                $X->{errInfo}{dieFlag} = 0;
                if ($userstat == RETURN_NEXTQUERY) {
                # He wants next result set, so leave this one.
                   $X->dbcanquery;
                   die "dbcanquery failed" if $X->{errInfo}{dieFlag};
                }
                elsif ($userstat != RETURN_NEXTROW) {
                # Whatever, cancel the entire batch.
                   $X->dbcancel;
                   if ($userstat == RETURN_ABORT) {
                      croak "User-supplied callback returned RETURN_ABORT";
                   }
                   elsif ($userstat != RETURN_CANCEL and $userstat != RETURN_ERROR) {
                      croak "User-supplied callback returned unknown return code";
                   }
                   elsif ($X->{errInfo}{dieFlag}) {
                      die "dbcancel failed";
                   }
                }
             }
          }
       }  until $stat == NO_MORE_ROWS;

       # If multiset requested advance index
       $ix++ if $resultstyle == MULTISET;
    }

    if ($is_callback) {
       return $userstat;
    }
    elsif (wantarray) {
       if    ($resultstyle == MULTISET)  {return @$resref }
       elsif ($resultstyle == SINGLESET) {return @{$$resref[0]} }
       elsif ($resultstyle == SINGLEROW) {
           if    ($rowstyle == HASH)
              { return (defined $$resref[0][0] ? %{$$resref[0][0]} : () )}
           elsif ($rowstyle == LIST)
              { return (defined $$resref[0][0] ? @{$$resref[0][0]} : () )}
           elsif ($rowstyle == SCALAR) { return @{$$resref[0]} }
       }
       elsif ($resultstyle == KEYED) { return %$keyed_res; }
       else  { return ()}
    }
    else {
       if    ($resultstyle == MULTISET)  {return $resref }
       elsif ($resultstyle == SINGLESET) {return $$resref[0] }
       elsif ($resultstyle == SINGLEROW) {return $$resref[0][0] }
       elsif ($resultstyle == KEYED)     {return $keyed_res }
       else  { return undef}
    }
}

#----------------------------- list_to_scalar ------------------------
# This routine takes a data array and returns a scalar from it. Care
# if being taken to avoid "unitialized value" warnings.
sub list_to_scalar {
   my ($arr) = @_;
   local($^W) = 0;
   if (@$arr == 0) {
      return undef;
   }
   else {
      return join($SQLSEP, @$arr);
   }
}


#------------------------------ stored_keyed_result ---------------------
# This routine implements KEYED access. The key columns are removed from the
# list/hash that $dataref points to and added as keys to $keyed_res.
sub store_keyed_result {
   my ($X, $rowstyle, $keys, $dataref, $keyed_res) = @_;

   my ($ix, $keyvalue, $keyname, $keyno, $ref, $keystr);

   $ref = $keyed_res;
   $keystr = "";

   # Loop over the keys.
   foreach $ix (0..$#$keys) {
      # First find the key value, different strategies with different row styles.
      if ($rowstyle == HASH) {
         # Get the key name.
         $keyname = $$keys[$ix];

         # If the key does not exist, we give up.
         unless (exists $$dataref{$keyname}) {
            $X->dbcancel;
            croak "No key '$keyname' in result set";
         }

         # Get the key value, and delete it from the data.
         $keyvalue = $$dataref{$keyname};
         delete $$dataref{$keyname};
      }
      else {
         # Now we have a key number.
         $keyno = $$keys[$ix];

         # It must be a valid index in the result set.
         unless ($keyno >= 1 and $keyno <= $#$dataref + 1) {
             $X->dbcancel;
             croak "Key number '$keyno' is not valid in result set";
         }

         # Get the key value, but don't touch @$dataref yet.
         $keyvalue = $$dataref[$keyno - 1];
      }

      # If this is not the last key, just create the node.
      if ($ix < $#$keys) {
         $ref = \%{$$ref{$keyvalue}};
      }

      # Add keys to debug string, for use in warning messages.
      $keystr .= "<$keyvalue>" if $^W;
   }

   # Now we can remove data from an array - had we done this above, the key numbers
   # wouldn't have matched.
   if ($rowstyle != HASH) {
      foreach $ix (reverse sort @$keys) {
         splice(@$dataref, $ix - 1, 1);
      }

      # If we're talking scalar, convert at this point
      if ($rowstyle == SCALAR) {
         $dataref = list_to_scalar($dataref);
      }
   }


   # At this point $ref{$keyvalue} is where we want to store the rest of the data.
   # Just check that the spot is not already occupied.
   if ($^W) {
      warn "Key(s) $keystr is not unique" if exists $$ref{$keyvalue};
   }

   # And write into the result set.
   $$ref{$keyvalue} = $dataref;
}
#
1;
