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

    # Error catching
    my $email = eval { $y->fetch_message( 93848 ) };
    if ( $@ and ref $@ and $@->isa('X::WWW::Yahoo::Groups') )
    {
        warn "Problem: ".$@->error;
    }

=head1 ABSTRACT

C<WWW::Yahoo::Groups> retrieves messages from the archive of Yahoo
Groups. It provides a simple OO interface to logging in and retrieving
said messages which you may then do with as you will.

=head1 DESCRIPTION

C<WWW::Yahoo::Groups> is a subclass of C<WWW::Mechanize>, overriding a
few methods and supplying a few extra. As such, any method available in
C<WWW::Mechanize> is available to C<WWW::Yahoo::Groups>, perhaps
augmented with extra features.

It is recommended that you use this only if you're the moderator of a
group, else you will get munged email addresses for everything. If
there's sufficient demand for semi-automatic address demunging, I'll
add it.

All exceptions are subclasses of C<X::WWW::Yahoo::Groups>, itself a
subclass of C<Exception::Class>.

=head2 Things it does

=over 4

=item *

Handles access restricted archives. It lets you login.

=item *

Handles the intermittent advertisements. It notes that it got one and
progresses straight to the message.

=item *

Handles attachments. We get the source which happens to be the raw stuff.

=item *

Sanity checking. Could be improved, but it will generally barf if it
doesn't understand something.

=back

=head2 Things it is yet to do

=over 4

=item *

B<Handle errors.> Well, it does, but not as gracefully as it might in
some situations.

=item *

B<Header restoration.> I've found that some groups' archives have
unusually corrupted headers. Evidently it would be beneficial to
restore these headers. As far as I can tell, it comes from not
being a moderator on the lists in question.

=back

As this is a recognised flaw, they are on the F<TODO> list.

=cut

our $VERSION = '1.72';

use base 'WWW::Mechanize';
use Carp;
use HTTP::Cookies;
use HTML::Entities;
use Params::Validate qw( :all );
use Exception::Class (
    'X::WWW::Yahoo::Groups' => {
	description => 'An error related to WWW::Yahoo::Groups'
    },
    'X::WWW::Yahoo::Groups::BadParam' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => 'Invalid parameters specified for function',
    },
    'X::WWW::Yahoo::Groups::BadLogin' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => 'For some reason, your login failed',
    },
    'X::WWW::Yahoo::Groups::NoListSet' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => 'You tried accessing a method that required the list to be set',
    },
    'X::WWW::Yahoo::Groups::UnexpectedPage' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => 'We received a page that I do not understand',
    },
    'X::WWW::Yahoo::Groups::NotThere' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => 'The message you wanted is not in the archive',
    },
    'X::WWW::Yahoo::Groups::BadFetch' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => 'We tried fetching a page, but failed',
    },
);

Params::Validate::validation_options(
    ignore_case => 1,
    strip_leading => 1,
    on_fail => sub {
	chomp($_[0]);
	X::WWW::Yahoo::Groups::BadParam->throw($_[0]);
    }
);

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

Generally, you won't need to use this method. It's used by a number of
the othe rmethods and will throw a C<X::WWW::Yahoo::Groups::BadFetch> if
it is unable to retrieve the specified page.

=cut

