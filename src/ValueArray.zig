const std = @import("std");
const memory = @import("./memory.zig");
const Value = @import("./value.zig").Value;

const value_array_allocator = std.heap.page_allocator;

capacity: usize = 0,
count: usize = 0,
values: []Value = &[0]Value{},

pub fn write(self: *@This(), value: Value) !void {
    if (self.capacity < self.count + 1) {
        const old_capacity = self.capacity;
        self.capacity = memory.growCapacity(usize, old_capacity);
        self.values = try memory.growArray(Value, value_array_allocator, self.values, self.capacity);
    }

    self.values[self.count] = value;
    self.count += 1;
}

pub fn deinit(self: *@This()) void {
    memory.freeArray(Value, value_array_allocator, self.values);
    self.reset();
}

fn reset(self: *@This()) void {
    self.count = 0;
    self.capacity = 0;
    self.code = &[0]Value{};
}
