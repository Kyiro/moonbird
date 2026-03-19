const Parser = @import("moonbird").Parser;
const Token = @import("moonbird").Token;

pub const PrefixParselet = struct {
    ptr: *const anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        parse: *const fn (*const anyopaque, parser: *Parser, token: *Token) void,
    };

    pub fn parse(self: PrefixParselet, parser: *Parser, token: Token) void {
        return self.vtable.parse(self.ptr, parser, token);
    }
};

pub const InfixParselet = struct {
    ptr: *const anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        parse: *const fn (*const anyopaque, parser: *Parser, left: *Token, token: *Token) void,
        precedence: *const fn (*const anyopaque) u16,
    };

    pub fn parse(self: PrefixParselet, parser: *Parser, token: Token) void {
        return self.vtable.parse(self.ptr, parser, token);
    }

    pub fn precedence(self: InfixParselet) u8 {
        return self.vtable.precedence(self.ptr);
    }
};
