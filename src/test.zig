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
