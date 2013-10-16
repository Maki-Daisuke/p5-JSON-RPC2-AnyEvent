package JSON::RPC::AnyEvent::Server::Handle;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.01";

use AnyEvent::Handle;
use Carp qw(croak);
use Errno ();
use Scalar::Util qw(blessed reftype openhandle);

use JSON::RPC::AnyEvent::Server;
use JSON::RPC::AnyEvent::Constants qw(ERR_PARSE_ERROR);


sub new {
    my ($class, $srv, $hdl) = @_;
    
    croak "Not an JSON::RPC::AnyEvent::Server object: $srv"  unless blessed $srv && $srv->isa('JSON::RPC::AnyEvent::Server');
    
    unless ( blessed $hdl && $hdl->isa('AnyEvent::Handle') ) {
        $hdl = openhandle $hdl  or croak "Neither AnyEvent::Handle nor open filehandle: $hdl";
        $hdl = AnyEvent::Handle->new(fh => $hdl);
    }
    
    my $self = bless {
        hdl => $hdl,
        srv => $srv,
    }, $class;
    
    $hdl->on_read(sub{
        shift->push_read(json => sub{
            my ($h, $json) = @_;
            $self->{srv}->dispatch($json)->cb(sub{
                my $res = shift->recv;
                $h->push_write(json => $res)  if defined $res;
            });
        });
    });
    
    $hdl->on_eof(sub{
        my $on_end = $self->{on_end};
        $self->destroy;
        $on_end->($self)  if $on_end;
    });
    
    $hdl->on_error(sub{
        my ($h, $fatal, $msg) = @_;
        if ( $! == Errno::EBADMSG ) {  # JSON Parse error
            my $res = JSON::RPC::AnyEvent::_make_error_response(undef, ERR_PARSE_ERROR, 'Parse error');
            $h->push_write(json => $res);
        } elsif ( $self->{on_error} ){
            $self->{on_error}->($self, $fatal, $msg);
            $self->destroy if $fatal;
        } else {
            $self->destroy if $fatal;
            croak "JSON::RPC::AnyEvent::Handle uncaught error: $msg";
        }
    });
    
    $self;
}


sub JSON::RPC::AnyEvent::Server::dispatch_handle {
    my ($self, $fh) = @_;
    __PACKAGE__->new($self, $fh);
}


# Create on_xxx methods
for my $name ( qw/ on_end on_error / ) {
    no strict 'refs';
    *$name = sub {
        my ($self, $code) = @_;
        reftype $code eq 'CODE'  or croak "coderef must be specified";
        $self->{$name} = $code;
    };
}


# This DESTROY-pattern originates from AnyEvent::Handle code.
sub DESTROY {
    my ($self) = @_;
    $self->{hdl}->destroy;
}

sub destroy {
    my ($self) = @_;
    $self->DESTROY;
    %$self = ();
    bless $self, "JSON::RPC::AnyEvent::Server::Handle::destroyed";
}

sub JSON::RPC::AnyEvent::Server::Handle::destroyed::AUTOLOAD {
   #nop
}


1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC::AnyEvent::Server::Handle - dispatch JSON-RPC requests comming from file-handle to JSON::RPC::AnyEvent::Server

=head1 SYNOPSIS

    use AnyEvent::Socket;
    use JSON::RPC::AnyEvent::Server::Handle;  # Add `dispatch_handle' method in JSON::RPC::AnyEvent::Server
    
    my $srv = JSON::RPC::AnyEvent::Server->(
        echo => sub{
            my ($cv, $args) = @_;
            $cv->send($args);
        }
    );
    
    my $w = tcp_server undef, 8080, sub {
        my ($fh, $host, $port) = @_;
        my $hdl = $srv->dispatch_handle($fh);  # This is equivalent to JSON::RPC::AnyEvent::Server::Handle->new($srv, $fh)
        $hdl->on_end(sub{
            my $h = shift;  # JSON::RPC::AnyEvent::Server::Handle
            # underlying fh is already closed here
            $h->destroy;
            undef $hdl;
        });
        $hdl->on_error(sub{
            my ($h, $fatal, $message) = @_;
            warn $message;
            $h->destroy  if $fatal;
            undef $hdl;
        });
    };

=head1 DESCRIPTION

JSON::RPC::AnyEvent::Server::Handle is AnyEvent::Handle interface for JSON::RPC::AnyEvent::Server.

=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut
