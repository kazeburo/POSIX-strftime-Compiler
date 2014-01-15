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
  compiler:  2 wallclock secs ( 1.13 usr +  0.00 sys =  1.13 CPU) @ 507469.03/s (n=573440)
 http_date:  2 wallclock secs ( 1.21 usr +  0.01 sys =  1.22 CPU) @ 512762.30/s (n=625570)
     posix:  2 wallclock secs ( 1.08 usr +  0.00 sys =  1.08 CPU) @ 245059.26/s (n=264664)
   sprintf:  0 wallclock secs ( 1.07 usr +  0.00 sys =  1.07 CPU) @ 918728.97/s (n=983040)
              Rate     posix  compiler http_date   sprintf
posix     245059/s        --      -52%      -52%      -73%
compiler  507469/s      107%        --       -1%      -45%
http_date 512762/s      109%        1%        --      -44%
sprintf   918729/s      275%       81%       79%        --
