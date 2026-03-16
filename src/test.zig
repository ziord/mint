const std = @import("std");
const fmt = @import("format.zig");
const ts = @import("translate.zig");
const OhSnap = @import("ohsnap");

const Allocator = std.mem.Allocator;

fn translate(src: [:0]const u8, al: Allocator) !*fmt.Doc {
  var t = try ts.Translate.init(src, al, .zig);
  return t.translate();
}

fn format(doc: *fmt.Doc, cfg: fmt.FmtConfig, al: Allocator) ![]const u8 {
  var f = fmt.Format.init(al, cfg);
  f.fmt(doc);
  return f.getFmtString();
}

test "vardecl 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\var x = foo(abc, bar, baz);
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  // default width: 80
  var res = try format(doc, .{.writer = .mem}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var x = foo(abc, bar, baz);
  ).diff(res, true);
  // using width: 10
  res = try format(doc, .{.writer = .mem, .width = 10}, al);
  try oh.snap(@src(),
    \\var x = foo(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
  ).diff(res, true);
}

test "vardecl 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ const y = box(abc, bar, baz,);
  \\ const a: ?Foo = box(abc, bar, baz);
  \\ const b: Foo = box(abc, bar, baz);
  \\ const c: [0xff]Foo = box(abc, bar, baz);
  \\ const d: [0xff:0]Foo = box(abc, bar, baz);
  \\ const e: *Foo = box(abc, bar, baz);
  \\ const f: [*]Foo = box(abc, bar, baz);
  \\ const f: [*c]Foo = box(abc, bar, baz);
  \\ const f: [*]Foo = box(abc, bar, baz);
  \\ const f: []Foo = box(abc, bar, baz);
  \\ const f: *[]Foo = box(abc, bar, baz);
  \\ const f: []Foo(Axe, Bxe, Cxe, Dxe, box()) = box(abc, bar, baz);
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  // default width: 80
  var res = try format(doc, .{.writer = .mem}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\const y = box(abc, bar, baz);
    \\const a: ?Foo = box(abc, bar, baz);
    \\const b: Foo = box(abc, bar, baz);
    \\const c: [0xff]Foo = box(abc, bar, baz);
    \\const d: [0xff:0]Foo = box(abc, bar, baz);
    \\const e: *Foo = box(abc, bar, baz);
    \\const f: [*]Foo = box(abc, bar, baz);
    \\const f: [*c]Foo = box(abc, bar, baz);
    \\const f: [*]Foo = box(abc, bar, baz);
    \\const f: []Foo = box(abc, bar, baz);
    \\const f: *[]Foo = box(abc, bar, baz);
    \\const f: []Foo(Axe, Bxe, Cxe, Dxe, box()) = box(abc, bar, baz);
  ).diff(res, true);
  // using width: 30
  res = try format(doc, .{.writer = .mem, .width = 30}, al);
  try oh.snap(@src(),
    \\const y = box(abc, bar, baz);
    \\const a: ?Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const b: Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const c: [0xff]Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const d: [0xff:0]Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const e: *Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: [*]Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: [*c]Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: [*]Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: []Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: *[]Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: []Foo(
    \\  Axe,
    \\  Bxe,
    \\  Cxe,
    \\  Dxe,
    \\  box(),
    \\) = box(abc, bar, baz);
  ).diff(res, true);
}

