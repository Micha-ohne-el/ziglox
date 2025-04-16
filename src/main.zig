const std = @import("std");

pub fn main() !void {
    std.debug.print("Robert Nystrom is pretty {s} :)\n", .{"cool"});
}

test {
    try std.testing.expect(1 + 1 == 2);
}
