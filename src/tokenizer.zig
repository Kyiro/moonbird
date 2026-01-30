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
    };
};

pub const Tokenizer = struct {
    buffer: [:0]const u8,
    index: usize,

    pub const TokenizerError = error{EOF};

    pub fn init(buffer: [:0]const u8) Tokenizer {
        return .{
            .buffer = buffer,
            // Skip the UTF-8 BOM if present.
            .index = if (std.mem.startsWith(u8, buffer, "\xEF\xBB\xBF")) 3 else 0,
        };
    }

    const State = enum {
        start,
    };

    pub fn next(self: *Tokenizer) TokenizerError!Token {
        var result: Token = .{
            .tag = undefined,
            .loc = .{
                .start = self.index,
                .end = undefined,
            },
        };

        state: switch (State.start) {
            0 => {
                continue :state .start;
            },
        }

        result.loc.end = self.index;
        return result;
    }
};
