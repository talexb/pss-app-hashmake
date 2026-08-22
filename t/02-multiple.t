#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;

use Data::Dumper;	# XXX Remove later

my $cmd = 'bin/hashmake';

my $other_makefile   = 'other.makefile';
my $work_dir         = tempdir ( CLEANUP => 1 );

{
    #  Test that we can handle multiple targets (no continuation lines yet).

    #  I'm going to use a temporary directory and create a temporary
    #  Hash_Makefile with 1, 2 and 3 files, and also create those three files.
    #  The code to handle this doesn't exist yet, so everything will be wrapped
    #  in a TODO block.

    my @list = qw/foo bar baz/;

    TODO: {

      local $TODO = 'Under development';

      my $stderr_file   = File::Spec->catfile ( $work_dir, 'stderr.out' );
      my $hash_makefile = File::Spec->catfile ( $work_dir, $other_makefile );
      my $indexfile     = File::Spec->catfile ( $work_dir, '.hash_index' );

      foreach my $c ( 1..2 ) {

        #  Touch the last file so that the module finds a file to look at.

	open ( my $fh, '>', $list[ ($c-1) ] );
	print $fh "Something something\n";
	close ( $fh );

        my $targets = join ( ' ', @list[ 0..($c-1) ] );
	ok ( 1, "Targets are $targets" );

 	open ( $fh, '>', $hash_makefile );
 	print $fh join ( "\n", $targets, "  echo \"Targets are $targets\"", '' );
 	close ( $fh );
 
 	#  First run: Should see all Targets.

	my $line = join ( ' ', $cmd, "-f $hash_makefile" );
	my @result = qx/$line 2>$stderr_file/;
 
  	ok (  @result, "There is output" );
  	ok ( -z $stderr_file, "No errors" );

	ok ( -e $indexfile, "Index file exiata" );

	like ( $result[ 0 ], qr/Targets are $targets/, "Target message seen" );

	#  Seecond run: Should do nothing.

	#  Here we need to do cleanup so that the index file isn't here the
	#  next time through the loop. Except make(1) doesn't have a command
	#  line option to clean, and the module I'm calling also doesn't have a
	#  method to clean. So maybe I need to add that later.

        ok ( unlink ( $indexfile ), "Index file deleted" );
      }
    }
    done_testing;
}
