#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/Sqllib/t/1_resultsets.t 3     02-12-24 23:48 Sommar $
#
# $History: 1_resultsets.t $
# 
# *****************  Version 3  *****************
# User: Sommar       Date: 02-12-24   Time: 23:48
# Updated in $/Perl/MSSQL/Sqllib/t
# Run with $^W = 1, so that test of warnings work,
#
# *****************  Version 2  *****************
# User: Sommar       Date: 01-05-01   Time: 22:51
# Updated in $/Perl/MSSQL/Sqllib/t
# Added tests for style parameters errors. Added tests for the case there
# are not result sets due to error.
#
# *****************  Version 1  *****************
# User: Sommar       Date: 99-01-30   Time: 16:36
# Created in $/Perl/MSSQL/sqllib/t
#---------------------------------------------------------------------

use strict;
use MSSQL::Sqllib qw(:DEFAULT :consts);
use File::Basename qw(dirname);

use vars qw(@testres $verbose);

sub blurb{
    push (@testres, "------ Testing @_ ------\n");
    print "------ Testing @_ ------\n" if $verbose;
}

$verbose = shift @ARGV;

$^W = 1;

$| = 1;

my($X, $line, $sql, $sql1, $sql_empty, $sql_error, $sql_key1, $sql_key_many,
   %result, @result, $result, %expect, @expect, $expect);

use vars qw($Srv $Uid $Pwd);
require &dirname($0) . '\sqllogin.pl';

$X = sql_init($Srv, $Uid, $Pwd, "tempdb");

# Accept all errors, and be silent about them.
$X->{errInfo}{maxSeverity}   = 25;
$X->{errInfo}{printLines} = 25;
$X->{errInfo}{printMsg}   = 25;
$X->{errInfo}{printText}  = 25;

$SQLSEP = '@!@';

# First set up tables and data.
sql(<<SQLEND);
CREATE TABLE #a(a char(1), b char(1), i int)
CREATE TABLE #b(x char(3) NULL)
CREATE TABLE #c(key1  char(5)     NOT NULL,
                key2  char(1)     NOT NULL,
                key3  int         NOT NULL,
                data1 smallint    NULL,
                data2 varchar(10) NULL,
                data3 char(1)     NOT NULL)

INSERT #a VALUES('A', 'A', 12)
INSERT #a VALUES('A', 'D', 24)
INSERT #a VALUES('A', 'H', 1)
INSERT #a VALUES('C', 'B', 12)

INSERT #b VALUES('xyz')
INSERT #b VALUES(NULL)

INSERT #c VALUES('apple', 'X', 1, NULL, NULL,      'T')
INSERT #c VALUES('apple', 'X', 2, -15,  NULL,      'T')
INSERT #c VALUES('apple', 'X', 3, NULL, NULL,      'T')
INSERT #c VALUES('apple', 'Y', 1, 18,   'Verdict', 'H')
INSERT #c VALUES('apple', 'Y', 6, 18,   'Maracas', 'I')
INSERT #c VALUES('peach', 'X', 1, 18,   'Lastkey', 'T')
INSERT #c VALUES('peach', 'X', 8, 4711, 'Monday',  'T')
INSERT #c VALUES('melon', 'Y', 1, 118,  'Lastkey', 'T')
SQLEND

# This is our test batch: three result sets whereof one empty.
$sql = <<SQLEND;
SELECT *
FROM   #a
ORDER  BY a, b
COMPUTE SUM(i) BY a
COMPUTE SUM(i)

SELECT * FROM #a WHERE a = '?'

SELECT * FROM #b
SQLEND

# Test code for single-row queries.
$sql1 = "SELECT * FROM #a WHERE i = 24";

# Test code for empty result sets
$sql_empty = <<SQLEND;
SELECT * FROM #a WHERE i = 456
SELECT * FROM #a WHERE a = 'z'
SQLEND

# Test code with incorrect SQL which will not produce even a resultset,
$sql_error = 'SELECT FROM';

# Test code for keyed access.
$sql_key1     = "SELECT * FROM #a";
sql("CREATE PROCEDURE #sql_key_many AS SELECT * FROM #c");

