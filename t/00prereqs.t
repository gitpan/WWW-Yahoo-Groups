use strict;
use warnings;
use Test::More tests => 1;
# Do all the modules used in the various
# files actually exist in Build.PL?
use Test::Prereq::Build;

prereq_ok();
