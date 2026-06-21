const std = @import("std");
const util = @import("util.zig");
const glue = @import("glue.zig");
const fmt = @import("format.zig");
const Allocator = std.mem.Allocator;
const Glue = glue.Glue;
const Path = glue.Path;
const Mode = glue.Mode;
const FileType = glue.FileType;
const FileTypes = glue.FileTypes;
const ExtensionFilters = glue.ExtensionFilters;

pub const Cli = struct {
  al: Allocator,
  io: std.Io,
  paths: []Path,
  mode: Mode,
  /// dirs to watch
  dirs: std.StringHashMapUnmanaged(void) = .empty,
  cfg: fmt.FmtConfig = .{},
  has_cfg_file: bool = false,

  var WriteBuf: [2048]u8 = undefined;
  
  // TODO: populate this from a config file like a `config.mint` file
  const IgnoreList = [_][]const u8 {".zig-", "zig-"};

  pub fn init(parent_al: Allocator, io: std.Io, paths: ?[]const []const u8, mode: Mode) !Cli {
    var self = Cli{.al = parent_al, .io = io, .paths = &.{}, .mode = mode};
    if (mode == .help) return self;
    const p = paths orelse &.{@as([]const u8, ".")};
    try self.findFilePaths(p);
    return self;
  }

  fn findFilePaths(self: *Cli, paths: []const []const u8) !void {
    var files: std.ArrayList(Path) = .empty;
    for (paths) |path| {
      _ = std.Io.Dir.cwd().openFile(self.io, path, .{.allow_directory = false}) catch |e| {
        switch (e) {
          error.IsDir => {
            var dir = try std.Io.Dir.cwd().openDir(self.io, path, .{.iterate = true});
            var walker = try dir.walk(self.al);
            l: while (try walker.next(self.io)) |entry| {
              switch (entry.kind) {
                .file => {
                  // FIXME: inefficient, rework this. 
                  for (IgnoreList) |ign| {
                    if (std.mem.containsAtLeast(u8, entry.path, 1, ign)) {
                      continue :l;
                    }
                  }
                  var idx = @as(usize, 0);
                  inline for (ExtensionFilters, 0..) |filter, i| {
                    if (std.mem.endsWith(u8, entry.path, "." ++ filter)) {
                      idx = i;
                      break;
                    }
                  } else {
                    continue :l;
                  }
                  const tmp = try self.al.dupe(u8, entry.path);
                  const p = try std.fs.path.join(self.al, &.{path, tmp});
                  try files.append(self.al, .{.path = p, .ty = FileTypes[idx]});
                },
                else => {},
              }
            }
            // save for rescan later
            if (files.items.len > 0 and self.mode == .watch) {
              try self.dirs.put(self.al, path, {});
            }
            self.paths = files.items;
            return;
          },
          else => return e,
        }
      };
      const tmp = util.allocSlice(Path, 1, self.al);
      var ty: FileType = undefined;
      if (std.mem.endsWith(u8, path, ".zig")) {
        ty = .zig;
      } else if (std.mem.endsWith(u8, path, ".zon")) {
        ty = .zon;
      } else {
        return error.InvalidPath;
      }
      tmp[0] = .{.path = path, .ty = ty};
      self.paths = tmp;
    }
  }
  
  fn loadConfig(self: *Cli) !void {
    // TODO:
    // var cfg_path: ?Path = null;
    // for (self.paths) |p| {
    //   if (p.ty == .mint) {
    //     if (cfg_path != null) {
    //       return error.MultipleMintFiles;
    //     }
    //     if (std.mem.eql(u8, "config.mint", p.path)) {
    //       cfg_path = p;
    //     }
    //   }
    // }
    // if (cfg_path) |p| {
    //   // TODO:
    //   // read file and load config contents
    //   _ = p;
    //   self.has_cfg_file = true;
    // }
    // 85 is the ideal width by default
    self.cfg = .{.write_mode = .file};
    // return error.NoConfigFileFound;
  }

  inline fn getStatMTime(self: *Cli, f: []const u8) !std.Io.Timestamp {
    const stat = try std.Io.Dir.cwd().statFile(self.io, f, .{});
    return stat.mtime;
  }

  fn formatWatch(self: *Cli, g: *Glue) !void {
    // TODO: rescan dirs at some point
    // TODO: should update to use hashes instead of timestamps
    var simple_hash = std.StringHashMapUnmanaged(std.Io.Timestamp){};
    while (true) {
      for (self.paths) |p| {
        var mtime_a: std.Io.Timestamp = undefined;
        if (simple_hash.get(p.path)) |time| {
          const mtime_b = try self.getStatMTime(p.path);
          if (mtime_b.toNanoseconds() == time.toNanoseconds()) continue;
          mtime_a = time;
        } else {
          mtime_a = try self.getStatMTime(p.path);
        }
        try g.formatWatch(p);
        const mtime_b = try self.getStatMTime(p.path);
        if (mtime_b.toNanoseconds() != mtime_a.toNanoseconds()) {
          try simple_hash.put(self.al, p.path, mtime_b);
        }
      }
    }
  }

  pub fn format(self: *Cli) !void {
    if (self.mode == .help) return;
    try self.loadConfig();
    var g = try Glue.init(self.io, self.cfg);
    if (self.mode == .watch) {
      try self.formatWatch(&g);
    } else {
      for (self.paths) |p| {
        try g.formatImm(p);
      }
    }
  }
};

pub const ArgParse = struct {
  const info =
  \\Usage:
  \\  mint fmt [filename|directory]    -  format a file or directory of files
  \\  mint watch [filename|directory]  -  format in watch mode
  \\  mint help                        -  display usage information
  ;
  pub fn parseArgs(al: Allocator, io: std.Io, args: []const [:0]const u8) !Cli {
    // mint [filename|directory]
    // mint watch [filename|directory]
    if (args.len == 0) {
      std.debug.print("{s}\n", .{info});
      return Cli.init(al, io, null, .help);
    } else {
      const m_cmd = args[0];
      if (std.mem.eql(u8, "fmt", m_cmd)) {
        return Cli.init(al, io, if (args.len > 1) args[1..] else null, .imm);
      } else if (std.mem.eql(u8, "watch", m_cmd)) {
        return Cli.init(al, io, if (args.len > 1) args[1..] else null, .watch);
      } else {
        if (std.mem.eql(u8, "help", m_cmd)) {
          if (args.len > 1) std.debug.print("Invalid argument(s) passed to 'help'.\n", .{});
        } else {
          std.debug.print("Invalid argument.\n", .{});
        }
        std.debug.print("{s}\n", .{info});
        return Cli.init(al, io, null, .help);
      }
    }
  }
};
