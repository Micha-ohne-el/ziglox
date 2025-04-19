const std = @import("std");

pub const Value = union(enum) {
    float: f64,

    pub fn format(value: Value, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;

        switch (value) {
            .float => |it| try std.fmt.formatType(it, "d", options, writer, 0),
        }
    }
};
