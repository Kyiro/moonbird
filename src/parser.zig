const std = @import("std");
const moonbird = @import("moonbird");

const PrefixParselet = moonbird.PrefixParselet;
const InfixParselet = moonbird.InfixParselet;
const Tokenizer = moonbird.Tokenizer;
const Token = moonbird.Token;

pub const Parser = struct {
    allocator: std.mem.Allocator,
    current_token: Token,
    tokenizer: *Tokenizer,

    // arrays of the parselets for each token, O(1) lookup time!
    infix_parselets: [Token.Tag.count]?InfixParselet = .{null} ** Token.Tag.count,
    prefix_parselets: [Token.Tag.count]?PrefixParselet = .{null} ** Token.Tag.count,

    const ParserError = error{
        UnexpectedToken,
        MissingPrefixParselet,
        MissingInfixParselet,
    };

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

        const prefix_parser = try self.prefix_parselets[@intFromEnum(token.tag)] orelse ParserError.MissingPrefixParselet;

        var left = try prefix_parser.parse(self, token);

        while (precedence < self.getPrecedence()) {
            const infix_token = self.current_token;
            self.advance();

            const infix_parser = try self.infix_parselets[@intFromEnum(infix_token.tag)] orelse ParserError.MissingInfixParselet;

            left = try infix_parser.parse(self, left, infix_token);
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
