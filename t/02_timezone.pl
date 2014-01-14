#!/usr/bin/perl

use strict;
use warnings;

use Time::Local;
use Time::Format::Compiler;

my $fmt = shift @ARGV || '%z';
my @t = @ARGV ? localtime timelocal(@ARGV) : localtime;

print Time::Format::Compiler->new($fmt)->to_string(@t);

