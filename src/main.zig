const std = @import("std");
const Tokenizer = @import("moonbird").Tokenizer;

pub fn main() void {
    var tokenizer = Tokenizer.init(
        \\local x =
        \\print(hello)
        \\if not x then
        \\end
    );

    while (true) {
        const token = tokenizer.next();

        if (token.tag == .eof) break;

        std.debug.print("{s}\n", .{@tagName(token.tag)});
    }
}
