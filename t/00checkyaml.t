use Test::More tests => 6;
$|=1;
use strict;
use warnings;

SKIP: {
    skip "No YAML", 6 unless eval { require YAML; 1 };
    pass("We have YAML");
    YAML->import(qw( LoadFile Dump ));


# Check that the TODO file is fine
{
    my $todo = (testload('TODO'))[0]->{TODO};
    diag "\n";
    if (@$todo == 1) {
	diag "There is 1 item on the TODO list.";
    } else {
	diag "There are ".@$todo." items on the TODO list.";
    }
    diag Dump($todo),"\n";
}

# Check that the META.yaml file is fine, plus we need its information
my $meta = (testload('META.yaml'))[0];
diag Dump($meta);

# Check that the changes file is fine and up to date.
{
    my @changes = testload('Changes');
    my $latest = shift @changes;
    # Extract dist_version from Build.PL
    my $file = do {
	local $/ = undef;
	open FH, 'Build.PL' or die "Could not open Build.PL: $!\n";
	my $file = <FH>;
	close FH;
	$file;
    };
    my (undef, $version) = ($file =~ m!
	dist_version \s*
	=> \s*
	(['"]?)
	(\d+\.\d+(?:\.\d+)?)
	\1 \s* ,
	!x); # there should be a better way

    # All three should have the same version.
    diag <<"DIAG";


Build.PL  has <$version>
Change log is <$latest->{version}>
META.yaml has <$meta->{version}>

DIAG
    is $latest->{version}, $version, 'Changes and Build.PL equal';
    is $meta->{version}, $version, 'META.yaml and Build.PL equal';
    # (if those are equal, then all combinations are equal)
}


# Display versions of installed required modules
my %requires = %{ $meta->{requires} };
diag sprintf "\n%-30.30s %10s %10s", '', 'wanted', 'installed';
foreach my $module (sort keys %requires)
{
    next if lc($module) eq 'perl';
    eval "require $module";
    die "$module not found: $@" if $@;
    my $v = eval " \$${module}::VERSION "; # eval++ =)
    diag sprintf "%-30.30s %10s %10s", $module, $requires{$module}, $v;
}
diag "\n";
}

# Yada. Tidy away file loading.
sub testload
{
    my $file = shift;
    my @out = eval { LoadFile($file) };
    if ($@) {
	fail("$file is not valid YAML: $@");
    } else {
	pass("$file is valid YAML");
    }
    return @out;
}
