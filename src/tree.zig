const std = @import("std");

const heap = std.heap;

pub const NodeKind = enum(u8) {
    variable_declaration,
    function_declaration,
    if_statement,
    block_statement,
    expression_statement,
};

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

pub const VariableDeclaration = struct {};

pub const FunctionDeclaration = struct {};

pub const IfStatement = struct {};

pub const BlockStatement = struct {};

pub const ExpressionStatement = struct {};

pub const NodeContent = union(NodeKind) {
    variable_declaration: VariableDeclaration,
    function_declaration: FunctionDeclaration,
    if_statement: IfStatement,
    block_statement: BlockStatement,
    expression_statement: ExpressionStatement,
};

pub const Node = struct {
    content: NodeContent,
};

pub const Tree = struct {
    arena: heap.ArenaAllocator,
    nodes: std.ArrayList(Node),

    pub fn init(allocator: *heap.Allocator) Tree {
        const arena = heap.ArenaAllocator.init(allocator);

        return Tree{
            .arena = arena,
            .nodes = std.ArrayList(Node).init(arena.allocator()),
        };
    }

    pub fn deinit(self: *Tree) void {
        self.arena.deinit();
    }
};
