const std = @import("std");
const fmt = @import("format.zig");
const ts = @import("translate.zig");
const OhSnap = @import("ohsnap");

const Allocator = std.mem.Allocator;

fn format(src: [:0]const u8, cfg: fmt.FmtConfig, al: Allocator) ![]const u8 {
  var t = try ts.Translate.init(src, al, .zig, cfg);
  const doc = try t.translate();
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
  // default width: 80
  var res = try format(src, .{}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var x = foo(abc, bar, baz);
  ).diff(res, true);
  // using width: 10
  res = try format(src, .{.width = 10}, al);
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
  // default width: 80
  var res = try format(src, .{}, al);
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
  res = try format(src, .{.width = 30}, al);
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
  // default width: 80
  var res = try format(src, .{}, al);
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
  res = try format(src, .{.width = 60}, al);
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
  res = try format(src, .{.width = 30}, al);
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
    \\const g: [*:Bar]const Foo = x.box(abc(), bar, baz);
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
  \\var buffer: [1024]u8 align(64) addrspace(.generic) linksection(".my_custom_section") = undefined;
  \\const buffer: [1024]u8 align(64) addrspace(.generic) linksection(".my_custom_section") = text(self.token_token_token_token_token_token_token_token_token_token(rhs, abc, lhs));
  \\const buffer: [1024]u8 align(64) addrspace(.generic) linksection(".my_custom_section") = text(self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs));
  \\var buffer align(64) addrspace(.generic) linksection(".my_custom_section") = undefined;
  \\var buffer align(64) linksection(".my_custom_section") = text(self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs));
  ;
  const al = arena.allocator();
  // default width: 80
  var res = try format(src, .{}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\const buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token_token_token_token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\const buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var buffer
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\var buffer
    \\  align(64)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
  ).diff(res, true);
  // using width: 100
  res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\var buffer: [1024]u8 align(64) addrspace(.generic) linksection(".my_custom_section") = undefined;
    \\const buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token_token_token_token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\const buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var buffer align(64) addrspace(.generic) linksection(".my_custom_section") = undefined;
    \\var buffer
    \\  align(64)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs),
    \\);
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\var buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\const buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token_token_token_token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\const buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\var buffer
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\var buffer
    \\  align(64)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\const buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token_token_token_token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\const buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\var buffer
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\var buffer
    \\  align(64)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
  ).diff(res, true);
}

test "vardecl 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\const buffer: [1024]u8 align(64) = text(self.token_token_token_token_token_token_token_token_token_token(rhs, abc, lhs));
  \\const buffer: [1024]u8 align(64) = text(self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs));
  \\var buffer align(64) = undefined;
  \\var buffer align(64) = text(self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs));
  \\var a align(b) = c;
  \\var a: b align(c) = d;
  ;
  const al = arena.allocator();
  // default width: 80
  var res = try format(src, .{}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\const buffer: [1024]u8
    \\  align(64) = text(
    \\  self.token_token_token_token_token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\const buffer: [1024]u8
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var buffer align(64) = undefined;
    \\var buffer
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var a align(b) = c;
    \\var a: b align(c) = d;
  ).diff(res, true);
  // using width: 100
  res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\const buffer: [1024]u8
    \\  align(64) = text(self.token_token_token_token_token_token_token_token_token_token(rhs, abc, lhs));
    \\const buffer: [1024]u8
    \\  align(64) = text(
    \\  self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var buffer align(64) = undefined;
    \\var buffer
    \\  align(64) = text(
    \\  self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var a align(b) = c;
    \\var a: b align(c) = d;
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\const buffer: [1024]u8
    \\  align(64) = text(
    \\  self.token_token_token_token_token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\const buffer: [1024]u8
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\var buffer align(64) = undefined;
    \\var buffer
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\var a align(b) = c;
    \\var a: b align(c) = d;
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\const buffer: [1024]u8
    \\  align(64) = text(
    \\  self.token_token_token_token_token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\const buffer: [1024]u8
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\var buffer
    \\  align(64) = undefined;
    \\var buffer
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\  .token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\var a align(b) = c;
    \\var a: b align(c) = d;
  ).diff(res, true);
}

test "vardecl 6" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ threadlocal const x = expr;
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // default width: 80
  const res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\threadlocal const x = expr;
  ).diff(res, true);
}
test "vardecl.chains 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var xyz = foo.bar("ok").box();
  \\ var ky = self.group(self.seqb().text("Group(").indent(self.seqb().softline().text(id).text(",").normline().appends(_d).finish()).softline().text(")").finish());
  ;
  const al = arena.allocator();
  // default width: 80
  var res = try format(src, .{}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var xyz = foo.bar("ok").box();
    \\var ky = self.group(
    \\  self.seqb()
    \\  .text("Group(")
    \\  .indent(
    \\    self.seqb()
    \\    .softline()
    \\    .text(id)
    \\    .text(",")
    \\    .normline()
    \\    .appends(_d)
    \\    .finish(),
    \\  )
    \\  .softline()
    \\  .text(")")
    \\  .finish(),
    \\);
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\var xyz = foo.bar("ok").box();
    \\var ky = self.group(
    \\  self.seqb()
    \\  .text("Group(")
    \\  .indent(
    \\    self.seqb()
    \\    .softline()
    \\    .text(id)
    \\    .text(",")
    \\    .normline()
    \\    .appends(_d)
    \\    .finish(),
    \\  )
    \\  .softline()
    \\  .text(")")
    \\  .finish(),
    \\);
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var xyz = foo.bar("ok").box();
    \\var ky = self.group(
    \\  self.seqb()
    \\  .text("Group(")
    \\  .indent(
    \\    self.seqb()
    \\    .softline()
    \\    .text(id)
    \\    .text(",")
    \\    .normline()
    \\    .appends(_d)
    \\    .finish(),
    \\  )
    \\  .softline()
    \\  .text(")")
    \\  .finish(),
    \\);
  ).diff(res, true);
}

