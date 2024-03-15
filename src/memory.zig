const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn growCapacity(comptime T: type, capacity: T) T {
    return if (capacity < 8) 8 else capacity * 2;
}

pub fn growArray(comptime T: type, allocator: Allocator, array: []T, new_count: usize) ![]T {
    return try allocator.realloc(array, new_count);
}

pub fn freeArray(comptime T: type, allocator: Allocator, array: []T) void {
    allocator.free(array);
}
