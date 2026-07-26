#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

my $cmd = 'bin/hashmake';

my $default_makefile = 'Hash.Makefile';     #  Duplicated from module :/
my $other_makefile   = 'other.makefile';
my $env_makefile     = 'env.makefile';

{
    ok ( -e $cmd, "Script found" );
    ok ( -x $cmd, "Script is executable" );

    #  I want to just test that argument parsing is working, so that means
    #  debug is always set.

    my $d = 1;

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

	    my $last_make_file;
            foreach my $l ( @result ) {

              unlike ( $l, qr/Unknown option:/, "Did not see 'unknown option'" ); 

              if ( $l =~ /print_only: (\d)/ ) {

                my $value = $1;
                is ( $value, $n, "Pring value matches" );
              }

              if ( $l =~ /makefile: (\S+)/ ) {

                #  The order of precedence is 1) command line, 2)
                #  environment, and 3) default.

                $last_make_file = $1;
                if ( $f ) {

                  is ( $last_make_file, $other_makefile, "Other makefile" );

                }
                elsif ( $e ) {

                  is ( $last_make_file, $env_makefile, "Env makefile" );

                } else
                {

                  is ( $last_make_file, $default_makefile, "Default makefile" );
                }
              }

	      if ( $l =~ /No targets specified and no makefile found/ ) {

	        ok ( ! -e $last_make_file, "Makefile $last_make_file not found" );
	      }
            }
          } else {

            is ( @result, 0, "No results because not debug" );
          }

        }
      }
    }

    done_testing;
}
