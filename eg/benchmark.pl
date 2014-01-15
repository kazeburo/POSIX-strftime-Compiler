use Benchmark qw/:all/;
use POSIX qw/strftime/;
use POSIX::strftime::Compiler;
use HTTP::Date qw//;

my $fmt = '%d/%b/%Y:%T %z';
my $compiler = POSIX::strftime::Compiler->new($fmt);
my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
my $t = time;
my @lt = localtime;

sub with_sprintf {
    my $tz = '+0900';
    sprintf '%02d/%s/%04d:%02d:%02d:%02d %s', $_[3], $abbr[$_[4]], $_[5]+1900, 
        $_[2], $_[1], $_[0], $tz;
}

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
        with_sprintf(@lt);
    },
}));


__END__
% perl -Ilib eg/benchmark.pl   
Benchmark: running compiler, http_date, posix, sprintf for at least 1 CPU seconds...
  compiler:  1 wallclock secs ( 1.08 usr +  0.01 sys =  1.09 CPU) @ 631310.09/s (n=688128)
 http_date:  1 wallclock secs ( 1.18 usr +  0.00 sys =  1.18 CPU) @ 530144.07/s (n=625570)
     posix:  1 wallclock secs ( 1.09 usr +  0.00 sys =  1.09 CPU) @ 263044.95/s (n=286719)
   sprintf:  1 wallclock secs ( 1.11 usr +  0.01 sys =  1.12 CPU) @ 936227.68/s (n=1048575)
              Rate     posix http_date  compiler   sprintf
posix     263045/s        --      -50%      -58%      -72%
http_date 530144/s      102%        --      -16%      -43%
compiler  631310/s      140%       19%        --      -33%
sprintf   936228/s      256%       77%       48%        --
