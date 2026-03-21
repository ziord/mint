const std = @import("std");
const util = @import("util.zig");
pub const config = @import("config.zig");
pub const doc = @import("doc.zig");

const Allocator = std.mem.Allocator;
const DocList = doc.DocList;
pub const Doc = doc.Doc;
pub const FmtConfig = config.FmtConfig;

pub const Format = struct {
  cfg: FmtConfig,
  split_groups: IDSet = .empty,
  al: Allocator,
  mem_writer: std.Io.Writer.Allocating,
  out_writer: std.fs.File.Writer,
  writer: *std.Io.Writer = undefined,

  var WriteBuf: [4096]u8 = undefined;

  const Self = @This();
  
  const IDSet = std.AutoHashMapUnmanaged(u32, void);

  const FitMode = enum(u8) {
    flat,
    split,
  };
  
  const StackData = struct{
    indent: u8,
    mode: FitMode,
    doc: *Doc,
  
    pub inline fn init(indent: u8, mode: FitMode, d: *Doc) @This() {
      return .{.indent = indent, .mode = mode, .doc = d};
    }
  };

  const Stack = std.ArrayList(StackData);

  pub fn init(al: Allocator, cfg: FmtConfig) Self {
    return .{
      .al = al,
      .cfg = cfg,
      .mem_writer = std.Io.Writer.Allocating.init(al),
      .out_writer = std.fs.File.Writer.init(std.fs.File.stdout(), &WriteBuf),
    };
  }

  fn setWriter(self: *Self) void {
    switch (self.cfg.writer) {
      .file => @panic("todo: file writer"),
      .out => {
        self.writer = &self.out_writer.interface;
      }, 
      .mem => {
        self.writer = &self.mem_writer.writer;
      },
    }
  }

  inline fn stackPush(self: *Self, s: *Stack, sm: StackData) void {
    util.listAppend(sm, s, self.al);
  }

  inline fn copyStack(self: *Self, s: *Stack) Stack {
    var s2 = util.listInit(StackData, s.items.len + 1, self.al);
    s2.appendSliceAssumeCapacity(s.items);
    return s2;
  }

  fn pushDocsToStack(
    self: *Self, docs: []*Doc, stack: *Stack,
    indent: u8, mode: FitMode,
  ) void {
    for (0..docs.len) |i| {
      self.stackPush(
        stack,
        StackData.init(indent, mode, docs[docs.len - i - 1]),
      );
    }
  }

  fn copyDocsToStack(
    self: *Self, docs: []*Doc, stack: *Stack,
    indent: u8, mode: FitMode,
  ) void {
    stack.ensureTotalCapacity(self.al, stack.items.len+docs.len) catch unreachable;
    for (0..docs.len) |i| {
      stack.appendAssumeCapacity(
        StackData.init(indent, mode, docs[docs.len - i - 1])
      );
    }
  }

  fn fits(self: *Self, rem_width: i32, stack: *Stack) bool {
    var width = rem_width;
    while (width >= 0) {
      if (stack.items.len == 0) return true;
      const sm = stack.pop().?;
      switch (sm.doc.*) {
        .text => |*d| {
          if (width < d.s.len) return false;
          width -= @intCast(d.s.len);
        },
        .line => |*d| {
          switch (d.ty) {
            .hard => return true,
            .soft => {
              // soft is "" in flat mode (len = 0)
              if (sm.mode == .split) {
                return true;
              }
            },
            .norm => {
              if (sm.mode == .split) {
                return true;
              } else {
                width -= 1;
              }
            },
            .chain => {
              // soft is "" in flat mode (len = 0)
              if (sm.mode == .split) {
                return true;
              }
            },
          }
        },
        .seq => |*d| {
          self.pushDocsToStack(d.docs, stack, sm.indent, sm.mode);
        },
        .indent => |*d| {
          self.pushDocsToStack(d.docs, stack, sm.indent+self.cfg.indent, sm.mode);
        },
        .group => |*d| {
          self.pushDocsToStack(d.docs, stack, sm.indent, sm.mode);
        },
        .ifsplit => |*d| {
          const _d = if (sm.mode == .split) d.split else d.flat;
          self.stackPush(stack, StackData.init(sm.indent, sm.mode, _d));
        }
      }
    }
    return false;
  }

  fn print(self: *Self, t: []const u8) void {
    _ = self.writer.write(t) catch unreachable;
  }

  fn printn(self: *Self, t: []const u8, n: usize) void {
    for (0..n) |_| {
      _ = self.writer.write(t) catch unreachable;
    }
  }

  pub fn fmt(self: *Self, d: *Doc) void {
    self.setWriter();
    defer self.writer.flush() catch {};
    var stack = Stack.initCapacity(self.al, 1) catch unreachable;
    self.stackPush(&stack, .{.indent = 0, .mode = .split, .doc = d});
    var column = @as(u32, 0);
    while (stack.items.len != 0) {
      const sm = stack.pop().?;
      switch (sm.doc.*) {
        .text => |*_d| {
          self.print(_d.s);
          column += @intCast(_d.s.len);
        },
        .line => |*_d| {
          switch (_d.ty) {
            .soft => {
              if (sm.mode == .split) {
                self.print("\n");
                self.printn(" ", sm.indent);
                column = @intCast(sm.indent);
              }
            },
            .chain => {
              if (sm.mode == .split) {
                self.print("\n");
                self.printn(" ", sm.indent);
                column = @intCast(sm.indent);
              }
            },
            .norm => {
              if (sm.mode == .flat) {
                self.print(" ");
                column += 1;
              } else {
                self.print("\n");
                self.printn(" ", sm.indent);
                column = @intCast(sm.indent);
              }
            },
            .hard => {
              self.print("\n");
              self.printn(" ", sm.indent);
              column = @intCast(sm.indent);
            },
          }
        },
        .seq => |*_d| {
          self.pushDocsToStack(_d.docs, &stack, sm.indent, sm.mode);
        },
        .indent => |*_d| {
          self.pushDocsToStack(_d.docs, &stack, sm.indent+self.cfg.indent, sm.mode);
        },
        .group => |*_d| {
          if (sm.mode == .flat) {
            self.pushDocsToStack(_d.docs, &stack, sm.indent, sm.mode);
          } else {
            var new = self.copyStack(&stack);
            self.copyDocsToStack(_d.docs, &new, sm.indent, .flat);
            if (self.fits(
                @as(i32, @intCast(self.cfg.width)) - @as(i32, @intCast(column)),
                &new
              ))
            {
              self.pushDocsToStack(_d.docs, &stack, sm.indent, .flat);
            } else {
              self.pushDocsToStack(_d.docs, &stack, sm.indent, .split);
              self.split_groups.put(self.al, _d.id, {}) catch unreachable;
            }
          }
        },
        .ifsplit => |*_d| {
          const mode: FitMode = (
            if (self.split_groups.get(_d.group) != null) .split
            else sm.mode
          );
          const _sm = StackData.init(
            sm.indent, mode,
            if (mode == .flat) _d.flat else _d.split,
          );
          self.stackPush(&stack, _sm);
        }
      }
    }
  }

  pub fn getFmtString(self: *Self) [] const u8 {
    switch (self.cfg.writer) {
      .mem => {
        var str = self.mem_writer.toArrayList().items;
        // FIXME: hack to remove trailing line
        if (str.len >= 2 and str[str.len - 1] == '\n') {
          return str[0..str.len - 1];
        }
        return str;
      },
      else => return "",
    }
  }
};
