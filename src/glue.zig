const std = @import("std");
const fmt = @import("format.zig");
const util = @import("util.zig");
const ts = @import("translate.zig");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

pub const FileType = enum {zig, zon, mint};
pub const Mode = enum{ imm, watch, help };
pub const Path = struct {path: []const u8, ty: FileType};
// NOTE: keep `FileTypes` in sync with `ExtensionFilters`
pub const FileTypes = [_]FileType {.zig, .zon, .mint};
pub const ExtensionFilters = [_][]const u8 {"zig", "zon", "mint"};

pub const Glue = struct {
  io: std.Io,
  cfg: fmt.FmtConfig,
  /// arena for managing formatting allocations
  arena: ArenaAllocator,

  var WriteBuf: [2048]u8 = undefined;

  pub fn init(io: std.Io, cfg: fmt.FmtConfig) !Glue {
    return .{.io = io, .cfg = cfg, .arena = ArenaAllocator.init(std.heap.page_allocator)};
  }

  inline fn al(self: *Glue) Allocator {
    return self.arena.allocator();
  }
  
  pub inline fn getFormatter(self: *Glue, allocator: Allocator) struct{ts.Translate, fmt.Format} {
    // NOTE: we could reset every field of `t` and `f` but we'd
    // have to do it intrusively. This can easily break if we add
    // new fields to `t` or `f` or both. For now, simply creating
    // a fresh translator and formatter objects would suffice.
    return .{try ts.Translate.init(allocator, self.io), fmt.Format.init(self.io, allocator, self.cfg)};
  }

  fn readFile(self: *Glue, filename: []const u8, mode: std.Io.File.OpenFlags.Mode) !struct{std.Io.File, [:0]const u8} {
    var file = try std.Io.Dir.openFileAbsolute(self.io, filename, .{.mode = mode});
    const size = try file.length(self.io);
    const buf = util.allocSlice(u8, size + 1, self.al());
    const r_size = try file.readPositionalAll(self.io, buf, 0);
    std.debug.assert(size == r_size);
    buf[size] = 0;
    return .{file, buf[0..size:0]};
  }
  
  fn writeFile(self: *Glue, filename: []const u8, content: []const u8) !void {
    var file = try std.Io.Dir.openFileAbsolute(self.io, filename, .{.mode = .write_only});
    defer file.close(self.io);
    try file.setLength(self.io, 0);
    try file.writePositionalAll(self.io, content, 0);
  }
  
  pub fn formatImm(self: *Glue, p: Path) !void {
    if (p.ty != .zig) return;
    var file, const src = try self.readFile(p.path, .read_write);
    defer file.close(self.io);
    defer self.arena.deinit();
    var t, var f = self.getFormatter(self.arena.allocator());
    const doc = t.translate(p.path, src, .zig) catch return;
    try file.setLength(self.io, 0);
    f.setFileWriter(file.writer(self.io, &WriteBuf));
    f.fmt(doc);
    std.debug.print("successfully formated {s}\n", .{p.path});
  }

  pub fn formatWatch(self: *Glue, p: Path) !void {
    if (p.ty != .zig) return;
    var file, const src = try self.readFile(p.path, .read_only);
    file.close(self.io);
    var t, var f = self.getFormatter(self.arena.allocator());
    const doc = t.translate(p.path, src, .zig) catch return;
    const mode = f.cfg.write_mode;
    defer f.cfg.write_mode = mode;
    f.cfg.write_mode = .mem;
    f.fmt(doc);
    try self.writeFile(p.path, f.getFmtString(false));
    self.arena.deinit();
    self.arena = ArenaAllocator.init(std.heap.page_allocator);
  }
};