#-------------------- MULTISET ----------------------------
&blurb("HASH, MULTISET, wantarray");
@expect = ([{a => 'A', b => 'A', i => 12},
            {a => 'A', b => 'D', i => 24},
            {a => 'A', b => 'H', i => 1},
            {COMPUTEID => 1, i => 37},
            {a => 'C', b => 'B', i => 12},
            {COMPUTEID => 1, i => 12},
            {COMPUTEID => 2, i => 49}],
           [],
           [{'x' => 'xyz'},
            {'x' => undef}]);
@result = sql($sql, HASH, MULTISET);
push(@testres, compare(\@expect, \@result));

&blurb("HASH, MULTISET, wantscalar");
$result = sql($sql, HASH, MULTISET);
push(@testres, compare(\@expect, $result));


&blurb("LIST, MULTISET, wantarray");
@expect = ([['A', 'A', 12],
            ['A', 'D', 24],
            ['A', 'H', 1],
            [37],
            ['C', 'B', 12],
            [12],
            [49]],
           [],
           [['xyz'],
            [undef]]);
@result = sql($sql, LIST, MULTISET);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, MULTISET, wantscalar");
$result = sql($sql, LIST, MULTISET);
push(@testres, compare(\@expect, $result));

&blurb("SCALAR, MULTISET, wantarray");
@expect = (['A@!@A@!@12',
            'A@!@D@!@24',
            'A@!@H@!@1',
            '37',
            'C@!@B@!@12',
            '12',
            '49'],
           [],
           ['xyz',
            '']);
@result = sql($sql, MULTISET, SCALAR);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, MULTISET, wantscalar");
$result = sql($sql, SCALAR, MULTISET);
push(@testres, compare(\@expect, $result));

#--------------------- MULTISET empty, empty ------------------------
@expect = ([], []);
&blurb("HASH, MULTISET empty, wantarray");
@result = sql($sql_empty, HASH, MULTISET);
push(@testres, compare(\@expect, \@result));

&blurb("HASH, MULTISET empty, wantscalar");
$result = sql($sql_empty, HASH, MULTISET);
push(@testres, compare(\@expect, $result));

&blurb("LIST, MULTISET empty, wantarray");
@result = sql($sql_empty, LIST, MULTISET);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, MULTISET empty, wantscalar");
$result = sql($sql_empty, LIST, MULTISET);
push(@testres, compare(\@expect, $result));

&blurb("SCALAR, MULTISET empty, wantarray");
@result = sql($sql_empty, SCALAR, MULTISET);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, MULTISET empty, wantscalar");
$result = sql($sql_empty, SCALAR, MULTISET);
push(@testres, compare(\@expect, $result));


#--------------------- MULTISET error   ------------------------
@expect = ();
&blurb("HASH, MULTISET error, wantarray");
@result = sql($sql_error, HASH, MULTISET);
push(@testres, compare(\@expect, \@result));

&blurb("HASH, MULTISET error, wantscalar");
$result = sql($sql_error, HASH, MULTISET);
push(@testres, compare(undef, $result));

&blurb("LIST, MULTISET error, wantarray");
@result = sql($sql_error, LIST, MULTISET);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, MULTISET error, wantscalar");
$result = sql($sql_error, LIST, MULTISET);
push(@testres, compare(undef, $result));

&blurb("SCALAR, MULTISET error, wantarray");
@result = sql($sql_error, SCALAR, MULTISET);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, MULTISET error, wantscalar");
$result = sql($sql_error, SCALAR, MULTISET);
push(@testres, compare(undef, $result));


#-------------------- SINGLESET ----------------------------
&blurb("HASH, SINGLESET, wantarray");
@expect = ({a => 'A', b => 'A', i => 12},
           {a => 'A', b => 'D', i => 24},
           {a => 'A', b => 'H', i => 1},
           {COMPUTEID => 1, i => 37},
           {a => 'C', b => 'B', i => 12},
           {COMPUTEID => 1, i => 12},
           {COMPUTEID => 2, i => 49},
           {'x' => 'xyz'},
           {'x' => undef});
@result = sql($sql);
push(@testres, compare(\@expect, \@result));

&blurb("HASH, SINGLESET, wantscalar");
$result = sql($sql);
push(@testres, compare(\@expect, $result));


&blurb("LIST, SINGLESET, wantarray");
@expect = (['A', 'A', 12],
           ['A', 'D', 24],
           ['A', 'H', 1],
           [37],
           ['C', 'B', 12],
           [12],
           [49],
           ['xyz'],
           [undef]);
@result = sql($sql, LIST);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, SINGLESET, wantscalar");
$result = sql($sql, undef, LIST);
push(@testres, compare(\@expect, $result));

