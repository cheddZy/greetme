const std = @import("std");
const Io = std.Io;

pub const GreetError = error{
    EmptyName,
    NameTooLong,
    NameTooShort,
};

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const arena = init.arena.allocator();

    const stdout_file = Io.File.stdout();
    const supports_ansi = try stdout_file.supportsAnsiEscapeCodes(io);

    const stdout_buf_size = 4096;
    const stdin_buf_size = 128;

    var stdout_buf: [stdout_buf_size]u8 = undefined;
    var stdout_writer: Io.File.Writer = .init(.stdout(), io, &stdout_buf);
    const stdout = &stdout_writer.interface;

    var stdin_buf: [stdin_buf_size]u8 = undefined;
    var stdin_reader: Io.File.Reader = .init(.stdin(), io, &stdin_buf);
    const stdin = &stdin_reader.interface;

    const args = try init.minimal.args.toSlice(arena);

    const resolved_name: []const u8 = blk: {
        const from_args = parseArgs(args, stdout);
        if (from_args.len > 0) break :blk from_args;

        try stdout.writeAll("What is your name? ");
        try stdout.flush();

        const bare_name = try stdin.takeDelimiter('\n') orelse {
            fatal(stdout, "Error: well... that's not polite is it (unexpected end of input)");
        };

        const trimmed = std.mem.trim(u8, bare_name, "\r");

        if (supports_ansi) {
            try stdout.writeAll("\x1B[1A\x1B[2K");
            try stdout.flush();
        }

        break :blk trimmed;
    };

    greet(stdout, resolved_name) catch |err| switch (err) {
        GreetError.EmptyName => fatal(stdout, "Error: names cannot be empty!"),
        GreetError.NameTooShort => fatal(stdout, "Error: that's too damn short (min 2 chars)."),
        GreetError.NameTooLong => fatal(stdout, "Error: name is too damn long! (max 64 chars)."),
        else => return err,
    };

    try stdout.flush();
}

/// Greets the user in the console
pub fn greet(stdout: *Io.Writer, name: []const u8) !void {
    if (name.len == 0) return GreetError.EmptyName;
    if (name.len < 2) return GreetError.NameTooShort;
    if (name.len > 64) return GreetError.NameTooLong;

    try stdout.print("Hello, {s}!\n", .{name});
}

/// fucking dies a horrible death
///
/// but at least it elaborates
fn fatal(stdout: *Io.Writer, msg: []const u8) noreturn {
    stdout.print("{s}\n", .{msg}) catch {};
    stdout.flush() catch {};
    std.process.exit(1);
}

/// hold on, i actually... have the documentaiton right here. Ah, here we go... "Give orange me give eat orange me eat orange give me eat orange give me you"
fn parseArgs(args: []const []const u8, stdout: *Io.Writer) []const u8 {
    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--name")) {
            i += 1;
            if (i >= args.len) fatal(stdout, "Error: --name requires a value.");
            return args[i];
        }

        if (std.mem.startsWith(u8, arg, "--name=")) {
            return arg["--name=".len..];
        }

        fatal(stdout, "Error: ...why are you looking at me like that (unknown flag)");
    }

    return "";
}
