use strict;
use warnings;
use utf8;
use WWW::FC2Video::Download;
use Term::ProgressBar;

my $url = shift or die "Usage: $0 URL\n";

my $client = WWW::FC2Video::Download->new();

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