&blurb("SCALAR, SINGLESET, wantarray");
@expect = ('A@!@A@!@12',
           'A@!@D@!@24',
           'A@!@H@!@1',
           '37',
           'C@!@B@!@12',
           '12',
           '49',
           'xyz',
           '');
@result = sql($sql, SCALAR);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, SINGLESET, wantscalar");
$result = sql($sql, SCALAR);
push(@testres, compare(\@expect, $result));


#--------------------- SINGLESET, empty ------------------------
@expect = ();
&blurb("HASH, SINGLESET empty, wantarray");
@result = sql($sql_empty, HASH, SINGLESET);
push(@testres, compare(\@expect, \@result));

&blurb("HASH, SINGLESET empty, wantscalar");
$result = sql($sql_empty, HASH, SINGLESET);
push(@testres, compare(\@expect, $result));

&blurb("LIST, SINGLESET empty, wantarray");
@result = sql($sql_empty, LIST, SINGLESET);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, SINGLESET empty, wantscalar");
$result = sql($sql_empty, LIST, SINGLESET);
push(@testres, compare(\@expect, $result));

&blurb("SCALAR, SINGLESET empty, wantarray");
@result = sql($sql_empty, SCALAR, SINGLESET);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, SINGLESET empty, wantscalar");
$result = sql($sql_empty, SCALAR, SINGLESET);
push(@testres, compare(\@expect, $result));

#-------------------- SINGLESET, error ----------------------
@expect = ();
&blurb("HASH, SINGLESET error, wantarray");
@result = sql($sql_error, HASH, SINGLESET);
push(@testres, compare(\@expect, \@result));

&blurb("HASH, SINGLESET error, wantscalar");
$result = sql($sql_error, HASH, SINGLESET);
push(@testres, compare(undef, $result));

&blurb("LIST, SINGLESET error, wantarray");
@result = sql($sql_error, LIST, SINGLESET);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, SINGLESET error, wantscalar");
$result = sql($sql_error, LIST, SINGLESET);
push(@testres, compare(undef, $result));

&blurb("SCALAR, SINGLESET error, wantarray");
@result = sql($sql_error, SCALAR, SINGLESET);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, SINGLESET error, wantscalar");
$result = sql($sql_error, SCALAR, SINGLESET);
push(@testres, compare(undef, $result));

#-------------------- SINGLEROW ----------------------------
&blurb("HASH, SINGLEROW, wantarray");
%expect = (a => 'A', b => 'D', i => 24);
%result = sql($sql1, undef, SINGLEROW);
push(@testres, compare(\%expect, \%result));

&blurb("HASH, SINGLEROW, wantscalar");
$result = sql($sql1, SINGLEROW, undef);
push(@testres, compare(\%expect, $result));

&blurb("LIST, SINGLEROW, wantarray");
@expect = ('A', 'D', 24);
@result = sql($sql1, LIST, SINGLEROW);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, SINGLEROW, wantscalar");
$result = sql($sql1, LIST, SINGLEROW);
push(@testres, compare(\@expect, $result));

&blurb("SCALAR, SINGLEROW, wantarray");
@expect = ('A@!@D@!@24');
@result = sql($sql1, SCALAR, SINGLEROW);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, SINGLEROW, wantscalar");
$expect = 'A@!@D@!@24';
$result = sql($sql1, SCALAR, SINGLEROW);
push(@testres, compare($expect, $result));


#--------------------- SINGLEROW, empty ------------------------
@expect = ();
&blurb("HASH, SINGLEROW empty, wantarray");
@result = sql($sql_empty, HASH, SINGLEROW);
push(@testres, compare(\@expect, \@result));

&blurb("HASH, SINGLEROW empty, wantscalar");
$result = sql($sql_empty, HASH, SINGLEROW);
push(@testres, compare(undef, $result));

&blurb("LIST, SINGLEROW empty, wantarray");
@result = sql($sql_empty, LIST, SINGLEROW);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, SINGLEROW empty, wantscalar");
$result = sql($sql_empty, LIST, SINGLEROW);
push(@testres, compare(undef, $result));

&blurb("SCALAR, SINGLEROW empty, wantarray");
@result = sql($sql_empty, SCALAR, SINGLEROW);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, SINGLEROW empty, wantscalar");
$result = sql($sql_empty, SCALAR, SINGLEROW);
push(@testres, compare(undef, $result));

