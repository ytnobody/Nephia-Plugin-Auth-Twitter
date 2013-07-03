package Nephia::Plugin::Auth::Twitter;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use Nephia::DSLModifier;
use Net::Twitter::Lite::WithAPIv1_1;
use Data::Dumper::Concise;

sub twitter_auth (&) {
    my $code        = shift;
    my $req         = origin('req');
    my $session_key = origin('cookie')->('session.twitter');
    my $conf        = origin('config')->()->{'Auth::Twitter'};
    my $twitter     = Net::Twitter::Lite::WithAPIv1_1->new(%$conf);
    my $token       = $req->()->param('oauth_token');
    my $verifier    = $req->()->param('oauth_verifier');
    if ( $token && $verifier ) {
        return $twitter->request_access_token( verifier => $verifier );
    }
    elsif (defined $session_key) {
        return { session => $session_key };
    }
    else {
        my $auth_url = $twitter->get_authorization_url(callback => $conf->{callback_url});
        return origin('res')->(sub { redirect->($auth_url) });
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::Auth::Twitter - It's new $module

=head1 SYNOPSIS

in your config ...

    +{
        ...
        'Auth::Twitter' => +{
            consumer_key    => ... ,
            consumer_secret => ... ,
            callback_url    => 'http://...' ,
        },
        ...
    };

and in your app ...

    package Your::App;
    use Nephia plugins => ['Auth::Twitter'];
    our $SESSION = {};
    
    sub verify_session {
        my $session_key = twitter_session;
        return $SESSION->{$session_key};
    }
    
    path '/mypage' => sub {
        unless ( verify_session() ) {
            return twitter_auth {
                my $session_key = shift;
                $SESSION->{$session_key} = {};
            };
        }
        return +{...};
    };

=head1 DESCRIPTION

Nephia::Plugin::Auth::Twitter is ...

        # * patterns
        # authentication success => redirect to callback_url
        # has legal session key  => redirect to callback url
        # other case             => redirect to twitter's auth page
=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

