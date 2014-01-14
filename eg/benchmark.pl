use Benchmark qw/:all/;
use POSIX qw/strftime/;
use POSIX::strftime::Compiler;
use HTTP::Date qw//;

my $fmt = '%d/%b/%Y:%T %z';
my $compiler = POSIX::strftime::Compiler->new($fmt);
my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

cmpthese(timethese(-1, {
    'compiler' => sub {
        my @t = localtime;
        $compiler->to_string(@t);
    },
    'posix' => sub {
        my @t = localtime;
        POSIX::strftime($fmt,@t);
    },
#    'compiler_wo_cache' => sub {
#        my @t = localtime;
#        my $compiler2 = Time::Format::Compiler->new($fmt);
#        $compiler2->to_string(@t);
#    },
    'http_date' => sub {
        HTTP::Date::time2str();
    },
    'sprintf' => sub {
        my @lt = localtime();        
        my $tz = '+0900';
        sprintf '%02d/%s/%04d:%02d:%02d:%02d %s', $lt[3], $abbr[$lt[4]], $lt[5]+1900, 
          $lt[2], $lt[1], $lt[0], $tz;

    },
}));


__DATA__
% perl -Ilib eg/benchmark.pl
Benchmark: running compiler, compiler_wo_cache, http_date, posix for at least 1 CPU seconds...
  compiler:  1 wallclock secs ( 1.09 usr +  0.00 sys =  1.09 CPU) @ 286958.72/s (n=312785)
compiler_wo_cache:  1 wallclock secs ( 1.12 usr +  0.00 sys =  1.12 CPU) @ 3280.36/s (n=3674)
 http_date:  1 wallclock secs ( 1.10 usr +  0.00 sys =  1.10 CPU) @ 481208.18/s (n=529329)
     posix:  1 wallclock secs ( 1.05 usr +  0.01 sys =  1.06 CPU) @ 180326.42/s (n=191146)
                       Rate compiler_wo_cache       posix   compiler  http_date
compiler_wo_cache   3280/s                 --        -98%       -99%       -99%
posix              180326/s              5397%          --       -37%       -63%
compiler           286959/s              8648%         59%         --       -40%
http_date          481208/s             14569%        167%        68%         --


