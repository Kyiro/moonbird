const Parser = @import("parser.zig").Parser;
const Token = @import("tokenizer.zig").Token;
const Expression = @import("expression.zig").Expression;
const ParserError = @import("parser.zig").ParserError;

pub const PrefixParselet = struct {
    ptr: *const anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        parse: *const fn (*const anyopaque, parser: *Parser, token: Token) ParserError!Expression,
    };

    pub fn parse(self: PrefixParselet, parser: *Parser, token: Token) ParserError!Expression {
        return self.vtable.parse(self.ptr, parser, token);
    }
};

pub const InfixParselet = struct {
    ptr: *const anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        parse: *const fn (*const anyopaque, parser: *Parser, left: *Expression, token: Token) ParserError!Expression,
        precedence: *const fn (*const anyopaque) u8,
    };

    pub fn parse(self: InfixParselet, parser: *Parser, left: *Expression, token: Token) ParserError!Expression {
        return self.vtable.parse(self.ptr, parser, left, token);
    }

    pub fn precedence(self: InfixParselet) u8 {
        return self.vtable.precedence(self.ptr);
    }
};
