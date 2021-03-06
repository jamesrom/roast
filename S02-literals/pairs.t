use v6;

use Test;

# L<S02/Adverbial Pair forms/"There is now a generalized adverbial form of Pair">

# See thread "Demagicalizing pair" on p6l started by Luke Palmer,
# L<"http://article.gmane.org/gmane.comp.lang.perl.perl6.language/4778/"> and
# L<"http://colabti.de/irclogger/irclogger_log/perl6?date=2005-10-09,Sun&sel=528#l830">.
# Also see L<"http://www.nntp.perl.org/group/perl.perl6.language/23532">.

# To summarize:
#   foo(a => 42);  # named
#   foo(:a(42));   # named
#
#   foo((a => 42));  # pair passed positionally
#   foo((:a(42)));   # pair passed positionally
#
#   my $pair = (a => 42);
#   foo($pair);      # pair passed positionally
#   foo(|$pair);     # named
#
#   S02 lists ':a' as being equivlaent to a => 1, so
#   the type of the value of that pair is Int, not Bool

plan 79;

sub f1n (:$a) { $a.WHAT.gist }
sub f1p ( $a) { $a.WHAT.gist }
{
    is f1n(a => 42), 'Int()', "'a => 42' is a named";
    is f1n(:a(42)),  'Int()', "':a(42)' is a named";

    is f1n(:a),      'Bool()',  "':a' is a named";
    is f1n(:!a),     'Bool()',  "':!a' is also named";

    is f1p("a"   => 42), 'Pair()', "'\"a\" => 42' is a pair";
    is f1p(("a") => 42), 'Pair()', "'(\"a\") => 42' is a pair";
    is f1p((a   => 42)), 'Pair()', "'(a => 42)' is a pair";
    is f1p(("a" => 42)), 'Pair()', "'(\"a\" => 42)' is a pair";
    is f1p((:a(42)),  ), 'Pair()', "'(:a(42))' is a pair";
    is f1p((:a),      ), 'Pair()',  "'(:a)' is a pair";
    is f1p((:!a),     ), 'Pair()',  "'(:a)' is also a pair";
    is f1n(:a[1, 2, 3]), 'Array()', ':a[...] constructs an Array value';
    is f1n(:a{b => 3}),  'Hash()', ':a{...} constructs a Hash value';
}

{
    my $p = :a[1, 2, 3];
    is $p.key, 'a', 'correct key for :a[1, 2, 3]';
    is $p.value.join('|'), '1|2|3', 'correct value for :a[1, 2, 3]';
}

{
    my $p = :a{b => 'c'};
    is $p.key, 'a', 'correct key for :a{ b => "c" }';
    is $p.value.keys, 'b', 'correct value for :a{ b => "c" } (keys)';
    is $p.value.values, 'c', 'correct value for :a{ b => "c" } (values)';
}

sub f2 (:$a!) { WHAT($a) }
{
    my $f2 = &f2;

    isa_ok f2(a     => 42), Int, "'a => 42' is a named";
    isa_ok f2(:a(42)),      Int, "':a(42)' is a named";
    isa_ok f2(:a),          Bool,"':a' is a named";

    isa_ok(&f2.(:a),        Bool, "in '&f2.(:a)', ':a' is a named");
    isa_ok $f2(:a),         Bool, "in '\$f2(:a)', ':a' is a named";
    isa_ok $f2.(:a),        Bool, "in '\$f2.(:a)', ':a' is a named";

    dies_ok { f2("a"   => 42) }, "'\"a\" => 42' is a pair";
    dies_ok { f2(("a") => 42) }, "'(\"a\") => 42' is a pair";
    dies_ok { f2((a   => 42)) }, "'(a => 42)' is a pair";
    dies_ok { f2(("a" => 42)) }, "'(\"a\" => 42)' is a pair";
    dies_ok { f2((:a(42)))    }, "'(:a(42))' is a pair";
    dies_ok { f2((:a))        }, "'(:a)' is a pair";
    dies_ok { &f2.((:a))       }, 'in \'&f2.((:a))\', \'(:a)\' is a pair';

    dies_ok { $f2((:a))       }, "in '\$f2((:a))', '(:a)' is a pair";
    dies_ok { $f2.((:a))      }, "in '\$f2.((:a))', '(:a)' is a pair";
    dies_ok { $f2(((:a)))     }, "in '\$f2(((:a)))', '(:a)' is a pair";
    dies_ok { $f2.(((:a)))    }, "in '\$f2.(((:a)))', '(:a)' is a pair";
}

sub f3 ($a) { WHAT($a) }
{
    my $pair = (a => 42);

    isa_ok f3($pair),  Pair, 'a $pair is not treated magically...';
    #?pugs todo '[,]'
    #?rakudo skip 'prefix:<|>'
    isa_ok f3(|$pair), Int,    '...but |$pair is';
}

sub f4 ($a)    { WHAT($a) }
sub get_pair () { (a => 42) }
{

    isa_ok f4(get_pair()),  Pair, 'get_pair() is not treated magically...';
    #?rakudo skip 'reduce meta op'
    isa_ok f4(|get_pair()), Int,    '...but |get_pair() is';
}

sub f5 ($a) { WHAT($a) }
{
    my @array_of_pairs = (a => 42);

    isa_ok f5(@array_of_pairs), Array,
        'an array of pairs is not treated magically...';
    #?rakudo skip 'prefix:<|>'
    isa_ok f5(|@array_of_pairs), Array, '...and |@array isn\'t either';
}

sub f6 ($a) { WHAT($a) }
{

    my %hash_of_pairs = (a => "str");

    ok (f6(%hash_of_pairs)).does(Hash), 'a hash is not treated magically...';
    #?pugs todo '[,]'
    #?rakudo skip 'reduce meta op'
    isa_ok f6([,] %hash_of_pairs), Str,  '...but [,] %hash is';
}

sub f7 (:$bar!) { WHAT($bar) }
{
    my $bar = 'bar';

    dies_ok { f7($bar => 42) },
        "variables cannot be keys of syntactical pairs (1)";
}

sub f8 (:$bar!) { WHAT($bar) }
{
    my @array = <bar>;

    dies_ok { f8(@array => 42) },
        "variables cannot be keys of syntactical pairs (2)";
}

sub f9 (:$bar!) { WHAT($bar) }
{
    my $arrayref = <bar>;

    dies_ok { f9($arrayref => 42) },
        "variables cannot be keys of syntactical pairs (3)";
}

{
    is (a => 3).elems, 1, 'Pair.elems';
}

# RT #74948
#?rakudo skip 'nom regression'
#?DOES 32
{
    # We use a block because of RT #77646.
    { is eval("($_ => 1).key"), $_, "Pair with '$_' as key" } for <
        self rand time now YOU_ARE_HERE package module class role
        grammar my our state let temp has augment anon supersede
        sub method submethod macro multi proto only regex token
        rule constant enum subset
    >;
}

# vim: ft=perl6
