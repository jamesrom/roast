use v6;
use Test;
plan 78;

# L<S02/Names and Variables/To get a Perlish representation of any object>

my @tests = (
    # Basic scalar values
    42, 42/10, 4.2, 
    #?rakudo emit # sqrt(2) is a Num which we cannot currently .perl / eval
    sqrt(2),
    #?rakudo emit # 3e5 is converted to a Str when re-evaled
    3e5,
    Inf, -Inf, NaN,

    "a string", "", "\0", "\t", "\n", "\r\n", "\o7",
    '{', # "\d123",	# XXX there is no \d escape!!!
    '}',
    '$a @string %with &sigils()',

    ?1, ?0,
    #?rakudo emit # Mu eq Mu is an error now
    Mu,
    #?rakudo emit # parse error
    rx:P5/foo/, rx:P5//, rx:P5/^.*$/,

    # References to scalars
    #?rakudo emit # ng can't parse references yet
    \42, \Inf, \-Inf, \NaN, \"string", \"", \?1, \?0, \Mu,

    (a => 1),
    :b(2),

    # References to aggregates
    {},           # empty hash
    { a => 42 },  # only one elem
    { :a(1), :b(2), :c(3) },

    # Nested things
    { a => [1,2,3] },  # only one elem
    { a => [1,2,3], b => [4,5,6] },
    [ { :a(1) }, { :b(2), :c(3) } ],

    # a Seq
    <a b c>.Seq,
);

#?pugs emit force_todo 8, 45..50, 94, 96;

#?pugs emit unless $?PUGS_BACKEND eq "BACKEND_PUGS" {
#?pugs emit   skip_rest "eval() not yet implemented in $?PUGS_BACKEND.";
#?pugs emit   exit;
#?pugs emit }


# L<S02/Names and Variables/To get a Perlish representation of any object>
# Quoting S02 (emphasis added):
#   To get a Perlish representation of any data value, use the .perl method.
#   This will put quotes around strings, square brackets around list values,
#   curlies around hash values, etc., **such that standard Perl could reparse
#   the result**.
{
    for @tests -> $obj {
        my $s = (~$obj).subst(/\n/, '␤');
        ok eval($obj.perl) eq $obj,
            "($s.perl()).perl returned something whose eval()ed stringification is unchanged";
        is WHAT(eval($obj.perl)).gist, $obj.WHAT.gist,
            "($s.perl()).perl returned something whose eval()ed .WHAT is unchanged";
    }
}

# Recursive data structures
#?rakudo skip 'recursive data structure'
{
    my $foo = { a => 42 }; $foo<b> = $foo;
    is $foo<b><b><b><a>, 42, "basic recursive hashref";

    #?pugs skip 'hanging test'
    is ~$foo.perl.eval, ~$foo,
        ".perl worked correctly on a recursive hashref";
}

#?rakudo skip '{...}.perl does not work'
{
    my $foo = [ 42 ];
    my $bar = { a => 23 };
    $foo[1] = $bar;
    $bar<b> = $foo;

    is $foo[1]<b>[1]<b>[0], 42, "mixed arrayref/hashref recursive structure";

    #?pugs skip 'hanging test'
    is ~$foo.perl.eval, ~$foo,
        ".perl worked correctly on a mixed arrayref/hashref recursive structure";
}

{
    # test a bug reported by Chewie[] - apparently this is from S03
    is(eval((("f","oo","bar").keys).perl), <0 1 2>, ".perl on a .keys list");
}


# RT #61918
{
    class RT61918 {
        has $.inst is rw;
        has $!priv is rw;
        has $.string = 'krach';

        method init {
            $.inst = [ rand, rand ];
            $!priv = [ rand, rand ].perl;
        }
    }

    my $t1 = RT61918.new();
    my $t1_new = $t1.perl;
    $t1.init;
    my $t1_init = $t1.perl;

    ok $t1_new ne $t1_init, 'changing object changes .perl output';

    # TODO: more tests that show eval($t1_init) has the same guts as $t1.
    
    ok $t1_new ~~ /<< krach >>/, 'attribute value appears in .perl output';
}

# RT #64080
{
    my %h;
    lives_ok { %h<a> = [%h<a>] },
             'can assign list with new hash element to itself';
    lives_ok { %h<a>.perl }, 'can take .perl from hash element';
    ok %h<a> !=== %h<a>[0], 'hoa does not refer to hash element';
}

# RT #67790
{
    class RT67790 {}
    lives_ok { RT67790.HOW.perl }, 'can .perl on .HOW';
    ok eval(RT67790.HOW.perl) === RT67790.HOW, '... and it returns the right thing';
}

# RT #69869
{
    is 1.0.WHAT.gist, Rat.gist, '1.0 is Rat';
    is eval( 1.0.perl ).WHAT.gist, Rat.gist, "1.0 perl'd and eval'd is Rat";
}


# RT #67948
#?DOES 6
{
    my @a;
    ([0, 0], [1, 1]).grep({@a.push: .perl; 1}).eager;
    for @a {
        my $n = eval($_);
        isa_ok $n, Array, '.perl in .grep works - type';
        is $n.elems, 2, '.perl in .grep works - number of elems';
        is $n[0], $n[1], '.perl in .grep works - element equality';
    }
}

done;

# vim: ft=perl6
