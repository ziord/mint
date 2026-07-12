const std = @import("std");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;
pub const DocList = std.ArrayList(*Doc);

pub const Text = struct {
  s: []const u8,
  /// if not null this text is a meta comment.
  /// In that case, true indicates formatting is
  /// on while false indicates formatting is off
  comment: ?bool = null,
};

pub const Seq = struct { docs: []*Doc };

pub const Group = struct { id: u32, docs: []*Doc };

pub const Line = struct {
  ty: Ty,

  pub const Ty = enum(u4) {
    /// adds a line only when we break,
    /// when we don't it's equiv to ""
    soft,
    /// always adds a line
    hard,
    /// adds a line only when we break,
    /// when we don't it's equiv to " "
    norm,
    /// acts like `soft` when fitting and like
    /// `hard` when printing, good for decl braces {}
    decl,

    pub fn str(self: Ty) []const u8 {
      return switch (self) {
        .soft => "<soft>",
        .hard => "<hard>",
        .norm => "<norm>",
        .decl => "<decl>",
      };
    }
  };
};

pub const IfSplit = struct {
  /// id of the group this node checks before splitting
  group: u32,
  split: *Doc,
  flat: *Doc,
};

pub const Doc = union(enum) {
  text: Text,
  line: Line,
  seq: Seq,
  indent: Seq,
  group: Group,
  ifsplit: IfSplit,

  pub fn new(value: Doc, al: Allocator) *Doc {
    const n = util.box(value, al);
    n.* = value;
    return n;
  }

  pub fn is(d: *const Doc, ty: anytype) bool {
    return d.* == ty;
  }

  pub fn isGroup(d: *const Doc) bool {
    return switch (d.*) {
      .group => true,
      else => false,
    };
  }
};

