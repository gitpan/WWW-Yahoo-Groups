package WWW::Yahoo::Groups::Mechanize;
use base 'WWW::Mechanize';
use Params::Validate qw( validate_pos SCALAR );
use WWW::Yahoo::Groups::L10N;
our $lh = WWW::Yahoo::Groups::L10N->get_handle or die "Could not get localization handle!";
require WWW::Yahoo::Groups::Errors; 
Params::Validate::validation_options(
    WWW::Yahoo::Groups::Errors->import($lh)
);

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->cookie_jar({ });
    $self->agent("Mozilla/5.0 (LWP; $class)");
    return $self;
}

sub debug
{
    my $self = shift;
    $self->{__PACKAGE__.'-debug'} = ($_[0] ? 1 : 0) if @_;
    $self->{__PACKAGE__.'-debug'};
}

sub get
{
    my $self = shift;
    my $url = $_[0];
    warn "Fetching $url\n" if $self->debug;
    my $rv;
    $rv = eval {
	# Fetch page
	my $rv = $self->SUPER::get(@_);
	# Throw if problem
	X::WWW::Yahoo::Groups::BadFetch->throw(error =>
	    $lh->maketext("Unable to fetch [_1]: ", $url).
	    $self->res->code.' - '.$self->res->message)
		if ($self->res->is_error);
	# Sleep for a bit
	if (my $s = $self->autosleep() )
	{
	    sleep( $s );
	}
	# Return something
	0;
    };
    if ($@) {
	die $@ unless ref $@;
	$@->rethrow if $@->fatal;
	$rv = $@;
    }
    return $rv;
}

sub is_error { 0 }

sub autosleep
{
    my $w = shift;
    if (@_) {
	my ($sleep) = validate_pos( @_,
	    { type => SCALAR, callbacks => {
		    $lh->maketext('is integer') => sub { shift() =~ /^ \d+ $/x },
		    $lh->maketext('not negative') => sub { shift() >= 0 },
		} }, # number
	);
	$w->{__PACKAGE__.'-sleep'} = $sleep;
    }
    return $w->{__PACKAGE__.'-sleep'}||0;
}

1;
