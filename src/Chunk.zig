const Chunk = @This();
const std = @import("std");
const Value = @import("values.zig").Value;

code: std.ArrayListUnmanaged(Instruction),
constants: std.ArrayListUnmanaged(Value),
lines: std.ArrayListUnmanaged(u8),
allocator: std.mem.Allocator,

pub const Instruction = packed union {
    operation: OpCode,
    data: u8,

    pub fn format(this: Instruction, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        try std.fmt.formatType(@as(u8, @bitCast(this)), fmt, options, writer, 0);
    }
};

pub const OpCode = enum(u8) {
    op_return,
    op_constant,
    _,
};

pub fn init(allocator: std.mem.Allocator) Chunk {
    var this = Chunk{
        .code = .empty,
        .constants = .empty,
        .lines = .empty,
        .allocator = allocator,
    };

    // the very first entry is reserved (lines start at index 1):
    this.lines.append(this.allocator, 0) catch @panic("OOM");

    return this;
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

pub fn write(this: *Chunk, instruction: Instruction, line: u21) !void {
    try this.code.append(this.allocator, instruction);
    try this.addLine(line);
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

pub fn addLine(this: *Chunk, line: u21) !void {
    var buf: [4]u8 = undefined;
    const len = std.unicode.wtf8Encode(line, &buf) catch {
        var b: [128]u8 = undefined;
        @panic(std.fmt.bufPrint(&b, "Line number {d} cannot be encoded as WTF-8!", .{line}) catch "");
    };
    try this.lines.appendSlice(this.allocator, buf[0..len]);
}

pub fn getLine(this: Chunk, instruction_index: usize) u21 {
    var iter = std.unicode.Wtf8View.initUnchecked(this.lines.items).iterator();

    _ = iter.nextCodepoint(); // skip the very first (reserved) entry.

    var i: usize = 0;
    while (iter.nextCodepoint()) |line| : (i += 1) {
        if (instruction_index == i) return line;
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
