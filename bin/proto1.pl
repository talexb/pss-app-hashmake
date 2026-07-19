#!/usr/bin/perl

use strict;
use warnings;

use Digest::MD5 qw(md5_hex);

# 2026-0715: Prototype for HashMake. The real one will do most of it's stuff in
# a module in order to make it easier to test. For now, let's get the logic
# sorted out

{
    #  Check on the makefile, nothing can happen without that. For now, this
    #  defaults to a file in the local directory.

    my $make_file = './Hash_Makefile';
    if ( ! -e $make_file ) {

      print "WARN: Hash Makefile $make_file not found\n";
      exit;
    }

    #  Since that's where the makefile, the index file will (?) be in the same
    #  direcory. If the file's not there, we'll just end up with an empty hash.
    #  That's fine.

    my $index_file = './.hash_index';
    my %hash_values = ();

    if ( -e $index_file ) {

      open ( my $fh, '<', $index_file );
      while ( <$fh> ) {

	#  Ths file format is going to be filename, followed by at least one
	#  space, followed by the hash value (shown as an MD5 here). This will
	#  allow us to handle files with embedded spaces. I hope. This file is
	#  going to be a data file only, and will not have comments.

        my ( $target, $md5 ) = /^(.+)\s+(.+)$/;
	$hash_values{ $target } = $md5;
      }
      close ( $fh );
    }

    #  Read the makefile, so that we can undeerstand the targets.

    open ( my $fh, '<', $make_file );
    my ( %config, $target );

    undef $target;

    while ( <$fh> ) {

      next if ( /^#/ );		#  Skip comments

      my $line = $_;
      if ( $line =~ /^\s$/ ) {

	#  Blank line means we're doing with this target's commands if that's
	#  what we were doing.

        undef $target;
	next;
      }
      
      #  Strip leading spaces and trailing new lines.

      $line =~ s/^\s+x$//;
      $line =~ s/\s+$//;

      if ( defined $target ) {

	#  We have a target, so this is a command line for it.

        push ( @{ $config{ $target } }, $line );

      } else {

        ( $target ) = $line;
	$config{ $target } = ();	#  No commands for this target so far.
      }
    }
    close ( $fh );

    if ( !keys %config ) {

      print "INFO: No targets found, done.\n";
      exit;
    }

    # Now it's time to check out each target. At this point, we're going to be
    # checking them in heap order (so, random). I assume that's going to be
    # fine.

    my $action_count = 0;
    foreach my $target ( keys %config ) {

      #  Find the MD5 of the target, and see if our value matches the one from
      #  the index file.

      if ( !-e $target ) {

        print "WARN: Target $target does not exist.\n";
	next;
      }

      open ( my $fh, '<', $target );
      my $md5 = Digest::MD5->new;
      $md5->addfile ( $fh );
      close ( $fh );

      my $digest = $md5->hexdigest;
      my $action = 0;	#  No action yet;

      #  If there are keys, a key exists for this target, and the MD5 value is
      #  different, OR if there are no keys at all, then do the thing.

      if ( ( keys %hash_values && exists $hash_values{ $target } &&
             $hash_values{ $target } ne $digest ) ||
	   !keys %hash_values ) {

	$action = 1;
	$hash_values{ $target } = $digest;
      }

      #  If we're going to do the actions, this is where it happens. Later,
      #  we update the index file before we exit.

      if ( $action ) {

        print "INFO: Perform some actions for the target $target.\n";
	print join ( "\n", map { "--> $_" } @{ $config{ $target } } ) . "\n";
	$action_count++;

      } else {

        print "DEBUG: Nothing to do for the target $target.\n";
      }

    }

    if ( $action_count ) {

      #  We did some actions, time to update the index.

      open ( my $fh, '>', $index_file );
      print $fh join ( "\n",
        map { "$_ $hash_values{ $_ }" } keys %hash_values ) . "\n";
      close ( $fh );

      print "DEBUG: Updated index file $index_file.\n";
    }
}