test "vardecl.chains 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var ky = self.group(self.seqb() .text("Group(") .indent(self.seqb().softline() .text(id) .text(",") .normline() .appends(_d).finish() ) .softline().text(")").finish());
  ;
  const al = arena.allocator();
  // default width: 80
  var res = try format(src, .{}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var ky = self.group(
    \\  self.seqb()
    \\  .text("Group(")
    \\  .indent(
    \\    self.seqb()
    \\    .softline()
    \\    .text(id)
    \\    .text(",")
    \\    .normline()
    \\    .appends(_d)
    \\    .finish(),
    \\  )
    \\  .softline()
    \\  .text(")")
    \\  .finish(),
    \\);
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\var ky = self.group(
    \\  self.seqb()
    \\  .text("Group(")
    \\  .indent(
    \\    self.seqb()
    \\    .softline()
    \\    .text(id)
    \\    .text(",")
    \\    .normline()
    \\    .appends(_d)
    \\    .finish(),
    \\  )
    \\  .softline()
    \\  .text(")")
    \\  .finish(),
    \\);
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var ky = self.group(
    \\  self.seqb()
    \\  .text("Group(")
    \\  .indent(
    \\    self.seqb()
    \\    .softline()
    \\    .text(id)
    \\    .text(",")
    \\    .normline()
    \\    .appends(_d)
    \\    .finish(),
    \\  )
    \\  .softline()
    \\  .text(")")
    \\  .finish(),
    \\);
  ).diff(res, true);
}

test "vardecl.chains 3" {
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
  // default width: 80
  var res = try format(src, .{}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var ky = self.group(
    \\  self.seqb()
    \\  .text("Group(")
    \\  .indent(
    \\    self.seqb()
    \\    .softline()
    \\    .text(id)
    \\    .text(",")
    \\    .normline()
    \\    .appends(_d)
    \\    .finish(),
    \\    self.seqb()
    \\    .text("IfSplit(")
    \\    .indent(
    \\      self.seqb()
    \\      .softline()
    \\      .text(id)
    \\      .text(",")
    \\      .normline()
    \\      .appends(_ds)
    \\      .text(",")
    \\      .normline()
    \\      .appends(_df)
    \\      .finish(),
    \\    ),
    \\  )
    \\  .softline()
    \\  .text(")")
    \\  .finish(),
    \\);
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\var ky = self.group(
    \\  self.seqb()
    \\  .text("Group(")
    \\  .indent(
    \\    self.seqb()
    \\    .softline()
    \\    .text(id)
    \\    .text(",")
    \\    .normline()
    \\    .appends(_d)
    \\    .finish(),
    \\    self.seqb()
    \\    .text("IfSplit(")
    \\    .indent(
    \\      self.seqb()
    \\      .softline()
    \\      .text(id)
    \\      .text(",")
    \\      .normline()
    \\      .appends(_ds)
    \\      .text(",")
    \\      .normline()
    \\      .appends(_df)
    \\      .finish(),
    \\    ),
    \\  )
    \\  .softline()
    \\  .text(")")
    \\  .finish(),
    \\);
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var ky = self.group(
    \\  self.seqb()
    \\  .text("Group(")
    \\  .indent(
    \\    self.seqb()
    \\    .softline()
    \\    .text(id)
    \\    .text(",")
    \\    .normline()
    \\    .appends(_d)
    \\    .finish(),
    \\    self.seqb()
    \\    .text("IfSplit(")
    \\    .indent(
    \\      self.seqb()
    \\      .softline()
    \\      .text(id)
    \\      .text(",")
    \\      .normline()
    \\      .appends(_ds)
    \\      .text(",")
    \\      .normline()
    \\      .appends(_df)
    \\      .finish(),
    \\    ),
    \\  )
    \\  .softline()
    \\  .text(")")
    \\  .finish(),
    \\);
  ).diff(res, true);
}

