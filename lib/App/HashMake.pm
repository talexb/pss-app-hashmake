package App::HashMake;

use 5.008003;
use strict;
use warnings;

use Env qw(HASH_MAKEFILE);

=head1 NAME

App::HashMake - The great new App::HashMake!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

our $default_hash_makefile = 'Hash.Makefile';

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

sub run
{
    my ( $args ) = @_;

    my $debug      = exists $args->{d} ? 1 : 0;
    my $print_only = exists $args->{n} ? 1 : 0;
    my $makefile =   exists $args->{f} ?
      $args->{f} : ( $HASH_MAKEFILE // $default_hash_makefile );

    if ( $debug ) {

      print "Settings:\n";
      print "--> print_only: $print_only\n";
      print "--> makefile: $makefile\n";
    }

    if ( ! -e $makefile ) {

      msg ( "$0: *** No targets specified and no makefile found.  Stop." );

      return ( 0 );
    }

    return ( 0 );
}

sub msg
{
    my ( $msg ) = @_;

    print "$msg\n";	#  Will need to be gated on debug, verbosity and quiet flags.
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
