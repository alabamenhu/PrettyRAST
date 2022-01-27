use Pretty::RAST; colorize-RAST;

say pretty-print get-sample-ast;

sub get-sample-ast {
    my $ast;
    my $start-infix = ", ";
    my $middle-infix = ", ";
    my $end-infix = ", and ";
    my $two-infix = " and ";
    #| @list.elems - 2
    my $more = RakuAST::ApplyInfix.new(
        infix => RakuAST::Infix.new('-'),
        left  => RakuAST::Statement::Expression.new( expression =>
        RakuAST::ApplyPostfix.new(
            operand => RakuAST::Var::Lexical.new('@list'),
            postfix => RakuAST::Call::Method.new(
                name => RakuAST::Name.from-identifier('elems')
                ),
            )
            ),
        right => RakuAST::IntLiteral.new(2)
        );

    # @list[ 1 .. * - 2]
    $more = RakuAST::ApplyPostfix.new(
        operand => RakuAST::Var::Lexical.new('@list'),
        postfix => RakuAST::Postcircumfix::ArrayIndex.new(
            RakuAST::SemiList.new(
                RakuAST::ApplyInfix.new(
                    infix => RakuAST::Infix.new('..'),
                    left  => RakuAST::IntLiteral(1),
                    right => $more
                    )
                )
            )
        );

    #| @list[1 .. * - 2].join( ',' ) # or whatever the middle infix is
    $more = RakuAST::ApplyPostfix.new(
        operand => $more,
        postfix => RakuAST::Call::Method.new(
            name => RakuAST::Name.from-identifier('join'),
            args => RakuAST::ArgList.new(RakuAST::StrLiteral.new($middle-infix))
            )
        );
    # @list[0] ~ $start-infix ~ @list[1 .. *-2].join($middle-infix) ~ $end-infix ~ @list[*-1]
    $more = RakuAST::ApplyListInfix.new(
        infix => RakuAST::Infix.new('~'),
        operands => [
            RakuAST::ApplyPostfix.new(
                operand => RakuAST::Var::Lexical.new('@list'),
                postfix => RakuAST::Call::Method.new(
                    name => RakuAST::Name.from-identifier('AT-POS'),
                    args => RakuAST::ArgList.new(RakuAST::IntLiteral.new(0))
                    )
                ),
            RakuAST::StrLiteral.new($start-infix),
            $more,
            RakuAST::StrLiteral.new($end-infix),
            RakuAST::ApplyPostfix.new(
                operand => RakuAST::Var::Lexical.new('@list'),
                postfix => RakuAST::Call::Method.new(
                    name => RakuAST::Name.from-identifier('tail'),
                    )
                )
        ]
        );
    $more = RakuAST::Block.new(
        body => RakuAST::Blockoid.new(
            RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                    expression => $more
                    )
                )
            )
        );

    my $two = RakuAST::Block.new( body =>
    RakuAST::Blockoid.new(
        RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new( expression =>
            RakuAST::ApplyPostfix.new(
                operand => RakuAST::ApplyListInfix.new(
                    infix => RakuAST::Infix.new(','),
                    operands => [
                        RakuAST::ApplyPostfix.new(
                            operand => RakuAST::Var::Lexical.new('@list'),
                            postfix => RakuAST::Call::Method.new(
                                name => RakuAST::Name.from-identifier('AT-POS'),
                                args => RakuAST::ArgList.new(RakuAST::IntLiteral.new(0))
                                )
                            ),
                        RakuAST::StrLiteral.new($two-infix),
                        RakuAST::ApplyPostfix.new(
                            operand => RakuAST::Var::Lexical.new('@list'),
                            postfix => RakuAST::Call::Method.new(
                                name => RakuAST::Name.from-identifier('AT-POS'),
                                args => RakuAST::ArgList.new(RakuAST::IntLiteral.new(1))
                                )
                            )
                    ]
                    ),
                postfix => RakuAST::Call::Method.new(
                    name => RakuAST::Name.from-identifier('join'),
                    #args => []
                    )
                )
                )
            )
        )
        );


    # { @list[0] }
    my $one = RakuAST::Block.new( body =>
    RakuAST::Blockoid.new(
        RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new( expression =>
            RakuAST::ApplyPostfix.new(
                operand => RakuAST::Var::Lexical.new('@list'),
                postfix => RakuAST::Call::Method.new(
                    name => RakuAST::Name.from-identifier('AT-POS'),
                    args => RakuAST::ArgList.new(RakuAST::IntLiteral.new(0))
                    )
                )
                )
            )
        )
        );

    # { '' } - the empty string
    my $zero = RakuAST::Block.new( body =>
    RakuAST::Blockoid.new(
        RakuAST::StatementList.new(
            RakuAST::Statement::Expression.new: expression => RakuAST::StrLiteral('')
            )
        )
        );
    #| @lists.elems > 2
    my $greater-than-two = RakuAST::Statement::Expression.new(
        expression => RakuAST::ApplyInfix.new(
            left  => RakuAST::ApplyPostfix.new(
                operand => RakuAST::Var::Lexical.new('@list'),
                postfix => RakuAST::Call::Method.new(
                    name => RakuAST::Name.from-identifier('elems')
                    )
                ),
            infix => RakuAST::Infix.new('>'),
            right => RakuAST::IntLiteral(2)
            )
        );
    #| @lists.elems == 2
    my $equal-to-two = RakuAST::Statement::Expression.new(
        expression => RakuAST::ApplyInfix.new(
            left  => RakuAST::ApplyPostfix.new(
                operand => RakuAST::Var::Lexical.new('@list'),
                postfix => RakuAST::Call::Method.new(
                    name => RakuAST::Name.from-identifier('elems')
                    )
                ),
            infix => RakuAST::Infix.new('=='),
            right => RakuAST::IntLiteral(2)
            )
        );
    #| @lists.elems == 1
    my $equal-to-one = RakuAST::Statement::Expression.new(
        expression => RakuAST::ApplyInfix.new(
            left  => RakuAST::ApplyPostfix.new(
                operand => RakuAST::Var::Lexical.new('@list'),
                postfix => RakuAST::Call::Method.new(
                    name => RakuAST::Name.from-identifier('elems')
                    )
                ),
            infix => RakuAST::Infix.new('=='),
            right => RakuAST::IntLiteral(1)
            )
        );

    #| -> @lists { if … }
    $ast = RakuAST::PointyBlock.new(
        signature => RakuAST::Signature.new(
            parameters => (
            RakuAST::Parameter.new(
                target => RakuAST::ParameterTarget::Var.new('@list')
                ),
            ),
            ),
        body => RakuAST::Blockoid.new(
            RakuAST::StatementList.new(
                RakuAST::Statement::Expression.new(
                    expression => RakuAST::Statement::If.new(
                        condition => $greater-than-two,
                        then => $more,
                        elsifs => [
                            RakuAST::Statement::Elsif.new(
                                condition => $equal-to-two,
                                then => $two
                                ),
                            RakuAST::Statement::Elsif.new(
                                condition => $equal-to-one,
                                then => $one
                                )
                        ],
                        else => $zero,
                        )
                    )
                )
            )
        );
}