test "vardecl 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ const g: [*:Bar]Foo = box(abc, bar, baz);
  \\ const g: [*c:Bar]Foo = box(abc, bar, baz);
  \\ const g: [:Bar]Foo = box(abc, bar, baz);
  \\ const e: *const Foo = box(abc, bar, baz);
  \\ const f: [*]const Foo = box(abc, bar, baz);
  \\ const f: [*c]const Foo = box(abc, bar, baz);
  \\ const f: [*]const Foo = box(abc, bar, baz,);
  \\ var f: []const Foo = box(abc, bar, baz);
  \\ const f: *[]const Foo = box(abc, bar, baz);
  \\ const f: []const Foo(Axe, Bxe, Cxe, Dxe, box(),) = box(abc, bar, baz,);
  \\ const g: [*:Bar]const Foo = x.box(abc(), bar, baz);
  \\ const g: [*c:Bar] const Foo = box(abc, bar, baz);
  \\ const g: [:Bar] const Foo = box(abc, bar, baz);
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  // default width: 80
  var res = try format(doc, .{.writer = .mem}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\const g: [*:Bar]Foo = box(abc, bar, baz);
    \\const g: [:Bar]Foo = box(abc, bar, baz);
    \\const e: *const Foo = box(abc, bar, baz);
    \\const f: [*]const Foo = box(abc, bar, baz);
    \\const f: [*c]const Foo = box(abc, bar, baz);
    \\const f: [*]const Foo = box(abc, bar, baz);
    \\var f: []const Foo = box(abc, bar, baz);
    \\const f: *[]const Foo = box(abc, bar, baz);
    \\const f: []const Foo(Axe, Bxe, Cxe, Dxe, box()) = box(abc, bar, baz);
    \\const g: [*:Bar]const Foo = x.box(abc(), bar, baz);
    \\const Foo = box(abc, bar, baz);
    \\const g: [:Bar]const Foo = box(abc, bar, baz);
  ).diff(res, true);
  // using width: 60
  res = try format(doc, .{.writer = .mem, .width = 60}, al);
  try oh.snap(@src(),
    \\const g: [*:Bar]Foo = box(abc, bar, baz);
    \\const g: [:Bar]Foo = box(abc, bar, baz);
    \\const e: *const Foo = box(abc, bar, baz);
    \\const f: [*]const Foo = box(abc, bar, baz);
    \\const f: [*c]const Foo = box(abc, bar, baz);
    \\const f: [*]const Foo = box(abc, bar, baz);
    \\var f: []const Foo = box(abc, bar, baz);
    \\const f: *[]const Foo = box(abc, bar, baz);
    \\const f: []const Foo(Axe, Bxe, Cxe, Dxe, box()) = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const g: [*:Bar]const Foo = x.box(abc(), bar, baz);
    \\const Foo = box(abc, bar, baz);
    \\const g: [:Bar]const Foo = box(abc, bar, baz);
  ).diff(res, true);
  // using width: 30
  res = try format(doc, .{.writer = .mem, .width = 30}, al);
  try oh.snap(@src(),
    \\const g: [*:Bar]Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const g: [:Bar]Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const e: *const Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: [*]const Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: [*c]const Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: [*]const Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\var f: []const Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: *[]const Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const f: []const Foo(
    \\  Axe,
    \\  Bxe,
    \\  Cxe,
    \\  Dxe,
    \\  box(),
    \\) = box(abc, bar, baz);
    \\const g: [*:Bar]const Foo = x.box(
    \\    abc(),
    \\    bar,
    \\    baz,
    \\);
    \\const Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const g: [:Bar]const Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
  ).diff(res, true);
}

test "vardecl 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var xyz = foo.bar("ok").box();
  \\ var ky = self.group(self.seqb().text("Group(").indent(self.seqb().softline().text(id).text(",").normline().appends(_d).finish()).softline().text(")").finish());
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  // default width: 80
  var res = try format(doc, .{.writer = .mem}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var xyz = foo.bar("ok").box();
    \\var ky = self.group(
    \\    self
    \\      .seqb()
    \\      .text("Group(")
    \\      .indent(
    \\        self
    \\          .seqb()
    \\          .softline()
    \\          .text(id)
    \\          .text(",")
    \\          .normline()
    \\          .appends(_d)
    \\          .finish(),
    \\      )
    \\      .softline()
    \\      .text(")")
    \\      .finish(),
    \\);
  ).diff(res, true);
  // using width: 60
  res = try format(doc, .{.writer = .mem, .width = 60}, al);
  try oh.snap(@src(),
    \\var xyz = foo.bar("ok").box();
    \\var ky = self.group(
    \\    self
    \\      .seqb()
    \\      .text("Group(")
    \\      .indent(
    \\        self
    \\          .seqb()
    \\          .softline()
    \\          .text(id)
    \\          .text(",")
    \\          .normline()
    \\          .appends(_d)
    \\          .finish(),
    \\      )
    \\      .softline()
    \\      .text(")")
    \\      .finish(),
    \\);
  ).diff(res, true);
  // using width: 30
  res = try format(doc, .{.writer = .mem, .width = 30}, al);
  try oh.snap(@src(),
    \\var xyz = foo.bar("ok").box();
    \\var ky = self.group(
    \\    self
    \\      .seqb()
    \\      .text("Group(")
    \\      .indent(
    \\        self
    \\          .seqb()
    \\          .softline()
    \\          .text(id)
    \\          .text(",")
    \\          .normline()
    \\          .appends(_d)
    \\          .finish(),
    \\      )
    \\      .softline()
    \\      .text(")")
    \\      .finish(),
    \\);
  ).diff(res, true);
}

