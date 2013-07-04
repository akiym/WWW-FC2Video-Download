use strict;
use warnings;
use utf8;
use Getopt::Long;
use Pod::Usage;
use Term::ProgressBar;
use WWW::FC2Video::Download;

my %opt;
GetOptions(
    'email=s'    => \$opt{email},
    'password=s' => \$opt{password},
) or pod2usage(2);

my $url = shift or pod2usage(2);

my $client = WWW::FC2Video::Download->new(%opt);
if ($opt{email}) {
    $client->login;
}

my $title = $client->get_title($url);
my $suffix = $client->get_suffix($url);
my $filename = "$title.$suffix";

my ($term, $fh);
$client->download($url, sub {
    my ($data, $res, $proto) = @_;

    unless ($term && $fh) {
        open $fh, '>', "./$filename" or die $!;
        $term = Term::ProgressBar->new($res->header('Content-Length'));
    }

    $term->update($term->last_update + length $data);
    print {$fh} $data;
});

__END__

=head1 SYNOPSIS

  % perl eg/fc2video-download.pl URL

  --email       Email address (optional)
  --password    Password (optional)

=cut
