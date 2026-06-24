const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;

pub inline fn box(val: anytype, al: Allocator) *@TypeOf(val) {
  const item = al.create(@TypeOf(val)) catch |e| {
    std.debug.print("Allocation failed: {}\n", .{e});
    std.posix.system.exit(1);
  };
  item.* = val;
  return item;
}

pub inline fn allocSlice(comptime T: type, n: usize, al: Allocator) []T {
  return al.alloc(T, n) catch |e| {
    std.debug.print("Allocation failed: {}\n", .{e});
    std.posix.system.exit(1);
  };
}

pub inline fn listInit(
  comptime T: type,
  cap: usize,
  al: Allocator,
) std.ArrayList(T) {
  return std.ArrayList(T).initCapacity(al, cap) catch |e| {
    std.debug.print("list init failed: {}\n", .{e});
    std.posix.system.exit(1);
  };
}

pub inline fn listAppend(
  val: anytype,
  list: *std.ArrayList(@TypeOf(val)),
  al: Allocator,
) void {
  list.append(al, val) catch |e| {
    std.debug.print("list append failed: {}\n", .{e});
    std.posix.system.exit(1);
  };
}

pub inline fn listAppendSlice(
  comptime T: type,
  list: *std.ArrayList(T),
  val: []T,
  al: Allocator,
) void {
  list.appendSlice(al, val) catch |e| {
    std.debug.print("list append slice failed: {}\n", .{e});
    std.posix.system.exit(1);
  };
}

pub inline fn getStatMTime(io: std.Io, f: []const u8) !std.Io.Timestamp {
  const stat = try std.Io.Dir.cwd().statFile(io, f, .{});
  return stat.mtime;
}

pub inline fn getLoggerEnum(lit: @EnumLiteral()) @EnumLiteral() {
  return if (builtin.mode == .Debug) lit else .mint;
}

pub fn todo(comptime s: []const u8) noreturn {
  @panic("Todo: " ++ s ++ "!");
}
