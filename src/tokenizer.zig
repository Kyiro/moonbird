// reference
// https://codeberg.org/ziglang/zig/src/branch/main/lib/std/zig/tokenizer.zig
const std = @import("std");

pub const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        .{ "local", Tag.keyword_local },
        .{ "break", Tag.keyword_break },
        .{ "continue", Tag.keyword_continue },
        .{ "else", Tag.keyword_else },
        .{ "if", Tag.keyword_if },
        .{ "or", Tag.keyword_or },
        .{ "and", Tag.keyword_and },
        .{ "then", Tag.keyword_then },
        .{ "end", Tag.keyword_end },
        .{ "not", Tag.keyword_not },
        .{ "return", Tag.keyword_return },
        .{ "false", Tag.keyword_false },
        .{ "true", Tag.keyword_true },
        .{ "nil", Tag.keyword_nil },
        .{ "match", Tag.keyword_match },
        .{ "is", Tag.keyword_is },
        .{ "while", Tag.keyword_while },
        .{ "for", Tag.keyword_for },
        .{ "in", Tag.keyword_in },
        .{ "function", Tag.keyword_function },
    });

    pub const Tag = enum(u8) {
        keyword_local,
        keyword_break,
        keyword_continue,
        keyword_else,
        keyword_if,
        keyword_or,
        keyword_and,
        keyword_then,
        keyword_end,
        keyword_not,
        keyword_return,
        keyword_false,
        keyword_true,
        keyword_nil,
        keyword_match,
        keyword_is,
        keyword_while,
        keyword_for,
        keyword_in,
        keyword_function,

        eq, // '=' (assignment)
        not_eq, // '!=' (not equal)
        eq_eq, // '==' (comparison)
        lt, // '<' (less than)
        lt_eq, // '<=' (less than, equal)
        gt, // '>' (greater than)
        gt_eq, // '>=' (greater than, equal)
        plus, // '+' (addition)
        plus_plus, // '++' (array concat)
        plus_eq, // '+='
        minus, // '-' (subtraction)
        minus_eq, // '-='
        slash, // '/' (division)
        slash_eq, // '/='
        asterisk, // '*' (multiplication)
        asterisk_eq, // '*='
        caret, // '^'
        caret_eq, // '^='
        percent, // '%'
        percent_eq, // '%='

        identifier, // Variables names like 'x'
        l_paren, // '('
        r_paren, // ')'
        l_brace, // '{'
        r_brace, // '}'
        l_bracket, // '['
        r_bracket, // ']'
        comma, // ','
        dot, // '.'
        dot_dot, // '..'
        colon, // ':'
        question_mark, // '?'

        string_literal, // e.g. "Hello, World"
        multi_string_literal, // e.g. [[Hello, World!]]
        num_literal, // number literal
        new_line,
        comment, // '--' and '--[[...]]'
        illegal,
        eof, // end of file
    };
};

