#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;

my $cmd = 'bin/hashmake';

my $default_makefile = 'Hash.Makefile';     #  Duplicated from module :/
my $other_makefile   = 'other.makefile';
my $env_makefile     = 'env.makefile';
my $work_dir         = tempdir ( CLEANUP => 1 );

{
    ok ( -e $cmd, "Script found" );
    ok ( -x $cmd, "Script is executable" );

    #  I want to just test that argument parsing is working, so that means
    #  debug is always set.

    my $d = 1;

    #  Use a temporary file for STDERR so that it doesn't mess up the display
    #  during tests.

    my $stderr_file = File::Spec->catfile ( $work_dir, 'stderr.out' );

    foreach my $n ( 0..1 ) {          #  Print Only

      foreach my $f ( 0..1 ) {        #  Specify makefile

        foreach my $e ( 0..1 ) {      #  Environment has makefile

          foreach my $w ( 0..1 ) {    #  Working directory specified

            foreach my $r ( 0..1 ) {    #  Force rebuild

              my ( @args, @env );

              if ( $d ) { push ( @args, '-d' ); }
              if ( $n ) { push ( @args, '-n' ); }
              if ( $f ) { push ( @args, "-f $other_makefile" ); }
              if ( $e ) { push ( @env,  "HASH_MAKEFILE=$env_makefile" ); }
              if ( $w ) { push ( @args, "-w $work_dir" ); }
              if ( $r ) { push ( @args, '-r' ); }

              my $line = join ( ' ', @env, $cmd, @args );
              my @result = qx/$line 2>$stderr_file/;

              #  If anything came out of STDERR, add it to the output list.

              if ( ! -z $stderr_file ) {

                open ( my $fh, '<', $stderr_file );
                push ( @result, <$fh> );
                close $fh;
              }

              #  Since this filename is reused each time through the loop, it's
              #  not necessary to delete it at this point.

              my $last_make_file;
              foreach my $l ( @result ) {

                unlike ( $l, qr/Unknown option:/, "Did not see 'unknown option'" ); 

                if ( $l =~ /print_only: (\d)/ ) {

                  my $value = $1;
                  is ( $value, $n, "Printing value matches" );

                  next;
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

                  next;
                }

                if ( $l =~ /No makefile found/ ) {

                  ok ( ! -e $last_make_file, "Makefile $last_make_file not found" );

                  next;
                }

                if ( $w && $l =~ /working_dir: (\S+)/ ) {

                  my $value = $1;
                  is ( $value, $work_dir, "Working directory requested" );

                  next;
                }

                if ( $l =~ /Settings:/ ) {

                  next;
                }

                if ( $l =~ /force_rebuild: (\d)/ ) {

                  my $value = $1;
                  is ( $value, $r, "Force rebuild value matches" );

                  next;
                }

                #  If there was something that I wasn't expecting, complain.

                fail ( "Unexpected output: $l" );
              }
            }
          }
        }
      }
    }

    done_testing;
}