pub const SeqBuilder = struct {
  al: Allocator,
  docs: DocList = .empty,
  db: *DocBuilder,
  done: bool = false,

  pub fn init(al: Allocator, db: *DocBuilder) @This() {
    return .{ .al = al, .db = db };
  }

  pub inline fn _(self: *@This()) void {
    _ = self;
  }

  pub inline fn len(self: *@This()) usize {
    return self.docs.items.len;
  }

  pub inline fn isEmpty(self: *@This()) bool {
    return self.docs.items.len == 0;
  }

  pub inline fn isNotEmpty(self: *@This()) bool {
    return self.docs.items.len != 0;
  }

  pub fn copy(self: *@This()) @This() {
    var cpy = DocList.initCapacity(self.al, self.docs.items.len) catch unreachable;
    cpy.appendSliceAssumeCapacity(self.docs.items);
    return .{ .al = self.al, .docs = cpy, .db = self.db, .done = self.done };
  }

  pub fn text(self: *@This(), s: []const u8) *@This() {
    if (self.done) @panic("reusing a consumed builder!");
    const t = Doc.new(.{ .text = Text{ .s = s } }, self.al);
    util.listAppend(t, &self.docs, self.al);
    return self;
  }

  pub fn space(self: *@This()) *@This() {
    if (self.done) @panic("reusing a consumed builder!");
    const t = Doc.new(.{ .text = Text{ .s = " " } }, self.al);
    util.listAppend(t, &self.docs, self.al);
    return self;
  }

  pub fn spaceIf(self: *@This(), cond: bool) *@This() {
    return if (cond) self.space() else self;
  }

  pub inline fn line(self: *@This(), ty: Line.Ty) *@This() {
    if (self.done) @panic("reusing a consumed builder!");
    const l = Doc.new(.{ .line = Line{ .ty = ty } }, self.al);
    util.listAppend(l, &self.docs, self.al);
    return self;
  }

  pub fn softline(self: *@This()) *@This() {
    return self.line(.soft);
  }

  pub fn softlineIf(self: *@This(), cond: bool) *@This() {
    return if (cond) self.line(.soft) else self;
  }

  pub fn hardline(self: *@This()) *@This() {
    return self.line(.hard);
  }

  pub fn normline(self: *@This()) *@This() {
    return self.line(.norm);
  }

  pub fn declline(self: *@This()) *@This() {
    return self.line(.decl);
  }

  pub fn decllineOrSpace(self: *@This(), decl_cond: bool) void {
    if (decl_cond) {
      self.declline()._();
    } else {
      self.space()._();
    }
  }

  pub fn spaceOrDeclline(self: *@This(), space_cond: bool) void {
    if (space_cond) {
      self.space()._();
    } else {
      self.declline()._();
    }
  }

  pub fn decllineOrSoftline(self: *@This(), decl_cond: bool) void {
    if (decl_cond) {
      self.declline()._();
    } else {
      self.softline()._();
    }
  }

  pub fn softlineOrDeclline(self: *@This(), soft_cond: bool) void {
    if (soft_cond) {
      self.softline()._();
    } else {
      self.declline()._();
    }
  }

  pub fn decllineOrNormline(self: *@This(), decl_cond: bool) void {
    if (decl_cond) {
      self.declline()._();
    } else {
      self.normline()._();
    }
  }

  pub fn normlineOrDeclline(self: *@This(), norm_cond: bool) void {
    if (norm_cond) {
      self.normline()._();
    } else {
      self.declline()._();
    }
  }
  pub fn decllineIf(self: *@This(), cond: bool) *@This() {
    return if (cond) self.line(.decl) else self;
  }

  pub fn groupi(self: *@This(), id: u32, docs: []*Doc) *@This() {
    if (self.done) @panic("reusing a consumed builder!");
    const g = Doc.new(.{ .group = Group{ .id = id, .docs = docs } }, self.al);
    util.listAppend(g, &self.docs, self.al);
    return self;
  }

  pub fn indentOne(self: *@This(), doc: *Doc) *@This() {
    if (self.done) @panic("reusing a consumed builder!");
    var docs = util.allocSlice(*Doc, 1, self.db.al);
    docs[0] = doc;
    const i = Doc.new(.{ .indent = Seq{ .docs = docs } }, self.al);
    util.listAppend(i, &self.docs, self.al);
    return self;
  }

  pub fn indent(self: *@This(), docs: []*Doc) *@This() {
    if (self.done) @panic("reusing a consumed builder!");
    const i = Doc.new(.{ .indent = Seq{ .docs = docs } }, self.al);
    util.listAppend(i, &self.docs, self.al);
    return self;
  }

  pub fn ifsplit(self: *@This(), g: u32, split: *Doc, flat: *Doc) *@This() {
    if (self.done) @panic("reusing a consumed builder!");
    const i = Doc.new(
      .{ .ifsplit = IfSplit{ .group = g, .split = split, .flat = flat } },
      self.al,
    );
    util.listAppend(i, &self.docs, self.al);
    return self;
  }

  pub fn append(self: *@This(), d: *Doc) void {
    if (self.done) @panic("reusing a consumed builder!");
    util.listAppend(d, &self.docs, self.al);
  }

  pub fn extend(self: *@This(), docs: []*Doc) void {
    if (self.done) @panic("reusing a consumed builder!");
    util.listAppendSlice(*Doc, &self.docs, docs, self.al);
  }

  pub fn extends(self: *@This(), docs: []*Doc) *@This() {
    if (self.done) @panic("reusing a consumed builder!");
    util.listAppendSlice(*Doc, &self.docs, docs, self.al);
    return self;
  }

  pub fn appends(self: *@This(), d: *Doc) *@This() {
    if (self.done) @panic("reusing a consumed builder!");
    util.listAppend(d, &self.docs, self.al);
    return self;
  }

  pub fn clear(self: *@This()) void {
    self.docs.clearRetainingCapacity();
  }

  pub fn finish(self: *@This()) []*Doc {
    if (self.done) @panic("Builder already consumed");
    defer {
      self.done = true;
    }
    return self.docs.items;
  }

  pub fn finishSeq(self: *@This()) *Doc {
    if (self.done) @panic("Builder already consumed");
    defer {
      self.done = true;
    }
    return Doc.new(.{ .seq = Seq{ .docs = self.docs.items } }, self.al);
  }

  pub fn reset(self: *@This()) void {
    self.done = false;
    self.docs = .empty;
  }
};

