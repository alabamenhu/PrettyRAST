unit module RAST;

my $color = False;
sub colorize-RAST is export { $color = True }

constant %fore =
    black => "\x1b[30m", red => "\x001b[31m", green => "\x1b[32m", yellow => "\x1b[33m",
    blue => "\x1b[34m",  magenta => "\x1b[35m", cyan => "\x1b[36m", white => "\x1b[37m",
    gray => "\x1b[30;1m", pink => "\x1b[31;1m", neon-green => "\x1b[32;1m", bright-yellow => "\x1b[93m", #"\x1b[33;1m",
    sky-blue => "\x1b[34;1m", violet => "\x1b[35;1m", bright-cyan => "\x1b[36;1m", bright-white => "\x1b[37;1m",
    orange => "\x1b[38;5;166m", purple => "\x1b[38;5;99m", dark-green => "\x1b[38;5;22m",
    saffron => "\x1b[38;5;178m";
constant %back =
    black => "\x14[30m", red => "\x14[31m", green => "\x14[32m", yellow => "\x14[33m",
    blue => "\x14[34m", magenta => "\x14[35m", cyan => "\x14[36m", white => "\x14[37m",
    gray => "\x1b[40;1m", pink => "\x1b[41;1m", neon-green => "\x1b[42;1m", bright-yellow => "\x1b[43;1m",
    sky-blue => "\x1b[44;1m", violet => "\x1b[45;1m", bright-cyan => "\x1b[46;1m", bright-white => "\x1b[47;1m";
constant %deco =
    bold => "\x1b[1m", uline => "\x1b[4m", flip => "\x1b[0m", dim => "\x1b[2m";

constant $reset-text = "\x1b[0m";

sub green(  $s) { $color ?? %fore<dark-green>   ~ $s ~ $reset-text !! $s }
sub red(    $s) { $color ?? %fore<red>     ~ $s ~ $reset-text !! $s }
sub yellow( $s) { $color ?? %fore<saffron>  ~ $s ~ $reset-text !! $s }
sub bright-yellow( $s) { $color ?? %fore<bright-yellow>  ~ $s ~ $reset-text !! $s }
sub orange( $s) { $color ?? %fore<orange>  ~ $s ~ $reset-text !! $s }
sub blue(   $s) { $color ?? %fore<blue>    ~ $s ~ $reset-text !! $s }
sub cyan(   $s) { $color ?? %fore<cyan>    ~ $s ~ $reset-text !! $s }
sub magenta($s) { $color ?? %fore<purple>  ~ $s ~ $reset-text !! $s }
sub gray(   $s) { $color ?? %fore<gray>    ~ $s ~ $reset-text !! $s }

sub pretty-print(RakuAST::Node $node) is export {
    my $*indent     = 0; # to answer "how far nested are we?"
    my $*linelength = 0; # to answer "how long is my line?"
    my $*need-brace = True; # set to false by functions that will already brace a block
    my @*trail; # to answer "who is my parent?"
    pp $node;
}
proto sub pp(Any $x) is export {
    ENTER @*trail.push($x);
    LEAVE @*trail.pop;
    {*}
}

# Literals
multi sub pp(RakuAST::StrLiteral     $x) { green "'{$x.value}'"  }
multi sub pp(RakuAST::IntLiteral     $x) { cyan   $x.value.raku  }
multi sub pp(RakuAST::NumLiteral     $x) { cyan   $x.value.raku  }
multi sub pp(RakuAST::RatLiteral     $x) { $x.value.nude.map({cyan ~$_}).join(yellow '/') }
multi sub pp(RakuAST::VersionLiteral $x) { cyan $x.value.raku    }
multi sub pp(RakuAST::QuotedString   $x) {
    my $interpolated = False;
    $interpolated = True
        if .isa(RakuAST::Block) || .does(RakuAST::Var)
            for $x.segments;

    if $interpolated {
        return green('"')
             ~ $x.segments.map({
                   given $^s {
                       when RakuAST::StrLiteral { green   .value }
                       when RakuAST::Var        { magenta .name  }
                   }
               }).join
             ~ green('"')
    }else{
        return "'foo'"
    }
}

