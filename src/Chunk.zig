const Chunk = @This();
const std = @import("std");
const Value = @import("values.zig").Value;

entries: std.MultiArrayList(Entry),
constants: std.ArrayListUnmanaged(Value),
allocator: std.mem.Allocator,

pub const Entry = struct {
    code: u8,
    line: usize,
};

pub const OpCode = enum(u8) {
    op_return,
    op_constant,
    _,
};

pub fn init(allocator: std.mem.Allocator) Chunk {
    return Chunk{
        .entries = .empty,
        .constants = .empty,
        .allocator = allocator,
    };
}

pub fn deinit(this: *Chunk) void {
    this.entries.deinit(this.allocator);
    this.constants.deinit(this.allocator);
}

pub fn count(this: Chunk) usize {
    return this.entries.len;
}

pub fn capacity(this: Chunk) usize {
    return this.entries.capacity;
}

pub fn writeByte(this: *Chunk, byte: u8, line: usize) !void {
    try this.entries.append(this.allocator, .{ .code = byte, .line = line });
}

pub fn writeOpCode(this: *Chunk, op_code: OpCode, line: usize) !void {
    try this.writeByte(@intFromEnum(op_code), line);
}

pub fn addConstant(this: *Chunk, value: Value) !usize {
    try this.constants.append(this.allocator, value);
    return this.constants.items.len - 1;
}

pub fn getByte(this: Chunk, index: usize) u8 {
    return this.entries.items(.code)[index];
}

pub fn getOpCode(this: Chunk, index: usize) OpCode {
    return @enumFromInt(this.getByte(index));
}

pub fn getConstant(this: Chunk, index: usize) Value {
    return this.constants.items[index];
}

pub fn getLine(this: Chunk, index: usize) usize {
    return this.entries.items(.line)[index];
}
