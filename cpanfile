requires 'perl', '5.008001';

requires 'LWP::UserAgent';
requires 'URI';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

