const std = @import("std");
const lib = @import("moonbird");

pub fn main() !void {
    const variable_example =
        // \\local x = 2 + 2
        // \\
        // \\if x == 4 then
        // \\    print("x is 4")
        // \\end
        \\2+2
    ;

    std.debug.print("{s}\n", .{variable_example});

    var tokenizer = lib.Tokenizer.init(variable_example, variable_example.len);

    var val = try lib.Tokenizer.next(&tokenizer);

    while (true) {
        std.debug.print("{s} - {s}\n", .{ @tagName(val.id), variable_example[val.start..val.end] });

        val = lib.Tokenizer.next(&tokenizer) catch |err| {
            std.debug.print("ERROR: {s}\n", .{@errorName(err)});

            break;
        };
    }
}