test "vardecl.chains 4" {
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
  // default width: 80
  var res = try format(src, .{}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var sb = self.db.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\  self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\var sb = self.db.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\  self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var sb = self.db.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\  self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
}

test "vardecl.chains 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var sb = self.db.seqb().appends(lhs);
  \\ var sb = selfseqbseqbseqbseqbseqbseqbseqbseqb();
  \\ var ky = selfgroup(selfseqb(),text("Group("),indent(  selfseqb(),  softline(),  text(id),  text(","), normline(), appends(_d, finish()), selfseqb(), text("IfSplit(", selfseqb()), indent( selfseqb(),   softline(),   text(id), text(","), normline(), appends(_ds), text(","), normline(), appends(_df), finish()), ),softline(),text(")"),finish());
  ;
  const al = arena.allocator();
  // default width: 80
  var res = try format(src, .{}, al);
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
  res = try format(src, .{.width = 60}, al);
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
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var sb = self.db.seqb()
    \\.appends(lhs);
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

test "vardecl.chains 6" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var q = fox()().hahah(a, b, "yes").bar(abc());
  \\ var q = fox()().hahah(a, b, "yes").bar(compute_something(long_arg1, long_arg2));
  \\ var q = fox()().hahah(a, b, "yes").bar(compute_something(long_arg1, xlong_arg2));
  ;
  const al = arena.allocator();
  // default width: 80
  var res = try format(src, .{}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var q = fox()().hahah(a, b, "yes").bar(abc());
    \\var q = fox()().hahah(a, b, "yes").bar(compute_something(long_arg1, long_arg2));
    \\var q = fox()()
    \\.hahah(a, b, "yes")
    \\.bar(compute_something(long_arg1, xlong_arg2));
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\var q = fox()().hahah(a, b, "yes").bar(abc());
    \\var q = fox()()
    \\.hahah(a, b, "yes")
    \\.bar(compute_something(long_arg1, long_arg2));
    \\var q = fox()()
    \\.hahah(a, b, "yes")
    \\.bar(compute_something(long_arg1, xlong_arg2));
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var q = fox()()
    \\.hahah(a, b, "yes")
    \\.bar(abc());
    \\var q = fox()()
    \\.hahah(a, b, "yes")
    \\.bar(
    \\  compute_something(
    \\    long_arg1,
    \\    long_arg2,
    \\  ),
    \\);
    \\var q = fox()()
    \\.hahah(a, b, "yes")
    \\.bar(
    \\  compute_something(
    \\    long_arg1,
    \\    xlong_arg2,
    \\  ),
    \\);
  ).diff(res, true);
}

test "vardecl.chains 7" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var sb = self.db.seqb().appends(compute_value(lhs, rhs));
  ;
  const al = arena.allocator();
  // default width: 80
  var res = try format(src, .{}, al);
  const oh = OhSnap{};
  try oh.snap(@src(),
    \\var sb = self.db.seqb().appends(compute_value(lhs, rhs));
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\var sb = self.db.seqb().appends(compute_value(lhs, rhs));
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var sb = self.db.seqb()
    \\.appends(
    \\  compute_value(lhs, rhs),
    \\);
  ).diff(res, true);
}

test "vardecl.chains 8" {
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
  \\            ))
  \\          .sb.ifsplit(
  \\            id,
  \\            self.db.indent(
  \\              self.db.seqb().softline()
  \\              .text(".")
  \\              .text(self._token(rhs))
  \\              .finish()
  \\            )
  \\          )._();
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\var sb = self.db.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(self.db.seqb().softline().text(".").text(self._token(rhs)).finish()),
    \\)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(self.db.seqb().softline().text(".").text(self._token(rhs)).finish()),
    \\)
    \\._();
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{}, al);
  try oh.snap(@src(),
    \\var sb = self.db.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\)
    \\._();
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\var sb = self.db.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\)
    \\._();
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var sb = self.db.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\)
    \\._();
  ).diff(res, true);
}

test "vardecl.chains 9" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var sb = self.db.xyz().pkzy.aaa.seqb().appends(lhs) 
  \\          .sb.ifsplit(
  \\            id,
  \\            self.db.indent(
  \\              self.db.seqb().softline()
  \\              .text(".")
  \\              .text(self._token(rhs))
  \\              .finish()
  \\            ),
  \\            self.db.seqb().text(".").text(self._token(rhs)).finish(),
  \\ )._();
  ;
  const al = arena.allocator();
  var res = try format(src, .{.width = 100}, al);
  const oh = OhSnap{};
  // using width: 100
  try oh.snap(@src(),
    \\var sb = self.db.xyz()
    \\.pkzy.aaa.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(self.db.seqb().softline().text(".").text(self._token(rhs)).finish()),
    \\  self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\var sb = self.db.xyz()
    \\.pkzy.aaa.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\  self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\var sb = self.db.xyz()
    \\.pkzy.aaa.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\  self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var sb = self.db.xyz()
    \\.pkzy.aaa.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  ),
    \\  self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
}

test "vardecl.chains 10" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ var sb = self.db.xyz().pkzy.aaa.seqb().appends(lhs) 
  \\          .sb.ifsplit(
  \\            id,
  \\            self.db.indent(
  \\              self.db.seqb().softline()
  \\              .text(".")
  \\              .text(self._token(rhs))
  \\              .finish()
  \\            ).
  \\            self.db.seqb().text(".").text(self._token(rhs)).finish()
  \\ )._();
  ;
  const al = arena.allocator();
  var res = try format(src, .{.width = 100}, al);
  const oh = OhSnap{};
  // using width: 100
  try oh.snap(@src(),
    \\var sb = self.db.xyz()
    \\.pkzy.aaa.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(self.db.seqb().softline().text(".").text(self._token(rhs)).finish())
    \\  .self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
  res = try format(src, .{.width = 90}, al); 
  try oh.snap(@src(),
    \\var sb = self.db.xyz()
    \\.pkzy.aaa.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  )
    \\  .self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\var sb = self.db.xyz()
    \\.pkzy.aaa.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  )
    \\  .self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al);
  try oh.snap(@src(),
    \\var sb = self.db.xyz()
    \\.pkzy.aaa.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  )
    \\  .self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al);
  try oh.snap(@src(),
    \\var sb = self.db.xyz()
    \\.pkzy.aaa.seqb()
    \\.appends(lhs)
    \\.sb.ifsplit(
    \\  id,
    \\  self.db.indent(
    \\    self.db.seqb()
    \\    .softline()
    \\    .text(".")
    \\    .text(self._token(rhs))
    \\    .finish(),
    \\  )
    \\  .self.db.seqb()
    \\  .text(".")
    \\  .text(self._token(rhs))
    \\  .finish(),
    \\)
    \\._();
  ).diff(res, true);
}

