package WWW::Yahoo::Groups;
use strict;
use warnings;

=head1 NAME

WWW::Yahoo::Groups - automated access to Yahoo! Groups.

=head1 SYNOPSIS

    my $y = WWW::Yahoo::Groups->new();
    $y->login( $user => $pass );
    $y->list( 'Jade_Pagoda' );
    my $email = $y->fetch_message( 2345 );

=head1 DESCRIPTION

C<WWW::Yahoo::Groups> is a subclass of C<WWW::Mechanize>, overriding a
few methods and supplying a few extra. As such, any method available in
C<WWW::Mechanize> is available to C<WWW::Yahoo::Groups>, perhaps
augmented with extra features.

=head2 Things it will do

=over 4

=item *

Handle access restricted archives. It lets you login.

=item *

Handle the intermittent advertisements. It notes that it got one and
progresses straight to the message.

=back

=head2 Things it won't do (yet)

=over 4

=item *

Handle attachments.

=item *

Handle errors.

=back

As these are recognised flaws, they are on the L</TODO> list.

=cut

use base 'WWW::Mechanize';
use Carp;
use HTTP::Cookies;
use HTML::Entities;

=head1 METHODS

=head2 new()

Create a new C<WWW::Yahoo::Groups> robot.

    my $y = WWW::Yahoo::Groups->new();

=cut

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->cookie_jar({ });
    $self->agent("Mozilla/5.0 (LWP; WWW::Mechanize)");
    $self->debug(0);
    return bless $self, $class;
}

=head2 debug()

Enable/disable/read debugging mode.

    $y->debug(0); # Disable
    $y->debug(1); # Enable
    warn "Debugging!" if $y->debug();

=cut

sub debug
{
    my $self = shift;
    $self->{__PACKAGE__.'debug'} = ($_[0] ? 1 : 0) if @_;
    $self->{__PACKAGE__.'debug'};
}

=head2 get()

Fetch a given URL.

If C<debug()> is enabled, then it will displaying a warning showing
the URL.

    $y->get( 'http://groups.yahoo.com' );

Generally, you won't need to use this method.

=cut

sub get
{
    my $self = shift;
    warn "Fetching $_[0]\n" if $self->debug;
    return $self->SUPER::get(@_);
}

# field()

# As per the method of the same name in C<WWW::Mechanize>,
# but it doesn't unset the values when you are just reading
# them.

sub field {
    my ($self, $name, $value, $number) = @_;
    $number ||= 1;
    my $form = $self->{form};
    if ($number > 1) {
	$form->find_input($name, $number)->value(
	    (defined $value ? ($value) : ())
	);
    } else {
	$form->value($name, (defined $value ? ($value) : ()));
    }
}

=head2 login()

Logs the robot into the Yahoo! Groups system.

    $y->login( $user => $passwd );

=cut

sub login
{
    my $w = shift;
    my ($user, $passwd) = @_;
    $w->get('http://groups.yahoo.com/');
    $w->follow('Sign in');
    $w->field( login => $user );
    $w->field( passwd => $passwd );
    $w->click();
    $w->follow('here');
    return 1;
}

=head2 list()

Set/gets which list to use.

B<IMPORTANT>: list name must be correctly cased as per how Yahoo! Groups
cases it. If not, you may experience odd behaviour.

    $y->list( 'Jade_Pagoda' );
    my $list = $y->list();

=cut

sub list
{
    my $w = shift;
    if (@_) {
	my $list = shift;
	$w->{__PACKAGE__.'-list'} = $list;
    }
    return $w->{__PACKAGE__.'-list'};
}

=head2 fetch_message()

Fetches a specified message from the list's archives. Returns it as
a mail message (with headers) suitable for saving into a Maildir.

    my $message = $y->fetch_message( 435 );

You will probably experience problems if you retrieve messages with
attachments.

=cut

sub fetch_message
{
    my $w = shift;
    my $number = shift;
    my $list = $w->list();
    croak "No list set." unless defined $list and length $list;
    my $template = "http://groups.yahoo.com/group/$list/message/%d?source=1&unwrap=1";
    $w->get(sprintf $template, $number);
    my $res = $w->{res};
    while ($res->is_redirect)
    {
	my $url = $res->header('Location');
	$w->get($url);
	$res = $w->{res};
    }
    my $content = $res->content;
    if ($content =~ /\QYahoo! Groups is an advertising supported service.\E/gsm)
    {
	$w->follow('Continue to message');
	$res = $w->{res};
	$content = $res->content;
    }

    # Strip header
    $content =~ s/ ^ .*? \Q<!-- start content include -->\E //smx;
    $content =~ s/ ^ .*? <table[^>]+> \s+ <tt> //smx;

    # Strip footer
    $content =~ s/ \Q<!-- end content include -->\E .* $ //smx;
    $content =~ s! </tt> \s+ </table> .* $ !!smx;

    # Munge content
    $content =~ s!  <a \s+ href=" [^"]+ "> ([^<]+) </a> !$1!smgx;
    $content =~ s/ <BR> //smgx;
    decode_entities($content);

    # Return
    return $content;
}

1;
__END__

=head1 TODO

=over 4

=item *

Do some sanity checking on results from the fetches.

=item *

Handle attachments.

=item *

Tests. (Make dummy user for Yahoo Groups etc.)

=back

=head1 BUGS

Please report bugs at <bug-www-yahoo-groups@rt.cpan.org>
or via the web interface at L<http://rt.cpan.org>

=head1 AUTHOR

Iain Truskett <spoon@cpan.org>

=head1 SEE ALSO

L<perl>, L<WWW::Mechanize>

=cut
