# NAME

WWW::FC2Video::Download - FC2 video download interface

# SYNOPSIS

    use WWW::FC2Video::Download;

    my $client = WWW::FC2Video::Download->new();

    my $video_url = $client->get_video_url($upid);
    my $title     = $client->get_title($upid);
    my $filename  = $client->get_filename($upid);
    my $suffix    = $client->get_suffix($upid);

# DESCRIPTION

WWW::FC2Video::Download is a module to download video files from video.fc2.com.

# METHODS

- new(\[%args\])

    Create an instance of WWW::FC2Video::Download.

    - email

        Email address

    - password

        Password

    - agent

        [LWP::UserAgent](http://search.cpan.org/perldoc?LWP::UserAgent)

- download($upid, \[@args\])

    Download the video. $upid can also pass to FC2 video URL.

        my $filename = $client->get_filename($upid);
        my $fh;
        $client->download($upid, sub {
            my ($data, $res, $proto) = @_;
            unless ($fh) {
                open $fh, '>', "./$filename" or die $!;
            }
            print {$fh} $data;
        });

- login()

    Login with email and password.

        my $client = WWW::FC2Video::Download->new(
            email    => 'foo@example.com',
            password => 'p4ssw0rd',
        );

- get\_title($upid)
- get\_filename($upid)
- get\_suffix($upid)
- get\_video\_url($upid)

# HACKING

- I've got to download an incomplete video. Why?

    Perhaps, you attempted to download the video require pay member registration. Unfortunately, you CANNOT download it ;(

        my $data = $client->prepare_download($upid);
        if ($data->{charger}) {
            # pay member registration is required.
        }

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama <t.akiym@gmail.com>
