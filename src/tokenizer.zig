const std = @import("std");
const Token = @import("token.zig").Token;

const ascii = std.ascii;

fn isValidIdentifierChar(char: u8) bool {
    return switch (char) {
        'A'...'Z', 'a'...'z', '0'...'9', '$', '_' => true,
        else => false,
    };
}

pub const Tokenizer = struct {
    source: []const u8,
    length: usize,
    index: u32,

    pub fn init(source: []const u8, length: usize) Tokenizer {
        return Tokenizer{ .source = source, .length = length, .index = 0 };
    }

    fn skipWhitespace(self: *Tokenizer) void {
        while (!isEOF(self) and ascii.isWhitespace(self.source[self.index])) {
            self.index += 1;
        }
    }

    fn isEOF(self: *Tokenizer) bool {
        return self.index >= self.length;
    }

    pub fn next(self: *Tokenizer) ?Token {
        self.skipWhitespace();

        if (self.isEOF()) return null;

        var token = Token{ .id = .illegal, .start = self.index, .end = self.index };
        const startChar = self.source[self.index];

        if (ascii.isDigit(startChar)) {
            while (!self.isEOF() and ascii.isDigit(self.source[self.index])) {
                self.index += 1;
            }

            token.id = .int_literal;
            token.end = self.index;

            return token;
        }

        // we don't need to check for variables starting with numbers here
        // as they're checked above
        if (isValidIdentifierChar(startChar)) {
            while (!self.isEOF() and isValidIdentifierChar(self.source[self.index])) {
                self.index += 1;
            }

            token.end = self.index;

            const identifier = self.source[token.start..token.end];

            if (Token.keywords.get(identifier)) |keyword| {
                token.id = keyword;
            } else {
                token.id = .identifier;
            }

            return token;
        }

        switch (self.source[self.index]) {
            '+' => {
                token.id = .plus;
                self.index += 1;
                token.end = self.index;

                return token;
            },
            '=' => {
                if (!self.isEOF() and self.source[self.index + 1] == '=') {
                    token.id = .eq_eq;
                    self.index += 1;
                    token.end = self.index;
                    
                    return 
                }

                token.id = .eq;
                self.index += 1;
                token.end = self.index;

                return token;
            },
            else => return null,
        }
    }
};
