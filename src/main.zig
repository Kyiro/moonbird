const std = @import("std");
const Tokenizer = @import("moonbird").Tokenizer;

pub fn main() void {
    var tokenizer = Tokenizer.init(
        \\-- this is a comment
        \\--[[
        \\  this is a comment as well
        \\  with multiple lines
        \\]]
        \\
        \\-- variables
        \\local name: String = "Wiktor"
        \\local age: i32 = 67
        \\local isRetarded: bool = true
        \\local nothing: i32? = nil
        \\local table: Dictionary(string, i32) = { a = 2 }
        \\local list: List(i32) = { 1, 2, 3 }
        \\
        \\-- operators
        \\local sum = age + 20 -- 87
        \\local concat = "Your name is " ++ name -- "Your name is Wiktor"
        \\local concat2 = list ++ { 4, 5, 6 } -- { 1, 2, 3, 4, 5, 6 }
        \\local x = nothing or else 10 -- 10
        \\local y =
        \\  if age == 67 then "You're 67 years old."
        \\  else if age == 69 then "You're 68 years old."
        \\  else "I don't care."
        \\
        \\-- pattern matching (inspired by c#)
        \\local a = match x
        \\  if 10 then "The number is 10"
        \\  if >10 then "The number is bigger than 10"
        \\  if 2..8 then "The number is between 2 and 8"
        \\end
        \\local b = if x is not nil and >10 then "The number isn't nil and above 10"
    );

    while (true) {
        const token = tokenizer.next();

        if (token.tag == .eof) break;

        std.debug.print("{s}\n", .{@tagName(token.tag)});
    }
}
