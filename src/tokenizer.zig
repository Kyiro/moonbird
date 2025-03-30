const std = @import("std");
const Token = @import("token.zig").Token;

const ascii = std.ascii;
const mem = std.mem;

fn isValidIdentifierChar(char: u8) bool {
    return switch (char) {
        'A'...'Z', 'a'...'z', '0'...'9', '$', '_' => true,
        else => false,
    };
}

pub const Tokenizer = struct {
    source: []const u8,
    length: usize,
    index: usize,

    pub const TokenizerError = error{ InvalidIdentifier, InvalidOperator, EOF };

    pub fn init(source: []const u8, length: usize) Tokenizer {
        return Tokenizer{ .source = source, .length = length, .index = 0 };
    }

    fn skipWhitespace(self: *Tokenizer) ?Token {
        while (self.peek()) |char| {
            if (!ascii.isWhitespace(char)) break;

            if (char == '\n') {
                self.index += 1;
                return Token{ .id = .new_line, .start = self.index - 1, .end = self.index };
            }

            self.index += 1;
        }

        return null;
    }

    fn peekAhead(self: *Tokenizer, offset: usize) ?u8 {
        if (self.index + offset >= self.source.len) return null;
        return self.source[self.index + offset];
    }

    fn peekBehind(self: *Tokenizer, offset: usize) ?u8 {
        if (self.index - offset >= self.source.len) return null;
        return self.source[self.index - offset];
    }

    fn peek(self: *Tokenizer) ?u8 {
        if (self.index >= self.length) return null;
        return self.source[self.index];
    }

    fn pop(self: *Tokenizer) ?u8 {
        self.index += 1;
        return self.peekBehind(1);
    }

    pub fn parseNumberLiteral(self: *Tokenizer) !Token {
        const start = self.index;

        while (self.peek()) |char| {
            if (!ascii.isDigit(char)) break;

            self.index += 1;
        }

        return Token{ .id = .num_literal, .start = start, .end = self.index };
    }

    pub fn parseIdentifierOrKeyword(self: *Tokenizer) !Token {
        const start = self.index;

        while (self.peek()) |char| {
            if (!isValidIdentifierChar(char)) break;

            self.index += 1;
        }

        var token = Token{ .id = .identifier, .start = start, .end = self.index };

        const identifier = self.source[token.start..token.end];

        if (Token.keywords.get(identifier)) |keyword| {
            token.id = keyword;
        }

        return token;
    }

    pub fn parseStringLiteral(self: *Tokenizer) !Token {
        const start = self.index;

        self.index += 1;
        var isEscaped = false;

        while (self.pop()) |char| {
            if (!isEscaped and char == '"') break;

            if (char == '\\') {
                isEscaped = true;
            }
        }

        return Token{ .id = .string_literal, .start = start, .end = self.index };
    }

    pub fn parseComment(self: *Tokenizer) !Token {
        const start = self.index;

        self.index += 2; // we can skip the '--' characters

        while (self.peek() != '\n') {
            self.index += 1;
        }

        return Token{ .id = .comment, .start = start, .end = self.index };
    }

    pub fn next(self: *Tokenizer) !Token {
        if (self.skipWhitespace()) |val| return val;

        const startChar = self.peek() orelse return TokenizerError.EOF;

        if (ascii.isDigit(startChar))
            return self.parseNumberLiteral();

        // we don't need to check for variables starting with numbers here
        // as they're checked above
        if (isValidIdentifierChar(startChar))
            return self.parseIdentifierOrKeyword();

        if (startChar == '"')
            return self.parseStringLiteral();

        if (startChar == '-' and self.peekAhead(1) == '-')
            return self.parseComment();

        for (Token.operatorKeys) |key| {
            if (self.index + key.len > self.source.len) continue;

            const operator = self.source[self.index .. self.index + key.len];

            if (mem.eql(u8, operator, key)) {
                if (Token.operators.get(key)) |id| {
                    const token = Token{
                        .id = id,
                        .start = self.index,
                        .end = self.index + key.len,
                    };

                    self.index += key.len;

                    return token;
                }
            }
        }

        self.index += 1;

        return Token{ .id = .illegal, .start = self.index - 1, .end = self.index };
    }
};
