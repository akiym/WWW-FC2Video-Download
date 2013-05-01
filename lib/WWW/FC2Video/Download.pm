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

sub new {
    my ($class, %args) = @_;
    unless (exists $args{agent}) {
        $args{agent} = LWP::UserAgent->new(
            agent => __PACKAGE__ . '/' . $VERSION,
        );
    }
    return bless \%args, $class;
}

sub download {
    my ($self, $upid, @args) = @_;
    Carp::croak('Missing mandatory parameter: upid') unless defined $upid;

    my $data = $self->prepare_download($upid);
    unless ($data->{filepath}) {
        Carp::croak('URL not found');
    }
    my $video_url = $self->get_video_url($upid);
    my $filename = $self->get_filename($upid);

    my $req = HTTP::Request->new(GET => $video_url);
    my $res = $self->{agent}->request($req, @args);
    unless ($res->is_success) {
        Carp::croak('Download failed: ', $res->status_line);
    }
}

sub prepare_download {
    my ($self, $upid) = @_;
    if ($upid =~ m!/content/(\w+)/!) {
        $upid = $1;
    }
    return $self->{cache}{$upid} ||= $self->_ginfo($upid);
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
    my $url = "http://video.fc2.com/ginfo.php?upid=$upid&mimi=$mimi";
    my $res = $self->{agent}->get($url);
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

WWW::FC2Video::Download - It's new $module

=head1 SYNOPSIS

    use WWW::FC2Video::Download;

=head1 DESCRIPTION

WWW::FC2Video::Download is ...

=head1 LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Takumi Akiyama E<lt>t.akiym@gmail.comE<gt>

=cut

