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

pub const Node = struct {};

pub const Tree = struct {
    nodes: []Node,
};
