const Chunk = @This();
const std = @import("std");
const Value = @import("values.zig").Value;
const debug = @import("debug.zig");

code: std.ArrayListUnmanaged(Instruction),
constants: std.ArrayListUnmanaged(Value),
lines: std.ArrayListUnmanaged(LineSegment),
current_line: usize,
current_line_segment_start: usize,
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
    amount: u4,
    line_offset: u3,
    continues: bool,

    pub fn of(line_offset: u3, amount: u4) LineSegment {
        return LineSegment{
            .continues = false,
            .line_offset = line_offset,
            .amount = amount,
        };
    }
};

pub fn init(allocator: std.mem.Allocator) Chunk {
    return Chunk{
        .code = .empty,
        .constants = .empty,
        .lines = .empty,
        .current_line = 1,
        .current_line_segment_start = 0,
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
    if (line < this.current_line) return error.LineNumberLowerThanPrevious;

    try this.code.append(this.allocator, instruction);
    if (line == this.current_line) {
        try this.incrementCurrentLine();
    } else {
        try this.addLine(line - this.current_line);
        this.current_line = line;
    }
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

pub fn incrementCurrentLine(this: *Chunk) !void {
    if (this.lines.items.len == 0) try this.lines.append(this.allocator, .of(0, 0));

    var overflow: u1 = 1;
    var i: usize = 0;
    while (overflow == 1 and i < @sizeOf(usize)) : (i += 1) {
        if (this.current_line_segment_start + i >= this.lines.items.len) {
            this.lines.items[this.lines.items.len - 1].continues = true;
            try this.lines.append(this.allocator, .of(0, 0));
        }

        this.lines.items[this.current_line_segment_start + i].amount, overflow = @addWithOverflow(this.lines.items[this.current_line_segment_start + i].amount, overflow);
    }

    if (overflow == 1) {
        try this.addLine(0);
    }
}

pub fn addLine(this: *Chunk, line_offset: usize) !void {
    const required_bits = std.math.log2_int_ceil(usize, line_offset);

    try this.lines.append(this.allocator, .of(@intCast(line_offset & 0b111), 1));
    this.current_line_segment_start = this.lines.items.len - 1;
    var i: std.math.Log2Int(usize) = 3;
    while (i < required_bits) : (i += 3) {
        this.lines.items[this.lines.items.len - 1].continues = true;
        try this.lines.append(this.allocator, .of(@intCast((line_offset & (@as(usize, 0b111) << i)) >> i), 0));
    }
}

pub fn getLine(this: Chunk, instruction_index: usize) usize {
    const lines = this.lines.items;
    var current_line: usize = 1;
    var current_index: usize = 0;
    var i: usize = 0;
    while (i < lines.len) : (i += 1) {
        const start = i;
        while (lines[i].continues) : (i += 1) {
            if (i >= lines.len) @panic("Found continued line segment at the end of lines array!");

            current_line += @as(usize, @intCast(lines[i].line_offset)) << @intCast((i - start) * 3);
            current_index += @as(usize, @intCast(lines[i].amount)) << @intCast((i - start) * 4);
        }
        current_line += @as(usize, @intCast(lines[i].line_offset)) << @intCast((i - start) * 3);
        current_index += @as(usize, @intCast(lines[i].amount)) << @intCast((i - start) * 4);

        if (current_index > instruction_index) return current_line;
    }

    var b: [128]u8 = undefined;
    @panic(std.fmt.bufPrint(&b, "No line information found for instruction number {d}.", .{instruction_index}) catch "");
}

pub fn format(this: Chunk, _: []const u8, _: std.fmt.FormatOptions, writer: anytype) !void {
    try std.fmt.format(
        writer,
        "Chunk{{ .code = {any}, .constants = {any}, .lines = {any}}}",
        .{ this.code.items, this.constants.items, this.lines.items },
    );
}
