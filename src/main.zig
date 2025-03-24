const std = @import("std");
const lib = @import("moonbird");

pub fn main() !void {
    const variable_example = "local kurwa_mać = 2 + 2";

    std.debug.print("{s}\n", .{variable_example});

    var tokenizer = lib.Tokenizer.init(variable_example, variable_example.len);

    while (lib.Tokenizer.next(&tokenizer)) |val| {
        std.debug.print("{s} - {s}\n", .{ @tagName(val.id), variable_example[val.start..val.end] });
    }
}
