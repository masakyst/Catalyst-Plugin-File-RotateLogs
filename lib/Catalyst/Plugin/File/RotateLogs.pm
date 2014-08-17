package Catalyst::Plugin::File::RotateLogs;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = "0.01";

use MRO::Compat;

sub setup {
    my $c = shift;
    # catalyst app home dir
    #print "context: ".Dumper($c->config->{home});

    my $config = $c->config->{'File::RotateLogs'} || {};
    #print Dumper($config);
    $c->log((__PACKAGE__ . '::Backend')->new($config));
    return $c->maybe::next::method(@_);
}

package Catalyst::Plugin::File::RotateLogs::Backend;
use Moose;
#use Moose::Util 'find_meta';
use Cwd;
use Time::Piece;
use File::RotateLogs;
use Data::Dumper;

BEGIN { extends 'Catalyst::Log' }

#has _rotatelogs => (is => 'rw');

my $ROTATE_LOGS; #attributeだと無駄なmethod call増えるのでこの方がいい？
my $CALLER_DEPTH = 1; 
my $appdir = getcwd;


my $rotate_errorlog = File::RotateLogs->new(
    logfile  => "${appdir}/logs/error_log.%Y%m%d%H",
    linkname => "${appdir}/logs/error_log",
    rotationtime => 86400, #default 1day
    maxage => 86400 * 3, #3day
);

sub new {
    my $class = shift;
    my $args  = shift;
    print Dumper($args);
    my $self  = $class->next::method();
    $ROTATE_LOGS = File::RotateLogs->new(
        logfile  => "${appdir}/logs/error_log.%Y%m%d%H",
        linkname => "${appdir}/logs/error_log",
        rotationtime => 86400, #default 1day
        maxage => 86400 * 3,   #3day
    );

    #$self->_rotatelogs(
    #    File::RotateLogs->new(
    #        logfile  => "${appdir}/logs/error_log.%Y%m%d%H",
    #        linkname => "${appdir}/logs/error_log",
    #        rotationtime => 86400, #default 1day
    #        maxage => 86400 * 3, #3day
    #    )
    #);
    return $self;
}

{
    #my $meta = find_meta(__PACKAGE__);
    foreach my $handler (qw/debug info warn error fatal/) {
        override $handler => sub {
            my ($self, $message) = @_; 
            my ($package, $file, $line) = caller($CALLER_DEPTH); 
            $ROTATE_LOGS->print(sprintf(qq{%s: [%s] [%s] "%s at %s line %s"\n},
                    localtime->datetime, uc $handler, $package, $message, $file, $line));
        };

    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Catalyst::Plugin::File::RotateLogs - Catalyst Plugin for File::RotateLogs

=head1 SYNOPSIS

    use Catalyst::Plugin::File::RotateLogs;

=head1 DESCRIPTION

Catalyst::Plugin::File::RotateLogs is ...

=head1 LICENSE

Copyright (C) masakyst.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

masakyst E<lt>masakyst.public@gmail.comE<gt>

=cut

