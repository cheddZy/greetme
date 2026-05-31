//! By convention, root.zig is the root source file when making a package.
const std = @import("std");
const main = @import("main.zig");
const Io = std.Io;

test "greet with valid name" {
    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);
    const stdout = &writer;

    try main.greet(stdout, "Alice");

    const written = writer.buffered();
    try std.testing.expectEqualStrings("Hello, Alice!\n", written);
}

test "greet with empty name returns error" {
    var buf: [128]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);
    const stdout = &writer;

    const result = main.greet(stdout, "");
    try std.testing.expectError(main.GreetError.EmptyName, result);
}

test "greet with name over 64 chars returns error" {
    var buf: [256]u8 = undefined;
    var writer = std.Io.Writer.fixed(&buf);
    const stdout = &writer;

    const long_name = "A" ** 65;
    const result = main.greet(stdout, long_name);
    try std.testing.expectError(main.GreetError.NameTooLong, result);
}
