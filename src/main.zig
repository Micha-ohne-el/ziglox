const std = @import("std");
const Chunk = @import("Chunk.zig");
const VirtualMachine = @import("VirtualMachine.zig");
const debug = @import("debug.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var chunk: Chunk = .init(allocator);
    defer chunk.deinit();

    var vm: VirtualMachine = .new(&chunk);

    // return -((1.2 + 3.4) / 5.6)

    try chunk.write(.{ .operation = .op_constant }, 123);
    try chunk.write(.{ .data = @intCast(try chunk.addConstant(1.2)) }, 123);

    try chunk.write(.{ .operation = .op_constant }, 123);
    try chunk.write(.{ .data = @intCast(try chunk.addConstant(3.4)) }, 123);

    try chunk.write(.{ .operation = .op_add }, 123);

    try chunk.write(.{ .operation = .op_constant }, 123);
    try chunk.write(.{ .data = @intCast(try chunk.addConstant(5.6)) }, 123);

    try chunk.write(.{ .operation = .op_divide }, 123);

    try chunk.write(.{ .operation = .op_negate }, 123);

    try chunk.write(.{ .operation = .op_return }, 123);

    //debug.disassembleChunk(chunk, "test chunk");

    try vm.run();
}
