# NAME

Nephia::Plugin::Auth::Twitter - Twitter Auth for Nephia-apps.

# SYNOPSIS

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

# DESCRIPTION

Nephia::Plugin::Auth::Twitter is a plugin for Nephia that provides twitter authentication feature.

# COMMANDS

## twitter\_auth $CODEREF

Redirect to twitter authentication page. 

Then, execute code-block that supplied when authentication succeeded.

## twitter\_session

Fetch cookie that named 'session.twitter'.

## twitter\_session\_expire

Expire cookie named 'session.twitter'.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
