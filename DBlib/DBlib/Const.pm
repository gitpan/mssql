#---------------------------------------------------------------------
# $Header: /Perl/MSSQL/DBlib/DBlib/Const.pm 2     99-01-30 16:58 Sommar $
# Copyright (c) 1997-1999 Erland Sommarskog
#
# MSSQL::DBlib::Const
# - All SQL and DBlib constants gathered together in one file. You can also
#   choose to use only the modules which have the constants you really need.
#
# $History: Const.pm $
# 
# *****************  Version 2  *****************
# User: Sommar       Date: 99-01-30   Time: 16:58
# Updated in $/Perl/MSSQL/DBlib/DBlib
# Added kludge to avoid warnings for redefinition.
#---------------------------------------------------------------------

package MSSQL::DBlib::Const;

use strict;

use vars qw(@ISA @EXPORT);

use MSSQL::DBlib::Const::Aggregates;
use MSSQL::DBlib::Const::BCP;
use MSSQL::DBlib::Const::Cursor;
use MSSQL::DBlib::Const::Datatypes;
use MSSQL::DBlib::Const::DBSETLNAME;
use MSSQL::DBlib::Const::Errors;
use MSSQL::DBlib::Const::MaxValues;
use MSSQL::DBlib::Const::NetlibErrors;
use MSSQL::DBlib::Const::Offset;
use MSSQL::DBlib::Const::Options;
use MSSQL::DBlib::Const::Print;
use MSSQL::DBlib::Const::RPC;
use MSSQL::DBlib::Const::ServerInfo;
use MSSQL::DBlib::Const::Severity;
use MSSQL::DBlib::Const::Streamtokens;
use MSSQL::DBlib::Const::Text;
use MSSQL::DBlib::Const::Timeout;

# This is a kludge to avoid warnings about redefined subroutines.
BEGIN {local($^W) = 0;
       require 'MSSQL/DBlib/Const/General.pm';
       import MSSQL::DBlib::Const::General;
      }


@ISA = qw(Exporter
          MSSQL::DBlib::Const::Aggregates
          MSSQL::DBlib::Const::BCP
          MSSQL::DBlib::Const::Cursor
          MSSQL::DBlib::Const::Datatypes
          MSSQL::DBlib::Const::DBSETLNAME
          MSSQL::DBlib::Const::Errors
          MSSQL::DBlib::Const::General
          MSSQL::DBlib::Const::MaxValues
          MSSQL::DBlib::Const::NetlibErrors
          MSSQL::DBlib::Const::Offset
          MSSQL::DBlib::Const::Options
          MSSQL::DBlib::Const::Print
          MSSQL::DBlib::Const::RPC
          MSSQL::DBlib::Const::ServerInfo
          MSSQL::DBlib::Const::Severity
          MSSQL::DBlib::Const::Streamtokens
          MSSQL::DBlib::Const::Text
          MSSQL::DBlib::Const::Timeout);

@EXPORT = (@MSSQL::DBlib::Const::Aggregates::EXPORT,
           @MSSQL::DBlib::Const::BCP::EXPORT,
           @MSSQL::DBlib::Const::Cursor::EXPORT,
           @MSSQL::DBlib::Const::Datatypes::EXPORT,
           @MSSQL::DBlib::Const::DBSETLNAME::EXPORT,
           @MSSQL::DBlib::Const::Errors::EXPORT,
           @MSSQL::DBlib::Const::General::EXPORT,
           @MSSQL::DBlib::Const::MaxValues::EXPORT,
           @MSSQL::DBlib::Const::NetlibErrors::EXPORT,
           @MSSQL::DBlib::Const::Offset::EXPORT,
           @MSSQL::DBlib::Const::Options::EXPORT,
           @MSSQL::DBlib::Const::Print::EXPORT,
           @MSSQL::DBlib::Const::RPC::EXPORT,
           @MSSQL::DBlib::Const::ServerInfo::EXPORT,
           @MSSQL::DBlib::Const::Severity::EXPORT,
           @MSSQL::DBlib::Const::Streamtokens::EXPORT,
           @MSSQL::DBlib::Const::Text::EXPORT,
           @MSSQL::DBlib::Const::Timeout::EXPORT);

1;
