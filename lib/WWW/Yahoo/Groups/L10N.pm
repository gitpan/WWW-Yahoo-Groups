package WWW::Yahoo::Groups::L10N;
use strict;
use warnings;
use vars qw( @ISA %Lexicon );
%Lexicon = ( '_AUTO' => 1 );

our $VERSION = '1.00';

=head1 NAME

WWW::Yahoo::Groups::L10N - Localized messages for WWW::Yahoo::Groups

=head1 SYNOPSIS

    use WWW::Yahoo::Groups::L10N;
    my $lh = WWW::Yahoo::Groups::L10N->get_handle;
    $lh->maketext("Hello, world!\n");

=cut

# If we can internationalise, C<$i18n> is still true by the end.
{
    my $i18n = 1;
    if (eval { require Locale::Maketext; require Locale::Maketext::Lexicon; 1 })
    {
	@ISA = 'Locale::Maketext';

	require File::Spec;
	require File::Basename;

	my ($name, $path) = File::Basename::fileparse(__FILE__, '.pm');

	my @languages;
	foreach my $lexicon ( glob( File::Spec->catfile($path, $name, '*.po')) ) {
	    File::Basename::basename($lexicon) =~ /^(\w+).po$/ or next;
	    push @languages, $1;
	};

	eval
	{
	    Locale::Maketext::Lexicon->import( {
		    map { lc($_) => [Gettext => "$_.po"] } @languages
		}
	    );
	};
	undef $i18n if $@;
    }
    @ISA = 'WWW::Yahoo::Groups::L10N::_stub' unless $i18n;
}

# Ensure we get _some_ sort of object.

sub get_handle
{
    my $self = shift;
    my $handle = $self->SUPER::get_handle(@_);
    return $handle if $handle;
    @ISA = 'WWW::Yahoo::Groups::L10N::_stub';
    return $self->SUPER::get_handle(@_);
}

package WWW::Yahoo::Groups::L10N::_stub;

sub get_handle
{
    my $class = ref($_[0]) || $_[0];
    return bless {}, $class;
}

sub new {
    my ($class, %args) = @_;
    $class = ref($class) if defined(ref $class);

    return bless(\%args, $class);
}

# Basic substitution.
sub maketext {
    my ($self, $str, @params) = @_;
    my $i = 1;
    foreach (@params)
    {
        $str =~ s/\[_$i\]/$_/g;
        $i++;
    }
    return $str;
}

1;

__END__

=head1 THANKS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt> for writing
C<Acme::Hello> -- a paragon of modules -- on which this
precise module is based.

=head1 BUGS

Please report bugs at <bug-www-yahoo-groups@rt.cpan.org>
or via the web interface at L<http://rt.cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright E<copy> Iain Truskett, 2002. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Iain Truskett <spoon@cpan.org>

=head1 SEE ALSO

L<Locale::Maketext>, L<Locale::Maketext::Lexicon>

=cut
