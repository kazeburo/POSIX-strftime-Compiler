use strict;
use warnings;
use Test::More;
use POSIX;
use Time::Local;
use POSIX::strftime::Compiler;

eval {
    POSIX::tzset;
    die q!tzset is implemented on this Cygwin. But Windows can't change tz inside script! if $^O eq 'cygwin';
    die q!tzset is implemented on this Windows. But Windows can't change tz inside script! if $^O eq 'MSWin32';
};
if ( $@ ) {
    plan skip_all => $@;
}

my @timezones = ( 
    ['Australia/Darwin','+0930','+0930','+0930','+0930','CST','CST','CST','CST' ],
    ['Asia/Tokyo', '+0900','+0900','+0900','+0900', 'JST','JST','JST','JST'],
    ['UTC', '+0000','+0000','+0000','+0000','UTC','UTC','UTC','UTC'],
    ['Europe/London', '+0000','+0100','+0100','+0000','GMT','BST','BST','GMT'],
    ['Europe/Paris', '+0100','+0200','+0200','+0100','CET','CEST','CEST','CET'],
    ['America/New_York','-0500', '-0400', '-0400', '-0500','EST','EDT','EDT','EST']
);

my $psc = POSIX::strftime::Compiler->new('%z');
my $psc2 = POSIX::strftime::Compiler->new('%Z');
for my $timezones (@timezones) {
    my ($timezone, @tz) = @$timezones;
    local $ENV{TZ} = $timezone;
    POSIX::tzset;

    subtest "$timezone" => sub {
        my $i=0;
        for my $date ( ([10,1,2013], [10,5,2013], [15,8,2013], [15,11,2013]) ) {
            my ($day,$month,$year) = @$date;
            my $str = $psc->to_string(localtime(timelocal(0, 45, 12, $day, $month - 1, $year)));
            is $str, $tz[$i];
            my $str2 = $psc2->to_string(localtime(timelocal(0, 45, 12, $day, $month - 1, $year)));
            if ( ref $tz[$i+4] ) {
                like $str2, $tz[$i+4], "$timezone / $year-$month-$day => $str2";
            }
            else {
                is $str2, $tz[$i+4], "$timezone / $year-$month-$day => $str2";
            }
            $i++;
        }
    };

}

done_testing();

