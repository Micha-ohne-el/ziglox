const std = @import("std");
const Chunk = @import("Chunk.zig");
const VirtualMachine = @import("VirtualMachine.zig");
const debug = @import("debug.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var vm: VirtualMachine = .empty;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);
    if (args.len == 1) {
        try repl(&vm, allocator);
    } else if (args.len == 2) {
        runFile(&vm, allocator, args[1]) catch |err| switch (err) {
            VirtualMachine.Error.CompileError => std.process.exit(65),
            VirtualMachine.Error.RuntimeError => std.process.exit(70),
            else => std.process.exit(74),
        };
    } else {
        debug.print("Usage: ziglox [path]\n", .{});
        std.process.exit(64);
    }
}

fn repl(vm: *VirtualMachine, allocator: std.mem.Allocator) !void {
    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    while (true) {
        _ = try stdout.write("> ");

        if (stdin.readUntilDelimiterAlloc(allocator, '\n', 1024 * 1024)) |line| { // max_size: 1MiB
            try vm.interpret(line);
        } else |err| {
            try stdout.writeByte('\n');
            return err;
        }
    }
}

fn runFile(vm: *VirtualMachine, allocator: std.mem.Allocator, file_path: []const u8) !void {
    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        const stderr = std.io.getStdErr().writer();
        try std.fmt.format(stderr, "File '{s}' could not be opened because ", .{file_path});
        _ = switch (err) {
            error.FileNotFound => try stderr.write("it doesn't exist.\n"),
            error.AccessDenied => try stderr.write("permission to do so was denied.\n"),
            error.FileBusy => try stderr.write("it's locked by another process.\n"),
            error.AntivirusInterference => try stderr.write("the antivirus software interfered.\n"),
            error.IsDir => try stderr.write("it's actually a directory.\n"),
            error.NameTooLong => try stderr.write("its name is too long.\n"),
            else => try stderr.write("of some unknown error.\n"),
        };
        return err;
    };
    defer file.close();
    const content = file.readToEndAlloc(allocator, 1024 * 1024 * 1024) catch |err| { // max_bytes: 1GiB
        const stderr = std.io.getStdErr().writer();
        try std.fmt.format(stderr, "File '{s}' could not be read because ", .{file_path});
        _ = switch (err) {
            error.AccessDenied => try stderr.write("permission to do so was denied.\n"),
            error.IsDir => try stderr.write("it's actually a directory.\n"),
            error.FileTooBig => try stderr.write("it's too long (current limit = 1GiB).\n"),
            error.OutOfMemory => try stderr.write("there wasn't enough memory to store its contents.\n"),
            else => try stderr.write("of some unknown error.\n"),
        };
        return err;
    };
    defer allocator.free(content);

    try vm.interpret(content);
}