#--------------------- SINGLEROW, error -------------------
@expect = ();
&blurb("HASH, SINGLEROW error, wantarray");
@result = sql($sql_error, HASH, SINGLEROW);
push(@testres, compare(\@expect, \@result));

&blurb("HASH, SINGLEROW error, wantscalar");
$result = sql($sql_error, HASH, SINGLEROW);
push(@testres, compare(undef, $result));

&blurb("LIST, SINGLEROW error, wantarray");
@result = sql($sql_error, LIST, SINGLEROW);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, SINGLEROW error, wantscalar");
$result = sql($sql_error, LIST, SINGLEROW);
push(@testres, compare(undef, $result));

&blurb("SCALAR, SINGLEROW error, wantarray");
@result = sql($sql_error, SCALAR, SINGLEROW);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, SINGLEROW error, wantscalar");
$result = sql($sql_error, SCALAR, SINGLEROW);
push(@testres, compare(undef, $result));


#-------------------- sql_one ----------------------------
&blurb("HASH, sql_one, wantarray");
%expect = (a => 'A', b => 'D', i => 24);
%result = sql_one($sql1);
push(@testres, compare(\%expect, \%result));

&blurb("HASH, sql_one, wantscalar");
$result = sql_one($sql1, HASH);
push(@testres, compare(\%expect, $result));

&blurb("LIST, sql_one, wantarray");
@expect = ('A', 'D', 24);
@result = sql_one($sql1, LIST);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, sql_one, wantscalar");
$result = sql_one($sql1, LIST);
push(@testres, compare(\@expect, $result));

&blurb("SCALAR, sql_one, wantscalar");
$expect = 'A@!@D@!@24';
$result = sql_one($sql1);
push(@testres, compare($expect, $result));

&blurb("SCALAR, sql_one, two ressets, one row");
$result = sql_one("SELECT * FROM #b WHERE 1 = 0 $sql1");
push(@testres, compare($expect, $result));

&blurb("sql_one, fail: no rows");
eval("sql_one('SELECT * FROM #a WHERE i = 897')");
push(@testres, ($@ =~ /returned no/ ? 1 : 0));

&blurb("sql_one, fail: too many rows");
eval("sql_one('SELECT * FROM #a')");
push(@testres, ($@ =~ /more than one/ ? 1 : 0));

&blurb("sql_one, fail: two ressets, two rows");
eval("sql_one('SELECT 1 SELECT 2')");
push(@testres, ($@ =~ /more than one/ ? 1 : 0));


#-------------------- NORESULT ----------------------------
&blurb("HASH, NORESULT, wantarray");
@expect = ();
$expect = undef;
@result = sql($sql, HASH, NORESULT);
push(@testres, compare(\@expect, \@result));

&blurb("HASH, NORESULT, wantscalar");
$result = sql($sql, HASH, NORESULT);
push(@testres, compare($expect, $result));

&blurb("LIST, NORESULT, wantarray");
@result = sql($sql, LIST, NORESULT);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, NORESULT, wantscalar");
$result = sql($sql, LIST, NORESULT);
push(@testres, compare($expect, $result));

&blurb("SCALAR, NORESULT, wantarray");
@result = sql($sql, SCALAR, NORESULT);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, NORESULT, wantscalar");
$result = sql($sql, SCALAR, NORESULT);
push(@testres, compare($expect, $result));


#---------------------- KEYED, single key -------------------
&blurb("HASH, KEYED, single key, wantarray");
%expect = ('A' => {'a' => 'A', 'i' => 12},
           'D' => {'a' => 'A', 'i' => 24},
           'H' => {'a' => 'A', 'i' => 1},
           'B' => {'a' => 'C', 'i' => 12});
%result = sql($sql_key1, KEYED, ['b']);
push(@testres, compare(\%expect, \%result));

&blurb("HASH, KEYED, single key, wantref");
$result = sql($sql_key1, HASH, KEYED, ['b']);
push(@testres, compare(\%expect, $result));

&blurb("LIST, KEYED, single key, wantarray");
%expect = ('A' => ['A', 12],
           'D' => ['A', 24],
           'H' => ['A', 1],
           'B' => ['C', 12]);
%result = sql($sql_key1, LIST, KEYED, [2]);
push(@testres, compare(\%expect, \%result));

&blurb("LIST, KEYED, single key, wantref");
$result = sql($sql_key1, LIST, KEYED, [2]);
push(@testres, compare(\%expect, $result));

