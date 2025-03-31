const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const Token = @import("token.zig").Token;

const heap = std.heap;

pub const ExpressionKind = enum(u8) {
    array,
    assignment,
    binary,
    call,
    identifier,
    member,
    method,
    numeric,
    require,
    string,
};

pub const VariableDeclaration = struct {
    pub const Declaration = struct {
        identifier: IdentifierExpression,
        value: ExpressionStatement,
    };

    declarations: std.ArrayList(Declaration),
};

pub const FunctionDeclaration = struct {};

pub const IfStatement = struct {};

pub const BlockStatement = struct {};

pub const ExpressionStatement = struct {};

pub const IdentifierExpression = struct {};

pub const Node = struct {
    pub const Kind = enum(u8) {
        variable_declaration,
        function_declaration,
        if_statement,
        block_statement,
        expression_statement,
    };

    pub const Content = union(Kind) {
        variable_declaration: VariableDeclaration,
        function_declaration: FunctionDeclaration,
        if_statement: IfStatement,
        block_statement: BlockStatement,
        expression_statement: ExpressionStatement,
    };

    content: Content,
    start: usize,
    end: usize,
};

pub const ParseError = error{};

pub const Tree = struct {
    arena: heap.ArenaAllocator,
    nodes: std.ArrayList(Node),
    tokenizer: *Tokenizer,

    pub fn init(allocator: *heap.Allocator, tokenizer: *Tokenizer) Tree {
        const arena = heap.ArenaAllocator.init(allocator);

        return Tree{
            .arena = arena,
            .nodes = std.ArrayList(Node).init(arena.allocator()),
            .tokenizer = tokenizer,
        };
    }

    pub fn deinit(self: *Tree) void {
        self.arena.deinit();
    }

    fn process(self: *Tree) !Node {
        const token = self.tokenizer.nextToken() catch |err| return err;

        if (token.id == .local_keyword) {}
    }

    pub fn parseSource(self: *Tree) !void {
        while (true) {
            self.process() catch |err| return err;
        }
    }
};
