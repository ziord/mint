const std = @import("std");
const fmt = @import("format.zig");
const util = @import("util.zig");
const ts = @import("translate.zig");
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const log = std.log.scoped(util.getLoggerEnum(.glue));

pub const FileType = std.zig.Ast.Mode;
pub const Mode = enum { imm, watch, help, init };
pub const Path = struct { path: []const u8, ty: FileType, is_config: bool = false };
// NOTE: keep `FileTypes` in sync with `ExtensionFilters`
pub const FileTypes = [_]FileType{ .zig, .zon };
pub const ExtensionFilters = [_][]const u8{ "zig", "zon" };
pub const IgnoreList = [_][]const u8{"zig-"};

pub const MintConfig = struct {
  width: u32,
  indent: u8,
  ignore: [][]const u8,

  pub fn toFmtConfig(self: MintConfig) fmt.FmtConfig {
    return .{ .width = self.width, .indent = self.indent, .write_mode = .file };
  }
};

pub const Project = struct {
  config: ?struct {
    p: Path,
    mtime: std.Io.Timestamp,
    fmt_cfg: fmt.FmtConfig = .{ .write_mode = .file },
  } = null,
  files: []Path,

  pub fn getFmtConfig(self: Project) fmt.FmtConfig {
    if (self.config) |cfg| {
      return cfg.fmt_cfg;
    }
    return .{ .write_mode = .file };
  }
};

