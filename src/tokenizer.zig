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
                        continue :state .illegal;
                    }
                },
                ']' => continue :state .illegal,
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
                    '.' => {
                        if (self.buffer[self.index + 1] == '.') {
                            result.tag = .num_literal;
                        } else {
                            result.tag = .num_literal;
                        }
                    },
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
                    '.' => {
                        if (self.buffer[self.index + 1] == '.') {
                            result.tag = .num_literal;
                        } else {
                            result.tag = .num_literal;
                        }
                    },
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