pub const Tokenizer = struct {
    buffer: [:0]const u8,
    index: usize,

    pub fn init(buffer: [:0]const u8) Tokenizer {
        return .{
            .buffer = buffer,
            // Skip the UTF-8 BOM if present.
            .index = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0,
        };
    }

    const State = enum {
        start,
        identifier,
        int,
        int_zero,
        int_hex,
        int_bin,
        int_oct,
        float,
        float_exponent,
        eq,
        plus,
        minus,
        percent,
        asterisk,
        lt,
        gt,
        caret,
        dot,
        slash,
        bang,
        string_literal,
        string_literal_backslash,
        multi_string_literal,
        multi_string_literal_bracket,
        comment,
        comment_bracket_open,
        multi_line_comment,
        multi_line_comment_bracket_close,
        illegal,
    };

    pub fn next(self: *Tokenizer) Token {
        var result: Token = .{
            .tag = undefined,
            .loc = .{
                .start = self.index,
                .end = undefined,
            },
        };

        state: switch (State.start) {
            .start => switch (self.buffer[self.index]) {
                0 => {
                    if (self.index == self.buffer.len) {
                        return .{
                            .tag = .eof,
                            .loc = .{
                                .start = self.index,
                                .end = self.index,
                            },
                        };
                    } else {
                        continue :state .illegal;
                    }
                },
                ' ', '\t', '\r' => {
                    self.index += 1;
                    result.loc.start = self.index;
                    continue :state .start;
                },
                '\n' => {
                    self.index += 1;
                    result.tag = .new_line;
                },
                'a'...'z', 'A'...'Z', '_' => continue :state .identifier,
                '(' => {
                    self.index += 1;
                    result.tag = .l_paren;
                },
                ')' => {
                    self.index += 1;
                    result.tag = .r_paren;
                },
                '{' => {
                    self.index += 1;
                    result.tag = .l_brace;
                },
                '}' => {
                    self.index += 1;
                    result.tag = .r_brace;
                },
                '=' => continue :state .eq,
                '+' => continue :state .plus,
                '-' => continue :state .minus,
                '*' => continue :state .asterisk,
                '/' => continue :state .slash,
                '<' => continue :state .lt,
                '>' => continue :state .gt,
                '!' => continue :state .bang,
                '%' => continue :state .percent,
                '^' => continue :state .caret,
                '.' => continue :state .dot,
                ',' => {
                    self.index += 1;
                    result.tag = .comma;
                },
                ':' => {
                    self.index += 1;
                    result.tag = .colon;
                },
                '?' => {
                    self.index += 1;
                    result.tag = .question_mark;
                },
                '[' => {
                    if (self.buffer[self.index + 1] == '[') {
                        continue :state .multi_string_literal;
                    } else {
                        self.index += 1;
                        result.tag = .l_bracket;
                    }
                },
                ']' => {
                    self.index += 1;
                    result.tag = .r_bracket;
                },
                '0' => continue :state .int_zero,
                '1'...'9' => continue :state .int,
                '"' => continue :state .string_literal,
                else => continue :state .illegal,
            },
            .identifier => {
                self.index += 1;

                switch (self.buffer[self.index]) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :state .identifier,
                    else => {
                        const ident = self.buffer[result.loc.start..self.index];

                        result.tag = Token.keywords.get(ident) orelse .identifier;
                    },
                }
            },
            .eq => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .eq_eq;
                    },
                    else => result.tag = .eq,
                }
            },
            .plus => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .plus_eq;
                    },
                    '+' => {
                        self.index += 1;
                        result.tag = .plus_plus;
                    },
                    else => result.tag = .plus,
                }
            },
            .minus => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .minus_eq;
                    },
                    '-' => continue :state .comment,
                    else => result.tag = .minus,
                }
            },
            .asterisk => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .asterisk_eq;
                    },
                    else => result.tag = .asterisk,
                }
            },
            .slash => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .slash_eq;
                    },
                    else => result.tag = .slash,
                }
            },
            .percent => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .percent_eq;
                    },
                    else => result.tag = .percent,
                }
            },
            .caret => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .caret_eq;
                    },
                    else => result.tag = .caret,
                }
            },
            .lt => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .lt_eq;
                    },
                    else => result.tag = .lt,
                }
            },
            .gt => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .gt_eq;
                    },
                    else => result.tag = .gt,
                }
            },
            .bang => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        self.index += 1;
                        result.tag = .not_eq;
                    },
                    else => result.tag = .illegal,
                }
            },
            .dot => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '.' => {
                        self.index += 1;
                        result.tag = .dot_dot;
                    },
                    else => result.tag = .dot,
                }
            },
            .int => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '0'...'9', '_' => continue :state .int,
                    '.' => continue :state .float,
                    'e', 'E' => continue :state .float_exponent,
                    else => result.tag = .num_literal,
                }
            },
            .int_zero => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    'x', 'X' => continue :state .int_hex,
                    'b', 'B' => continue :state .int_bin,
                    'o', 'O' => continue :state .int_oct,
                    '0'...'9', '_' => continue :state .int,
                    '.' => continue :state .float,
                    'e', 'E' => continue :state .float_exponent,
                    else => result.tag = .num_literal,
                }
            },
            .int_hex => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '0'...'9', 'a'...'f', 'A'...'F', '_' => continue :state .int_hex,
                    else => result.tag = .num_literal,
                }
            },
            .int_bin => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '0', '1', '_' => continue :state .int_bin,
                    else => result.tag = .num_literal,
                }
            },
            .int_oct => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '0'...'7', '_' => continue :state .int_oct,
                    else => result.tag = .num_literal,
                }
            },
            .float => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '0'...'9', '_' => continue :state .float,
                    'e', 'E' => continue :state .float_exponent,
                    else => result.tag = .num_literal,
                }
            },
            .float_exponent => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '+', '-' => {
                        self.index += 1;
                        continue :state .float;
                    },
                    '0'...'9', '_' => continue :state .float,
                    else => result.tag = .num_literal,
                }
            },
            .string_literal => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            continue :state .illegal;
                        } else {
                            result.tag = .illegal;
                        }
                    },
                    '\n' => result.tag = .illegal,
                    '\\' => continue :state .string_literal_backslash,
                    '"' => {
                        self.index += 1;
                        result.tag = .string_literal;
                    },
                    0x01...0x09, 0x0b...0x1f, 0x7f => {
                        continue :state .illegal;
                    },
                    else => continue :state .string_literal,
                }
            },
            .string_literal_backslash => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0, '\n' => result.tag = .illegal,
                    else => continue :state .string_literal,
                }
            },
            .multi_string_literal => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            continue :state .illegal;
                        } else {
                            result.tag = .illegal;
                        }
                    },
                    '[' => continue :state .multi_string_literal_bracket,
                    else => {
                        result.tag = .illegal;
                    },
                }
            },
            .multi_string_literal_bracket => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => {
                        if (self.index != self.buffer.len) {
                            continue :state .illegal;
                        } else {
                            result.tag = .illegal;
                        }
                    },
                    ']' => {
                        self.index += 1;
                        if (self.buffer[self.index] == ']') {
                            self.index += 1;
                            result.tag = .multi_string_literal;
                        } else {
                            continue :state .multi_string_literal_bracket;
                        }
                    },
                    else => continue :state .multi_string_literal_bracket,
                }
            },
            .comment => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0, '\n' => {
                        result.tag = .comment;
                    },
                    '[' => continue :state .comment_bracket_open,
                    else => continue :state .comment,
                }
            },
            .comment_bracket_open => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '[' => continue :state .multi_line_comment,
                    0, '\n' => {
                        result.tag = .comment;
                    },
                    else => continue :state .comment,
                }
            },
            .multi_line_comment => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => {
                        result.tag = .illegal;
                    },
                    ']' => continue :state .multi_line_comment_bracket_close,
                    else => continue :state .multi_line_comment,
                }
            },
            .multi_line_comment_bracket_close => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    0 => {
                        result.tag = .illegal;
                    },
                    ']' => {
                        self.index += 1;
                        result.tag = .comment;
                    },
                    else => continue :state .multi_line_comment,
                }
            },
            .illegal => {
                self.index += 1;
                result.tag = .illegal;
            },
        }

        result.loc.end = self.index;
        return result;
    }
};