sub get
{
    my $self = shift;
    my $url = $_[0];
    warn "Fetching $url\n" if $self->debug;
    my $rv = $self->SUPER::get(@_);
    X::WWW::Yahoo::Groups::BadFetch->throw(
	"Unable to fetch $url: ".$self->{res}->message)
	    if ($self->{res}->is_error);
    return $rv;
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

May throw:

=over 4

=item *

C<X::WWW::Yahoo::Groups::BadFetch> if it cannot fetch any of the
appropriate pages.

=item *

C<X::WWW::Yahoo::Groups::BadParam> if given invalid parameters.

=item *

C<X::WWW::Yahoo::Groups::BadLogin> is unable to log in for some reason
(error will be given the text of the Yahoo error).

=back

=cut

sub login
{
    my $w = shift;
    my %p;
    @p{qw( user pass )} = validate_pos( @_,
	{ type => SCALAR, }, # user
	{ type => SCALAR, }, # pass
    );

    $w->get('http://groups.yahoo.com/');
    $w->follow('Sign in');
    $w->field( login => $p{user} );
    $w->field( passwd => $p{pass} );
    $w->click();
    my $result = $w->{res}->content;
    if (my ($error) = $result =~ m!
	    \Q<font color=red face=arial><b>\E
	    \s+
	    (.*?)
	    \s+
	    \Q</b></font></td></tr></table>\E
	!xsm)
    {
	X::WWW::Yahoo::Groups::BadLogin->throw($error);
    }
    else
    {
	$w->follow('here');
    }
    return 1;
}

=head2 list()

Set/gets which list to use.

B<IMPORTANT>: list name must be correctly cased as per how Yahoo! Groups
cases it. If not, you may experience odd behaviour.

    $y->list( 'Jade_Pagoda' );
    my $list = $y->list();

May throw C<X::WWW::Yahoo::Groups::BadParam> if given invalid parameters.

=cut

sub list
{
    my $w = shift;
    if (@_) {
	my ($list) = validate_pos( @_,
	    { type => SCALAR, callbacks => {
		    'defined and of length' => sub {
			defined $_[0] and length $_[0]
		    },
		}}, # list
	);
	$w->{__PACKAGE__.'-list'} = $list;
    }
    return $w->{__PACKAGE__.'-list'};
}

=head2 fetch_message()

Fetches a specified message from the list's archives. Returns it as
a mail message (with headers) suitable for saving into a Maildir.

    my $message = $y->fetch_message( 435 );

May throw any of:

=over 4

=item *

C<X::WWW::Yahoo::Groups::BadFetch> if it cannot fetch any of the
appropriate pages.

=item *

C<X::WWW::Yahoo::Groups::BadParam> if given invalid parameters.

=item *

C<X::WWW::Yahoo::Groups::NoListSet> if no list is set.

=item *

C<X::WWW::Yahoo::Groups::UnexpectedPage> if we fetched a page and it was
not what we thought it was meant to be.

=item *

C<X::WWW::Yahoo::Groups::NotThere> if the message does not exist in the
archive (any of deleted, never archived or you're beyond the range of
the group).

=back


=cut

sub fetch_message
{
    my $w = shift;
    my ($number) = validate_pos( @_,
	{ type => SCALAR, callbacks => {
		'is integer' => sub { shift() =~ /^ \d+ $/x },
		'greater than zero' => sub { shift() > 0 },
	    } }, # number
    );
    my $list = $w->list();
    X::WWW::Yahoo::Groups::NoListSet->throw("Cannot fetch a message without a list being specified.")
	unless defined $list and length $list;
    my $template = "http://groups.yahoo.com/group/$list/message/%d?source=1&unwrap=1";
    $w->get(sprintf $template, $number);
    my $res = $w->{res};
    while ($res->is_redirect)
    {
	# We do this manually because it doesn't work automatically for
	# some reason. I suspect we hit a redirection limit in LWP.
	my $url = $res->header('Location');
	$w->get($url);
	$res = $w->{res};
    }
    my $content = $res->content;
    if ($content =~ /\QYahoo! Groups is an advertising supported service.\E/gsm)
    {
	# If it's one of those damn interrupting ads, then click
	# through.
	$w->follow('Continue to message');
	$res = $w->{res};
	$content = $res->content;
    }

    # See if it's a missing article.
    if ($content =~ m!
	<blockquote>
	\s+
	<br>
	\s+
	\QMessage $number does not exist in $list\E
	</blockquote>
	!smx)
    {
	X::WWW::Yahoo::Groups::NotThere->throw("Message $number is not there.");
    }

    # Strip content boundaries
    $content =~ s/ ^ .*? \Q<!-- start content include -->\E //smx and
    $content =~ s/ \Q<!-- end content include -->\E .* $ //smx and

    # Strip table wrappings
    $content =~ s/ ^ .*? <table[^>]+> \s+ <tt> //smx and
    $content =~ s! </tt> \s+ </table> .* $ !!smx and

    # Munge content
    $content =~ s!  <a \s+ href=" [^"]+ "> ([^<]+) </a> !$1!smgx and
    $content =~ s/ <BR> //smgx or
	X::WWW::Yahoo::Groups::UnexpectedPage->throw(
	    "Message $number doesn't appear to be formatted as we like it.");
    decode_entities($content);

    # Return
    return $content;
}

=head2 fetch_rss()

Returns the RSS for the gruop's most recent messages. See
L<XML::Filter::YahooGroups> for ways to process this RSS into
containing the message bodies.

    my $rss = $w->fetch_rss();

If a parameter is given, it will return that many items in the RSS file.
The number must be between 1 and 100 inclusive.

    my $rss = $w->fetch_rss( 10 );

=cut

sub fetch_rss
{
    my $w = shift;
    my %opts;
    @opts{qw( count )} = validate_pos( @_,
	{ type => SCALAR, optional => 1, callbacks => {
		'is integer' => sub { shift() =~ /^ \d+ $/x },
		'greater than zero' => sub { shift() > 0 },
		'less than or equal to one hundred' => sub { shift() <= 100 },
	    } }, # number
    );
    #             href="http://groups.yahoo.com/group/rss-dev/messages?rss=1&amp;viscount=30">
    my $list = $w->list();
    X::WWW::Yahoo::Groups::NoListSet->throw(
	"Cannot fetch a list's RSS without a list being specified.")
	    unless defined $list and length $list;
    my $url = "http://groups.yahoo.com/group/$list/messages?rss=1";
    $url .= "&viscount=$opts{count}" if $opts{count};
    $w->get( $url );
    my $content = $w->{res}->content;
    X::WWW::Yahoo::Groups::UnexpectedPage->throw(
	"Thought we were getting RSS. Got something else.")
            unless $content =~ m[^
		\Q<?xml version="1.0"?>\E
		\s*
		\Q<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN"\E
    ]sx;
    return $w->{res}->content;
}

1;
__END__

=head1 THANKS

Simon Hanmer for having problems with the module, thus resulting
in improved error reporting, param validation and corrected
prerequisites.

Aaron Straup Cope for writing L<XML::Filter::YahooGroups> which
uses this module for retrieving message bodies to put into RSS.

Randal "Merlyn" Schwartz for pointing out some problems back in 1.4.

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

L<perl>, L<WWW::Mechanize>, L<XML::Filter::YahooGroups>,
L<Exception::Class>, L<http://groups.yahoo.com/>.

=cut
