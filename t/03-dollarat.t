#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;

use autodie;

my $cmd = 'bin/hashmake';

my $other_makefile   = 'other.makefile';
my $work_dir         = tempdir ( CLEANUP => 1 );

{
    #  Test that expanding $@ works correctly.

    #  From test 02: I'm going to use a temporary directory and create a
    #  temporary Hash_Makefile with a $@ element in the command line.

    my @list = qw/foo bar/;

    my $stderr_file   = File::Spec->catfile ( $work_dir, 'stderr.out' );
    my $hash_makefile = File::Spec->catfile ( $work_dir, $other_makefile );
    my $indexfile     = File::Spec->catfile ( $work_dir, '.hash_index' );

    open ( my $fh, '>', $hash_makefile );
    foreach my $t ( @list ) {

      print $fh "$t\n" . q{    echo "Target is $@"} . "\n";
    }
    close ( $fh );

    #  Suspiciously similar to the common_test_block in test 02.

    #  Before the run .. check there's no index file.

    ok ( ! -e $indexfile, "Index file doesn't exiat before first run" );

    #  First run: Should see all Targets.

    my $line = join ( ' ', $cmd, "-f $hash_makefile" );
    my @result = qx/$line 2>$stderr_file/;
 
    ok (  @result, "There is output after first run" );
    ok ( -z $stderr_file, "No errors from first run" );

    ok ( -e $indexfile, "Index file exists after first run" );

    #  Check that we saw each target exctly once, and no unexpected targets.

    my %lookfor = map { $_ => undef } @list;
    foreach my $l ( @result ) {

      my ( $t ) = $l =~ /Target is (\S+)/;
      ok ( defined $t, "Target is defined" );
      ok ( exists $lookfor{ $t }, "Saw target $t" );

      delete $lookfor{ $t };
    }
    is ( scalar keys %lookfor, 0, "All keys found" );

    #  Second run: Should do nothing.

    @result = qx/$line 2>$stderr_file/;

    ok ( ! @result, "There is no output after second run" );
    ok ( -z $stderr_file, "No errors after second runs" );

    done_testing;
}