test "vardecl 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var ky = self.group(self.seqb() .text("Group(") .indent(self.seqb().softline() .text(id) .text(",") .normline() .appends(_d).finish() ) .softline().text(")").finish());
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  // default width: 80
  var res = try format(doc, .{.writer = .mem}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var ky = self.group(
    \\    self
    \\      .seqb()
    \\      .text("Group(")
    \\      .indent(
    \\        self
    \\          .seqb()
    \\          .softline()
    \\          .text(id)
    \\          .text(",")
    \\          .normline()
    \\          .appends(_d)
    \\          .finish(),
    \\      )
    \\      .softline()
    \\      .text(")")
    \\      .finish(),
    \\);
  ).diff(res, true);
  // using width: 60
  res = try format(doc, .{.writer = .mem, .width = 60}, al);
  try oh.snap(@src(),
    \\var ky = self.group(
    \\    self
    \\      .seqb()
    \\      .text("Group(")
    \\      .indent(
    \\        self
    \\          .seqb()
    \\          .softline()
    \\          .text(id)
    \\          .text(",")
    \\          .normline()
    \\          .appends(_d)
    \\          .finish(),
    \\      )
    \\      .softline()
    \\      .text(")")
    \\      .finish(),
    \\);
  ).diff(res, true);
  // using width: 30
  res = try format(doc, .{.writer = .mem, .width = 30}, al);
  try oh.snap(@src(),
    \\var ky = self.group(
    \\    self
    \\      .seqb()
    \\      .text("Group(")
    \\      .indent(
    \\        self
    \\          .seqb()
    \\          .softline()
    \\          .text(id)
    \\          .text(",")
    \\          .normline()
    \\          .appends(_d)
    \\          .finish(),
    \\      )
    \\      .softline()
    \\      .text(")")
    \\      .finish(),
    \\);
  ).diff(res, true);
}

test "vardecl 6" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var ky = self.group(
  \\          self.seqb()
  \\           .text("Group(").indent(self.seqb()
  \\              .softline()
  \\              .text(id)
  \\              .text(",")
  \\              .normline()
  \\              .appends(_d).finish(), self.seqb()
  \\               .text("IfSplit(").indent(
  \\                 self.seqb()
  \\                   .softline()
  \\                   .text(id)
  \\                   .text(",")
  \\                   .normline()
  \\                   .appends(_ds)
  \\                   .text(",")
  \\                   .normline()
  \\                   .appends(_df)
  \\                   .finish()))
  \\           .softline()
  \\           .text(")")
  \\           .finish()
  \\         );
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  // default width: 80
  var res = try format(doc, .{.writer = .mem}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var ky = self.group(
    \\    self
    \\      .seqb()
    \\      .text("Group(")
    \\      .indent(
    \\        self
    \\          .seqb()
    \\          .softline()
    \\          .text(id)
    \\          .text(",")
    \\          .normline()
    \\          .appends(_d)
    \\          .finish(),
    \\        self
    \\          .seqb()
    \\          .text("IfSplit(")
    \\          .indent(
    \\            self
    \\              .seqb()
    \\              .softline()
    \\              .text(id)
    \\              .text(",")
    \\              .normline()
    \\              .appends(_ds)
    \\              .text(",")
    \\              .normline()
    \\              .appends(_df)
    \\              .finish(),
    \\          ),
    \\      )
    \\      .softline()
    \\      .text(")")
    \\      .finish(),
    \\);
  ).diff(res, true);
  // using width: 60
  res = try format(doc, .{.writer = .mem, .width = 60}, al);
  try oh.snap(@src(),
    \\var ky = self.group(
    \\    self
    \\      .seqb()
    \\      .text("Group(")
    \\      .indent(
    \\        self
    \\          .seqb()
    \\          .softline()
    \\          .text(id)
    \\          .text(",")
    \\          .normline()
    \\          .appends(_d)
    \\          .finish(),
    \\        self
    \\          .seqb()
    \\          .text("IfSplit(")
    \\          .indent(
    \\            self
    \\              .seqb()
    \\              .softline()
    \\              .text(id)
    \\              .text(",")
    \\              .normline()
    \\              .appends(_ds)
    \\              .text(",")
    \\              .normline()
    \\              .appends(_df)
    \\              .finish(),
    \\          ),
    \\      )
    \\      .softline()
    \\      .text(")")
    \\      .finish(),
    \\);
  ).diff(res, true);
  // using width: 30
  res = try format(doc, .{.writer = .mem, .width = 30}, al);
  try oh.snap(@src(),
    \\var ky = self.group(
    \\    self
    \\      .seqb()
    \\      .text("Group(")
    \\      .indent(
    \\        self
    \\          .seqb()
    \\          .softline()
    \\          .text(id)
    \\          .text(",")
    \\          .normline()
    \\          .appends(_d)
    \\          .finish(),
    \\        self
    \\          .seqb()
    \\          .text("IfSplit(")
    \\          .indent(
    \\            self
    \\              .seqb()
    \\              .softline()
    \\              .text(id)
    \\              .text(",")
    \\              .normline()
    \\              .appends(_ds)
    \\              .text(",")
    \\              .normline()
    \\              .appends(_df)
    \\              .finish(),
    \\          ),
    \\      )
    \\      .softline()
    \\      .text(")")
    \\      .finish(),
    \\);
  ).diff(res, true);
}

