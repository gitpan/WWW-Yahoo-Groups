package Build;

use Module::Build 0.11;
use base 'Module::Build';
our $VERSION = 0.11;

sub ACTION_build {
    my ($self) = @_;
    $self->process_PL_files('lib');
    my $files = $self->rscan_dir('lib', qr{\.(pm|pod|xs|po)$});
    $self->lib_to_blib($files, 'blib');
    $self->add_to_cleanup('blib');
}

sub lib_to_blib {
    my ($self, $files, $to) = @_;

    # Create $to/arch to keep blib.pm happy (what a load of hooie!)
    File::Path::mkpath( File::Spec->catdir($to, 'arch') );

    foreach my $file (@$files) {
        if ($file =~ /\.p(m|od?)$/) {
            # No processing needed
            $self->copy_if_modified($file, $to);
        } else {
            warn "gnoring file '$file', unknown extension\n";
        }
    }
}

1;
