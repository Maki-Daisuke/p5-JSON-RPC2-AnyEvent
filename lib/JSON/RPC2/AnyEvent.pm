package JSON::RPC2::AnyEvent;

our $VERSION = "0.01";

use JSON::RPC2::AnyEvent::Server;

1;
__END__

=encoding utf-8

=head1 NAME

JSON::RPC2::AnyEvent - It's new $module

=head1 SYNOPSIS

    use JSON::RPC2::AnyEvent::Server;

    my $jra = JSON::RPC2::AnyEvent::Server->new;
    $jra->register(a_method => "[param1, param2]" => sub{
        my ($cv $args_arr, $original_args) = @_;
        do_some_async_task(sub{
            # Done!
            $cv->send($result);
        });
    });
    
    my $cv = $j->dispatch($req);
    my $res = $cv->recv;
    
    # For Notification Request, just returns undef.
    my $res = $jra->dispatch({jsonrpc => "2.0", method => "a_method", ["some", "values"]})->recv;  # Non-bloking when "id" is omitted.
    not defined $res;  # true


=head1 DESCRIPTION

JSON::RPC2::AnyEvent is ...

=head1 LICENSE

Copyright (C) Daisuke (yet another) Maki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Daisuke (yet another) Maki E<lt>maki.daisuke@gmail.comE<gt>

=cut