multi sub pp (RakuAST::Statement::Expression $x) {
    my $r = pp $x.expression;
    if $x.condition-modifier {
        my $cm = do given $x.condition-modifier {
            when RakuAST::StatementModifier::If      { orange('if '     ) ~ pp .expression }
            when RakuAST::StatementModifier::Unless  { orange('unless ' ) ~ pp .expression }
            when RakuAST::StatementModifier::When    { orange('when '   ) ~ pp .expression }
            when RakuAST::StatementModifier::With    { orange('with '   ) ~ pp .expression }
            when RakuAST::StatementModifier::Without { orange('without ') ~ pp .expression }
        }
        $r ~= $cm; # check line length here
    }
    if $x.loop-modifier {
        my $lm = do given $x.loop-modifier {
            when RakuAST::StatementModifier::While { orange('while ') ~~ pp .extension }
            when RakuAST::StatementModifier::Until { orange('until ') ~~ pp .extension }
            when RakuAST::StatementModifier::Given { orange('given ') ~~ pp .extension }
            when RakuAST::StatementModifier::For   { orange('for '  ) ~~ pp .extension }
        }
        $r ~= $lm; # check line length here, etc
    }

    $r
}

multi sub pp (RakuAST::StatementList $x) {
    join do for $x.statements {
        "{pp $_};\n"
    }
}

multi sub pp (RakuAST::PointyBlock $x) {
    temp $*need-brace = False;
    my $body = pp $x.body;
    my $r = '-> ';
    $r ~= pp($x.signature) ~ ' {';
    if $body.lines > 1 {
        $*indent += 4;
        $r ~= "\n{' ' xx $*indent}$_" for $body.lines;
        $r ~= "\n}";
        $*indent -= 4;
    } else {
        $r ~= "\{ $body }"
    }
    $r
}

multi sub pp (RakuAST::Signature $x) {
    my $r = "(";
    for $x.parameters {
        $r ~= pp $_;
        $r ~= ',';
    }
    $r .= substr(0,*-1); # trim the ','
    $r ~= '--> ' ~ pp $x.returns if $x.returns;
    $r ~= ')'
}
multi sub pp(RakuAST::Parameter $x) {
    my $r = '';
    $r ~= red pp($_) ~ " "   with $x.type;   # e.g. 'Foo '
    $r ~= pp($_)         with $x.slurpy;
    $r ~= magenta pp($_)         with $x.target; # e.g. '$foo'
    $r ~= ' = ' ~ pp($_) with $x.default; # e.g. ' = 2'
    $r ~= ':' if $x.invocant; # e.g. 'Foo $foo:"
    $r;
}
multi sub pp (RakuAST::ParameterTarget $x) {
    $x.name.starts-with($x.sigil)
        ?? $x.name
        !! $x.sigil ~ $x.name;
}

multi sub pp (RakuAST::Blockoid $x) {
    $x.statement-list.statements.map({
        .WHAT.say;
        pp($_) ~ "\n"
    }).join
}
multi sub pp (RakuAST::Block $x) {
    my $needed-brace = $*need-brace;
    $*need-brace = True; # now inner blocks will get them
    my $body = $x.body.statement-list.statements.map({ (" " xx $*indent) ~ pp($_)}).join;
    if $*needed-brace {
        $body = "\{\n" ~ $body ~ "\n}";
    }
    $*need-brace = $needed-brace; # restore
    $body;
}

multi sub pp (RakuAST::Type::Simple $x) {
    $x.name;
}

multi sub pp (RakuAST::Node $x) { %back<blue> ~ %fore<white> ~ "🦋{$x.WHAT.gist}" ~ $reset-text } # this should be the last resort


