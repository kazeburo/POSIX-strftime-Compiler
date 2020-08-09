use strict;
use warnings;
use Test::More;
use POSIX::strftime::Compiler;

use File::Basename;

my $inc = join ' ', map { "-I\"$_\"" } @INC;
my $dir = dirname(__FILE__);

my $zone = $ENV{TZ};
eval {
    $ENV{TZ} = 'Australia/Darwin';
    my $d = `"$^X" $inc $dir/02_timezone.pl %z 0 0 0 10 0 113`;
    if ($d !~ m!^\+0930!) {
        die "tzdada is not enough: $d";
    }
};
if ( $@ ) {
    plan skip_all => $@;
}
$ENV{TZ} = $zone;

my $found;
for my $tz (qw( Europe/Paris CET-1CEST )) {
    $ENV{TZ} = $tz;
    if (`"$^X" $inc $dir/02_timezone.pl %z 0 0 0 1 1 112` =~ /^\+0[12]00$/) {
        $found = $tz;
        last;
    }
};

if ($found) {
    plan tests => 4;
}
else {
    plan skip_all => 'Missing tzdata on this system';
};

my @t1 = (0, 0, 0, 1, 1, 112);
my @t2 = (0, 0, 0, 1, 7, 112);

$ENV{TZ} = $found;

is `"$^X" $inc $dir/02_timezone.pl %z @t1`, '+0100', "tmzone1($ENV{TZ})";
is `"$^X" $inc $dir/02_timezone.pl %Z @t1`, 'CET',   "tmname1($ENV{TZ})";
is `"$^X" $inc $dir/02_timezone.pl %z @t2`, '+0200', "tmzone2($ENV{TZ})";
is `"$^X" $inc $dir/02_timezone.pl %Z @t2`, 'CEST',  "tmname2($ENV{TZ})";
