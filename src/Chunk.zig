const std = @import("std");
const memory = @import("./memory.zig");
const Value = @import("./value.zig").Value;
const ValueArray = @import("./ValueArray.zig");

const chunk_allocator = std.heap.page_allocator;

pub const OpCode = enum(u8) {
    op_constant,
    op_return,
    _,
};

count: usize = 0,
capacity: usize = 0,
code: []u8 = &[0]u8{},
lines: []u32 = &[0]u32{},
constants: ValueArray = ValueArray{},

pub fn write(self: *@This(), byte: u8, line: u32) !void {
    if (self.capacity < self.count + 1) {
        const old_capacity = self.capacity;
        self.capacity = memory.growCapacity(usize, old_capacity);
        self.code = try memory.growArray(u8, chunk_allocator, self.code, self.capacity);
        self.lines = try memory.growArray(u32, chunk_allocator, self.lines, self.capacity);
    }

    self.code[self.count] = byte;
    self.lines[self.count] = line;
    self.count += 1;
}

pub fn writeOpCode(self: *@This(), op_code: OpCode, line: u32) !void {
    return try self.write(@intFromEnum(op_code), line);
}

pub fn addConstant(self: *@This(), value: Value) !usize {
    try self.constants.write(value);
    return self.constants.count - 1;
}

pub fn deinit(self: *@This()) void {
    memory.freeArray(u8, chunk_allocator, self.code);
    self.reset();
}

fn reset(self: *@This()) void {
    self.count = 0;
    self.capacity = 0;
    self.code = &[0]u8{};
}