pub const Glue = struct {
  io: std.Io,
  /// arena for managing formatting allocations
  arena: ArenaAllocator,
  ignore_set_loaded: bool = false,
  ignore_set: std.StringArrayHashMapUnmanaged(void) = .empty,
  /// track the errors found during translation to prevent
  /// repetition of display of errors
  error_set: ts.Translate.ErrorSet,

  var WriteBuf: [2048]u8 = undefined;

  pub fn init(io: std.Io, top_al: Allocator) !Glue {
    return .{
      .io = io,
      .arena = undefined,
      .error_set = ts.Translate.ErrorSet.init(top_al),
    };
  }

  inline fn allocator(self: *Glue) Allocator {
    return self.arena.allocator();
  }

  pub inline fn getFormatter(
    self: *Glue,
    al: Allocator,
    cfg: fmt.FmtConfig,
  ) struct { ts.Translate, fmt.Format } {
    // NOTE: we could reset every field of `t` and `f` but we'd
    // have to do it intrusively. This can easily break if we add
    // new fields to `t` or `f` or both. For now, simply creating
    // a fresh translator and formatter objects would suffice.
    return .{
      try ts.Translate.init(al, self.io, &self.error_set),
      fmt.Format.init(self.io, al, cfg),
    };
  }

  fn readFile(
    self: *Glue,
    filename: []const u8,
    mode: std.Io.File.OpenFlags.Mode,
    al: Allocator,
  ) !struct { std.Io.File, [:0]const u8 } {
    var file = try std.Io.Dir.cwd().openFile(self.io, filename, .{ .mode = mode });
    const size = try file.length(self.io);
    var buf = util.allocSlice(u8, size + 1, al);
    const r_size = try file.readPositionalAll(self.io, buf, 0);
    if (r_size != size) return error.FileChanged;
    buf[size] = 0;
    return .{ file, buf[0..size:0] };
  }

  fn writeFile(self: *Glue, filename: []const u8, content: []const u8) !void {
    var file = try std.Io.Dir.cwd()
      .openFile(self.io, filename, .{ .mode = .write_only });
    defer file.close(self.io);
    try file.setLength(self.io, 0);
    try file.writePositionalAll(self.io, content, 0);
  }

  pub fn writeFileCwd(self: *Glue, filename: []const u8, content: []const u8) !void {
    var file = try std.Io.Dir.cwd().createFile(self.io, filename, .{});
    defer file.close(self.io);
    try file.setLength(self.io, 0);
    try file.writePositionalAll(self.io, content, 0);
  }

  /// load the config file pointed to by path `p`.
  fn loadMintConfig(self: *Glue, p: Path, al: Allocator) !MintConfig {
    self.arena = ArenaAllocator.init(std.heap.page_allocator);
    defer self.arena.deinit();
    var file, const src = try self.readFile(p.path, .read_only, self.allocator());
    file.close(self.io);
    var diag = std.zon.parse.Diagnostics{};
    return std.zon.parse.fromSliceAlloc(MintConfig, al, src, &diag, .{});
  }

  fn loadIgnoreList(self: *Glue, mcfg: MintConfig, al: Allocator) !void {
    // because ignore from config file is dynamic and maybe changed, we need to reload
    self.ignore_set.clearRetainingCapacity();
    for (mcfg.ignore) |ign| {
      try self.ignore_set.put(al, ign, {});
    }
    // useful for the first initial load
    self.ignore_set_loaded = true;
  }

  fn shouldIgnore(self: *Glue, p: Path) bool {
    for (self.ignore_set.keys()) |ign| {
      if (std.mem.containsAtLeast(u8, p.path, 1, ign)) {
        return true;
      }
    }
    for (IgnoreList) |ign| {
      if (std.mem.containsAtLeast(u8, p.path, 1, ign)) {
        return true;
      }
    }
    return false;
  }

  pub fn loadConfig(self: *Glue, proj: *Project, is_imm: bool, al: Allocator) !void {
    if (proj.config) |*cfg| {
      const mtime = try util.getStatMTime(self.io, cfg.p.path);
      if (
        is_imm
          or mtime.toNanoseconds() != cfg.mtime.toNanoseconds()
          or !self.ignore_set_loaded
      ) {
        cfg.mtime = mtime;
        const m_cfg = self.loadMintConfig(cfg.p, al) catch |e| {
          if (e == error.ParseZon) {
            std.debug.print("error: unable to parse zon file.\n", .{});
          } else {
            std.debug.print("error: invalid config file.\n", .{});
          }
          return e;
        };
        cfg.fmt_cfg = m_cfg.toFmtConfig();
        // TODO: integrate .gitignore
        try self.loadIgnoreList(m_cfg, al);
      }
    }
  }

  pub fn formatImm(self: *Glue, p: Path, cfg: fmt.FmtConfig) !void {
    if (self.shouldIgnore(p)) return;
    self.arena = ArenaAllocator.init(std.heap.page_allocator);
    defer self.arena.deinit();
    var file, const src = try self.readFile(p.path, .read_write, self.allocator());
    defer file.close(self.io);
    var t, var f = self.getFormatter(self.allocator(), cfg);
    const doc = t.translate(p.path, src, .zig) catch return;
    try file.setLength(self.io, 0);
    f.setFileWriter(file.writer(self.io, &WriteBuf));
    f.fmt(doc);
    std.debug.print("successfully formated {s}\n", .{p.path});
  }

  pub fn formatWatch(self: *Glue, p: Path, proj: *Project, al: Allocator) !bool {
    try self.loadConfig(proj, false, al);
    if (p.is_config or self.shouldIgnore(p)) return false;
    const cfg = proj.getFmtConfig();
    self.arena = ArenaAllocator.init(std.heap.page_allocator);
    defer self.arena.deinit();
    var file, const src = try self.readFile(p.path, .read_only, self.allocator());
    file.close(self.io);
    var t, var f = self.getFormatter(self.allocator(), cfg);
    log.debug("translating.", .{});
    const doc = try t.translate(p.path, src, .zig);
    // in watch mode, prefer mem, so that rollbacks are easy
    const mode = f.cfg.write_mode;
    defer f.cfg.write_mode = mode;
    f.cfg.write_mode = .mem;
    log.debug("formatting.", .{});
    f.fmt(doc);
    const new_src = f.getFmtString(false);
    if (new_src.len != 0) {
      log.debug("writing.", .{});
      try self.writeFile(p.path, new_src);
    } else {
      log.debug("empty, skipping.", .{});
    }
    return true;
  }
};
