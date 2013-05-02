use strict;
use warnings;
use LWP::UserAgent;
use Term::ProgressBar;
use WWW::FC2Video::Download;
use Web::Query;

my $url = shift;
if (!$url || $url !~ m!video\.fc2\.com/a/member!) {
    die "Usage: $0 http://video.fc2.com/a/member/*\n";
}

my $ua = LWP::UserAgent->new();
my $client = WWW::FC2Video::Download->new();

my $q = URI->new($url);
my %query = $q->query_form();
die "URL does not contain 'mid' parameter" unless exists $query{mid};

my $page = 1;
while ($page < 100) { # limit
    my $member_url = "http://video.fc2.com/a/member.php?isadult=1&ordertype=0&usetime=0&timestart=0&timeend=0&perpage=8&opentype=1&kobj_mb_id=$query{mid}&page=$page";
    my @href = wq($member_url)->find('div.video_list div.video_list_comment h3 a')->attr('href');
    last unless @href;

    for my $video_url (@href) {
        my $data = $client->prepare_download($video_url);
        if ($data->{charger}) {
            warn 'Pay member registration is required';
            next;
        }
        my $filename = $client->get_filename($video_url);
        next if -e $filename;

        warn "Downloading $filename";

        my ($term, $fh);
        $client->download($video_url, sub {
            my ($data, $res, $proto) = @_;
            unless ($term && $fh) {
                open $fh, '>', "./$filename" or die $!;
                $term = Term::ProgressBar->new($res->header('Content-Length'));
            }
            $term->update($term->last_update + length $data);
            print {$fh} $data;
        });
    }

    $page++;
}
