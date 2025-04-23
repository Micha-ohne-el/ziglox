const std = @import("std");
const builtin = @import("builtin");
const Chunk = @import("Chunk.zig");

const stdout = std.io.getStdOut().writer();

pub fn print(comptime fmt: []const u8, args: anytype) void {
    if (builtin.mode != .Debug) return;

    return std.fmt.format(stdout, fmt, args) catch {};
}

pub fn disassembleChunk(chunk: Chunk, name: []const u8) void {
    if (builtin.mode != .Debug) return;

    print("== {s} ==\n", .{name});

    var offset: usize = 0;
    while (offset < chunk.count()) {
        offset = disassembleInstruction(chunk, offset);
    }
}

pub fn disassembleInstruction(chunk: Chunk, offset: usize) usize {
    if (builtin.mode != .Debug) return 0;

    print("{d:04} ", .{offset});

    if (offset > 0 and chunk.getLine(offset) == chunk.getLine(offset - 1)) {
        print("   | ", .{});
    } else {
        print("{d:4} ", .{chunk.getLine(offset)});
    }

    return switch (chunk.read(offset).operation) {
        .op_return => simpleInstruction("OP_RETURN", offset),
        .op_constant => constantInstruction("OP_CONSTANT", chunk, offset),
        .op_add => simpleInstruction("OP_ADD", offset),
        .op_subtract => simpleInstruction("OP_SUBTRACT", offset),
        .op_multiply => simpleInstruction("OP_MULTIPLY", offset),
        .op_divide => simpleInstruction("OP_DIVIDE", offset),
        .op_negate => simpleInstruction("OP_NEGATE", offset),
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
    const constant_index = chunk.read(offset + 1).data;
    print("{s:<16} {d:4} '{d}'\n", .{ name, constant_index, chunk.getConstant(constant_index) });
    return offset + 2;
}
