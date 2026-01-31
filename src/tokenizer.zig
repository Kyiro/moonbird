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
        .{ "null", Tag.keyword_null },
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
        keyword_null,

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

        string_literal, // e.g. "Hello, World"
        multi_string_literal, // e.g. [[Hello, World!]]
        num_literal, // number literal
        regex_literal, // regex literal (e.g. /^dog/i)
        new_line,
        comment, // '--' (e.g. '-- This is a comment')
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
        eq,
        percent,
        asterisk,
        plus,
        lt,
        gt,
        caret,
        dot,
        minus,
        slash,
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
                    result.tag = .new_line;
                    self.index += 1;
                },
                'a'...'z', 'A'...'Z', '_' => continue :state .identifier,
                '(' => {
                    result.tag = .l_paren;
                    self.index += 1;
                },
                ')' => {
                    result.tag = .r_paren;
                    self.index += 1;
                },
                '{' => {
                    result.tag = .l_brace;
                    self.index += 1;
                },
                '}' => {
                    result.tag = .r_brace;
                    self.index += 1;
                },
                '=' => continue :state .eq,
                // '%' => continue :state .percent,
                // '*' => continue :state .asterisk,
                // '+' => continue :state .plus,
                // '<' => continue :state .lt,
                // '>' => continue :state .gt,
                // '^' => continue :state .caret,
                // '.' => continue :state .dot,
                // '-' => continue :state .minus,
                // '/' => continue :state .slash,
                // '0'...'9' => {
                //     result.tag = .number_literal;
                //     self.index += 1;
                //     continue :state .int;
                // },
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
                        result.tag = .eq_eq;
                        self.index += 1;
                    },
                    else => result.tag = .eq,
                }
            },
            .plus => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        result.tag = .plus_eq;
                        self.index += 1;
                    },
                    else => result.tag = .plus,
                }
            },
            .minus => {
                self.index += 1;
                switch (self.buffer[self.index]) {
                    '=' => {
                        result.tag = .minus_eq;
                        self.index += 1;
                    },
                    else => result.tag = .minus,
                }
            },
            .illegal => {
                self.index += 1;

                switch (self.buffer[self.index]) {
                    0 => if (self.index == self.buffer.len) {
                        result.tag = .illegal;
                    } else {
                        continue :state .illegal;
                    },
                    '\n' => result.tag = .illegal,
                    else => continue :state .illegal,
                }
            },
            else => continue :state .illegal,
        }

        result.loc.end = self.index;
        return result;
    }
};
