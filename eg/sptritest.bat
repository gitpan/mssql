@rem = '--*-PERL-*--';
@rem = '
@echo off
rem setlocal
set ARGS=
:loop
if .%1==. goto endloop
set ARGS=%ARGS% %1
shift
goto loop
:endloop
rem ***** This assumes PERL is in the PATH *****
perl.exe -S sptritest.bat %ARGS%
goto endofperl
@rem ';
@rem = <<'START';
#---------------------------------------------------------------------
#  $Header: /projects/dbverktyg/skript/sptritest.bat 2     98-03-13 18:42 Sommar $
#
#  Executes all stored procedures, triggers and views in a database,
#  and print the errors that occurs. The purpose is to find errors that
#  prevents building of query plans for the objects.
#
#  The test is carried out with nonsense data. DO NOT run this script on
#  a database with data you care about. Take a dump and run it on a copy.
#
#  A handful of errors which are likely to arise from the nonsense data
#  are ignored. Remaining errors are printed.
#
#  Note: only objects owned by dbo are considered.
#
#  $History: sptritest.bat $
#  ---------------------------------------------------------------------*/
START

use strict qw(vars subs);

use MSSQL::Sqllib qw(:DEFAULT :consts);
use MSSQL::DBlib;
use Getopt::Long;

my($opt_database, $opt_Server, $opt_Password, $opt_User, $opt_progress, $USAGE);

$Getopt::Long::ignorecase = 0;
$opt_User = "sa";
$opt_database = "tempdb";
$opt_progress = 40;
$USAGE = "sptritest -database db -Server server -Password pwd [-User sa] [-progress n]";
GetOptions("database=s"     => \$opt_database,
           "Server=s"       => \$opt_Server,
           "Password=s"     => \$opt_Password,
           "User=s"         => \$opt_User,
           "progress=i"     => \$opt_progress)
  or die "$USAGE\n";


# Log in and get a handle.
my($X) = sql_init($opt_Server, $opt_User, $opt_Password, $opt_database);

# Get all procedures and the number of parameters they have.
my(@procs) = sql(<<SQLEND);
     SELECT o.name, no_of_par = COUNT(*)
     FROM   sysobjects o, syscolumns c
     WHERE  o.id = c.id
       AND  o.uid = 1
       AND  o.type = 'P'
     GROUP  BY o.name
   UNION
     SELECT o.name, no_of_par = 0
     FROM   sysobjects o, sysusers u
     WHERE  o.uid = 1
       AND  NOT EXISTS (SELECT *
                        FROM   syscolumns c
                        WHERE  c.id = o.id)
       AND  o.type = 'P'
   ORDER BY 1
SQLEND

# Get all views
my(@views) = sql(<<SQLEND);
   SELECT name
   FROM   sysobjects
   WHERE  uid = 1
     AND  type = 'V'
   ORDER  BY name
SQLEND

# Get all tables and their triggers
my(@tables) = sql(<<SQLEND);
   SELECT o.name, instrig = i.name, updtrig = p.name, deltrig = d.name
   FROM   sysobjects o, sysobjects i, sysobjects p, sysobjects d
   WHERE  nullif(o.instrig, 0) *= i.id
     AND  nullif(o.updtrig, 0) *= p.id
     AND  nullif(o.deltrig, 0) *= d.id
     AND  o.type = "U"
     AND  o.uid = 1
   ORDER  BY o.name
SQLEND

# Go through the tables, and do 1) clear when a trigger appears twice. 2)
# for update and insert triggers get the columns.
my $tbl;
foreach $tbl (@tables) {
   next unless $tbl->{'instrig'} or $tbl->{'updtrig'} or $tbl->{'deltrig'};

   # Clear double-function triggers, with priority to 1) INSERT 2) UPDATE.
   if ($tbl->{'updtrig'} eq $tbl->{'instrig'}) {
       $tbl->{'updtrig'} = undef;
   }
   if ($tbl->{'deltrig'} eq $tbl->{'instrig'}) {
       $tbl->{'deltrig'} = undef;
   }
   if ($tbl->{'deltrig'} eq $tbl->{'updtrig'}) {
       $tbl->{'deltrig'} = undef;
   }

   if ($tbl->{'instrig'} or $tbl->{'updtrig'}) {
      my($name) = $tbl->{'name'};
      $tbl->{'columns'} = sql(<<SQLEND, SCALAR);
          SELECT c.name
          FROM   syscolumns c, sysobjects o
          WHERE  c.id = o.id
            AND  o.name = '$name'
            AND  c.status & 0x80 = 0
            AND  c.usertype <> 80
SQLEND
   }
}

# Set up the error handling we want. That is print nothing, but send the
# the messages back to us.
setup_errinfo($X);

my($i) = 0;