test "tokenizer - keywords" {
    const source = "local break continue else if or and then end not return false true nil match is while for in function";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .keyword_local,
        .keyword_break,
        .keyword_continue,
        .keyword_else,
        .keyword_if,
        .keyword_or,
        .keyword_and,
        .keyword_then,
        .keyword_end,
        .keyword_not,
        .keyword_return,
        .keyword_false,
        .keyword_true,
        .keyword_nil,
        .keyword_match,
        .keyword_is,
        .keyword_while,
        .keyword_for,
        .keyword_in,
        .keyword_function,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}

test "tokenizer - identifiers" {
    const source = "foo bar_baz _test x1 y2z";
    var tokenizer = Tokenizer.init(source);

    const tokens = [_]struct { tag: Token.Tag, text: []const u8 }{
        .{ .tag = .identifier, .text = "foo" },
        .{ .tag = .identifier, .text = "bar_baz" },
        .{ .tag = .identifier, .text = "_test" },
        .{ .tag = .identifier, .text = "x1" },
        .{ .tag = .identifier, .text = "y2z" },
    };

    for (tokens) |expected| {
        const token = tokenizer.next();
        try std.testing.expectEqual(expected.tag, token.tag);
        try std.testing.expectEqualStrings(expected.text, source[token.loc.start..token.loc.end]);
    }
}

test "tokenizer - punctuation" {
    const source = "(){}[] , : ?";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .l_paren,
        .r_paren,
        .l_brace,
        .r_brace,
        .l_bracket,
        .r_bracket,
        .comma,
        .colon,
        .question_mark,
        .eof,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}

test "tokenizer - operators" {
    const source = "= == != < <= > >= + ++ += - -= / /= * *= ^ ^= % %=";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .eq,
        .eq_eq,
        .not_eq,
        .lt,
        .lt_eq,
        .gt,
        .gt_eq,
        .plus,
        .plus_plus,
        .plus_eq,
        .minus,
        .minus_eq,
        .slash,
        .slash_eq,
        .asterisk,
        .asterisk_eq,
        .caret,
        .caret_eq,
        .percent,
        .percent_eq,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}

test "tokenizer - dot operators" {
    const source = ". ..";
    var tokenizer = Tokenizer.init(source);

    try std.testing.expectEqual(Token.Tag.dot, tokenizer.next().tag);
    try std.testing.expectEqual(Token.Tag.dot_dot, tokenizer.next().tag);
}

