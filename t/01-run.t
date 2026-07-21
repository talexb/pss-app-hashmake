#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $cmd = 'bin/hashmake';

my $default_makefile = 'Hash.Makefile';     #  Duplicated from module :/
my $other_makefile   = 'other_makefile';
my $env_makefile     = 'env_makefile';

{
    ok ( -e $cmd, "Script found" );
    ok ( -x $cmd, "Script is executable" );

    foreach my $d ( 0..1 ) {            #  Debug

      foreach my $n ( 0..1 ) {          #  Print Only

        foreach my $f ( 0..1 ) {        #  Specify makefile

          foreach my $e ( 0..1 ) {      #  Environment has makefile

            my ( @args, @env );

            if ( $d ) { push ( @args, '-d' ); }
            if ( $n ) { push ( @args, '-n' ); }
            if ( $f ) { push ( @args, "-f $other_makefile" ); }
            if ( $e ) { push ( @env,  "HASH_MAKEFILE=$env_makefile" ); }

            my $line = join ( ' ', @env, $cmd, @args );
            my @result = qx/$line/;

            if ( $d ) {

              foreach my $l ( @result ) {

                unlike ( $l, qr/Unknown option:/, "Did not see 'unknown option'" ); 
                if ( $l =~ /print_only: (\d)/ ) {

                  my $value = $1;
                  is ( $value, $n, "Pring value matches" );
                }

                if ( $l =~ /makefile: (\S+)/ ) {

                  #  The order of precedence is 1) command line, 2)
                  #  environment, and 3) default.

                  my $value = $1;
                  if ( $f ) {

                    is ( $value, $other_makefile, "Other makefile" );

                  }
                  elsif ( $e ) {

                    is ( $value, $env_makefile, "Env makefile" );

                  } else
                  {

                    is ( $value, $default_makefile, "Default makefile" );
                  }
                }
              }
            } else {

              is ( @result, 0, "No results because not debug" );
            }

          }
        }
      }
    }

    done_testing;
}
