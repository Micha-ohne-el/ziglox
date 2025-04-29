const VirtualMachine = @This();
const std = @import("std");
const builtin = @import("builtin");
const Chunk = @import("Chunk.zig");
const Value = @import("values.zig").Value;
const debug = @import("debug.zig");

const max_stack_size = 256;

chunk: ?*Chunk,
ii: usize,
stack: [max_stack_size]Value,
stack_size: usize,

pub const Error = error{
    CompileError,
    RuntimeError,
};

pub const empty: VirtualMachine = .{
    .chunk = null,
    .ii = 0,
    .stack = undefined,
    .stack_size = 0,
};

pub fn run(this: *VirtualMachine, chunk: *Chunk) Error!void {
    this.chunk = chunk;

    while (true) {
        debug.print("          ", .{});
        for (this.stack[0..this.stack_size]) |frame| debug.print("[ {d} ]", .{frame});
        debug.print("\n", .{});

        _ = debug.disassembleInstruction(this.chunk.?.*, this.ii);

        switch (this.read().operation) {
            .op_constant => {
                const constant = this.readConstant();
                this.push(constant);
            },
            .op_return => {
                debug.print("{d}\n", .{this.pop()});
                return;
            },
            .op_add => {
                const b = this.pop();
                const a = this.pop();
                this.push(a + b);
            },
            .op_subtract => {
                const b = this.pop();
                const a = this.pop();
                this.push(a - b);
            },
            .op_multiply => {
                const b = this.pop();
                const a = this.pop();
                this.push(a * b);
            },
            .op_divide => {
                const b = this.pop();
                const a = this.pop();
                this.push(a / b);
            },
            .op_negate => this.push(-this.pop()),
            else => @panic("Unkown OpCode!"),
        }
    }
}

fn read(this: *VirtualMachine) Chunk.Instruction {
    defer this.ii += 1;
    return this.chunk.?.read(this.ii);
}

fn readConstant(this: *VirtualMachine) Value {
    return this.chunk.?.getConstant(this.read().data);
}

fn push(this: *VirtualMachine, value: Value) void {
    this.stack[this.stack_size] = value;
    this.stack_size += 1;
}

fn pop(this: *VirtualMachine) Value {
    this.stack_size -= 1;
    return this.stack[this.stack_size];
}
