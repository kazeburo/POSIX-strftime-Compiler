use Benchmark qw/:all/;
use POSIX qw/strftime/;
use Time::Format::Compiler;

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
}));


__DATA__
% perl -Ilib eg/benchmark.pl
Benchmark: running compiler, compiler_w/o_cache, posix for at least 1 CPU seconds...
  compiler:  0 wallclock secs ( 1.06 usr +  0.00 sys =  1.06 CPU) @ 295080.19/s (n=312785)
compiler_w/o_cache:  1 wallclock secs ( 1.14 usr +  0.01 sys =  1.15 CPU) @ 3894.78/s (n=4479)
     posix:  1 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 247349.53/s (n=264664)
                       Rate compiler_w/o_cache            posix         compiler
compiler_w/o_cache   3895/s                 --             -98%             -99%
posix              247350/s              6251%               --             -16%
compiler           295080/s              7476%              19%               --