pub const DocBuilder = struct {
  al: Allocator,
  /// stack allocated builders
  builders: [BUILDERS_LEN]SeqBuilder = undefined,
  /// builders stored on the heap
  heap_builders: std.ArrayList(*SeqBuilder) = .empty,
  len: usize = 0,

  const BUILDERS_LEN = 4096;

  pub fn init(al: Allocator) @This() {
    return .{ .al = al };
  }

  pub inline fn seqb(self: *@This()) *SeqBuilder {
    if (self.len >= BUILDERS_LEN) {
      // reuse a stack builder object if available
      for (0..BUILDERS_LEN) |i| {
        if (self.builders[i].done) {
          self.builders[i].reset();
          return &self.builders[i];
        }
      }
      // reuse a heap builder object if available
      for (self.heap_builders.items) |bd| {
        if (bd.done) {
          bd.reset();
          return bd;
        }
      }
      // allocate a builder object on the heap if we must
      const sb = util.box(SeqBuilder.init(self.al, self), self.al);
      util.listAppend(sb, &self.heap_builders, self.al);
      return sb;
    }
    self.builders[self.len] = SeqBuilder.init(self.al, self);
    self.len += 1;
    return &self.builders[self.len - 1];
  }

  pub fn text(self: *@This(), s: []const u8) *Doc {
    return Doc.new(.{ .text = Text{ .s = s } }, self.al);
  }

  pub fn space(self: *@This()) *Doc {
    return Doc.new(.{ .text = Text{ .s = " " } }, self.al);
  }

  pub fn line(self: *@This(), ty: Line.Ty) *Doc {
    return Doc.new(.{ .line = Line{ .ty = ty } }, self.al);
  }

  pub fn softline(self: *@This()) *Doc {
    return self.line(.soft);
  }

  pub fn hardline(self: *@This()) *Doc {
    return self.line(.hard);
  }

  pub fn normline(self: *@This()) *Doc {
    return self.line(.norm);
  }

  pub fn declline(self: *@This()) *Doc {
    return self.line(.decl);
  }

  pub fn seq(self: *@This(), docs: []*Doc) *Doc {
    return Doc.new(.{ .seq = Seq{ .docs = docs } }, self.al);
  }

  pub fn empty(self: *@This()) *Doc {
    return Doc.new(.{ .seq = Seq{ .docs = &.{} } }, self.al);
  }

  pub fn groupi(self: *@This(), id: u32, docs: []*Doc) *Doc {
    return Doc.new(.{ .group = Group{ .id = id, .docs = docs } }, self.al);
  }

  pub fn indent(self: *@This(), docs: []*Doc) *Doc {
    return Doc.new(.{ .indent = Seq{ .docs = docs } }, self.al);
  }

  pub fn ifsplit(self: *@This(), g: u32, split: *Doc, flat: *Doc) *Doc {
    return Doc.new(
      .{ .ifsplit = IfSplit{ .group = g, .split = split, .flat = flat } },
      self.al,
    );
  }

  pub inline fn resetBuilders(self: *@This()) void {
    self.len = 0;
    self.heap_builders.clearRetainingCapacity();
  }

  pub fn verify(self: *@This()) void {
    for (self.builders[0..self.len]) |bd| {
      if (!bd.done) {
        @panic("found unfinished builder!");
      }
    }
    for (self.heap_builders.items) |bd| {
      if (!bd.done) {
        @panic("found unfinished builder!");
      }
    }
  }
};
