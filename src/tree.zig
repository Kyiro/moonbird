const std = @import("std");
const pretty = @import("pretty.zig");
const Tokenizer = @import("tokenizer.zig").Tokenizer;
const Token = @import("token.zig").Token;

const heap = std.heap;

pub const VariableDeclaration = struct {
    pub const Declaration = struct {
        identifier: NodeOf(IdentifierExpression),
        value: ExpressionNode,
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

        pub fn init(start: usize, end: usize, content: T) NodeOf(T) {
            return .{
                .start = start,
                .end = end,
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

pub const NumericExpression = struct {
    number: u64,
};

pub const Expression = union(ExpressionKind) {
    array: ArrayExpression,
    assignment: AssignmentExpression,
    binary: struct {},
    call: struct {},
    identifier: struct {},
    member: struct {},
    method: struct {},
    numeric: NumericExpression,
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

    // CURRENTLY ONLY PARSES A SINGLE TOKEN
    pub fn parseExpression(self: *Tree, token: *const Token) !ExpressionNode {
        const string = self.tokenizer.readToString(token);
        const number = try std.fmt.parseInt(u64, string, 10);

        return ExpressionNode.init(token.start, token.end, .{
            .numeric = .{
                .number = number,
            },
        });
    }

    pub fn processVariableDeclaration(self: *Tree) !void {
        const start = self.tokenizer.index;

        var left = std.ArrayList(NodeOf(IdentifierExpression)).init(std.heap.page_allocator);
        var right = std.ArrayList(ExpressionNode).init(std.heap.page_allocator);

        defer left.deinit();
        defer right.deinit();

        while (true) {
            const token = try self.tokenizer.nextToken();

            if (token.id == .eq) break;

            if (token.id == .identifier) {
                try left.append(NodeOf(IdentifierExpression).init(token.start, token.end, .{
                    .name = self.tokenizer.readToString(&token),
                }));

                std.debug.print("left.\n", .{});

                continue;
            }

            try token.expect(.comma);
        }

        while (true) {
            const token = try self.tokenizer.nextToken();

            if (token.id == .new_line) break;

            std.debug.print("right: {s}\n", .{@tagName(token.id)});

            try right.append(try self.parseExpression(&token));
        }

        const end = self.tokenizer.index;

        var declarations = std.ArrayList(VariableDeclaration.Declaration).init(self.allocator);

        try declarations.append(.{ .identifier = left.items[0], .value = right.items[0] });

        const node = Node.init(start, end, .{
            .variable_declaration = .{ .declarations = declarations },
        });

        try pretty.print(std.heap.page_allocator, node, .{});

        try self.nodes.append(node);
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