multi sub pp(RakuAST::Statement::If $x) {
    my $r = orange 'if ';
    $r ~= pp($x.condition) ~ ' {';
    temp $*need-brace = False;
    my $then = pp $x.then;
    if $then.lines == 1 && $then.chars < 25 {
        $r ~= $then ~ ' }'
    } else {
        $*indent += 4;
        $r ~= "\n{' ' xx $*indent}$_" for $then.lines;
        $r ~= "\n}";
        $*indent -= 4;
    }
    for $x.elsifs {
        my $elsif = pp .then;
        if $r.lines == 1 { $r ~= orange("\nelsif ") ~ pp(.condition) ~ " \{" }
        else             { $r ~= orange(' elsif ' ) ~ pp(.condition) ~ ' { ' }

        if $elsif.lines == 1 && $elsif.chars < 25 && !$r.lines.tail.starts-with('}')  {
            $r ~= $elsif ~ ' }'
        } else {
            $*indent += 4;
            $r ~= "\n{' ' xx $*indent}$_" for $elsif.lines;
            $r ~= "\n}";
            $*indent -= 4;
        }
    }
    if $x.else {
        my $else = pp $x.else;
        if $r.lines > 1 && !$r.lines.tail.starts-with('}') { $r ~= orange "\nelse " ~ '{' }
        else             { $r ~= orange(' else') ~ ' { '   }
        if $else.lines == 1 && $else.chars < 25 {
            $r ~= $else ~ ' }'
        }else {
            $*indent += 4;
            $r ~= "\n{' ' xx $*indent}$_" for $else.lines;
            $r ~= "\n}";
            $*indent -= 4;
        }
    }
    $r;
}

subset NoOperandParens of Any where RakuAST::Var::Lexical | RakuAST::StrLiteral | RakuAST::IntLiteral | RakuAST::NumLiteral;

multi sub pp(RakuAST::ApplyInfix      $x) { "{pp $x.left} {pp $x.infix} {pp $x.right}" }
multi sub pp(RakuAST::ApplyPostfix    $x) {
    $x.operand ~~ NoOperandParens
        ?? "{pp $x.operand}{pp $x.postfix}"
        !! "({pp $x.operand}){pp $x.postfix}"
}
multi sub pp(RakuAST::ApplyPrefix     $x) { "{pp $x.prefix}{pp $x.operand}" }
multi sub pp(RakuAST::ApplyListInfix  $x) {
    $x.operands.map({ pp $_ }).join(
        $x.infix.operator eq <, ;>.any ?? "{pp $x.infix} " !! " {pp $x.infix} ")
}

multi sub pp(RakuAST::Infix   $x) { bright-yellow $x.operator }
multi sub pp(RakuAST::Postfix $x) { bright-yellow $x.operator }
multi sub pp(RakuAST::Prefix  $x) { bright-yellow $x.operator }

multi sub pp(RakuAST::Var::Lexical $x) {
    magenta $x.name.starts-with($x.sigil)
        ?? $x.name
        !! $x.sigil ~ $x.name
}

multi sub pp(RakuAST::Call::Method $x) {
    my $r = yellow '.' ~ pp $x.name;
    $r ~= "({pp $x.args})" if $x.args.args > 0;
    $r
}

multi sub pp(RakuAST::ArgList $x) {
    $x.args.map({pp $_}).join(', ')
}

multi sub pp(RakuAST::Postcircumfix::ArrayIndex $x) {
    '[' ~ pp($x.index) ~ ']'
}

multi sub pp(RakuAST::Name $x) {
    $x.parts.map({pp $_}).join('::');
}
multi sub pp(RakuAST::SemiList $x) {
    $x.statements.map({pp $_}).join(orange '; ')
}


multi sub pp(RakuAST::Name::Part::Simple $x) { $x.name }


#sub EXPORT (*@x) {
#    Map.new:
#        '$*PRETTY-RAST-COLOR' => (my $*PRETTY-RAST-COLOR := ($color = @x.any eq 'color')),
#        '&pretty-print' => &pretty-print
#}
