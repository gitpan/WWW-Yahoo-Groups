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

Try to be a well behaved bot and C<sleep()> for a few seconds (at least)
after doing things. It's considered polite. There's a method
C<autosleep()> that should be useful for this.

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

our $VERSION = '1.78';

use base 'WWW::Mechanize';
use Carp;
use HTTP::Cookies;
use HTML::Entities;
use Params::Validate qw( :all );
use WWW::Yahoo::Groups::L10N;
our $lh = WWW::Yahoo::Groups::L10N->get_handle or die "Could not get localization handle!";

require Exception::Class;
Exception::Class->import(
    'X::WWW::Yahoo::Groups' => {
	description => $lh->maketext('An error related to WWW::Yahoo::Groups'),
	fields => [qw( fatal )],
    },
    'X::WWW::Yahoo::Groups::BadParam' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => $lh->maketext('Invalid parameters specified for function'),
    },
    'X::WWW::Yahoo::Groups::BadLogin' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => $lh->maketext('For some reason, your login failed'),
    },
    'X::WWW::Yahoo::Groups::NoHere' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => $lh->maketext(
	    "The ``here'' link was not found on the login page."),
    },
    'X::WWW::Yahoo::Groups::AlreadyLoggedIn' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => $lh->maketext('You are already logged in with this object.'),
    },
    'X::WWW::Yahoo::Groups::NotLoggedIn' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => $lh->maketext('You must be logged in to perform that method.'),
    },
    'X::WWW::Yahoo::Groups::NoListSet' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => $lh->maketext('You tried accessing a method that required the list to be set'),
    },
    'X::WWW::Yahoo::Groups::UnexpectedPage' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => $lh->maketext('We received a page that I do not understand'),
    },
    'X::WWW::Yahoo::Groups::NotThere' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => $lh->maketext('The message you wanted is not in the archive'),
    },
    'X::WWW::Yahoo::Groups::BadFetch' => {
	isa => 'X::WWW::Yahoo::Groups',
	description => $lh->maketext('We tried fetching a page, but failed'),
    },
);
sub X::WWW::Yahoo::Groups::is_error { 1 }

Params::Validate::validation_options(
    ignore_case => 1,
    strip_leading => 1,
    on_fail => sub {
	chomp($_[0]);
	X::WWW::Yahoo::Groups::BadParam->throw(error => $_[0], fatal => 1);
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
    $self->{__PACKAGE__.'-debug'} = ($_[0] ? 1 : 0) if @_;
    $self->{__PACKAGE__.'-debug'};
}

=head2 get()

Fetch a given URL.

If C<debug()> is enabled, then it will displaying a warning showing the
URL. If C<autosleep()> has been given an interval, then C<get()> will
sleep for that interval after successfully fetching a page.

    $y->get( 'http://groups.yahoo.com' );

Generally, you won't need to use this method. It's used by a number of
the other methods and will throw a C<X::WWW::Yahoo::Groups::BadFetch> if
it is unable to retrieve the specified page.

Returns 0 if success, else an exception object.

    my $rv = $y->get( 'http://groups.yahoo.com' );
    $rv->rethrow if $rv;

    # or, more idiomatically
    my $rv = $y->get( 'http://groups.yahoo.com' ) and $rv->rethrow;

=cut

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
	    $self->{res}->code.' - '.$self->{res}->message)
		if ($self->{res}->is_error);
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

=head2 autosleep()

If given a parameter, it sets the numbers of seconds to sleep.
Otherwise, it returns the number.

    $y->autosleep( 5 );
    sleep ( $y->autosleep() );

May throw C<X::WWW::Yahoo::Groups::BadParam> if given invalid parameters.

This is used by C<get()>. If C<autosleep()> is set, then C<get()> will
C<sleep()> for the specified period after every fetch.

=cut

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

C<X::WWW::Yahoo::Groups::BadLogin> if unable to log in for some reason
(error will be given the text of the Yahoo error).

=item *

