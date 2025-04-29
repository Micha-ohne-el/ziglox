const Chunk = @This();
const std = @import("std");
const Value = @import("values.zig").Value;
const debug = @import("debug.zig");
const util = @import("util.zig");

code: std.ArrayListUnmanaged(Instruction),
constants: std.ArrayListUnmanaged(Value),
lines: std.ArrayListUnmanaged(LineSegment),
current_line: usize,
allocator: std.mem.Allocator,

pub const Instruction = packed union {
    operation: OpCode,
    data: u8,
};

pub const OpCode = enum(u8) {
    op_return,
    op_constant,
    op_add,
    op_subtract,
    op_multiply,
    op_divide,
    op_negate,
    _,
};

pub const LineSegment = packed struct {
    amount: u8,
    offset: i8,

    pub fn format(this: LineSegment, _: []const u8, comptime options: std.fmt.FormatOptions, writer: anytype) !void {
        var b: [@max(8, options.width)]u8 = undefined;
        if (this.offset < 0) {
            try std.fmt.formatBuf(try std.fmt.bufPrint(&b, "{d}×{d}", .{ this.offset, this.amount }), options, writer);
        } else {
            try std.fmt.formatBuf(try std.fmt.bufPrint(&b, "+{d}×{d}", .{ this.offset, this.amount }), options, writer);
        }
    }
};

pub fn init(allocator: std.mem.Allocator) Chunk {
    return Chunk{
        .code = .empty,
        .constants = .empty,
        .lines = .empty,
        .current_line = 1,
        .allocator = allocator,
    };
}

pub fn deinit(this: *Chunk) void {
    this.code.deinit(this.allocator);
    this.constants.deinit(this.allocator);
    this.lines.deinit(this.allocator);
}

pub fn count(this: Chunk) usize {
    return this.code.items.len;
}

pub fn capacity(this: Chunk) usize {
    return this.code.capacity;
}

pub fn write(this: *Chunk, instruction: Instruction, line: usize) !void {
    if (line == 0) return error.InvalidLine;

    try this.code.append(this.allocator, instruction);
    errdefer _ = this.code.pop();

    if (line != this.current_line or this.lines.items.len == 0) {
        try this.addNewLineSegment(util.i(line) - util.i(this.current_line));
    }

    try this.incrementCurrentLineSegment();
}

pub fn read(this: Chunk, index: usize) Instruction {
    return this.code.items[index];
}

pub fn addConstant(this: *Chunk, value: Value) !usize {
    try this.constants.append(this.allocator, value);
    return this.constants.items.len - 1;
}

pub fn getConstant(this: Chunk, index: usize) Value {
    return this.constants.items[index];
}

pub fn getLine(this: Chunk, instruction_index: usize) usize {
    var line: usize = 1;
    var index: usize = 0;

    for (this.lines.items) |segment| {
        line = util.u(util.i(line) + segment.offset);
        index += segment.amount;

        if (index > instruction_index) return line;
    }

    var b: [128]u8 = undefined;
    @panic(std.fmt.bufPrint(
        &b,
        "No line information found for instruction #{d}. Final index is {d} at line {d}.",
        .{ instruction_index, index, line },
    ) catch "No line information found for an instruction (formatting error message failed).");
}

/// asserts that `this.lines` is not empty.
fn incrementCurrentLineSegment(this: *Chunk) !void {
    const lines = this.lines.items;

    if (lines[lines.len - 1].amount == 0xFF) {
        try this.lines.append(this.allocator, .{ .amount = 1, .offset = 0 });
    } else {
        lines[lines.len - 1].amount += 1;
    }
}

fn addNewLineSegment(this: *Chunk, line_offset: isize) !void {
    if (util.i(this.current_line) + line_offset <= 0) return error.InvalidLineOffset;

    var offset = line_offset;
    if (offset > 0) {
        while (offset > 0) : (offset -= 0x7F) {
            try this.lines.append(this.allocator, .{ .amount = 0, .offset = @intCast(@min(offset, 0x7F)) });
        }
    } else if (offset < 0) {
        while (offset < 0) : (offset += 0x80) {
            try this.lines.append(this.allocator, .{ .amount = 0, .offset = @intCast(@max(offset, -0x80)) });
        }
    } else {
        try this.lines.append(this.allocator, .{ .amount = 0, .offset = 0 });
    }
    this.current_line = util.u(util.i(this.current_line) + line_offset);
}

pub fn format(this: Chunk, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    try std.fmt.format(
        writer,
        "Chunk{{ .code = {any}, .constants = {any}, .lines = {any}}}",
        .{ this.code.items, this.constants.items, this.lines.items },
    );
}
