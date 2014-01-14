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
}));


__DATA__
% perl -Ilib eg/benchmark.pl
Benchmark: running compiler, posix for at least 1 CPU seconds...
  compiler:  1 wallclock secs ( 1.04 usr +  0.00 sys =  1.04 CPU) @ 300754.81/s (n=312785)
     posix:  1 wallclock secs ( 1.09 usr +  0.00 sys =  1.09 CPU) @ 255530.28/s (n=278528)
             Rate    posix compiler
posix    255530/s       --     -15%
compiler 300755/s      18%       --