C<X::WWW::Yahoo::Groups::AlreadyLoggedIn> if the object is already
logged in. I intend to make this exception redundant, and add a
C<logout()> method.

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
    my $rv = eval {
	X::WWW::Yahoo::Groups::AlreadyLoggedIn->throw(
	    $lh->maketext("You must logout before you can log in again."))
		if $w->loggedin;

	$w->get('http://groups.yahoo.com/');
	$w->follow('Sign In');
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
	    X::WWW::Yahoo::Groups::BadLogin->throw(
		fatal => 1,
		error => $lh->maketext($error));
	}
	else
	{
	    while (my $url = $w->res->header('Location'))
	    {
		$w->get( $url );
	    }
	    my $content = $w->content;
	    if ( $content =~ m[
		\Qwindow.location.replace("http://groups.yahoo.com/");\E
		]x )
	    {
		$w->{__PACKAGE__.'-loggedin'} = 1;
	    } else {
		X::WWW::Yahoo::Groups::BadLogin->throw(
		    fatal => 1,
		    error => $lh->maketext("Nope. That's not a good login."));
	    }
	}
	0;
    };
    if ($@) {
	die $@ unless ref $@;
	$@->rethrow if $@->fatal;
	$rv = $@;
    }
    return $rv;
}

=head2 logout()

Logs the robot out of the Yahoo! Groups system.

    $y->logout();

May throw:

=over 4

=item *

C<X::WWW::Yahoo::Groups::BadFetch> if it cannot fetch any of the
appropriate pages.

=item *

C<X::WWW::Yahoo::Groups::BadParam> if given invalid parameters.

=item *

C<X::WWW::Yahoo::Groups::NotLoggedIn> if the bot is already logged out
(or never logged in).

=back

=cut

sub logout
{
    my $w = shift;
    validate_pos( @_ );
    my $rv = eval {
	X::WWW::Yahoo::Groups::NotLoggedIn->throw(
	    $lh->maketext("You can not log out if you are not logged in."))
		unless $w->loggedin;
	delete $w->{__PACKAGE__.'-loggedin'};

	$w->get('http://groups.yahoo.com/');

	X::WWW::Yahoo::Groups::NotLoggedIn->throw(
	    $lh->maketext("You can not log out if you are not logged in."))
		unless $w->follow('Sign Out');

	$w->follow('Return to Yahoo! Groups');
	my $res = $w->{res};
	while ($res->is_redirect)
	{
	    # We do this manually because it doesn't work automatically for
	    # some reason. I suspect we hit a redirection limit in LWP.
	    my $url = $res->header('Location');
	    $w->get($url);
	    $res = $w->{res};
	}
	0;
    };
    if ($@) {
	die $@ unless ref $@;
	$@->rethrow if $@->fatal;
	$rv = $@;
    }
    return $rv;
}

=head2 loggedin()

Returns 1 if you are logged in, else 0. Note that this merely tests if
you've used the C<login()> method successfully, not whether the Yahoo!
site has expired your session.

   print "Logged in!\n" if $w->loggedin();

=cut

sub loggedin
{
    my $w = shift;
    validate_pos( @_ );
    if (exists $w->{__PACKAGE__.'-loggedin'}
	    and $w->{__PACKAGE__.'-loggedin'})
    {
	return 1;
    }
    return 0;
}

=head2 list()

If given a parameter, it sets the list to use. Otherwise, it returns
the current list, or C<undef> if no list is set.

B<IMPORTANT>: list name must be correctly cased as per how Yahoo! Groups
cases it. If not, you may experience odd behaviour.

    $y->list( 'Jade_Pagoda' );
    my $list = $y->list();

May throw C<X::WWW::Yahoo::Groups::BadParam> if given invalid parameters.

See also C<lists()> for how to get a list of possible lists.

=cut

sub list
{
    my $w = shift;
    if (@_) {
	my ($list) = validate_pos( @_,
	    { type => SCALAR, callbacks => {
		    $lh->maketext('defined and of length') => sub {
			defined $_[0] and length $_[0]
		    },
		    $lh->maketext('appropriate characters') => sub {
			$_[0] =~ /^ [\w-]+ $/x;
		    },
		}}, # list
	);
	$w->{__PACKAGE__.'-list'} = $list;
    }
    return $w->{__PACKAGE__.'-list'};
}

=head2 lists()

If you'd like a list of the groups to which you are subscribed,
then use this method.

    my @groups = $w->lists();

May throw C<X::WWW::Yahoo::Groups::BadParam> if given invalid
parameters, or C<X::WWW::Yahoo::Groups::BadFetch> if it cannot fetch any
of the appropriate pages from which it extracts the information.

Note that it does handle people with more than one page of groups.

=cut

