package App::HashMake;

use 5.008003;
use strict;
use warnings;

use Env qw(HASH_MAKEFILE);

use File::Spec;
use Digest::MD5;

=head1 NAME

App::HashMake - The great new App::HashMake!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our $default_hash_makefile = 'Hash.Makefile';
our $index_file = '.hash_index';

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use App::HashMake;

    my $result = App::HashMake->run();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 run

=cut

our $verb = 1;      #  Verbosity. 0 - quiet, 1 - normal, 2 - debug.
our ( @out, @err ); #  Output and Error lists to be returned to caller.

sub run
{
    my ( $args ) = @_;

    my $debug      = exists $args->{d} ? 1 : 0;
    my $print_only = exists $args->{n} ? 1 : 0;
    my $makefile   = exists $args->{f} ?
      $args->{f} : ( $HASH_MAKEFILE // $default_hash_makefile );
    my $work_dir   = $args->{w};

    if ($debug) {

      $verb++;

      my @out = (
        "Settings:",
        "--> print_only: $print_only",
        "--> makefile: $makefile"
      );
      if ( defined $work_dir ) {

        push( @out, "--> working_dir: $work_dir" );
      }
      msg ( @out );
    }

    if ( ! -e $makefile ) {

      err ( "$0: ERROR: No makefile found, done." );

      return ( 0, { out => \@out, err => \@err } );
    }

    #  The file we're versioning may be in a directory that we can't write to,
    #  so the caller will have set up a working directory for us to use
    #  instead.

    my ( $vol, $dir, $file );
    if ( defined $work_dir ) {

      #  Check that this directory exists.

      if ( ! -e $work_dir ) {

        err ( "$work_dir doesn't exist" );
        return ( 0, { out => \@out, err => \@err } );
      }

      $dir = $work_dir;

    } else {

      #  OK, at this point we do have a makefile, so we need to locate the index
      #  file, which should be in the same directory. If it's there, we'll load
      #  up the hash values.

      ( $vol, $dir, $file ) = File::Spec->splitpath ( $makefile );

    }
    my $full_index_file = File::Spec->catfile ( $dir, $index_file );

    #  Let's check that we can write to this directory -- if not, exit with an
    #  error.

    if ( ! -w $dir ) {

      err ( "$0: $dir is not writable" );

      return ( 0, { out => \@out, err => \@err } );
    }

    #  OK, we've dealt with all of the input parameters, and now we're ready to
    #  start actually doing The Thing.

    my %hash_values = ();

    if ( -e $full_index_file ) {

      open ( my $fh, '<', $full_index_file );
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

    open ( my $fh, '<', $makefile );
    my ( %config, $target );

    undef $target;

    while ( <$fh> ) {

      next if ( /^#/ );		#  Skip comments

      my $line = $_;
      if ( $line =~ /^\s+$/ ) {

        #  Blank line means we're doing with this target's commands if we had a
        #  target to begin with.

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

        #  Unlike a makefile, which has a target and then a list of dependents,
        #  we just have a target.

        ( $target ) = $line;
        $config{ $target } = ();	#  No commands for this target so far.
      }
    }
    close ( $fh );

    #  Nothing actionable in the makefile? Get out.

    if ( !keys %config ) {

      msg ( "$0: WARN: No targets found, done." );
      return ( 0, { out => \@out, err => \@err } );
    }

    # Now it's time to check out each target. At this point, we're going to be
    # checking them in heap order (so, random). I assume that's going to be
    # fine.

    my $action_count = 0;
    foreach my $target ( keys %config ) {

      #  Find the MD5 of the target, and see if our value matches the one from
      #  the index file.

      if ( !-e $target ) {

        msg ( "$0: WARN: Target $target does not exist." );
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

        if ( $print_only ) {

          msg ( map { "Would run this --> $_" } @{ $config{ $target } } );

        } else {

          foreach my $cmd ( @{ $config{ $target } } ) {

            system ( $cmd );        #  Run the command. Yikes.
          }
          $action_count++;
        }

      } else {

        dbg ( "DEBUG: Nothing to do for the target $target." );
      }

    }

    if ( $action_count ) {

      #  We did some actions, time to update the index.

      open ( my $fh, '>', $full_index_file );
      print $fh join ( "\n",
        map { "$_ $hash_values{ $_ }" } keys %hash_values ) . "\n";
      close ( $fh );

      dbg ( "DEBUG: Updated full_index file $full_index_file." );
    }
    return ( 0, { out => \@out, err => \@err } );
}

sub dbg
{
    my ( @msg ) = @_;

   if ( $verb > 1 ) { push ( @out, @msg ); }
}

sub msg
{
    my ( @msg ) = @_;

   push ( @out, @msg );
}

sub err
{
    my ( @msg ) = @_;

   push ( @err, @msg );
}

=head1 AUTHOR

T. Alex Beamish <talexb@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-hashmake at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-HashMake>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::HashMake


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=App-HashMake>

=item * GitHub issue tracker

L<https://github.com/talexb/App-HashMake/issues>

=item * Search CPAN

L<https://metacpan.org/release/App-HashMake>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by T. Alex Beamish <talexb@gmail.com>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of App::HashMake
