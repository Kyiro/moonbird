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

    pub fn init(allocator: std.mem.Allocator, tokenizer: *Tokenizer) Parser {
        var self = Parser{
            .allocator = allocator,
            .current_token = undefined,
            .tokenizer = tokenizer,
        };

        self.advance();

        return self;
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
};