test "vardecl.chains 11" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ const y = text(self.token_token_token_token_token_token_token_token_token_token(rhs, abc, lhs));
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // default width: 80
  const res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\const y = text(
    \\  self.token_token_token_token_token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
  ).diff(res, true);
}

test "fundecl 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ fn foo(x: std.ArrayList(T), comptime x: i32, ..., noalias y: u2, k: anytype,) A(T) {
  \\  var x = 5;
  \\    print("just testing!");
  \\   var x: i32, const y: u32 = foo_(bar(1, 2));
  \\   x = 5; 
  \\ }
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\fn foo(x: std.ArrayList(T), comptime x: i32, ..., noalias y: u2, k: anytype) A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\  x = 5;
    \\}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\fn foo(
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  ...,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\  x = 5;
    \\}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\fn foo(
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  ...,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\  x = 5;
    \\}
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al); 
  try oh.snap(@src(),
    \\fn foo(
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  ...,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(
    \\    bar(1, 2),
    \\  );
    \\  x = 5;
    \\}
  ).diff(res, true);
}

test "fundecl 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ fn foo2(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype, noalias y: u2, k: anytype, ...) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\fn foo2(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  ...,
    \\) A(T) {}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\fn foo2(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  ...,
    \\) A(T) {}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\fn foo2(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  ...,
    \\) A(T) {}
  ).diff(res, true);
}

test "fundecl 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ fn foo3(comptime T: type, x: std.ArrayList(T), comptime x: i32, ...,) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\fn foo3(comptime T: type, x: std.ArrayList(T), comptime x: i32, ...) A(T) {}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\fn foo3(comptime T: type, x: std.ArrayList(T), comptime x: i32, ...) A(T) {}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\fn foo3(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  ...,
    \\) A(T) {}
  ).diff(res, true);
}

test "fundecl 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ pub fn foo4(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\pub fn foo4(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\pub fn foo4(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\pub fn foo4(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  ).diff(res, true);
}

test "fundecl 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ inline fn foo5(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  \\ pub inline fn foo6(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\inline fn foo5(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
    \\
    \\pub inline fn foo6(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\inline fn foo5(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
    \\
    \\pub inline fn foo6(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\inline fn foo5(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
    \\
    \\pub inline fn foo6(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  ).diff(res, true);
}

test "fundecl 6" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ export fn foo7(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  \\ pub export fn foo8(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\export fn foo7(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
    \\
    \\pub export fn foo8(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\export fn foo7(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
    \\
    \\pub export fn foo8(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\export fn foo7(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
    \\
    \\pub export fn foo8(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  ).diff(res, true);
}

test "fundecl 7" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ extern fn foo9(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T);
  \\ pub extern fn foo10(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T);
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\extern fn foo9(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T);
    \\
    \\pub extern fn foo10(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T);
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\extern fn foo9(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T);
    \\
    \\pub extern fn foo10(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T);
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\extern fn foo9(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T);
    \\
    \\pub extern fn foo10(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T);
  ).diff(res, true);
}

test "fundecl 8" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ pub fn fantasticFooBar(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) align(64) addrspace(.generic) linksection(".my_custom_section") callconv(.c) A(T) {
  \\    var x = 5;
  \\    print("just testing!");
  \\   var x: i32, const y: u32 = foo_(bar(1, 2));
  \\ }
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\pub fn fantasticFooBar(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) align(64) addrspace(.generic) callconv(.c) linksection(".my_custom_section") A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\pub fn fantasticFooBar(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\)
    \\align(64)
    \\addrspace(.generic)
    \\callconv(.c)
    \\linksection(".my_custom_section")
    \\A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\pub fn fantasticFooBar(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\)
    \\align(64)
    \\addrspace(.generic)
    \\callconv(.c)
    \\linksection(".my_custom_section")
    \\A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
}

test "fundecl 9" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ pub fn fantasticFooBar(comptime T: anytype, x: anytype, comptime x: anytype, noalias y: anytype, k: anytype) align(64) addrspace(.generic) linksection(".my_custom_section") callconv(.c) A(T) {
  \\    var x = 5;
  \\    print("just testing!");
  \\   var x: i32, const y: u32 = foo_(bar(1, 2));
  \\ }
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\pub fn fantasticFooBar(
    \\  comptime T: anytype,
    \\  x: anytype,
    \\  comptime x: anytype,
    \\  noalias y: anytype,
    \\  k: anytype,
    \\) align(64) addrspace(.generic) callconv(.c) linksection(".my_custom_section") A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\pub fn fantasticFooBar(
    \\  comptime T: anytype,
    \\  x: anytype,
    \\  comptime x: anytype,
    \\  noalias y: anytype,
    \\  k: anytype,
    \\)
    \\align(64)
    \\addrspace(.generic)
    \\callconv(.c)
    \\linksection(".my_custom_section")
    \\A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\pub fn fantasticFooBar(
    \\  comptime T: anytype,
    \\  x: anytype,
    \\  comptime x: anytype,
    \\  noalias y: anytype,
    \\  k: anytype,
    \\)
    \\align(64)
    \\addrspace(.generic)
    \\callconv(.c)
    \\linksection(".my_custom_section")
    \\A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
}

test "fundecl 10" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ pub fn fantasticFooBar() align(64) addrspace(.generic) linksection(".my_custom_section") callconv(.c) A(T) {
  \\    var x = 5;
  \\    print("just testing!");
  \\   var x: i32, const y: u32 = foo_(bar(1, 2));
  \\ }
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\pub fn fantasticFooBar()
    \\align(64)
    \\addrspace(.generic)
    \\callconv(.c)
    \\linksection(".my_custom_section")
    \\A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\pub fn fantasticFooBar()
    \\align(64)
    \\addrspace(.generic)
    \\callconv(.c)
    \\linksection(".my_custom_section")
    \\A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\pub fn fantasticFooBar()
    \\align(64)
    \\addrspace(.generic)
    \\callconv(.c)
    \\linksection(".my_custom_section")
    \\A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
}

test "fundecl 11" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ pub fn fan() align(64) addrspace(.generic) linksection(".my_custom_section") callconv(.c) A(T) {
  \\    var x = 5;
  \\    print("just testing!");
  \\   var x: i32, const y: u32 = foo_(bar(1, 2));
  \\ }
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\pub fn fan() align(64) addrspace(.generic) callconv(.c) linksection(".my_custom_section") A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\pub fn fan()
    \\align(64)
    \\addrspace(.generic)
    \\callconv(.c)
    \\linksection(".my_custom_section")
    \\A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\pub fn fan()
    \\align(64)
    \\addrspace(.generic)
    \\callconv(.c)
    \\linksection(".my_custom_section")
    \\A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  ).diff(res, true);
}

test "fundecl 12" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ const T = fn (a: anytype, comptime T: type, x: i32);
  \\ const T = fn abc(a: anytype, comptime T: type, x: i32);
  \\ const T = fn (a: anytype, comptime T: type, x: i32) void;
  \\ const T = fn abc(a: anytype, comptime T: type, x: i32) []const u8;
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\const T = fn (a: anytype, comptime T: type, x: i32);
    \\const T = fn abc(a: anytype, comptime T: type, x: i32);
    \\const T = fn (a: anytype, comptime T: type, x: i32) void;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) []const u8;
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\const T = fn (a: anytype, comptime T: type, x: i32);
    \\const T = fn abc(a: anytype, comptime T: type, x: i32);
    \\const T = fn (a: anytype, comptime T: type, x: i32) void;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) []const u8;
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\const T = fn (a: anytype, comptime T: type, x: i32);
    \\const T = fn abc(a: anytype, comptime T: type, x: i32);
    \\const T = fn (a: anytype, comptime T: type, x: i32) void;
    \\const T = fn abc(
    \\  a: anytype,
    \\  comptime T: type,
    \\  x: i32,
    \\) []const u8;
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al); 
  try oh.snap(@src(),
    \\const T = fn (
    \\  a: anytype,
    \\  comptime T: type,
    \\  x: i32,
    \\);
    \\const T = fn abc(
    \\  a: anytype,
    \\  comptime T: type,
    \\  x: i32,
    \\);
    \\const T = fn (
    \\  a: anytype,
    \\  comptime T: type,
    \\  x: i32,
    \\) void;
    \\const T = fn abc(
    \\  a: anytype,
    \\  comptime T: type,
    \\  x: i32,
    \\) []const u8;
  ).diff(res, true);
}