test "tokenizer - number literals - integers" {
    const source = "0 1 42 1234567890";
    var tokenizer = Tokenizer.init(source);

    for (0..4) |_| {
        const token = tokenizer.next();
        try std.testing.expectEqual(Token.Tag.num_literal, token.tag);
    }
}

test "tokenizer - number literals - hex" {
    const source = "0x0 0xFF 0xdeadbeef 0xABCD";
    var tokenizer = Tokenizer.init(source);

    for (0..4) |_| {
        const token = tokenizer.next();
        try std.testing.expectEqual(Token.Tag.num_literal, token.tag);
    }
}

test "tokenizer - number literals - binary" {
    const source = "0b0 0b1 0b10101010";
    var tokenizer = Tokenizer.init(source);

    for (0..3) |_| {
        const token = tokenizer.next();
        try std.testing.expectEqual(Token.Tag.num_literal, token.tag);
    }
}

test "tokenizer - number literals - octal" {
    const source = "0o0 0o7 0o777 0o1234567";
    var tokenizer = Tokenizer.init(source);

    for (0..4) |_| {
        const token = tokenizer.next();
        try std.testing.expectEqual(Token.Tag.num_literal, token.tag);
    }
}

test "tokenizer - number literals - underscores" {
    const source = "1_000 0xFF_FF 0b1010_1010 0o777_777";
    var tokenizer = Tokenizer.init(source);

    for (0..4) |_| {
        const token = tokenizer.next();
        try std.testing.expectEqual(Token.Tag.num_literal, token.tag);
    }
}

test "tokenizer - number literals - floats" {
    const source = "0.0 1.0 10.5 0.5 123.456";
    var tokenizer = Tokenizer.init(source);

    for (0..5) |_| {
        const token = tokenizer.next();
        try std.testing.expectEqual(Token.Tag.num_literal, token.tag);
    }
}

test "tokenizer - number literals - floats with exponent" {
    const source = "1e10 1e-10 1e+10 1.0e10 1.0e-10 1.0e+10";
    var tokenizer = Tokenizer.init(source);

    for (0..6) |_| {
        const token = tokenizer.next();
        try std.testing.expectEqual(Token.Tag.num_literal, token.tag);
    }
}

test "tokenizer - number literals - floats with underscores" {
    const source = "1_000.5_5 1.0_0_0 1e1_0";
    var tokenizer = Tokenizer.init(source);

    for (0..3) |_| {
        const token = tokenizer.next();
        try std.testing.expectEqual(Token.Tag.num_literal, token.tag);
    }
}

test "tokenizer - string literal" {
    const source = "\"hello\" \"world\" \"\"";
    var tokenizer = Tokenizer.init(source);

    const tokens = [_]struct { tag: Token.Tag, text: []const u8 }{
        .{ .tag = .string_literal, .text = "\"hello\"" },
        .{ .tag = .string_literal, .text = "\"world\"" },
        .{ .tag = .string_literal, .text = "\"\"" },
    };

    for (tokens) |expected| {
        const token = tokenizer.next();
        try std.testing.expectEqual(expected.tag, token.tag);
        try std.testing.expectEqualStrings(expected.text, source[token.loc.start..token.loc.end]);
    }
}

test "tokenizer - string literal with escapes" {
    const source = "\"hello\\nworld\" \"tab\\there\"";
    var tokenizer = Tokenizer.init(source);

    for (0..2) |_| {
        const token = tokenizer.next();
        try std.testing.expectEqual(Token.Tag.string_literal, token.tag);
    }
}

test "tokenizer - multi-line string literal" {
    const source = "[[hello world]][[multi\nline]]";
    var tokenizer = Tokenizer.init(source);

    for (0..2) |_| {
        const token = tokenizer.next();
        try std.testing.expectEqual(Token.Tag.multi_string_literal, token.tag);
    }
}

test "tokenizer - single line comment" {
    const source = "-- this is a comment\nlocal x";
    var tokenizer = Tokenizer.init(source);

    try std.testing.expectEqual(Token.Tag.comment, tokenizer.next().tag);
    try std.testing.expectEqual(Token.Tag.new_line, tokenizer.next().tag);
    try std.testing.expectEqual(Token.Tag.keyword_local, tokenizer.next().tag);
}

test "tokenizer - multi-line comment" {
    const source = "--[[multi\nline\ncomment]] local x";
    var tokenizer = Tokenizer.init(source);

    try std.testing.expectEqual(Token.Tag.comment, tokenizer.next().tag);
    try std.testing.expectEqual(Token.Tag.keyword_local, tokenizer.next().tag);
}

