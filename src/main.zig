const std = @import("std");
const Chunk = @import("Chunk.zig");
const debug = @import("debug.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var chunk: Chunk = .init(allocator);
    defer chunk.deinit();

    try chunk.writeOpCode(.op_constant, 123);
    try chunk.writeByte(@intCast(try chunk.addConstant(.{ .float = 1.2 })), 123);

    try chunk.writeOpCode(.op_return, 123);

    debug.disassembleChunk(chunk, "test chunk");
}