test "fundecl 13" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ fn foo(bar: T) void {
  \\   comptime const x, var y = expr;
  \\   comptime const x, const y = expr;
  \\}
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al); 
  try oh.snap(@src(),
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  ).diff(res, true);
}

test "expr 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\ fn foo(bar: T) void {
  \\    var x: u3 = 5;
  \\    const a, _ = expr;
  \\   var j = a * b;
  \\   var j = a * b + 5;
  \\    var j = x * x - (x + 5);
  \\    var j = x * x - (x + 5) + k;
  \\   var x = 1 * foo + bar - car * booh - dah / boxMM * foom4 + barm3 * foom3 + barm2 * foom2 + barm1 * foom1 + bar0 * foo0 + bar1 * foo1 + bar2 * foo2 + bar3 / boxN * foo;
  \\  var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
  \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo + (bar  * foo + bar * foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
  \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo + (bar * foo + bar * foo + bar * foo + bar / boxB * foo * foo + bar / boxB * foo * foo + bar / boxB * foo);
  \\}
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\fn foo(bar: T) void {
    \\  var x: u3 = 5;
    \\  const a, _ = expr;
    \\  var j = a * b;
    \\  var j = a * b + 5;
    \\  var j = x * x - (x + 5);
    \\  var j = x * x - (x + 5) + k;
    \\  var x = 1 * foo + bar - car * booh - dah / boxMM * foom4 + barm3 * foom3 + barm2 * foom2
    \\    + barm1 * foom1
    \\    + bar0 * foo0
    \\    + bar1 * foo1
    \\    + bar2 * foo2
    \\    + bar3 / boxN * foo;
    \\  var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo
    \\    + (bar * foo + bar * foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
    \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo
    \\    + (bar * foo + bar * foo + bar * foo + bar / boxB * foo * foo + bar / boxB * foo * foo
    \\      + bar / boxB * foo);
    \\}
  ).diff(res, true);
  // using width: 100, indent: 4
  res = try format(src, .{.width = 100, .indent = 4}, al); 
  try oh.snap(@src(),
    \\fn foo(bar: T) void {
    \\    var x: u3 = 5;
    \\    const a, _ = expr;
    \\    var j = a * b;
    \\    var j = a * b + 5;
    \\    var j = x * x - (x + 5);
    \\    var j = x * x - (x + 5) + k;
    \\    var x = 1 * foo + bar - car * booh - dah / boxMM * foom4 + barm3 * foom3 + barm2 * foom2
    \\        + barm1 * foom1
    \\        + bar0 * foo0
    \\        + bar1 * foo1
    \\        + bar2 * foo2
    \\        + bar3 / boxN * foo;
    \\    var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\    var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo
    \\        + (bar * foo + bar * foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
    \\    var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo
    \\        + (bar * foo + bar * foo + bar * foo + bar / boxB * foo * foo + bar / boxB * foo * foo
    \\            + bar / boxB * foo);
    \\}
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\fn foo(bar: T) void {
    \\  var x: u3 = 5;
    \\  const a, _ = expr;
    \\  var j = a * b;
    \\  var j = a * b + 5;
    \\  var j = x * x - (x + 5);
    \\  var j = x * x - (x + 5) + k;
    \\  var x = 1 * foo + bar - car * booh - dah / boxMM * foom4 + barm3 * foom3
    \\    + barm2 * foom2
    \\    + barm1 * foom1
    \\    + bar0 * foo0
    \\    + bar1 * foo1
    \\    + bar2 * foo2
    \\    + bar3 / boxN * foo;
    \\  var x = this.is.fancy(
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\  );
    \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo
    \\    + bar * foo
    \\    + (bar * foo + bar * foo + bar * foo + bar * foo + bar * foo
    \\      + bar / boxB * foo);
    \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo
    \\    + bar * foo
    \\    + (bar * foo + bar * foo + bar * foo + bar / boxB * foo * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo);
    \\}
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\fn foo(bar: T) void {
    \\  var x: u3 = 5;
    \\  const a, _ = expr;
    \\  var j = a * b;
    \\  var j = a * b + 5;
    \\  var j = x * x - (x + 5);
    \\  var j = x * x - (x + 5) + k;
    \\  var x = 1 * foo + bar - car * booh - dah / boxMM * foom4
    \\    + barm3 * foom3
    \\    + barm2 * foom2
    \\    + barm1 * foom1
    \\    + bar0 * foo0
    \\    + bar1 * foo1
    \\    + bar2 * foo2
    \\    + bar3 / boxN * foo;
    \\  var x = this.is.fancy(
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\  );
    \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo + bar * foo + bar * foo + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo);
    \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo + bar * foo + bar * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo);
    \\}
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al); 
  try oh.snap(@src(),
    \\fn foo(bar: T) void {
    \\  var x: u3 = 5;
    \\  const a, _ = expr;
    \\  var j = a * b;
    \\  var j = a * b + 5;
    \\  var j = x * x - (x + 5);
    \\  var j = x * x - (x + 5) + k;
    \\  var x = 1 * foo
    \\    + bar - car * booh - dah / boxMM * foom4
    \\    + barm3 * foom3
    \\    + barm2 * foom2
    \\    + barm1 * foom1
    \\    + bar0 * foo0
    \\    + bar1 * foo1
    \\    + bar2 * foo2
    \\    + bar3 / boxN * foo;
    \\  var x = this.is.fancy(
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\  );
    \\  var x = 1 * foo
    \\    + bar - car * booh - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo + bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo);
    \\  var x = 1 * foo
    \\    + bar - car * booh - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo);
    \\}
  ).diff(res, true);
}

