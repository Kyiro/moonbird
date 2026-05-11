const std = @import("std");
const expression = @import("expression.zig");
const tokenizer_mod = @import("tokenizer.zig");
const parselets = @import("parselet.zig");

const PrefixParselet = parselets.PrefixParselet;
const InfixParselet = parselets.InfixParselet;
const Tokenizer = tokenizer_mod.Tokenizer;
const Token = tokenizer_mod.Token;
const Expression = expression.Expression;

pub const ParserError = error{
    UnexpectedToken,
    MissingPrefixParselet,
    MissingInfixParselet,
};

pub const Parser = struct {
    allocator: std.mem.Allocator,
    current_token: Token,
    tokenizer: *Tokenizer,

    // arrays of the parselets for each token, O(1) lookup time!
    infix_parselets: [Token.count]?InfixParselet = .{null} ** Token.count,
    prefix_parselets: [Token.count]?PrefixParselet = .{null} ** Token.count,

    pub fn init(allocator: std.mem.Allocator, tokenizer: *Tokenizer) Parser {
        var self = Parser{
            .allocator = allocator,
            .current_token = undefined,
            .tokenizer = tokenizer,
        };

        self.advance();

        return self;
    }

    pub fn parse(self: *Parser, precedence: u8) ParserError!void {
        const token = self.current_token;
        self.advance();

        const prefix_opt = self.prefix_parselets[@intFromEnum(token.tag)];
        var left = if (prefix_opt) |prefix_parser| {
            try prefix_parser.parse(self, token);
        } else return error.MissingPrefixParselet;

        while (precedence < self.getPrecedence()) {
            const infix_token = self.current_token;
            self.advance();

            const infix_opt = self.infix_parselets[@intFromEnum(infix_token.tag)];
            if (infix_opt) |infix_parser| {
                left = try infix_parser.parse(self, left, infix_token);
            } else return error.MissingInfixParselet;
        }

        return left;
    }

    pub fn consume(self: *Parser, expected: Token.Tag) ParserError!void {
        if (self.current_token.tag != expected) return ParserError.UnexpectedToken;
        self.advance();
    }

    pub fn advance(self: *Parser) void {
        // loop until we find a token that is useful
        while (true) {
            self.current_token = self.tokenizer.next();
            switch (self.current_token.tag) {
                .new_line, .comment => continue,
                else => break,
            }
        }
    }

    pub fn getPrecedence(self: *Parser) u8 {
        if (self.current_token.tag == .eof) return 0;
        if (self.infix_parselets[@intFromEnum(self.current_token.tag)]) |infix| {
            return infix.precedence();
        }
        return 0;
    }
};
