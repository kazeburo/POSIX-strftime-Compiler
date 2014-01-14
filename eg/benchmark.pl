use Benchmark qw/:all/;
use POSIX qw/strftime/;
use Time::Format::Compiler;
use HTTP::Date qw//;

my @t = localtime;
my $fmt = '%a, %d %b %Y %T %z';
my $compiler = Time::Format::Compiler->new($fmt);


cmpthese(timethese(-1, {
    'compiler' => sub {
        $compiler->display(@t);
    },
    'posix' => sub {
        POSIX::strftime($fmt,@t);
    },
    'compiler_w/o_cache' => sub {
        my $compiler2 = Time::Format::Compiler->new($fmt);
        $compiler2->display(@t);
    },
    'http_date' => sub {
        HTTP::Date::time2str();
    },
}));


__DATA__
% perl -Ilib eg/benchmark.pl
Benchmark: running compiler, compiler_w/o_cache, http_date, posix for at least 1 CPU seconds...
  compiler:  0 wallclock secs ( 1.09 usr +  0.00 sys =  1.09 CPU) @ 485622.94/s (n=529329)
compiler_w/o_cache:  1 wallclock secs ( 1.10 usr +  0.00 sys =  1.10 CPU) @ 3759.09/s (n=4135)
 http_date:  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 494700.00/s (n=529329)
     posix:  1 wallclock secs ( 1.05 usr +  0.00 sys =  1.05 CPU) @ 252060.95/s (n=264664)
                       Rate compiler_w/o_cache       posix   compiler  http_date
compiler_w/o_cache   3759/s                 --        -99%       -99%       -99%
posix              252061/s              6605%          --       -48%       -49%
compiler           485623/s             12819%         93%         --        -2%
http_date          494700/s             13060%         96%         2%         --
