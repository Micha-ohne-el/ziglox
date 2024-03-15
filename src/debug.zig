const std = @import("std");
const Chunk = @import("./Chunk.zig");
const Value = @import("./value.zig").Value;
const OpCode = Chunk.OpCode;

pub fn disassembleChunk(chunk: Chunk, name: []const u8) void {
    std.debug.print("== {s:0>4} ==\n", .{name});

    std.debug.print("inst line             name info\n", .{});

    var offset: usize = 0;
    while (offset < chunk.count) {
        offset = disassembleInstruction(chunk, offset);
    }
}

fn disassembleInstruction(chunk: Chunk, offset: usize) usize {
    std.debug.print("{:0>4} ", .{offset});

    if (offset > 0 and chunk.lines[offset] == chunk.lines[offset - 1]) {
        std.debug.print("   | ", .{});
    } else {
        std.debug.print("{:0>4} ", .{chunk.lines[offset]});
    }

    const op_code: OpCode = @enumFromInt(chunk.code[offset]);

    switch (op_code) {
        .op_constant => return constantInstruction("op_constant", chunk, offset),
        .op_return => return simpleInstruction("op_return", offset),
        _ => {
            std.debug.print("Unknown opcode '{}'.\n", .{@intFromEnum(op_code)});
            return offset + 1;
        },
    }
}

fn constantInstruction(name: []const u8, chunk: Chunk, offset: usize) usize {
    const constant = chunk.code[offset + 1];

    std.debug.print("{s:16} #{:0>4} '", .{ name, constant });
    printValue(chunk.constants.values[constant]);
    std.debug.print("'\n", .{});

    return offset + 2;
}

fn simpleInstruction(name: []const u8, offset: usize) usize {
    std.debug.print("{s:16}\n", .{name});

    return offset + 1;
}

fn printValue(value: Value) void {
    std.debug.print("{d}", .{value});
}
