use strict;
use warnings;
use Test::More 0.98;

{
    package Catalyst::Plugin::File::RotateLogs::Test;
    use base qw(Catalyst::Plugin::File::RotateLogs Class::Accessor::Fast);

    __PACKAGE__->mk_accessors(qw(log config));

}

my $c = Catalyst::Plugin::File::RotateLogs::Test->new();

ok 1, 1;


done_testing;
