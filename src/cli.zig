const std = @import("std");
const util = @import("util.zig");
const glue = @import("glue.zig");
const fmt = @import("format.zig");
const work = @import("work.zig");
const Allocator = std.mem.Allocator;
const Glue = glue.Glue;
const Path = glue.Path;
const Mode = glue.Mode;
const FileType = glue.FileType;
const FileTypes = glue.FileTypes;
const ExtensionFilters = glue.ExtensionFilters;
const IgnoreList = glue.IgnoreList;
const Project = glue.Project;
const JobQueue = work.JobQueue;

const log = std.log.scoped(util.getLoggerEnum(.cli));

pub const Cli = struct {
  al: Allocator,
  io: std.Io,
  mode: Mode,
  projects: std.StringArrayHashMapUnmanaged(Project) = .empty,

  // maximum number of threads we can use
  const MAX_THREAD_COUNT = 16;
  // threshold for sequential file processing
  const SEQ_THRESHOLD = 100;

  const CfgFilename = "mint.zon";

  pub fn init(
    parent_al: Allocator,
    io: std.Io,
    paths: ?[]const []const u8,
    mode: Mode,
  ) !Cli {
    var self = Cli{ .al = parent_al, .io = io, .mode = mode };
    if (mode == .help or mode == .init) return self;
    const p = paths orelse &.{@as([]const u8, ".")};
    try self.findFilePaths(p);
    return self;
  }

  fn findFilePaths(self: *Cli, paths: []const []const u8) !void {
    m: for (paths) |path| {
      var files: std.ArrayList(Path) = .empty;
      _ = std.Io.Dir.cwd()
        .openFile(self.io, path, .{ .allow_directory = false }) catch |e| {
        switch (e) {
          error.IsDir => {
            var dir = try std.Io.Dir.cwd()
              .openDir(self.io, path, .{ .iterate = true });
            var walker = try dir.walk(self.al);
            l: while (try walker.next(self.io)) |entry| {
              switch (entry.kind) {
                .file => {
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
                  const p = try std.fs.path.join(self.al, &.{ path, tmp });
                  try files.append(self.al, .{ .path = p, .ty = FileTypes[idx] });
                },
                else => {},
              }
            }
            // save for rescan later
            if (files.items.len > 0) {
              try self.projects.put(self.al, path, .{ .files = files.items });
              files = .empty;
            }
            continue :m;
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
      tmp[0] = .{ .path = path, .ty = ty };
      try self.projects.put(self.al, path, .{ .files = tmp });
    }
  }

  inline fn configFileIsModified(self: *Cli, proj: *Project) bool {
    if (proj.config) |cfg| {
      const mtime = util.getStatMTime(self.io, cfg.p.path) catch return false;
      return mtime.toNanoseconds() != cfg.mtime.toNanoseconds();
    }
    return false;
  }

  fn discoverConfigs(self: *Cli) !void {
    for (self.projects.values()) |*proj| {
      if (proj.config == null) {
        var cfg: ?Path = null;
        for (proj.files) |*f| {
          if (
            f.ty == .zon
              and std.mem.eql(u8, std.fs.path.basename(f.path), CfgFilename)
          ) {
            if (cfg == null) {
              f.is_config = true;
              cfg = f.*;
              // we don't break immediately because we also try to
              // validate that there's only one `mint.zon` file per project
            } else {
              std.debug.print("error: found multiple `mint.zon` files:\n", .{});
              std.debug.print("  {s} and {s}\n", .{ cfg.?.path, f.path });
              return error.MultipleConfigFiles;
            }
          }
        }
        if (cfg) |p| {
          proj.config = .{ .p = p, .mtime = try util.getStatMTime(self.io, p.path) };
        }
      }
    }
  }

  fn formatWatch(self: *Cli, g: *Glue) !void {
    // TODO: should update to use hashes instead of timestamps
    var simple_hash = std.StringHashMapUnmanaged(std.Io.Timestamp){};
    while (true) {
      for (self.projects.values()) |*proj| {
        const cfg_was_modified = self.configFileIsModified(proj);
        for (proj.files) |p| {
          if (cfg_was_modified) {
            if (!p.is_config) {
              const formatted = g.formatWatch(p, proj, self.al) catch continue;
              const mtime_b = try util.getStatMTime(self.io, p.path);
              try simple_hash.put(self.al, p.path, mtime_b);
              if (formatted) log.info("{s} (changed)", .{p.path});
            } else {
              try proj.loadConfig(self.io, false, self.al);
            }
          } else {
            var mtime_a: std.Io.Timestamp = undefined;
            if (simple_hash.get(p.path)) |time| {
              var curr_time = try util.getStatMTime(self.io, p.path);
              if (curr_time.toNanoseconds() == time.toNanoseconds()) continue;
              mtime_a = time;
              _ = g.formatWatch(p, proj, self.al) catch continue;
              curr_time = try util.getStatMTime(self.io, p.path);
              log.info("watching {s}", .{p.path});
              if (curr_time.toNanoseconds() != mtime_a.toNanoseconds()) {
                log.info("{s} (changed)", .{p.path});
                try simple_hash.put(self.al, p.path, curr_time);
              }
            } else {
              mtime_a = try util.getStatMTime(self.io, p.path);
              const formatted = g.formatWatch(p, proj, self.al) catch continue;
              try simple_hash.put(
                self.al,
                p.path,
                try util.getStatMTime(self.io, p.path),
              );
              if (formatted) log.info("{s} (new)", .{p.path});
            }
          }
        }
      }
      try self.io.sleep(.fromMilliseconds(500), .awake);
    }
  }

  fn formatImm(self: *Cli) !void {
    var files: usize = 0;
    const num_cpus = try std.Thread.getCpuCount();
    for (self.projects.values()) |*proj| {
      // we only need to load the project's config once
      try proj.loadConfig(self.io, true, self.al);
      // TODO: finetune `SEQ_THRESHOLD`
      if (proj.files.len > SEQ_THRESHOLD) {
        // create workers for the files
        var jq = JobQueue.init(self.io, self.al, proj);
        const num_threads = @min(@min(num_cpus, proj.files.len), MAX_THREAD_COUNT);
        log.debug("using {} cpus and {} workers", .{ num_cpus, num_threads });
        var threads: [MAX_THREAD_COUNT]std.Thread = undefined;
        for (0..num_threads) |i| {
          threads[i] = try std.Thread.spawn(.{}, JobQueue.task, .{&jq});
        }
        for (threads[0..num_threads]) |thread| {
          thread.join();
        }
        files += jq.getSuccessCount();
      } else {
        var g = try Glue.init(self.io, self.al);
        for (proj.files) |f| {
          if (try Glue.formatImm(&g, proj, f, proj.getFmtConfig(), true)) {
            files += 1;
          }
        }
      }
    }
    std.debug.print(
      "Formatted {} file(s) across {} project(s).\n",
      .{ files, self.projects.count() },
    );
  }

  fn doInit(self: *Cli) !void {
    const template =
    \\.{ .width = 85, .indent = 2, .ignore = .{} }
    \\
    ;
    var g = try Glue.init(self.io, self.al);
    try g.writeFileCwd(CfgFilename, template);
    std.debug.print("created {s}.\n", .{CfgFilename});
  }

  pub fn run(self: *Cli) !void {
    switch (self.mode) {
      .help => return,
      .init => return self.doInit(),
      else => {
        self.discoverConfigs() catch return;
        if (self.mode == .watch) {
          var g = try Glue.init(self.io, self.al);
          try self.formatWatch(&g);
        } else {
          try self.formatImm();
        }
      },
    }
  }
};

pub const ArgParse = struct {
  const info =
  \\Usage:
  \\  mint <command> [<args>]
  \\    init                        -  create a `mint.zon` config file
  \\    fmt [filename|directory]    -  format a file or directory of files
  \\    watch [filename|directory]  -  format in watch mode
  \\    help                        -  display usage information
  ;

  inline fn getHelp(al: Allocator, io: std.Io) !Cli {
    std.debug.print("{s}\n", .{info});
    return Cli.init(al, io, null, .help);
  }

  pub fn parseArgs(al: Allocator, io: std.Io, args: []const [:0]const u8) !Cli {
    if (args.len == 0) {
      std.debug.print("{s}\n", .{info});
      return Cli.init(al, io, null, .help);
    } else {
      const m_cmd = args[0];
      if (std.mem.eql(u8, "fmt", m_cmd)) {
        return Cli.init(al, io, if (args.len > 1) args[1..] else null, .imm);
      } else if (std.mem.eql(u8, "watch", m_cmd)) {
        return Cli.init(al, io, if (args.len > 1) args[1..] else null, .watch);
      } else if (std.mem.eql(u8, "init", m_cmd)) {
        if (args.len > 1) {
          std.debug.print("Invalid argument(s) passed to 'init'.\n", .{});
          return getHelp(al, io);
        }
        return Cli.init(al, io, null, .init);
      } else {
        if (std.mem.eql(u8, "help", m_cmd)) {
          if (args.len > 1)
            std.debug.print("Invalid argument(s) passed to 'help'.\n", .{});
        } else {
          std.debug.print("Invalid argument.\n", .{});
        }
        return getHelp(al, io);
      }
    }
  }
};
