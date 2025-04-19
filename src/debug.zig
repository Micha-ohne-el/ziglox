const std = @import("std");
const Chunk = @import("Chunk.zig");

const stdout = std.io.getStdOut().writer();

pub fn disassembleChunk(chunk: Chunk, name: []const u8) void {
    print("== {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.count()) {
        offset = disassembleInstruction(chunk, offset);
    }
}

pub fn disassembleInstruction(chunk: Chunk, offset: usize) usize {
    print("{d:04} ", .{offset});

    if (offset > 0 and chunk.getLine(offset) == chunk.getLine(offset - 1)) {
        print("   | ", .{});
    } else {
        print("{d:4} ", .{chunk.getLine(offset)});
    }

    return switch (chunk.getOpCode(offset)) {
        .op_return => simpleInstruction("OP_RETURN", offset),
        .op_constant => constantInstruction("OP_CONSTANT", chunk, offset),
        else => |code| {
            print("Unknown opcode: {d}\n", .{code});
            return offset + 1;
        },
    };
}

fn simpleInstruction(name: []const u8, offset: usize) usize {
    print("{s}\n", .{name});
    return offset + 1;
}

fn constantInstruction(name: []const u8, chunk: Chunk, offset: usize) usize {
    const constant_index = chunk.getByte(offset + 1);
    print("{s:<16} {d:4} '{}'\n", .{ name, constant_index, chunk.getConstant(constant_index) });
    return offset + 2;
}

fn print(comptime fmt: []const u8, args: anytype) void {
    return std.fmt.format(stdout, fmt, args) catch {};
}
