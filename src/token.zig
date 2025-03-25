const std = @import("std");

pub const Token = struct {
    start: u32,
    end: u32,
    id: Id,

    pub const Id = enum(u8) {
        local_keyword,
        break_keyword,
        continue_keyword,
        else_keyword,
        elseif_keyword,
        if_keyword,
        or_keyword,
        and_keyword,
        then_keyword,
        require_keyword,
        end_keyword,
        return_keyword,
        false_keyword,
        true_keyword,

        eq, // '=' (assignment)
        not_eq, // '!=' (not equal)
        eq_eq, // '==' (comparison)
        lt, // '<' (less than)
        lt_eq, // '<=' (less than, equal)
        gt, // '>' (greater than)
        gt_eq, // '>=' (greater than, equal)
        plus, // '+' (addition)
        slash, // '/' (division)
        asterisk, // '*' (multiplication)

        identifier, // Variables names like 'x'
        l_paren, // '('
        r_paren, // ')'
        l_brace, // '{'
        r_brace, // '}'
        l_bracket, // '['
        r_bracket, // ']'
        comma, // ','
        dot, // '.'
        colon, // ':'

        string_literal, // e.g. "Hello, World"
        multi_string_literal, // e.g. [[Hello, World!]]
        int_literal, // integer literal
        new_line,
        illegal,
    };

    pub const keywords = std.StaticStringMap(Id).initComptime(.{
        .{ "local", .local_keyword },
        .{ "break", .break_keyword },
        .{ "continue", .continue_keyword },
        .{ "else", .else_keyword },
        .{ "elseif", .elseif_keyword },
        .{ "if", .if_keyword },
        .{ "or", .or_keyword },
        .{ "and", .and_keyword },
        .{ "then", .then_keyword },
        .{ "require", .require_keyword },
        .{ "end", .end_keyword },
        .{ "return", .return_keyword },
        .{ "false", .false_keyword },
        .{ "true", .true_keyword },
    });

    pub const operators = std.StaticStringMap(Id).initComptime(.{
        // inshallah, you will not format
        .{ "=", .eq },
        .{ "!=", .not_eq },
        .{ "==", .eq_eq },
        .{ "<", .lt },
        .{ "<=", .lt_eq },
        .{ ">", .gt },
        .{ ">=", .gt_eq },
        .{ "+", .plus },
        .{ "/", .slash },
        .{ "*", .asterisk },
        .{ "(", .l_paren },
        .{ ")", .r_paren },
        .{ "[", .l_brace },
        .{ "]", .r_brace },
        .{ "{", .l_bracket },
        .{ "}", .r_bracket },
        .{ ",", .comma },
        .{ ".", .dot },
        .{ ":", .colon },
    });
};
