package Catalyst::Plugin::File::RotateLogs;
use strict;
use warnings;
use MRO::Compat;
use Path::Class ();

our $VERSION = "0.06";

sub setup {
    my $c = shift;
    my $home = $c->config->{home};
    my $config = $c->config->{'File::RotateLogs'} || {
        logfile      => Path::Class::file($home, "root", "error_log.%Y%m%d%H")->absolute->stringify,
        linkname     => Path::Class::file($home, "root", "error_log")->absolute->stringify,
        rotationtime => 86400, #default 1day
        maxage       => 86400 * 3,   #3day
        autodump     => 0,
        color        => 1,
    };
    $config->{maxage} = int eval($config->{maxage});
    $c->log((__PACKAGE__ . '::Backend')->new($config));
    return $c->maybe::next::method(@_);
}

package Catalyst::Plugin::File::RotateLogs::Backend;
use Moose;
use Time::Piece;
use File::RotateLogs;
use Term::ANSIColor;

BEGIN { extends 'Catalyst::Log' }

my $ROTATE_LOGS; 
my $CALLER_DEPTH = 1; 
my $AUTODUMP     = 0;
my $COLOR        = 0;

sub new {
    my $class = shift;
    my $config  = shift;

    $AUTODUMP = $config->{autodump} //= 0;
    $COLOR    = $config->{color} //= 0;
    delete $config->{autodump};
    delete $config->{color};

    my $self  = $class->next::method();
    $ROTATE_LOGS = File::RotateLogs->new($config);

    return $self;
}

{
    foreach my $handler (qw/debug info warn error fatal/) {
        override $handler => sub {
            my ($self, $message) = @_; 
            if ($AUTODUMP && ref($message) ) {
                local $Data::Dumper::Terse = 1;
                local $Data::Dumper::Indent = 0;
                local $Data::Dumper::Sortkeys = 1;
                $message = Data::Dumper::Dumper($message);
            }

            my ($package, $file, $line) = caller($CALLER_DEPTH); 
 
            my $datetime   = localtime->datetime;
            my $uc_handler = uc $handler;

            if ($COLOR) {
                $datetime   = colored(['yellow on_magenta'],    $datetime), 
                $uc_handler = colored(['red on_bright_yellow'], $uc_handler), 
                $package    = colored(['bright_red on_black'], $package), 
                $message    = colored(['bold blue'],           $message), 
                #    $file, 
                $line       = colored(['white on_black'], $line)
            }
            
            $ROTATE_LOGS->print(sprintf(qq{%s: [%s] [%s] %s at %s line %s\n},
                    $datetime, $uc_handler, $package, $message, $file, $line
            ));
        };

    }
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::File::RotateLogs - Catalyst Plugin for File::RotateLogs

=head1 SYNOPSIS

    # plugin is loaded
    use Catalyst qw/ 
        ConfigLoader
        Static::Simple
        File::RotateLogs
    /;

    $c->log->info("hello catalyst"); 

    # Catalyst configuration by default (e. g. in YAML format):
    File::RotateLogs:
        logfile: '/[absolute path]/root/error.log.%Y%m%d%H' 
        linkname: '/[absolute path]/root/error.log'
        rotationtime: 86400
        maxage: 86400 * 3
        autodump: 0

=head1 DESCRIPTION

This module allows you to initialize File::RotateLogs within the application's configuration. File::RotateLogs is utility for file logger and very simple logfile rotation. I wanted easier catalyst log rotation.

=head1 SEE ALSO

=over 2

=item L<Catalyst::Log>

=item L<File::RotateLogs>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

masakyst E<lt>masakyst.public@gmail.comE<gt>

=cut