&blurb("SCALAR, KEYED, single key, wantarray");
%expect = ('A' => 'A@!@12',
           'D' => 'A@!@24',
           'H' => 'A@!@1',
           'B' => 'C@!@12');
%result = sql($sql_key1, SCALAR, KEYED, [2]);
push(@testres, compare(\%expect, \%result));

&blurb("SCALAR, KEYED, single key, wantref");
$result = sql($sql_key1, SCALAR, KEYED, [2]);
push(@testres, compare(\%expect, $result));


#---------------------- KEYED, multiple key -------------------
&blurb("HASH, KEYED, multiple key, wantarray");
%expect = ('apple' => {'X' => {'1' => {data1 => undef, data2 => undef,     data3 => 'T'},
                               '2' => {data1 => -15,   data2 => undef,     data3 => 'T'},
                               '3' => {data1 => undef, data2 => undef,     data3 => 'T'}
                              },
                       'Y' => {'1' => {data1 => 18,    data2 => 'Verdict', data3 => 'H'},
                               '6' => {data1 => 18,    data2 => 'Maracas', data3 => 'I'}
                              }
                      },
           'peach' => {'X' => {'1' => {data1 => 18,    data2 => 'Lastkey', data3 => 'T'},
                               '8' => {data1 => 4711,  data2 => 'Monday',  data3 => 'T'}
                               }
                      },
           'melon' => {'Y' => {'1' => {data1 => 118,   data2 => 'Lastkey',  data3 => 'T'}
                              }
                      }
          );
%result = sql_sp('#sql_key_many', HASH, KEYED, ['key1', 'key2', 'key3']);
push(@testres, compare(\%expect, \%result));

&blurb("HASH, KEYED, multiple key, wantref");
$result = sql_sp('#sql_key_many', HASH, KEYED, ['key1', 'key2', 'key3']);
push(@testres, compare(\%expect, $result));

&blurb("LIST, KEYED, mulitple key, wantarray");
%expect = ('apple' => {'X' => {'1' => [undef, undef,    'T'],
                               '2' => [-15,   undef,    'T'],
                               '3' => [undef, undef,    'T']
                              },
                       'Y' => {'1' => [18,   'Verdict', 'H'],
                               '6' => [18,   'Maracas', 'I']
                              }
                      },
           'peach' => {'X' => {'1' => [18,   'Lastkey', 'T'],
                               '8' => [4711, 'Monday',  'T']
                               }
                      },
           'melon' => {'Y' => {'1' => [118,  'Lastkey', 'T']
                              }
                      }
          );
%result = sql_sp('#sql_key_many', LIST, KEYED, [1, 2, 3]);
push(@testres, compare(\%expect, \%result));

&blurb("LIST, KEYED, multiple key, wantref");
$result = sql_sp('#sql_key_many', LIST, KEYED, [1, 2, 3]);
push(@testres, compare(\%expect, $result));

&blurb("SCALAR, KEYED, multiple key, wantarray");
%expect = ('apple' => {'X' => {'1' => '@!@@!@T',
                               '2' => '-15@!@@!@T',
                               '3' => '@!@@!@T'
                              },
                       'Y' => {'1' => '18@!@Verdict@!@H',
                               '6' => '18@!@Maracas@!@I'
                              }
                      },
           'peach' => {'X' => {'1' => '18@!@Lastkey@!@T',
                               '8' => '4711@!@Monday@!@T'
                               }
                      },
           'melon' => {'Y' => {'1' => '118@!@Lastkey@!@T'
                              }
                      }
          );
%result = sql_sp('#sql_key_many', SCALAR, KEYED, [1, 2, 3]);
push(@testres, compare(\%expect, \%result));

&blurb("SCALAR, KEYED, multiple key, wantref");
$result = sql_sp('#sql_key_many', SCALAR, KEYED, [1, 2, 3]);
push(@testres, compare(\%expect, $result));

#-------------------- KEYED, empty ----------------------
%expect = ();
&blurb("HASH, KEYED empty, wantarray");
%result = sql($sql_empty, HASH, KEYED, ['a']);
push(@testres, compare(\%expect, \%result));

&blurb("HASH, KEYED empty, wantscalar");
$result = sql($sql_empty, HASH, KEYED, ['a']);
push(@testres, compare(\%expect, $result));

