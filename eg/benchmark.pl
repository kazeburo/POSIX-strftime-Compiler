use Benchmark qw/:all/;
use POSIX qw/strftime/;
use POSIX::strftime::Compiler;
use HTTP::Date qw//;

my $fmt = '%d/%b/%Y:%T %z';
my $compiler = POSIX::strftime::Compiler->new($fmt);
my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my $t = time;
my @lt = localtime;

cmpthese(timethese(-1, {
    'compiler' => sub {
        $compiler->to_string(@lt);
    },
    'posix' => sub {
        POSIX::strftime($fmt,@lt);
    },
#    'compiler_wo_cache' => sub {
#        my @t = localtime;
#        my $compiler2 = Time::Format::Compiler->new($fmt);
#        $compiler2->to_string(@t);
#    },
    'http_date' => sub {
        HTTP::Date::time2str($t);
    },
    'sprintf' => sub {
        my $tz = '+0900';
        sprintf '%02d/%s/%04d:%02d:%02d:%02d %s', $lt[3], $abbr[$lt[4]], $lt[5]+1900, 
          $lt[2], $lt[1], $lt[0], $tz;
    },
}));


__DATA__
% perl -Ilib eg/benchmark.pl
Benchmark: running compiler, http_date, posix, sprintf for at least 1 CPU seconds...
  compiler:  2 wallclock secs ( 1.05 usr +  0.00 sys =  1.05 CPU) @ 655360.00/s (n=688128)
 http_date:  2 wallclock secs ( 1.12 usr +  0.00 sys =  1.12 CPU) @ 558544.64/s (n=625570)
     posix:  1 wallclock secs ( 1.11 usr +  0.00 sys =  1.11 CPU) @ 258305.41/s (n=286719)
   sprintf:  2 wallclock secs ( 1.10 usr +  0.00 sys =  1.10 CPU) @ 1251140.91/s (n=1376255)
               Rate     posix http_date  compiler   sprintf
posix      258305/s        --      -54%      -61%      -79%
http_date  558545/s      116%        --      -15%      -55%
compiler   655360/s      154%       17%        --      -48%
sprintf   1251141/s      384%      124%       91%        --


