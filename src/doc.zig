const std = @import("std");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;
pub const DocList = std.ArrayList(*Doc);

pub const Text = struct {
  s: []const u8,
};

pub const Seq = struct {
  docs: []*Doc,
};

pub const Group = struct {
  id: u32,
  docs: []*Doc,
};

pub const Line = struct {
  ty: Ty,

  pub const Ty = enum (u4) {
    soft, hard, norm, chain,
    pub fn str(self: Ty) []const u8 {
      return switch (self) {
        .soft => "<soft>",
        .hard => "<hard>",
        .norm => "<norm>",
        .chain => "<chain>",
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

  pub fn isChainLine(d: *const Doc) bool {
    return switch (d.*) {
      .line => |l| {
        return l.ty == .chain;
      },
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
    return .{.al = al, .db = db};
  }

  pub inline fn _(self: *@This()) void {
    _ = self;
  }

  pub fn copy(self: *@This()) @This() {
    var cpy = DocList.initCapacity(self.al, self.docs.items.len) catch unreachable;
    cpy.appendSliceAssumeCapacity(self.docs.items);
    return .{.al = self.al, .docs = cpy, .db = self.db};
  }

  pub fn text(self: *@This(), s: []const u8) *@This() {
    const t = Doc.new(.{.text = Text{.s = s}}, self.al);
    util.listAppend(t, &self.docs, self.al);
    return self;
  }

  pub fn space(self: *@This()) *@This() {
    const t = Doc.new(.{.text = Text{.s = " "}}, self.al);
    util.listAppend(t, &self.docs, self.al);
    return self;
  }

  pub inline fn line(self: *@This(), ty: Line.Ty) *@This() {
    const l = Doc.new(.{.line = Line{.ty = ty}}, self.al);
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

  pub fn chainline(self: *@This()) *@This() {
    return self.line(.chain);
  }

  pub fn group(self: *@This(), docs: []*Doc) *@This() {
    const g = Doc.new(.{.group = Group{.id = getID(), .docs = docs}}, self.al);
    util.listAppend(g, &self.docs, self.al);
    return self;
  }

  pub fn groupi(self: *@This(), id: u32, docs: []*Doc) *@This() {
    const g = Doc.new(.{.group = Group{.id = id, .docs = docs}}, self.al);
    util.listAppend(g, &self.docs, self.al);
    return self;
  }

  pub fn indent(self: *@This(), docs: []*Doc) *@This() {
    const i = Doc.new(.{.indent = Seq{.docs = docs}}, self.al);
    util.listAppend(i, &self.docs, self.al);
    return self;
  }

  pub fn ifsplit(self: *@This(), g: u32, split: *Doc, flat: *Doc) *@This() {
    const i = Doc.new(
      .{.ifsplit = IfSplit{.group = g, .split = split, .flat = flat}},
      self.al,
    );
    util.listAppend(i, &self.docs, self.al);
    return self;
  }

  pub fn append(self: *@This(), d: *Doc) void {
    util.listAppend(d, &self.docs, self.al);
  }

  pub fn extend(self: *@This(), docs: []*Doc) void {
    util.listAppendSlice(*Doc, docs, &self.docs, self.al);
  }

  pub fn extends(self: *@This(), docs: []*Doc) *@This() {
    util.listAppendSlice(*Doc, docs, &self.docs, self.al);
    return self;
  }

  pub fn appends(self: *@This(), d: *Doc) *@This() {
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
    return Doc.new(.{.seq = Seq{.docs = self.docs.items}}, self.al);
  }
};

var group_ids: u32 = 0;

fn getID() u32 {
  const id = group_ids;
  group_ids += 1;
  return id;
}

pub inline fn genGroupID() u32 {
  return getID();
}

pub inline fn getNextGroupID() u32 {
  return group_ids + 1;
}

pub inline fn getCurrentGroupID() u32 {
  return group_ids;
}

pub const DocBuilder = struct {
  al: Allocator,
  builders: [BUILDERS_LEN]SeqBuilder = undefined,
  len: usize = 0,

  const BUILDERS_LEN = 4096;

  pub fn init(al: Allocator) @This() {
    return .{.al = al};
  }

  pub inline fn seqb(self: *@This()) *SeqBuilder {
    if (self.len >= BUILDERS_LEN) @panic("Too many builders, max exceeded");
    self.builders[self.len] = SeqBuilder.init(self.al, self);
    self.len += 1;
    return &self.builders[self.len - 1];
  }

  pub fn copySeqb(self: *@This(), sb: *SeqBuilder) *SeqBuilder {
    if (self.len >= BUILDERS_LEN) @panic("Too many builders, max exceeded");
    self.builders[self.len] = sb.copy();
    self.len += 1;
    return &self.builders[self.len - 1];
  }

  pub fn text(self: *@This(), s: []const u8) *Doc {
    return Doc.new(.{.text = Text{.s = s}}, self.al);
  }

  pub fn space(self: *@This()) *Doc {
    return Doc.new(.{.text = Text{.s = " "}}, self.al);
  }

  pub fn line(self: *@This(), ty: Line.Ty) *Doc {
    return Doc.new(.{.line = Line{.ty = ty}}, self.al);
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

  pub fn seq(self: *@This(), docs: []*Doc) *Doc {
    return Doc.new(.{.seq = Seq{.docs = docs}}, self.al);
  }

  pub fn group(self: *@This(), docs: []*Doc) *Doc {
    return Doc.new(.{.group = Group{.id = getID(), .docs = docs}}, self.al);
  }

  pub fn groupi(self: *@This(), id: u32, docs: []*Doc) *Doc {
    return Doc.new(.{.group = Group{.id = id, .docs = docs}}, self.al);
  }

  pub fn indent(self: *@This(), docs: []*Doc) *Doc {
    return Doc.new(.{.indent = Seq{.docs = docs}}, self.al);
  }

  pub fn ifsplit(self: *@This(), g: u32, split: *Doc, flat: *Doc) *Doc {
    return Doc.new(
      .{.ifsplit = IfSplit{.group = g, .split = split, .flat = flat}},
      self.al,
    );
  }

  pub fn verify(self: *@This()) void {
    for (self.builders[0..self.len]) |bd| {
      if (!bd.done) {
        @panic("found unfinished builder!");
      }
    }
  }

  pub fn dbg(self: *@This(), doc: *Doc) *Doc {
    switch (doc.*) {
      .text => |*d| {
        return self.group(
          self.seqb()
            .text("Text(")
            .indent(self.seqb().softline().text("\"").text(d.s).text("\"").finish())
            .softline()
            .text(")")
            .finish()
          );
      },
      .line => |*d| {
        return self.group(
          self.seqb()
           .text("Line(")
           .indent(self.seqb().softline().text(d.ty.str()).finish())
           .softline()
           .text(")")
           .finish()
        );
      },
      .seq => |*d| {
        var sb1 = self.seqb().text("Seq([");
        if (d.docs.len > 0) {
          var sb2 = self.seqb().softline();
          for (d.docs, 0..) |_d, i| {
            sb2.append(self.dbg(_d));
            if (i < d.docs.len - 1) {
              sb2.text(",").normline()._();
            }
          }
          sb1.indent(sb2.finish()).softline().text("])")._();
        } else {
          sb1.text("])")._();
        }
        return self.group(sb1.finish());
      },
      .indent => |*d| {
        return self.group(
          self.seqb()
           .text("Indent(")
           .indent(self.seqb().softline().extends(d.docs).finish())
           .softline()
           .text(")")
           .finish()
         );
      },
      .group => |*d| {
        const id = std.fmt.allocPrint(self.al, "{}", .{d.id}) catch unreachable;
        return self.group(
          self.seqb()
           .text("Group(")
           .indent(
             self.seqb()
              .softline()
              .text(id)
              .text(",")
              .normline()
              .extends(d.docs).finish()
           )
           .softline()
           .text(")")
           .finish()
         );
      },
      .ifsplit => |*d| {
        const id = std.fmt.allocPrint(self.al, "{}", .{d.group}) catch unreachable;
        const _ds = self.dbg(d.split);
        const _df = self.dbg(d.flat);
        return self.group(
          self.seqb()
           .text("IfSplit(")
           .indent(
             self.seqb()
              .softline()
              .text(id)
              .text(",")
              .normline()
              .appends(_ds)
              .text(",")
              .normline()
              .appends(_df)
              .finish()
           )
           .softline()
           .text(")")
           .finish()
         );
      }
    }
  }
};
