const std = @import("std");
const glue = @import("glue.zig");
const Path = glue.Path;
const FmtConfig = glue.FmtConfig;
const Glue = glue.Glue;
const Project = glue.Project;

pub const JobQueue = struct {
  io: std.Io,
  al: std.mem.Allocator,
  proj: *Project,
  idx: AtomicUsize,
  succ: AtomicUsize,

  const AtomicUsize = std.atomic.Value(usize);

  pub fn init(io: std.Io, al: std.mem.Allocator, project: *Project) @This() {
    return .{
      .io = io,
      .al = al,
      .proj = project,
      .idx = AtomicUsize.init(0),
      .succ = AtomicUsize.init(0),
    };
  }

  pub fn getSuccessCount(self: *JobQueue) usize {
    return self.succ.load(.monotonic);
  }

  pub fn task(self: *JobQueue) !void {
    while (true) {
      const idx = self.idx.fetchAdd(1, .monotonic);
      if (idx >= self.proj.files.len) return;
      const job = self.proj.files[idx];
      var g = try Glue.init(self.io, self.al);
      if (try Glue.formatImm(&g, self.proj, job, self.proj.getFmtConfig(), false)) {
        _ = self.succ.fetchAdd(1, .monotonic);
      }
    }
  }
};