# Iterate over the tables
foreach $tbl (@tables) {
   next unless $tbl->{'instrig'} or $tbl->{'updtrig'} or $tbl->{'deltrig'};

   # Print current item, if it's time for that.
   $i++;
   if ($opt_progress == 1 or $opt_progress > 1 and $i % $opt_progress == 1) {
      print STDERR $tbl->{'name'}, "\n";
   }

   # Attempt a DELETE if there is a DELETE trigger.
   if ($tbl->{'deltrig'}) {
      $X->sql("DELETE " . $tbl->{'name'} . " WHERE 1 = 0", HASH, NORESULT);

      # Examine the error messages
      examine_msgs($X, $tbl->{'deltrig'});
   }

   # Same for an UPDATE trigger.
   if ($tbl->{'updtrig'}) {
      my ($col) = $tbl->{'columns'}->[$#{$tbl->{'columns'}} / 2];
      my $sql = "UPDATE " . $tbl->{'name'} . " SET  $col = $col WHERE 1 = 0";
      $X->sql($sql, HASH, NORESULT);

      # Examine the error messages
      examine_msgs($X, $tbl->{'updtrig'});
   }

   # And a INSERT trigger
   if ($tbl->{'instrig'}) {
      my $sql = "INSERT " . $tbl->{'name'} . " ( " .
                join(", ", @{$tbl->{'columns'}}) . ") SELECT " .
                join(", ", @{$tbl->{'columns'}}) . " FROM " . $tbl->{'name'} .
                " WHERE 1 = 0";
      $X->sql($sql, HASH, NORESULT);

      # Examine the error messages
      examine_msgs($X, $tbl->{'instrig'});
   }
}


# Do the views.
my $view;
foreach $view (@views) {

   # Print current item, if it's time for that.
   $i++;
   if ($opt_progress == 1 or $opt_progress > 1 and $i % $opt_progress == 1) {
      print STDERR $view->{'name'}, "\n";
   }

   # SELECT from view, ignore the result.
   $X->sql("SELECT * FROM " . $view->{'name'}, HASH, NORESULT);

   # Examine the error messages
   examine_msgs($X, $view->{'name'});
}

# Now, iterate over the procedures.
my $proc;
foreach $proc (@procs) {

   # Fill a trash list as many values we need. We pick a value that goes
   # with all kinds of parameters.
   my(@parameters);
   my($dummy) = "Feb 5 1997";
   my $i;
   foreach $i (1..$proc->{no_of_par}) {
      push(@parameters, \$dummy);
   }

   # Print current procedure, if we've came that far.
   $i++;
   if ($opt_progress == 1 or $opt_progress > 1 and $i % $opt_progress == 1) {
      print STDERR $proc->{'name'}, "\n";
   }

   # Call the SP, ditch the result set.
   $X->sql_sp($proc->{'name'}, \@parameters, HASH, NORESULT);

   # Examine the error messages
   examine_msgs($X, $proc->{'name'});
}


sub examine_msgs {
   my($X, $name) = @_;
# Prints messages in $X, filtering out those that are known to be execution
# errors, bound to happen due to the nonsense we send as parameters.

   # These are errors we ignore:
   my(@ignored_errors) = (513,  # RULE violation
                          515,  # Attempt to insert NULL.
                          532,  # timestamp error
                          547,  # CONSTRAINT violation
                          2627, # PRIMARY KEY violation
                          );

   my($name_printed) = 0;

   # Iterate over the message array.
   my $msg;
   foreach $msg (@{$X->{errInfo}{messages}}) {
      # Skip if severity <= 10 (information).
      next if $msg->{'severity'} <= 10;

      # Skip user-defined errors, and as defined above.
      next if $msg->{'errno'} >= 50000 or
              grep($_ == $msg->{'errno'}, @ignored_errors);

      # Print a heading for the first error for this item.
      print "=========== $name ===========\n"
          if not $name_printed++;
      print "Msg: " . $msg->{'errno'} . "  Severity: " . $msg->{'severity'} .
            "  Proc: " . $msg->{'proc'} . "  Line: " . $msg->{'line'} . "   " .
            $msg->{'text'} . "\n";
   }
   print "\n" if $name_printed;

   # Erase the messages.
   delete $X->{errInfo}{messages};

   # If things when really bad DBprocess is dead, then we need to log in
   # again.
   if ($X->DBDEAD) {
      $X = sql_init($opt_Server, $opt_User, $opt_Password, $opt_database);
      setup_errinfo($X);
   }
}


sub setup_errinfo{
   my($X) = @_;
   $X->{errInfo}{maxSeverity} = 30;
   $X->{errInfo}{printMsg} = 30;
   $X->{errInfo}{printText} = 30;
   $X->{errInfo}{printLines} = 30;
   $X->{errInfo}{alwaysPrint} = undef;
   $X->{errInfo}{checkRetStat} = 0;
   $X->{errInfo}{saveMessages} = 1;
}

__END__
:endofperl