test "tokenizer - newline" {
    const source = "local\nx";
    var tokenizer = Tokenizer.init(source);

    try std.testing.expectEqual(Token.Tag.keyword_local, tokenizer.next().tag);
    try std.testing.expectEqual(Token.Tag.new_line, tokenizer.next().tag);
    try std.testing.expectEqual(Token.Tag.identifier, tokenizer.next().tag);
}

test "tokenizer - whitespace is skipped" {
    const source = "local   x\t\ty";
    var tokenizer = Tokenizer.init(source);

    try std.testing.expectEqual(Token.Tag.keyword_local, tokenizer.next().tag);
    try std.testing.expectEqual(Token.Tag.identifier, tokenizer.next().tag);
    try std.testing.expectEqual(Token.Tag.identifier, tokenizer.next().tag);
}

test "tokenizer - eof" {
    const source = "";
    var tokenizer = Tokenizer.init(source);

    try std.testing.expectEqual(Token.Tag.eof, tokenizer.next().tag);
}

test "tokenizer - utf-8 BOM is skipped" {
    const source = "\xEF\xBB\xBFlocal x";
    var tokenizer = Tokenizer.init(source);

    try std.testing.expectEqual(Token.Tag.keyword_local, tokenizer.next().tag);
    try std.testing.expectEqual(Token.Tag.identifier, tokenizer.next().tag);
}

test "tokenizer - token locations" {
    const source = "local x = 42";
    var tokenizer = Tokenizer.init(source);

    const token1 = tokenizer.next();
    try std.testing.expectEqual(@as(usize, 0), token1.loc.start);
    try std.testing.expectEqual(@as(usize, 5), token1.loc.end);

    const token2 = tokenizer.next();
    try std.testing.expectEqual(@as(usize, 6), token2.loc.start);
    try std.testing.expectEqual(@as(usize, 7), token2.loc.end);

    const token3 = tokenizer.next();
    try std.testing.expectEqual(@as(usize, 8), token3.loc.start);
    try std.testing.expectEqual(@as(usize, 9), token3.loc.end);

    const token4 = tokenizer.next();
    try std.testing.expectEqual(@as(usize, 10), token4.loc.start);
    try std.testing.expectEqual(@as(usize, 12), token4.loc.end);
}

test "tokenizer - brackets" {
    const source = "arr[0] arr[1 + 2]";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .identifier,
        .l_bracket,
        .num_literal,
        .r_bracket,
        .identifier,
        .l_bracket,
        .num_literal,
        .plus,
        .num_literal,
        .r_bracket,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}

test "tokenizer - complex expression" {
    const source = "local x = 1 + 2 * 3";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .keyword_local,
        .identifier,
        .eq,
        .num_literal,
        .plus,
        .num_literal,
        .asterisk,
        .num_literal,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}

test "tokenizer - function definition" {
    const source = "local function foo() end";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .keyword_local,
        .keyword_function,
        .identifier,
        .l_paren,
        .r_paren,
        .keyword_end,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}

test "tokenizer - control flow" {
    const source = "if x then return x else return y end";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .keyword_if,
        .identifier,
        .keyword_then,
        .keyword_return,
        .identifier,
        .keyword_else,
        .keyword_return,
        .identifier,
        .keyword_end,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}

test "tokenizer - boolean operators" {
    const source = "x and y or z";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .identifier,
        .keyword_and,
        .identifier,
        .keyword_or,
        .identifier,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}

test "tokenizer - comparison operators" {
    const source = "x == y x != y x < y x <= y x > y x >= y";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .identifier,
        .eq_eq,
        .identifier,
        .identifier,
        .not_eq,
        .identifier,
        .identifier,
        .lt,
        .identifier,
        .identifier,
        .lt_eq,
        .identifier,
        .identifier,
        .gt,
        .identifier,
        .identifier,
        .gt_eq,
        .identifier,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}

test "tokenizer - compound assignment operators" {
    const source = "x += 1 x -= 1 x *= 1 x /= 1 x %= 1 x ^= 1";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .identifier,
        .plus_eq,
        .num_literal,
        .identifier,
        .minus_eq,
        .num_literal,
        .identifier,
        .asterisk_eq,
        .num_literal,
        .identifier,
        .slash_eq,
        .num_literal,
        .identifier,
        .percent_eq,
        .num_literal,
        .identifier,
        .caret_eq,
        .num_literal,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}

test "tokenizer - array concat" {
    const source = "x ++ y";
    var tokenizer = Tokenizer.init(source);

    const expected = [_]Token.Tag{
        .identifier,
        .plus_plus,
        .identifier,
    };

    for (expected) |tag| {
        const token = tokenizer.next();
        try std.testing.expectEqual(tag, token.tag);
    }
}
