# This Makefile.PL creates a pass-through Makefile that simply calls
# the equivalent Module::Build methods for each make target.  See the
# documentation for Module::Build::Compat for more information.

unless (eval { require Module::Build::Compat; 1 }) {
  # Workaround with old CPAN.pm and CPANPLUS.pm
  require ExtUtils::MakeMaker;
  ExtUtils::MakeMaker::WriteMakefile(
    PREREQ_PM => { 'Module::Build::Compat' => 0.01 }
  );
  warn "Warning: prerequisite Module::Build::Compat is not found.\n";
  exit(0);
}
Module::Build::Compat->run_build_pl(args => \@ARGV);
Module::Build::Compat->write_makefile();
