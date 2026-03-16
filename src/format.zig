const std = @import("std");
const util = @import("util.zig");
pub const doc = @import("doc.zig");

const Allocator = std.mem.Allocator;
const DocList = doc.DocList;
const Doc = doc.Doc;

pub const FmtConfig = struct {
  max_width: u32 = 80,
  indent: u8 = 2,
};

pub const Format = struct {
  cfg: FmtConfig,
  split_groups: IDSet = .empty,
  al: Allocator,

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
    return .{.al = al, .cfg = cfg};
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
            }
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
    _ = self;
    std.debug.print("{s}", .{t});
  }

  fn printn(self: *Self, t: []const u8, n: usize) void {
    _ = self;
    for (0..n) |_| {
      std.debug.print("{s}", .{t});
    }
  }

  pub fn fmt(self: *Self, d: *Doc) void {
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
                @as(i32, @intCast(self.cfg.max_width)) - @as(i32, @intCast(column)),
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
};