test "vardecl 7" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var sb = self.db.seqb().appends(lhs) 
  \\          .sb.ifsplit(
  \\            id,
  \\            self.db.indent(
  \\              self.db.seqb().softline()
  \\              .text(".")
  \\              .text(self._token(rhs))
  \\              .finish()
  \\            ),
  \\            self.db.seqb().text(".").text(self._token(rhs)).finish(),
  \\          )._();
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  // default width: 80
  var res = try format(doc, .{.writer = .mem}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var sb = self
    \\  .db
    \\  .seqb()
    \\  .appends(lhs)
    \\  .sb
    \\  .ifsplit(
    \\    id,
    \\    self
    \\      .db
    \\      .indent(
    \\        self.db.seqb().softline().text(".").text(self._token(rhs)).finish(),
    \\      ),
    \\    self.db.seqb().text(".").text(self._token(rhs)).finish(),
    \\  )
    \\  ._();
  ).diff(res, true);
  // using width: 60
  res = try format(doc, .{.writer = .mem, .width = 60}, al);
  try oh.snap(@src(),
    \\var sb = self
    \\  .db
    \\  .seqb()
    \\  .appends(lhs)
    \\  .sb
    \\  .ifsplit(
    \\    id,
    \\    self
    \\      .db
    \\      .indent(
    \\        self
    \\          .db
    \\          .seqb()
    \\          .softline()
    \\          .text(".")
    \\          .text(self._token(rhs))
    \\          .finish(),
    \\      ),
    \\    self
    \\      .db
    \\      .seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  ).diff(res, true);
  // using width: 30
  res = try format(doc, .{.writer = .mem, .width = 30}, al);
  try oh.snap(@src(),
    \\var sb = self
    \\  .db
    \\  .seqb()
    \\  .appends(lhs)
    \\  .sb
    \\  .ifsplit(
    \\    id,
    \\    self
    \\      .db
    \\      .indent(
    \\        self
    \\          .db
    \\          .seqb()
    \\          .softline()
    \\          .text(".")
    \\          .text(
    \\            self._token(rhs),
    \\          )
    \\          .finish(),
    \\      ),
    \\    self
    \\      .db
    \\      .seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  ).diff(res, true);
}

test "vardecl 8" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var sb = self.db.seqb().appends(lhs);
  \\ var sb = selfseqbseqbseqbseqbseqbseqbseqbseqb();
  \\ var ky = selfgroup(selfseqb(),text("Group("),indent(  selfseqb(),  softline(),  text(id),  text(","), normline(), appends(_d, finish()), selfseqb(), text("IfSplit(", selfseqb()), indent( selfseqb(),   softline(),   text(id), text(","), normline(), appends(_ds), text(","), normline(), appends(_df), finish()), ),softline(),text(")"),finish());
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  // default width: 80
  var res = try format(doc, .{.writer = .mem}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var sb = self.db.seqb().appends(lhs);
    \\var sb = selfseqbseqbseqbseqbseqbseqbseqbseqb();
    \\var ky = selfgroup(
    \\  selfseqb(),
    \\  text("Group("),
    \\  indent(
    \\    selfseqb(),
    \\    softline(),
    \\    text(id),
    \\    text(","),
    \\    normline(),
    \\    appends(_d, finish()),
    \\    selfseqb(),
    \\    text("IfSplit(", selfseqb()),
    \\    indent(
    \\      selfseqb(),
    \\      softline(),
    \\      text(id),
    \\      text(","),
    \\      normline(),
    \\      appends(_ds),
    \\      text(","),
    \\      normline(),
    \\      appends(_df),
    \\      finish(),
    \\    ),
    \\  ),
    \\  softline(),
    \\  text(")"),
    \\  finish(),
    \\);
  ).diff(res, true);
  // using width: 60
  res = try format(doc, .{.writer = .mem, .width = 60}, al);
  try oh.snap(@src(),
    \\var sb = self.db.seqb().appends(lhs);
    \\var sb = selfseqbseqbseqbseqbseqbseqbseqbseqb();
    \\var ky = selfgroup(
    \\  selfseqb(),
    \\  text("Group("),
    \\  indent(
    \\    selfseqb(),
    \\    softline(),
    \\    text(id),
    \\    text(","),
    \\    normline(),
    \\    appends(_d, finish()),
    \\    selfseqb(),
    \\    text("IfSplit(", selfseqb()),
    \\    indent(
    \\      selfseqb(),
    \\      softline(),
    \\      text(id),
    \\      text(","),
    \\      normline(),
    \\      appends(_ds),
    \\      text(","),
    \\      normline(),
    \\      appends(_df),
    \\      finish(),
    \\    ),
    \\  ),
    \\  softline(),
    \\  text(")"),
    \\  finish(),
    \\);
  ).diff(res, true);
  // using width: 30
  res = try format(doc, .{.writer = .mem, .width = 30}, al);
  try oh.snap(@src(),
    \\var sb = self
    \\  .db
    \\  .seqb()
    \\  .appends(lhs);
    \\var sb = selfseqbseqbseqbseqbseqbseqbseqbseqb();
    \\var ky = selfgroup(
    \\  selfseqb(),
    \\  text("Group("),
    \\  indent(
    \\    selfseqb(),
    \\    softline(),
    \\    text(id),
    \\    text(","),
    \\    normline(),
    \\    appends(_d, finish()),
    \\    selfseqb(),
    \\    text(
    \\      "IfSplit(",
    \\      selfseqb(),
    \\    ),
    \\    indent(
    \\      selfseqb(),
    \\      softline(),
    \\      text(id),
    \\      text(","),
    \\      normline(),
    \\      appends(_ds),
    \\      text(","),
    \\      normline(),
    \\      appends(_df),
    \\      finish(),
    \\    ),
    \\  ),
    \\  softline(),
    \\  text(")"),
    \\  finish(),
    \\);
  ).diff(res, true);
}