test "expr 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\    var x: u3 = 5;
  \\   var j = a * b;
  \\   var j = a * b + 5;
  \\    var j = x * x - (x + 5);
  \\    var j = x * x - (x + 5) + k;
  \\   var x = 1 * foo + bar - car * booh - dah / boxMM * foom4 + barm3 * foom3 + barm2 * foom2 + barm1 * foom1 + bar0 * foo0 + bar1 * foo1 + bar2 * foo2 + bar3 / boxN * foo;
  \\  var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
  \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo + (bar  * foo + bar * foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
  \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo + (bar * foo + bar * foo + bar * foo + bar / boxB * foo * foo + bar / boxB * foo * foo + bar / boxB * foo);
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b + 5;
    \\var j = x * x - (x + 5);
    \\var j = x * x - (x + 5) + k;
    \\var x = 1 * foo + bar - car * booh - dah / boxMM * foom4 + barm3 * foom3 + barm2 * foom2
    \\  + barm1 * foom1
    \\  + bar0 * foo0
    \\  + bar1 * foo1
    \\  + bar2 * foo2
    \\  + bar3 / boxN * foo;
    \\var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo
    \\  + (bar * foo + bar * foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
    \\var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo
    \\  + (bar * foo + bar * foo + bar * foo + bar / boxB * foo * foo + bar / boxB * foo * foo
    \\    + bar / boxB * foo);
  ).diff(res, true);
  // using width: 100, indent: 4
  res = try format(src, .{.width = 100, .indent = 4}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b + 5;
    \\var j = x * x - (x + 5);
    \\var j = x * x - (x + 5) + k;
    \\var x = 1 * foo + bar - car * booh - dah / boxMM * foom4 + barm3 * foom3 + barm2 * foom2
    \\    + barm1 * foom1
    \\    + bar0 * foo0
    \\    + bar1 * foo1
    \\    + bar2 * foo2
    \\    + bar3 / boxN * foo;
    \\var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo
    \\    + (bar * foo + bar * foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
    \\var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo
    \\    + (bar * foo + bar * foo + bar * foo + bar / boxB * foo * foo + bar / boxB * foo * foo
    \\        + bar / boxB * foo);
  ).diff(res, true);
  // default width: 80
  res = try format(src, .{.width = 80}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b + 5;
    \\var j = x * x - (x + 5);
    \\var j = x * x - (x + 5) + k;
    \\var x = 1 * foo + bar - car * booh - dah / boxMM * foom4 + barm3 * foom3
    \\  + barm2 * foom2
    \\  + barm1 * foom1
    \\  + bar0 * foo0
    \\  + bar1 * foo1
    \\  + bar2 * foo2
    \\  + bar3 / boxN * foo;
    \\var x = this.is.fancy(
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo
    \\  + bar * foo
    \\  + (bar * foo + bar * foo + bar * foo + bar * foo + bar * foo
    \\    + bar / boxB * foo);
    \\var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo
    \\  + bar * foo
    \\  + (bar * foo + bar * foo + bar * foo + bar / boxB * foo * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo);
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b + 5;
    \\var j = x * x - (x + 5);
    \\var j = x * x - (x + 5) + k;
    \\var x = 1 * foo + bar - car * booh - dah / boxMM * foom4
    \\  + barm3 * foom3
    \\  + barm2 * foom2
    \\  + barm1 * foom1
    \\  + bar0 * foo0
    \\  + bar1 * foo1
    \\  + bar2 * foo2
    \\  + bar3 / boxN * foo;
    \\var x = this.is.fancy(
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo + bar - car * booh - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo + bar * foo + bar * foo + bar * foo
    \\    + bar * foo
    \\    + bar / boxB * foo);
    \\var x = 1 * foo + bar - car * booh - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo + bar * foo + bar * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo);
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b + 5;
    \\var j = x * x - (x + 5);
    \\var j = x * x - (x + 5) + k;
    \\var x = 1 * foo
    \\  + bar - car * booh - dah / boxMM * foom4
    \\  + barm3 * foom3
    \\  + barm2 * foom2
    \\  + barm1 * foom1
    \\  + bar0 * foo0
    \\  + bar1 * foo1
    \\  + bar2 * foo2
    \\  + bar3 / boxN * foo;
    \\var x = this.is.fancy(
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo
    \\  + bar - car * booh - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar / boxB * foo);
    \\var x = 1 * foo
    \\  + bar - car * booh - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo + bar * foo
    \\    + bar * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo);
  ).diff(res, true);
}

test "expr 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\    var x: u3 = 5;
  \\   var j = a * b;
  \\   var j = a * b * 5;
  \\    var j = x * x / (x * 5);
  \\    var j = x * x / (x * 5) * k;
  \\   var x = 1 * foo * bar / car * booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2 * barm1 * foom1 * bar0 * foo0 * bar1 * foo1 * bar2 * foo2 * bar3 / boxN * foo;
  \\  var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
  \\  var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo * (bar  * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB * foo);
  \\  var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB * foo * foo * bar / boxB * foo);
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car * booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2
    \\  * barm1 * foom1
    \\  * bar0 * foo0
    \\  * bar1 * foo1
    \\  * bar2 * foo2
    \\  * bar3 / boxN
    \\  * foo;
    \\var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB * foo);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB * foo * foo
    \\    * bar / boxB
    \\    * foo);
  ).diff(res, true);
  // using width: 100, indent: 4
  res = try format(src, .{.width = 100, .indent = 4}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car * booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2
    \\    * barm1 * foom1
    \\    * bar0 * foo0
    \\    * bar1 * foo1
    \\    * bar2 * foo2
    \\    * bar3 / boxN
    \\    * foo;
    \\var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB * foo);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB * foo * foo
    \\        * bar / boxB
    \\        * foo);
  ).diff(res, true);
  // default width: 80, indent: 4
  res = try format(src, .{.width = 80, .indent = 4}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car * booh / dah / boxMM * foom4 * barm3 * foom3
    \\    * barm2 * foom2
    \\    * barm1 * foom1
    \\    * bar0 * foo0
    \\    * bar1 * foo1
    \\    * bar2 * foo2
    \\    * bar3 / boxN
    \\    * foo;
    \\var x = this.is.fancy(
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo
    \\    * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB
    \\        * foo);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo
    \\    * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB
    \\        * foo * foo
    \\        * bar / boxB
    \\        * foo);
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car * booh / dah / boxMM * foom4
    \\  * barm3 * foom3
    \\  * barm2 * foom2
    \\  * barm1 * foom1
    \\  * bar0 * foo0
    \\  * bar1 * foo1
    \\  * bar2 * foo2
    \\  * bar3 / boxN
    \\  * foo;
    \\var x = this.is.fancy(
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar * foo
    \\    * bar * foo
    \\    * bar / boxB
    \\    * foo);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar / boxB
    \\    * foo * foo
    \\    * bar / boxB
    \\    * foo * foo
    \\    * bar / boxB
    \\    * foo);
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car
    \\  * booh / dah
    \\  / boxMM * foom4
    \\  * barm3 * foom3
    \\  * barm2 * foom2
    \\  * barm1 * foom1
    \\  * bar0 * foo0
    \\  * bar1 * foo1
    \\  * bar2 * foo2
    \\  * bar3 / boxN
    \\  * foo;
    \\var x = this.is.fancy(
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car
    \\  * booh / dah
    \\  / boxB * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * (bar * foo * bar * foo
    \\    * bar * foo
    \\    * bar * foo
    \\    * bar * foo
    \\    * bar / boxB
    \\    * foo);
    \\var x = 1 * foo * bar / car
    \\  * booh / dah
    \\  / boxB * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * (bar * foo * bar * foo
    \\    * bar * foo
    \\    * bar / boxB
    \\    * foo * foo
    \\    * bar / boxB
    \\    * foo * foo
    \\    * bar / boxB
    \\    * foo);
  ).diff(res, true);
}

