const Compiler = @This();
const std = @import("std");
const Scanner = @import("Scanner.zig");
const debug = @import("debug.zig");

pub const empty: Compiler = .{};

pub const Error = error{
    CompileError,
} || Scanner.Error;

pub fn compile(this: *Compiler, source_code: []const u8) Error!void {
    _ = this;
    var scanner: Scanner = .new(source_code);

    const token = try scanner.scan();

    debug.print("< {any}\n", .{token});
}