test "vardecl 9" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var q = fox()().hahah(a, b, "yes").bar(abc());
  \\ var q = fox()().hahah(a, b, "yes").bar(compute_something(long_arg1, long_arg2));
  \\ var q = fox()().hahah(a, b, "yes").bar(compute_something(long_arg1, xlong_arg2));
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  // default width: 80
  var res = try format(doc, .{.writer = .mem}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var q = fox()().hahah(a, b, "yes").bar(abc());
    \\var q = fox()().hahah(a, b, "yes").bar(compute_something(long_arg1, long_arg2));
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(
    \\    compute_something(long_arg1, xlong_arg2),
    \\);
  ).diff(res, true);
  // using width: 60
  res = try format(doc, .{.writer = .mem, .width = 60}, al);
  try oh.snap(@src(),
    \\var q = fox()().hahah(a, b, "yes").bar(abc());
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(
    \\    compute_something(long_arg1, long_arg2),
    \\);
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(
    \\    compute_something(long_arg1, xlong_arg2),
    \\);
  ).diff(res, true);
  // using width: 30
  res = try format(doc, .{.writer = .mem, .width = 30}, al);
  try oh.snap(@src(),
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(abc());
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(
    \\    compute_something(
    \\      long_arg1,
    \\      long_arg2,
    \\    ),
    \\);
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(
    \\    compute_something(
    \\      long_arg1,
    \\      xlong_arg2,
    \\    ),
    \\);
  ).diff(res, true);
}