&blurb("LIST, KEYED empty, wantarray");
%result = sql($sql_empty, LIST, KEYED, [1]);
push(@testres, compare(\%expect, \%result));

&blurb("LIST, KEYED empty, wantscalar");
$result = sql($sql_empty, LIST, KEYED, [1]);
push(@testres, compare(\%expect, $result));

&blurb("SCALAR, KEYED empty, wantarray");
%result = sql($sql_empty, SCALAR, KEYED, [1]);
push(@testres, compare(\%expect, \%result));

&blurb("SCALAR, KEYED empty, wantscalar");
$result = sql($sql_empty, SCALAR, KEYED, [1]);
push(@testres, compare(\%expect, $result));

#--------------------- KEYED, sql_error  -------------------
@expect = ();
&blurb("HASH, KEYED error, wantarray");
@result = sql($sql_error, HASH, KEYED, ['a']);
push(@testres, compare(\@expect, \@result));

&blurb("HASH, KEYED error, wantscalar");
$result = sql($sql_error, HASH, KEYED, ['a']);
push(@testres, compare(undef, $result));

&blurb("LIST, KEYED error, wantarray");
@result = sql($sql_error, LIST, KEYED, [1]);
push(@testres, compare(\@expect, \@result));

&blurb("LIST, KEYED error, wantscalar");
$result = sql($sql_error, LIST, KEYED, [1]);
push(@testres, compare(undef, $result));

&blurb("SCALAR, KEYED error, wantarray");
@result = sql($sql_error, SCALAR, KEYED, [1]);
push(@testres, compare(\@expect, \@result));

&blurb("SCALAR, KEYED error, wantscalar");
$result = sql($sql_error, SCALAR, KEYED, [1]);
push(@testres, compare(undef, $result));

#------------------- KEYED, call errors -----------------
&blurb("KEYED, no keys list");
eval('sql("SELECT * FROM #a", HASH, KEYED)');
push(@testres, $@ =~ /no keys/i ? 1 : 0);

&blurb("KEYED, illegal type \$keys");
eval('sql("SELECT * FROM #a", KEYED, undef, "a")');
push(@testres, $@ =~ /not a .*reference/i ? 1 : 0);

&blurb("KEYED, empty keys list");
eval('sql("SELECT * FROM #a", HASH, KEYED, [])');
push(@testres, $@ =~ /empty/i ? 1 : 0);

&blurb("KEYED, undefined key name");
eval('sql("SELECT * FROM #a", HASH, KEYED, ["bogus"])');
push(@testres, $@ =~ /no key\b.*in result/i ? 1 : 0);

&blurb("KEYED, key out of range");
eval('sql("SELECT * FROM #a", LIST, KEYED, [47])');
push(@testres, $@ =~ /number .*not valid/i ? 1 : 0);

&blurb("KEYED, not unique");
eval(<<'EVALEND');
    local $SIG{__WARN__} = sub {$X->dbcancel; die $_[0]};
    sql("SELECT * FROM #a", LIST, KEYED, [1]);
EVALEND
push(@testres, $@ =~ /not unique/i ? 1 : 0);


#-------------------- &callback ----------------------------
use vars qw ($ix $ok $cancel_ix $error_ix);
my ($retstat);
sub callback {
   my ($row, $ressetno) = @_;
   if ($expect[$ix][0] != $ressetno or
       not compare($row, $expect[$ix++][1])) {
      $ok = 0;
      return RETURN_CANCEL;
   }
   if ($ix == $cancel_ix) {
      return RETURN_NEXTQUERY;
   }
   if ($ix == $error_ix) {
      return RETURN_ERROR;
   }
   RETURN_NEXTROW;
}

&blurb("HASH, &callback");
@expect = ([1, {a => 'A', b => 'A', i => 12}],
           [1, {a => 'A', b => 'D', i => 24}],
           [1, {a => 'A', b => 'H', i => 1}],
           [1, {COMPUTEID => 1, i => 37}],
           [1, {a => 'C', b => 'B', i => 12}],
           [1, {COMPUTEID => 1, i => 12}],
           [1, {COMPUTEID => 2, i => 49}],
           [3, {'x' => 'xyz'}],
           [3, {'x' => undef}]);
$ix = 0;
$cancel_ix = 0;
$error_ix = 0;
$ok = 1;
$retstat = sql($sql, \&callback);
if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_NEXTROW) {
   push(@testres, 1);
}
else {
   push(@testres, 0);
}

