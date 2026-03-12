const Tokenizer = @import("moonbird").Tokenizer;

pub const Parser = struct {
    tokenizer: *Tokenizer,

    pub fn init(tokenizer: *Tokenizer) Parser {
        return Parser{
            .tokenizer = tokenizer,
        };
    }

    pub fn parseExpression(self: *Parser) void {
        _ = self;
    }
};