sub lists
{
    my $w = shift;
    validate_pos( @_ );
    X::WWW::Yahoo::Groups::NotLoggedIn->throw(
	$lh->maketext("Must be logged in to get a list of groups."))
	    unless $w->loggedin;

    my %lists;

    my $next = 'http://groups.yahoo.com/mygroups';
    do {
	$w->get( $next );
	undef $next;
	my $links = $w->extract_links();
	# [0]: the contents of the href attribute
	# [1]: the text enclosed by the <A> tag
	# [2]: the contents of the name attribute
	for my $link (@$links)
	{
	    $next = $link->[0] if $link->[1] eq 'Next';
	    next unless $link->[0] =~ m# /group/ ([\w-]+?) \Q?yguid=\E #x;
	    $lists{$1} = 1;
	}
    } until ( not defined $next );

    return (sort keys %lists);
}

=head2 last_msg_id()

Returns the highest message number with the archive.

    my $last = $w->last_msg_id();
    # Fetch last 10 messages:
    for my $number ( ($last-10) .. $last )
    {
        push @messages, $w->fetch_message( $number );
    }

It will throw C<X::WWW::Yahoo::Groups::NoListSet> if no list has been
specified with C<lists()>, C<X::WWW::Yahoo::Groups::UnexpectedPage> if
the page fetched does not contain anything we thought it would, and
C<X::WWW::Yahoo::Groups::BadFetch> if it is unable to fetch the page it
needs.

=cut

sub last_msg_id
{
    my $w = shift;
    validate_pos( @_ );
    my $list = $w->list();
    X::WWW::Yahoo::Groups::NoListSet->throw(
	$lh->maketext("Cannot determine archive extent without a list being specified."))
	    unless defined $list and length $list;

    $w->get( "http://groups.yahoo.com/group/$list/messages" );
    my $content = $w->{res}->content;
    my ($count) = $content =~ m!
	<TITLE>
	[^<]+?
	\s+ of \s+
	(\d+)
	[^<]*?
	<\/TITLE>
    !six;
    X::WWW::Yahoo::Groups::UnexpectedPage->throw(
	$lh->maketext("Unexpected title format. Perhaps group has no archive."))
	    unless defined $count;

    return $count;
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
		$lh->maketext('is integer') => sub { shift() =~ /^ \d+ $/x },
		$lh->maketext('greater than zero') => sub { shift() > 0 },
	    } }, # number
    );
    my $list = $w->list();
    X::WWW::Yahoo::Groups::NoListSet->throw(
	$lh->maketext("Cannot fetch a message without a list being specified."))
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
	<br>
	\s+
	<blockquote>
	\s+
	\QMessage $number does not exist in $list\E
	</blockquote>
	!smx)
    {
	X::WWW::Yahoo::Groups::NotThere->throw(
	    $lh->maketext("Message [_1] is not there.", $number));
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
	    $lh->maketext("Message [_1] doesn't appear to be formatted as we like it.", $number));
    decode_entities($content);

    # Return
    return $content;
}

=head2 fetch_rss()

Returns the RSS for the group's most recent messages. See
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
		$lh->maketext('is integer') => sub { shift() =~ /^ \d+ $/x },
		$lh->maketext('greater than zero') => sub { shift() > 0 },
		$lh->maketext('less than or equal to one hundred') => sub { shift() <= 100 },
	    } }, # number
    );
    #             href="http://groups.yahoo.com/group/rss-dev/messages?rss=1&amp;viscount=30">
    my $list = $w->list();
    X::WWW::Yahoo::Groups::NoListSet->throw(
	$lh->maketext("Cannot fetch a list's RSS without a list being specified."))
	    unless defined $list and length $list;
    my $url = "http://groups.yahoo.com/group/$list/messages?rss=1";
    $url .= "&viscount=$opts{count}" if $opts{count};
    $w->get( $url );
    my $content = $w->{res}->content;
    X::WWW::Yahoo::Groups::UnexpectedPage->throw(
	$lh->maketext("Thought we were getting RSS. Got something else."))
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

Simon Hanmer for having problems with the module, thus resulting in
improved error reporting, param validation and corrected prerequisites.
Since then, Simon also provided a basis for the C<lists()> and
C<last_msg_id()> methods and is causing me to think harder about my
exceptions.

Aaron Straup Cope for writing L<XML::Filter::YahooGroups> which
uses this module for retrieving message bodies to put into RSS.

Randal "Merlyn" Schwartz for pointing out some problems back in 1.4.

Autrijus Tang for L<Locale::Maketext::Lexicon> and Sean M Burke for
L<Locale::Maketext>. With any luck this module is now appropriate
internationalised, albeit not localised.

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
L<Exception::Class>, L<http://groups.yahoo.com/>,
L<Locale::Maketext>, L<Locale::Maketext::Lexicon>.

=cut