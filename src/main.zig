const std = @import("std");
const Chunk = @import("Chunk.zig");
const debug = @import("./debug.zig");
const OpCode = Chunk.OpCode;

pub fn main() !void {
    var chunk = Chunk{};
    defer chunk.deinit();

    const constant = try chunk.addConstant(123.456);
    try chunk.writeOpCode(OpCode.op_constant, 123);
    try chunk.write(@truncate(constant), 123);

    try chunk.writeOpCode(OpCode.op_return, 123);

    debug.disassembleChunk(chunk, "test chunk");
}