&blurb("LIST, &callback");
@expect = ([1, ['A', 'A', 12]],
           [1, ['A', 'D', 24]],
           [1, ['A', 'H', 1]],
           [1, [37]],
           [3, ['xyz']],
           [3, [undef]]);
$ix = 0;
$cancel_ix = 4;
$error_ix = 0;
$ok = 1;
$retstat = sql($sql, LIST, \&callback);
if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_NEXTROW) {
   push(@testres, 1);
}
else {
   push(@testres, 0);
}

$ix = 0;
$cancel_ix = 0;
$error_ix = 3;
$ok = 1;
&blurb("SCALAR, &callback");
@expect = ([1, 'A@!@A@!@12'],
           [1, 'A@!@D@!@24'],
           [1, 'A@!@H@!@1']);
$retstat = sql($sql, \&callback, SCALAR);
if ($ok == 1 and $ix == $#expect + 1 and $retstat == RETURN_ERROR) {
   push(@testres, 1);
}
else {
   push(@testres, 0);
}

#------------------------ Various style-parameter erros.
&blurb("Bogus row style 1");
eval('sql("SELECT * FROM #a", -23, KEYED)');
push(@testres, $@ =~ /Illegal row.* -23 at/i ? 1 : 0);

&blurb("Bogus row style 2");
eval('sql("SELECT * FROM #a", undef, -23)');
push(@testres, $@ =~ /Illegal row.* -23 at/i ? 1 : 0);

&blurb("Bogus row style 3");
eval('sql("SELECT * FROM #a", SINGLESET, -23)');
push(@testres, $@ =~ /Illegal row.* -23 at/i ? 1 : 0);

&blurb("Bogus result style");
eval('sql("SELECT * FROM #a", LIST, -23)');
push(@testres, $@ =~ /Illegal result.* -23 at/i ? 1 : 0);

&blurb("Two row styles");
eval('sql("SELECT * FROM #a", LIST, HASH)');
push(@testres, $@ =~ /Illegal result.* 93 at/i ? 1 : 0);

&blurb("Two result styles");
eval('sql("SELECT * FROM #a", SINGLESET, MULTISET)');
push(@testres, $@ =~ /Illegal row.* 139 at/i ? 1 : 0);


my $no_of_tests = 3 * 6 * 4 +  # Four resultstyles with result and empty.
                  6 + 6 +      # Extra test for KEYED (mulitple + errors)
                  5 + 4 +      # sql_one, five regular + error
                  6 + 3 +      # NORESULT, 6 empty + 3 callback.
                  6;           # Style errors.
print "1..$no_of_tests\n";

my $ix = 1;
my $blurb = "";
foreach $result (@testres) {
   if ($result =~ /^--/) {
      print $result if $verbose;
      $blurb = $result;
   }
   elsif ($result == 1) {
      printf "ok %d\n", $ix++;
   }
   else {
      printf "not ok %d\n$blurb", $ix++;
   }
}

exit;

sub compare {
   my ($x, $y) = @_;

   my ($refx, $refy, $ix, $key, $result);


   $refx = ref $x;
   $refy = ref $y;

   if (not $refx and not $refy) {
      if (defined $x and defined $y) {
         warn "<$x> ne <$y>" if $x ne $y;
         return ($x eq $y);
      }
      else {
         return (not defined $x and not defined $y);
      }
   }
   elsif ($refx ne $refy) {
      return 0;
   }
   elsif ($refx eq "ARRAY") {
      if ($#$x != $#$y) {
         return 0;
      }
      elsif ($#$x >= 0) {
         foreach $ix (0..$#$x) {
            $result = compare($$x[$ix], $$y[$ix]);
            last if not $result;
         }
         return $result;
      }
      else {
         return 1;
      }
   }
   elsif ($refx eq "HASH") {
      my $nokeys_x = scalar(keys %$x);
      my $nokeys_y = scalar(keys %$y);
      if ($nokeys_x != $nokeys_y) {
         return 0;
      }
      elsif ($nokeys_x > 0) {
         foreach $key (keys %$x) {
            if (not exists $$y{$key}) {
                return 0;
            }
            $result = compare($$x{$key}, $$y{$key});
            last if not $result;
         }
         return $result;
      }
      else {
         return 1;
      }
   }
   elsif ($refx eq "SCALAR") {
      return compare($$x, $$y);
   }
   else {
      return ($x eq $y);
   }
}
