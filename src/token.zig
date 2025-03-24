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
        eq_eq, // '==' (comparison)
        plus, // '+' (addition)

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
        eof,
        illegal,
    };
    
    pub const keywords = std.StaticStringMap(Id).initComptime(.{
        .{ "local", Id.local_keyword },
        .{ "break", Id.break_keyword },
        .{ "continue", Id.continue_keyword },
        .{ "else", Id.else_keyword },
        .{ "elseif", Id.elseif_keyword },
        .{ "if", Id.if_keyword },
        .{ "or", Id.or_keyword },
        .{ "and", Id.and_keyword },
        .{ "then", Id.then_keyword },
        .{ "require", Id.require_keyword },
        .{ "end", Id.end_keyword },
        .{ "return", Id.return_keyword },
        .{ "false", Id.false_keyword },
        .{ "true", Id.true_keyword }
    });
};
