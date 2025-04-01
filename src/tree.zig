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

        pub fn init(token: *const Token, content: T) NodeOf(T) {
            return .{
                .start = token.start,
                .end = token.end,
                .content = content,
            };
        }
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
    assignment: AssignmentExpression,
    binary: struct {},
    call: struct {},
    identifier: struct {},
    member: struct {},
    method: struct {},
    numeric: struct {},
    require: struct {},
    string: struct {},
};

pub const ParseError = error{};

pub const Tree = struct {
    arena: heap.ArenaAllocator,
    allocator: std.mem.Allocator,
    nodes: std.ArrayList(Node),
    tokenizer: *Tokenizer,

    pub fn init(allocator: std.mem.Allocator, tokenizer: *Tokenizer) Tree {
        var arena = heap.ArenaAllocator.init(allocator);
        const arenaAlloc = arena.allocator();

        return Tree{
            .arena = arena,
            .allocator = arenaAlloc,
            .nodes = std.ArrayList(Node).init(arenaAlloc),
            .tokenizer = tokenizer,
        };
    }

    pub fn deinit(self: *Tree) void {
        self.arena.deinit();
    }

    pub fn processVariableDeclaration(self: *Tree) !void {
        const allocator = self.arena.allocator();

        var left = std.ArrayList(NodeOf(IdentifierExpression)).init(allocator);

        while (true) {
            const token = try self.tokenizer.nextToken();

            std.debug.print("token: {s}\n", .{@tagName(token.id)});

            if (token.id == .eq) {
                break;
            } else if (token.id == .identifier) {
                try left.append(NodeOf(IdentifierExpression).init(&token, .{
                    .name = self.tokenizer.readToString(&token),
                }));

                continue;
            }

            try token.expect(.comma);
        }
    }

    fn process(self: *Tree) !void {
        const token = try self.tokenizer.nextToken();

        if (token.id == .local_keyword)
            return try self.processVariableDeclaration();

        return Tokenizer.TokenizerError.EOF;
    }

    pub fn parseSource(self: *Tree) !void {
        while (true) {
            try self.process();
        }
    }
};
