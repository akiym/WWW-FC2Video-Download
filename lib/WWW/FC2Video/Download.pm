package WWW::FC2Video::Download;
use 5.008005;
use strict;
use warnings;
use Carp ();
use Digest::MD5;
use HTTP::Request;
use LWP::UserAgent;
use URI;

our $VERSION = "0.01";

our $SALT = 'gGddgPfeaf_gzyr';
our $API_SERVER = '50.112.136.211';

sub new {
    my ($class, %args) = @_;
    unless (exists $args{agent}) {
        my $ua = LWP::UserAgent->new(
            agent      => __PACKAGE__ . '/' . $VERSION,
            cookie_jar => {},
        );
        push @{$ua->requests_redirectable}, 'POST';
        $args{agent} = $ua;
    }
    return bless \%args, $class;
}

sub download {
    my ($self, $upid, @args) = @_;
    Carp::croak('Missing mandatory parameter: upid') unless defined $upid;

    my $video_url = $self->get_video_url($upid);
    my $req = HTTP::Request->new(GET => $video_url);
    my $res = $self->{agent}->request($req, @args);
    unless ($res->is_success) {
        Carp::croak('Download failed: ', $res->status_line);
    }
}

sub prepare_download {
    my ($self, $upid) = @_;
    if ($upid =~ m!/content/(?:.+?/)?(\w+)/?!) {
        $upid = $1;
    }
    return $self->{cache}{$upid} if exists $self->{cache}{$upid};

    my $data = $self->_ginfo($upid);
    if ($data->{filepath} eq '' && $data->{err_code} && $data->{err_code} == 403) {
        Carp::croak('This video has been disabled');
    }
    if (not exists $data->{filepath}) {
        Carp::croak('This content has already been deleted or set for private by the submitter');
    } elsif ($data->{filepath} eq '') {
        Carp::croak('This video is not found');
    }
    return $self->{cache}{$upid} = $data;
}

sub login {
    my $self = shift;

    Carp::croak('Missing mandatory parameter: email') unless defined $self->{email};
    Carp::croak('Missing mandatory parameter: password') unless defined $self->{password};

    my $res = $self->{agent}->post('https://secure.id.fc2.com/index.php?mode=login', {
        email => $self->{email},
        pass  => $self->{password},
    });
    if ($res->is_error) {
        Carp::croak('Login failed: ', $res->status_line);
    } elsif ($res->request->uri =~ /error=1/) {
        Carp::croak('Login failed because of invalid e-mail address or password');
    }

    $self->{agent}->get('http://id.fc2.com/?login=done');

    return 1;
}

sub get_filename {
    my ($self, $upid) = @_;
    my $filepath = $self->prepare_download($upid)->{filepath};
    my ($filename) = $filepath =~ m!/([^/]+)$!;
    return $filename;
}

sub get_suffix {
    my ($self, $upid) = @_;
    my $filename = $self->get_filename($upid);
    my ($suffix) = $filename =~ m!\.(.+?)$!;
    return $suffix;
}

sub get_title {
    my ($self, $upid) = @_;
    return $self->prepare_download($upid)->{title};
}

sub get_video_url {
    my ($self, $upid) = @_;
    my $data = $self->prepare_download($upid);
    return "$data->{filepath}?mid=$data->{mid}";
}

sub _ginfo {
    my ($self, $upid) = @_;

    my $mimi = $self->_gen_mimi($upid);
    my $url = "http://$API_SERVER/ginfo.php?upid=$upid&mimi=$mimi";
    my $res = $self->{agent}->get($url,
        Host => 'video.fc2.com',
    );
    unless ($res->is_success) {
        Carp::croak('ginfo API error: ', $res->status_line);
    }

    my $q = URI->new();
    $q->query($res->content);
    return +{$q->query_form};
}

sub _gen_mimi {
    my ($self, $upid) = @_;
    return Digest::MD5::md5_hex($upid . '_' . $SALT);
}

1;
__END__

=encoding utf-8

=head1 NAME

WWW::FC2Video::Download - FC2 video download interface

=head1 SYNOPSIS

    use WWW::FC2Video::Download;

    my $client = WWW::FC2Video::Download->new();

    my $video_url = $client->get_video_url($upid);
    my $title     = $client->get_title($upid);
    my $filename  = $client->get_filename($upid);
    my $suffix    = $client->get_suffix($upid);

=head1 DESCRIPTION

WWW::FC2Video::Download is a module to download video files from video.fc2.com.

=head1 METHODS

=over 4

=item new([%args])

Create an instance of WWW::FC2Video::Download.

=over 4

=item email

Email address

=item password

Password

=item agent

L<LWP::UserAgent>

=back

=item download($upid, [@args])

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

=item login()

Login with email and password.

  my $client = WWW::FC2Video::Download->new(
      email    => 'foo@example.com',
      password => 'p4ssw0rd',
  );

=item get_title($upid)

=item get_filename($upid)

=item get_suffix($upid)

=item get_video_url($upid)

=back

=head1 HACKING

=over 4

=item I've got to download an incomplete video. Why?

Perhaps, you attempted to download the video require pay member registration. Unfortunately, you CANNOT download it ;(

  my $data = $client->prepare_download($upid);
  if ($data->{charger}) {
      # pay member registration is required.
  }

=back

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut

