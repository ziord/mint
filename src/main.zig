const std = @import("std");
const cli = @import("cli.zig");

test {
  _ = @import("test.zig");
}

pub fn main(init: std.process.Init) !void {
  var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
  const al = arena.allocator();
  defer arena.deinit();
  var args = try init.minimal.args.toSlice(al);
  var c = try cli.ArgParse.parseArgs(al, init.io, args[1..]);
  try c.run();
}
