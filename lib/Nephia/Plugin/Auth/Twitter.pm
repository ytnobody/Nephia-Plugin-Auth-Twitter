package Nephia::Plugin::Auth::Twitter;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use Nephia::DSLModifier;
use Net::Twitter::Lite::WithAPIv1_1;
use Data::UUID::MT;
use Carp;

our $UUID_VERSION = '4';
our $COOKIE_NAME = 'session.twitter';

my $uuid_generator = Data::UUID::MT->new(version => $UUID_VERSION);

sub twitter_auth (&) {
    my $code        = shift;
    my $req         = origin('req');
    my $conf        = origin('config')->()->{'Auth::Twitter'};
    my $twitter     = Net::Twitter::Lite::WithAPIv1_1->new(%$conf);
    my $token       = $req->()->param('oauth_token');
    my $verifier    = $req->()->param('oauth_verifier');
    my $denied      = $req->()->param('denied');
    return _redirect_to_denied_url($twitter) if $denied;
    return $token && $verifier ? 
        _verify_token($twitter, $token, $verifier, $code) : 
        _redirect_to_auth_url($twitter)
    ;
}

sub _verify_token {
    my ($twitter, $token, $verifier, $code) = @_;
    my $twitter_id = eval { $twitter->request_access_token( 
        token        => $token, 
        token_secret => $twitter->{consumer_secret}, 
        verifier     => $verifier 
    ) };
    if ($@) {
        carp "verify failure: $@";
        return;
    }
    my $uuid = $uuid_generator->create_hex;
    $code->($uuid, $twitter_id);
    origin('set_cookie')->($COOKIE_NAME => $uuid);
    return origin('res')->(sub { redirect->($twitter->{callback_url}) });
}

sub _redirect_to_auth_url {
    my $twitter = shift;
    my $auth_url = $twitter->get_authorization_url(callback => $twitter->{callback_url});
    return origin('res')->(sub { redirect->($auth_url) });
}

sub _redirect_to_denied_url {
    my $twitter = shift;
    my $denied_url = $twitter->{denied_url};
    return $denied_url ? 
        origin('res')->(sub { redirect->($denied_url) }) : 
        origin('res')->(sub { 400, [], ['Access Denied'] }) 
    ;
}

sub twitter_session () {
    origin('cookie')->($COOKIE_NAME);
}

sub twitter_session_expire () {
    origin('set_cookie')->($COOKIE_NAME => {value => undef, expires => time - 86400});
}

1;
__END__

=encoding utf-8

=head1 NAME

Nephia::Plugin::Auth::Twitter - Twitter Auth for Nephia-apps.

=head1 SYNOPSIS

in your config ...

    +{
        ...
        'Auth::Twitter' => +{
            consumer_key    => ... ,
            consumer_secret => ... ,
            callback_url    => 'http://...' ,
            denied_url      => 'http://...' ,
        },
        ...
    };

and in your app ...

    package Your::App;
    use strict;
    use warnings;
    use utf8;
    
    use Nephia plugins => ['Auth::Twitter'];
    
    our $SESSION = {};
    
    sub get_twitter_id {
        my $session_id = shift;
        $SESSION->{$session_id};
    }
    
    path '/' => sub {
        my $session_id = twitter_session;
        my $twitter_id = get_twitter_id($session_id);

        ### redirect to auth url when failure to get twitter_id
        unless ($twitter_id) {
            return twitter_auth {
                # this code-block executes when authentication succeeded
                my ($session_id, $twitter_id) = @_;
                $SESSION->{$session_id} = $twitter_id;
            } 
        }
        
        ### authorized area
        return +{ yourname => $name };
    };
    
    path '/logout' => sub {
        twitter_session_expire;
        +{ message => 'logout' };
    };

=head1 DESCRIPTION

Nephia::Plugin::Auth::Twitter is a plugin for Nephia that provides twitter authentication feature.

=head1 COMMANDS

=head2 twitter_auth $CODEREF

Redirect to twitter authentication page. 

Then, execute code-block that supplied when authentication succeeded.

=head2 twitter_session

Fetch cookie that named 'session.twitter'.

=head2 twitter_session_expire

Expire cookie named 'session.twitter'.

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

