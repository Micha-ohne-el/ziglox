/// Converts any integer to its signed counterpart of the same bitwidth.
/// Invokes detectable undefined behavior if `x` doesn't fit into the new type. E.g. `128` doesn't fit into `i8`.
/// See `@intCast` for details.
pub fn i(x: anytype) I(@TypeOf(x)) {
    return @intCast(x);
}

/// Converts any integer to its unsigned counterpart of the same bitwidth.
/// Invokes detectable undefined behavior if `x < 0`.
/// See `@intCast` for details.
pub fn u(x: anytype) U(@TypeOf(x)) {
    return @intCast(x);
}

pub fn I(T: type) type {
    return @Type(
        .{
            .int = .{
                .bits = @typeInfo(T).int.bits,
                .signedness = .signed,
            },
        },
    );
}

pub fn U(T: type) type {
    return @Type(
        .{
            .int = .{
                .bits = @typeInfo(T).int.bits,
                .signedness = .unsigned,
            },
        },
    );
}
