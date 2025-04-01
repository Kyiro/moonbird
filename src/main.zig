const std = @import("std");
const lib = @import("moonbird");

pub fn main() !void {
    const variable_example =
        // \\local x = 2 + 2 -- adds 2 and 2
        // \\
        // \\if x == 4 then
        // \\    print("x is 4") -- x is 4 indeed
        // \\end
        \\local x =
    ;

    std.debug.print("{s}\n", .{variable_example});

    var tokenizer = lib.Tokenizer.init(variable_example, variable_example.len);
    var tree = lib.Tree.init(std.heap.page_allocator, &tokenizer);

    tree.parseSource() catch |err| std.debug.print("Error: {s}\n", .{@errorName(err)});
}
