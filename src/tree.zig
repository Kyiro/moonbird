const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const Token = @import("token.zig").Token;

const heap = std.heap;

pub const VariableDeclaration = struct {
    pub const Declaration = struct {
        identifier: NodeOf(IdentifierExpression),
        value: NodeOf(ExpressionStatement),
    };

    declarations: std.ArrayList(Declaration),
};

pub const FunctionDeclaration = struct {
    identifier: NodeOf(IdentifierExpression),
    body: BlockStatement,
};

pub const IfStatement = struct {
    testing: ExpressionNode,
};

pub const BlockStatement = struct {
    body: std.ArrayList(Node),
};

pub const ExpressionStatement = struct {
    expression: ExpressionNode,
};

pub const IdentifierExpression = struct {
    name: []const u8,
};

pub const NodeKind = enum(u8) {
    variable_declaration,
    function_declaration,
    if_statement,
    block_statement,
    expression_statement,
};

pub const NodeContent = union(NodeKind) {
    variable_declaration: VariableDeclaration,
    function_declaration: FunctionDeclaration,
    if_statement: IfStatement,
    block_statement: BlockStatement,
    expression_statement: ExpressionStatement,
};

pub const Node = NodeOf(NodeContent);

pub fn NodeOf(comptime T: type) type {
    return struct {
        start: usize,
        end: usize,
        content: T,
    };
}

pub const ExpressionNode = NodeOf(Expression);

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

pub const ArrayExpression = struct {
    body: std.ArrayList(Expression),
};

pub const AssignmentExpression = struct {
    // left:
};

pub const Expression = union(ExpressionKind) {
    array: ArrayExpression,
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

    // pub fn processVariableDeclaration(self: *Tree) !Node {

    // }

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