test "expr 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src = 
  \\    var x: u3 = 5;
  \\   var j = a * b;
  \\   var j = a * b * 5;
  \\    var j = x * x / (x * 5);
  \\    var j = x * x / (x * 5) * k;
  \\   var x = 1 * foo * bar / car - booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2 * barm1 * foom1 * bar0 * foo0 * bar1 * foo1 * bar2 * foo2 * bar3 / boxN * foo;
  \\  var x = this.is.fancy(a.b((a * b + 5 * 6 / c * 12 / xyz)).not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
  \\  var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo * (bar  * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB * foo);
  \\  var x = 1 * foo * bar * car + booh / dah / boxB - foo * bar * foo * bar * foo * bar * foo * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB * foo * foo * bar / boxB * foo);
  ;
  const al = arena.allocator();
  const oh = OhSnap{};
  // using width: 100
  var res = try format(src, .{.width = 100}, al);
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car - booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2
    \\    * barm1 * foom1
    \\    * bar0 * foo0
    \\    * bar1 * foo1
    \\    * bar2 * foo2
    \\    * bar3 / boxN
    \\    * foo;
    \\var x = this.is.fancy(
    \\  a.b((a * b + 5 * 6 / c * 12 / xyz)).not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB * foo);
    \\var x = 1 * foo * bar * car + booh / dah / boxB - foo * bar * foo * bar * foo * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB * foo * foo
    \\    * bar / boxB
    \\    * foo);
  ).diff(res, true);
  // using width: 100, indent: 4
  res = try format(src, .{.width = 100, .indent = 4}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car - booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2
    \\        * barm1 * foom1
    \\        * bar0 * foo0
    \\        * bar1 * foo1
    \\        * bar2 * foo2
    \\        * bar3 / boxN
    \\        * foo;
    \\var x = this.is.fancy(
    \\    a.b((a * b + 5 * 6 / c * 12 / xyz)).not().so(a, b),
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB * foo);
    \\var x = 1 * foo * bar * car + booh / dah / boxB - foo * bar * foo * bar * foo * bar * foo
    \\        * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB * foo * foo
    \\        * bar / boxB
    \\        * foo);
  ).diff(res, true);
  // default width: 80, indent: 4
  res = try format(src, .{.width = 80, .indent = 4}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car - booh / dah / boxMM * foom4 * barm3 * foom3
    \\        * barm2 * foom2
    \\        * barm1 * foom1
    \\        * bar0 * foo0
    \\        * bar1 * foo1
    \\        * bar2 * foo2
    \\        * bar3 / boxN
    \\        * foo;
    \\var x = this.is.fancy(
    \\    a.b((a * b + 5 * 6 / c * 12 / xyz)).not().so(a, b),
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo
    \\    * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB
    \\        * foo);
    \\var x = 1 * foo * bar * car + booh / dah / boxB - foo * bar * foo * bar * foo
    \\        * bar * foo
    \\        * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo
    \\        * bar / boxB
    \\        * foo * foo
    \\        * bar / boxB
    \\        * foo);
  ).diff(res, true);
  // using width: 60
  res = try format(src, .{.width = 60}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car - booh / dah / boxMM * foom4
    \\    * barm3 * foom3
    \\    * barm2 * foom2
    \\    * barm1 * foom1
    \\    * bar0 * foo0
    \\    * bar1 * foo1
    \\    * bar2 * foo2
    \\    * bar3 / boxN
    \\    * foo;
    \\var x = this.is.fancy(
    \\  a.b((a * b + 5 * 6 / c * 12 / xyz)).not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar * foo
    \\    * bar * foo
    \\    * bar / boxB
    \\    * foo);
    \\var x = 1 * foo * bar * car + booh / dah / boxB - foo
    \\    * bar * foo
    \\    * bar * foo
    \\    * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar / boxB
    \\    * foo * foo
    \\    * bar / boxB
    \\    * foo * foo
    \\    * bar / boxB
    \\    * foo);
  ).diff(res, true);
  // using width: 30
  res = try format(src, .{.width = 30}, al); 
  try oh.snap(@src(),
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car
    \\  - booh / dah
    \\    / boxMM * foom4
    \\    * barm3 * foom3
    \\    * barm2 * foom2
    \\    * barm1 * foom1
    \\    * bar0 * foo0
    \\    * bar1 * foo1
    \\    * bar2 * foo2
    \\    * bar3 / boxN
    \\    * foo;
    \\var x = this.is.fancy(
    \\  a.b(
    \\    (a * b
    \\      + 5 * 6 / c * 12 / xyz),
    \\  )
    \\  .not()
    \\  .so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car
    \\  * booh / dah
    \\  / boxB * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * bar * foo
    \\  * (bar * foo * bar * foo
    \\    * bar * foo
    \\    * bar * foo
    \\    * bar * foo
    \\    * bar / boxB
    \\    * foo);
    \\var x = 1 * foo * bar * car
    \\  + booh / dah
    \\    / boxB - foo
    \\    * bar * foo
    \\    * bar * foo
    \\    * bar * foo
    \\    * (bar * foo * bar * foo
    \\    * bar * foo
    \\    * bar / boxB
    \\    * foo * foo
    \\    * bar / boxB
    \\    * foo * foo
    \\    * bar / boxB
    \\    * foo);
  ).diff(res, true);
}
