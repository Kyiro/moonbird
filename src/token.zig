const std = @import("std");

const mem = std.mem;

pub const Token = struct {
    start: usize,
    end: usize,
    id: Id,

    pub fn expect(self: *const Token, id: Id) !void {
        if (self.id == id) return;

        return error{UnexpectedToken}.UnexpectedToken;
    }

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
        plus_eq, // '+='
        minus, // '-' (subtraction)
        minus_eq, // '-='
        slash, // '/' (division)
        slash_eq, // '/='
        asterisk, // '*' (multiplication)
        asterisk_eq, // '*='

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
        num_literal, // number literal
        new_line,
        comment,
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

    pub const operators = std.StaticStringMap(Id).initComptime(&.{
        .{ "!=", .not_eq },
        .{ "==", .eq_eq },
        .{ "=", .eq },
        .{ "<=", .lt_eq },
        .{ "<", .lt },
        .{ ">=", .gt_eq },
        .{ ">", .gt },
        .{ "+", .plus },
        .{ "+=", .plus_eq },
        .{ "-", .minus },
        .{ "-=", .minus_eq },
        .{ "/", .slash },
        .{ "/=", .slash_eq },
        .{ "*", .asterisk },
        .{ "*=", .asterisk_eq },
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

    pub const operatorKeys = [_][]const u8{
        "!=", // 2-char operators
        "==",
        "<=",
        ">=",
        "+=",
        "-=",
        "*=",
        "/=",
        "(", // 1-char operators
        ")",
        "[",
        "]",
        "{",
        "}",
        ",",
        ".",
        ":",
        "<",
        ">",
        "=",
        "+",
        "/",
        "*",
    };
};
