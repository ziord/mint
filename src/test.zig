const std = @import("std");
const fmt = @import("format.zig");
const ts = @import("translate.zig");

const Allocator = std.mem.Allocator;

fn check(got: []const u8, expected: []const u8) !void {
  if (!std.mem.eql(u8, expected, got)) {
    return error.Different;
  }
}

fn translate(src: [:0]const u8, al: Allocator) !*fmt.Doc {
  var error_set = ts.Translate.ErrorSet.init(al);
  var t = try ts.Translate.init(al, std.testing.io, &error_set);
  return t.translate("test.zig", src, .zig);
}

fn format(doc: *fmt.Doc, cfg: fmt.FmtConfig, al: Allocator) ![]const u8 {
  var f = fmt.Format.init(std.testing.io, al, cfg);
  f.fmt(doc);
  return f.getFmtString(true);
}

test "vardecl 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\var x = foo(abc, bar, baz);
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var x = foo(abc, bar, baz);
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\var x = foo(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
  );
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
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
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
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
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
  );
}

test "vardecl 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const g: [*:Bar]Foo = box(abc, bar, baz);
  \\ const g: [*c]Foo = box(abc, bar, baz);
  \\ const g: [:Bar]Foo = box(abc, bar, baz);
  \\ const e: *const Foo = box(abc, bar, baz);
  \\ const f: [*]const Foo = box(abc, bar, baz);
  \\ const f: [*c]const Foo = box(abc, bar, baz);
  \\ const f: [*]const Foo = box(abc, bar, baz,);
  \\ var f: []const Foo = box(abc, bar, baz);
  \\ const f: *[]const Foo = box(abc, bar, baz);
  \\ const f: []const Foo(Axe, Bxe, Cxe, Dxe, box(),) = box(abc, bar, baz,);
  \\ const g: [*:Bar]const Foo = x.box(abc(), bar, baz);
  \\ const g: [*c] const Foo = box(abc, bar, baz);
  \\ const g: [:Bar] const Foo = box(abc, bar, baz);
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const g: [*:Bar]Foo = box(abc, bar, baz);
    \\const g: [*c]Foo = box(abc, bar, baz);
    \\const g: [:Bar]Foo = box(abc, bar, baz);
    \\const e: *const Foo = box(abc, bar, baz);
    \\const f: [*]const Foo = box(abc, bar, baz);
    \\const f: [*c]const Foo = box(abc, bar, baz);
    \\const f: [*]const Foo = box(abc, bar, baz);
    \\var f: []const Foo = box(abc, bar, baz);
    \\const f: *[]const Foo = box(abc, bar, baz);
    \\const f: []const Foo(Axe, Bxe, Cxe, Dxe, box()) = box(abc, bar, baz);
    \\const g: [*:Bar]const Foo = x.box(abc(), bar, baz);
    \\const g: [*c]const Foo = box(abc, bar, baz);
    \\const g: [:Bar]const Foo = box(abc, bar, baz);
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const g: [*:Bar]Foo = box(abc, bar, baz);
    \\const g: [*c]Foo = box(abc, bar, baz);
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
    \\const g: [*c]const Foo = box(abc, bar, baz);
    \\const g: [:Bar]const Foo = box(abc, bar, baz);
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const g: [*:Bar]Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const g: [*c]Foo = box(
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
    \\const g: [
    \\  *:Bar
    \\]const Foo = x.box(
    \\  abc(),
    \\  bar,
    \\  baz,
    \\);
    \\const g: [*c]const Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
    \\const g: [
    \\  :Bar
    \\]const Foo = box(
    \\  abc,
    \\  bar,
    \\  baz,
    \\);
  );
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
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
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
    \\var buffer
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\var buffer
    \\  align(64)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs),
    \\);
  );
  // using width: 100
  res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
    \\    .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var buffer
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\var buffer
    \\  align(64)
    \\  linksection(".my_custom_section") = text(
    \\  self.token_token.token2_token()
    \\    .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(
    \\    ".my_custom_section"
    \\  ) = undefined;
    \\const buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(
    \\    ".my_custom_section"
    \\  ) = text(
    \\  self.token_token_token_token_token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
    \\const buffer: [1024]u8
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(
    \\    ".my_custom_section"
    \\  ) = text(
    \\  self.token_token.token2_token()
    \\    .token_token_token_token_token_token(
    \\      rhs,
    \\      abc,
    \\      lhs,
    \\    ),
    \\);
    \\var buffer
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(
    \\    ".my_custom_section"
    \\  ) = undefined;
    \\var buffer
    \\  align(64)
    \\  linksection(
    \\    ".my_custom_section"
    \\  ) = text(
    \\  self.token_token.token2_token()
    \\    .token_token_token_token_token_token(
    \\      rhs,
    \\      abc,
    \\      lhs,
    \\    ),
    \\);
  );
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
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
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
    \\    .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var buffer align(64) = undefined;
    \\var buffer
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\    .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var a align(b) = c;
    \\var a: b align(c) = d;
  );
  // using width: 100
  res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
    \\    .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var buffer align(64) = undefined;
    \\var buffer
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\    .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var a align(b) = c;
    \\var a: b align(c) = d;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
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
    \\    .token_token_token_token_token_token(
    \\      rhs,
    \\      abc,
    \\      lhs,
    \\    ),
    \\);
    \\var buffer
    \\  align(64) = undefined;
    \\var buffer
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\    .token_token_token_token_token_token(
    \\      rhs,
    \\      abc,
    \\      lhs,
    \\    ),
    \\);
    \\var a align(b) = c;
    \\var a: b align(c) = d;
  );
}

test "vardecl 6" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ threadlocal const x = expr;
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  const res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\threadlocal const x = expr;
  );
}

test "vardecl.chains 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var xyz = foo.bar("ok").box();
  \\ var ky = self.group(self.seqb().text("Group(").indent(self.seqb().softline().text(id).text(",").normline().appends(_d).finish()).softline().text(")").finish());
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var xyz = foo.bar("ok").box();
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb().softline().text(id).text(",").normline().appends(_d).finish(),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var xyz = foo.bar("ok").box();
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb()
    \\        .softline()
    \\        .text(id)
    \\        .text(",")
    \\        .normline()
    \\        .appends(_d)
    \\        .finish(),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var xyz = foo.bar("ok").box();
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb()
    \\        .softline()
    \\        .text(id)
    \\        .text(",")
    \\        .normline()
    \\        .appends(_d)
    \\        .finish(),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
  );
}

test "vardecl.chains 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var ky = self.group(self.seqb() .text("Group(") .indent(self.seqb().softline() .text(id) .text(",") .normline() .appends(_d).finish() ) .softline().text(")").finish());
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb().softline().text(id).text(",").normline().appends(_d).finish(),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb()
    \\        .softline()
    \\        .text(id)
    \\        .text(",")
    \\        .normline()
    \\        .appends(_d)
    \\        .finish(),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb()
    \\        .softline()
    \\        .text(id)
    \\        .text(",")
    \\        .normline()
    \\        .appends(_d)
    \\        .finish(),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
  );
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
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb().softline().text(id).text(",").normline().appends(_d).finish(),
    \\      self.seqb()
    \\        .text("IfSplit(")
    \\        .indent(
    \\          self.seqb()
    \\            .softline()
    \\            .text(id)
    \\            .text(",")
    \\            .normline()
    \\            .appends(_ds)
    \\            .text(",")
    \\            .normline()
    \\            .appends(_df)
    \\            .finish(),
    \\        ),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb()
    \\        .softline()
    \\        .text(id)
    \\        .text(",")
    \\        .normline()
    \\        .appends(_d)
    \\        .finish(),
    \\      self.seqb()
    \\        .text("IfSplit(")
    \\        .indent(
    \\          self.seqb()
    \\            .softline()
    \\            .text(id)
    \\            .text(",")
    \\            .normline()
    \\            .appends(_ds)
    \\            .text(",")
    \\            .normline()
    \\            .appends(_df)
    \\            .finish(),
    \\        ),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb()
    \\        .softline()
    \\        .text(id)
    \\        .text(",")
    \\        .normline()
    \\        .appends(_d)
    \\        .finish(),
    \\      self.seqb()
    \\        .text("IfSplit(")
    \\        .indent(
    \\          self.seqb()
    \\            .softline()
    \\            .text(id)
    \\            .text(",")
    \\            .normline()
    \\            .appends(_ds)
    \\            .text(",")
    \\            .normline()
    \\            .appends(_df)
    \\            .finish(),
    \\        ),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
  );
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
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var sb = self.db.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb().softline().text(".").text(self._token(rhs)).finish(),
    \\    ),
    \\    self.db.seqb().text(".").text(self._token(rhs)).finish(),
    \\  )
    \\  ._();
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var sb = self.db.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb()
    \\        .softline()
    \\        .text(".")
    \\        .text(self._token(rhs))
    \\        .finish(),
    \\    ),
    \\    self.db.seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var sb = self.db.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb()
    \\        .softline()
    \\        .text(".")
    \\        .text(
    \\          self._token(rhs),
    \\        )
    \\        .finish(),
    \\    ),
    \\    self.db.seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  );
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
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var sb = self.db.seqb()
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
  );
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
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\var q = fox()().hahah(a, b, "yes").bar(abc());
    \\var q = fox()().hahah(a, b, "yes").bar(compute_something(long_arg1, long_arg2));
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(compute_something(long_arg1, xlong_arg2));
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var q = fox()().hahah(a, b, "yes").bar(abc());
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(compute_something(long_arg1, long_arg2));
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(compute_something(long_arg1, xlong_arg2));
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
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
    \\  );
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(
    \\    compute_something(
    \\      long_arg1,
    \\      xlong_arg2,
    \\    ),
    \\  );
  );
}

test "vardecl.chains 7" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var sb = self.db.seqb().appends(compute_value(lhs, rhs));
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var sb = self.db.seqb().appends(compute_value(lhs, rhs));
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var sb = self.db.seqb().appends(compute_value(lhs, rhs));
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var sb = self.db.seqb()
    \\  .appends(
    \\    compute_value(lhs, rhs),
    \\  );
  );
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
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var sb = self.db.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(self.db.seqb().softline().text(".").text(self._token(rhs)).finish()),
    \\  )
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(self.db.seqb().softline().text(".").text(self._token(rhs)).finish()),
    \\  )
    \\  ._();
  );
  // default width: 85
  res = try format(doc, .{}, al);
  try check(
    res,
    \\var sb = self.db.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb().softline().text(".").text(self._token(rhs)).finish(),
    \\    ),
    \\  )
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb().softline().text(".").text(self._token(rhs)).finish(),
    \\    ),
    \\  )
    \\  ._();
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var sb = self.db.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb()
    \\        .softline()
    \\        .text(".")
    \\        .text(self._token(rhs))
    \\        .finish(),
    \\    ),
    \\  )
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb()
    \\        .softline()
    \\        .text(".")
    \\        .text(self._token(rhs))
    \\        .finish(),
    \\    ),
    \\  )
    \\  ._();
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var sb = self.db.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb()
    \\        .softline()
    \\        .text(".")
    \\        .text(
    \\          self._token(rhs),
    \\        )
    \\        .finish(),
    \\    ),
    \\  )
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb()
    \\        .softline()
    \\        .text(".")
    \\        .text(
    \\          self._token(rhs),
    \\        )
    \\        .finish(),
    \\    ),
    \\  )
    \\  ._();
  );
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
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  // using width: 100
  try check(
    res,
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(self.db.seqb().softline().text(".").text(self._token(rhs)).finish()),
    \\    self.db.seqb().text(".").text(self._token(rhs)).finish(),
    \\  )
    \\  ._();
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb().softline().text(".").text(self._token(rhs)).finish(),
    \\    ),
    \\    self.db.seqb().text(".").text(self._token(rhs)).finish(),
    \\  )
    \\  ._();
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb()
    \\        .softline()
    \\        .text(".")
    \\        .text(self._token(rhs))
    \\        .finish(),
    \\    ),
    \\    self.db.seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb()
    \\        .softline()
    \\        .text(".")
    \\        .text(
    \\          self._token(rhs),
    \\        )
    \\        .finish(),
    \\    ),
    \\    self.db.seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  );
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
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  // using width: 100
  try check(
    res,
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(self.db.seqb().softline().text(".").text(self._token(rhs)).finish())
    \\      .self.db.seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  );
  res = try format(doc, .{ .width = 90 }, al);
  try check(
    res,
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(self.db.seqb().softline().text(".").text(self._token(rhs)).finish())
    \\      .self.db.seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb().softline().text(".").text(self._token(rhs)).finish(),
    \\    )
    \\      .self.db.seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb()
    \\        .softline()
    \\        .text(".")
    \\        .text(self._token(rhs))
    \\        .finish(),
    \\    )
    \\      .self.db.seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    id,
    \\    self.db.indent(
    \\      self.db.seqb()
    \\        .softline()
    \\        .text(".")
    \\        .text(
    \\          self._token(rhs),
    \\        )
    \\        .finish(),
    \\    )
    \\      .self.db.seqb()
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  );
}

test "vardecl.chains 11" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const y = text(self.token_token_token_token_token_token_token_token_token_token(rhs, abc, lhs));
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  const res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const y = text(
    \\  self.token_token_token_token_token_token_token_token_token_token(
    \\    rhs,
    \\    abc,
    \\    lhs,
    \\  ),
    \\);
  );
}

test "fundecl 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo(x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype, ...,) A(T) {
  \\  var x = 5;
  \\    print("just testing!");
  \\   var x: i32, const y: u32 = foo_(bar(1, 2));
  \\   x = 5;
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn foo(x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype, ...) A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\  x = 5;
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn foo(
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  ...,
    \\) A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\  x = 5;
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn foo(
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  ...,
    \\) A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\  x = 5;
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo(
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  ...,
    \\) A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(
    \\    bar(1, 2),
    \\  );
    \\  x = 5;
    \\}
  );
}

test "fundecl 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo2(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype, noalias y: u2, k: anytype, ...) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
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
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
  );
}

test "fundecl 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo3(comptime T: type, x: std.ArrayList(T), comptime x: i32, ...,) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn foo3(comptime T: type, x: std.ArrayList(T), comptime x: i32, ...) A(T) {}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn foo3(comptime T: type, x: std.ArrayList(T), comptime x: i32, ...) A(T) {}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn foo3(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  ...,
    \\) A(T) {}
  );
}

test "fundecl 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ pub fn foo4(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\pub fn foo4(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\pub fn foo4(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\pub fn foo4(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  );
}

test "fundecl 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ inline fn foo5(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  \\
  \\ pub inline fn foo6(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
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
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
  );
}

test "fundecl 6" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ export fn foo7(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  \\
  \\ pub export fn foo8(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
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
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
  );
}

test "fundecl 7" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ extern fn foo9(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T);
  \\
  \\ pub extern fn foo10(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T);
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
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
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
  );
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
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
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
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
  );
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
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
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
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
  );
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
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
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
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
  );
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
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\pub fn fan() align(64) addrspace(.generic) callconv(.c) linksection(".my_custom_section") A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
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
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
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
  );
}

test "fundecl 12" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const T = fn (a: anytype, comptime T: type, x: i32) u32;
  \\ const T = fn abc(a: anytype, comptime T: type, x: i32) u32;
  \\ const T = fn (a: anytype, comptime T: type, x: i32) void;
  \\ const T = fn abc(a: anytype, comptime T: type, x: i32) []const u8;
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const T = fn (a: anytype, comptime T: type, x: i32) u32;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) u32;
    \\const T = fn (a: anytype, comptime T: type, x: i32) void;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) []const u8;
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const T = fn (a: anytype, comptime T: type, x: i32) u32;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) u32;
    \\const T = fn (a: anytype, comptime T: type, x: i32) void;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) []const u8;
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const T = fn (a: anytype, comptime T: type, x: i32) u32;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) u32;
    \\const T = fn (a: anytype, comptime T: type, x: i32) void;
    \\const T = fn abc(
    \\  a: anytype,
    \\  comptime T: type,
    \\  x: i32,
    \\) []const u8;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const T = fn (
    \\  a: anytype,
    \\  comptime T: type,
    \\  x: i32,
    \\) u32;
    \\const T = fn abc(
    \\  a: anytype,
    \\  comptime T: type,
    \\  x: i32,
    \\) u32;
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
  );
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
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  );
}

test "fundecl 14" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testing() Foo!A.B(0xff, 123) {
  \\  return self.puke("no!");
  \\}
  ;
  const al = arena.allocator();
  // using width: 30
  const doc = try translate(src, al);
  const res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testing() Foo!A.B(
    \\  0xff,
    \\  123,
    \\) {
    \\  return self.puke("no!");
    \\}
  );
}

test "fundecl 15" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testing(x: u2) Foo!A.B(0xff, 123) {
  \\  return self.puke("no!");
  \\}
  ;
  const al = arena.allocator();
  // using width: 30
  const doc = try translate(src, al);
  const res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testing(
    \\  x: u2,
    \\) Foo!A.B(0xff, 123) {
    \\  return self.puke("no!");
    \\}
  );
}

test "fundecl 16" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\fn ship() b: {break :b void;} {
  \\ return voidExpr();  
  \\}
  \\
  \\fn ship(x: u32, y: TypeExpr) b: {var x = getType(); break :b setType(x);} {
  \\ return voidExpr();  
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn ship() b: {
    \\  break :b void;
    \\} {
    \\  return voidExpr();
    \\}
    \\
    \\fn ship(x: u32, y: TypeExpr) b: {
    \\  var x = getType();
    \\  break :b setType(x);
    \\} {
    \\  return voidExpr();
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn ship() b: {
    \\  break :b void;
    \\} {
    \\  return voidExpr();
    \\}
    \\
    \\fn ship(x: u32, y: TypeExpr) b: {
    \\  var x = getType();
    \\  break :b setType(x);
    \\} {
    \\  return voidExpr();
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn ship() b: {
    \\  break :b void;
    \\} {
    \\  return voidExpr();
    \\}
    \\
    \\fn ship(
    \\  x: u32,
    \\  y: TypeExpr,
    \\) b: {
    \\  var x = getType();
    \\  break :b setType(x);
    \\} {
    \\  return voidExpr();
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn ship() b: {
    \\  break :b void;
    \\} {
    \\  return voidExpr();
    \\}
    \\
    \\fn ship(
    \\  x: u32,
    \\  y: TypeExpr,
    \\) b: {
    \\  var x = getType();
    \\  break :b setType(x);
    \\} {
    \\  return voidExpr();
    \\}
  );
}

test "fundecl 17" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo(... // abc
  \\ ) void { if (last_tkn) |tkn| flat.decllineIf(self.tknHasTC(tkn))._();}
  \\
  \\ fn bar(x: anytype // abc
  \\ ) void {
  \\ const result =
  \\   if (attr_doc) |doc| blk: {
  \\     var tmp = self.db.seqb();
  \\     if (top_comments) |c_doc| {
  \\       tmp.declline().append(c_doc);
  \\     } else if (lb_has_trailing) {
  \\       tmp.declline()._();
  \\     } else {
  \\       tmp.softline()._();
  \\     }
  \\     tmp.append(doc);
  \\     const has_comment = top_comments != null or lb_has_trailing;
  \\     break :blk CallResult{.sb = tmp, .has_comment = has_comment, .softline = true};
  \\   }
  \\   else if (fn_tkn) |ftkn| try self.tFnParams(id, ftkn, params, lb_has_trailing, top_comments)
  \\   else try self.tCallArgs(id, params, lb_has_trailing, top_comments, can_add_trailing_comma);
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn foo(
    \\  ... // abc
    \\) void {
    \\  if (last_tkn) |tkn| flat.decllineIf(self.tknHasTC(tkn))._();
    \\}
    \\
    \\fn bar(
    \\  x: anytype // abc
    \\) void {
    \\  const result = if (attr_doc) |doc| blk: {
    \\    var tmp = self.db.seqb();
    \\    if (top_comments) |c_doc| {
    \\      tmp.declline().append(c_doc);
    \\    } else if (lb_has_trailing) {
    \\      tmp.declline()._();
    \\    } else {
    \\      tmp.softline()._();
    \\    }
    \\    tmp.append(doc);
    \\    const has_comment = top_comments != null or lb_has_trailing;
    \\    break :blk CallResult{ .sb = tmp, .has_comment = has_comment, .softline = true };
    \\  } else if (fn_tkn) |ftkn|
    \\    try self.tFnParams(id, ftkn, params, lb_has_trailing, top_comments)
    \\  else
    \\    try self.tCallArgs(id, params, lb_has_trailing, top_comments, can_add_trailing_comma);
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn foo(
    \\  ... // abc
    \\) void {
    \\  if (last_tkn) |tkn| flat.decllineIf(self.tknHasTC(tkn))._();
    \\}
    \\
    \\fn bar(
    \\  x: anytype // abc
    \\) void {
    \\  const result = if (attr_doc) |doc| blk: {
    \\    var tmp = self.db.seqb();
    \\    if (top_comments) |c_doc| {
    \\      tmp.declline().append(c_doc);
    \\    } else if (lb_has_trailing) {
    \\      tmp.declline()._();
    \\    } else {
    \\      tmp.softline()._();
    \\    }
    \\    tmp.append(doc);
    \\    const has_comment = top_comments != null or lb_has_trailing;
    \\    break :blk CallResult{
    \\      .sb = tmp,
    \\      .has_comment = has_comment,
    \\      .softline = true,
    \\    };
    \\  } else if (fn_tkn) |ftkn|
    \\    try self.tFnParams(id, ftkn, params, lb_has_trailing, top_comments)
    \\  else
    \\    try self.tCallArgs(
    \\      id,
    \\      params,
    \\      lb_has_trailing,
    \\      top_comments,
    \\      can_add_trailing_comma,
    \\    );
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn foo(
    \\  ... // abc
    \\) void {
    \\  if (last_tkn) |tkn|
    \\    flat.decllineIf(self.tknHasTC(tkn))._();
    \\}
    \\
    \\fn bar(
    \\  x: anytype // abc
    \\) void {
    \\  const result = if (attr_doc) |doc| blk: {
    \\    var tmp = self.db.seqb();
    \\    if (top_comments) |c_doc| {
    \\      tmp.declline().append(c_doc);
    \\    } else if (lb_has_trailing) {
    \\      tmp.declline()._();
    \\    } else {
    \\      tmp.softline()._();
    \\    }
    \\    tmp.append(doc);
    \\    const has_comment = top_comments != null
    \\      or lb_has_trailing;
    \\    break :blk CallResult{
    \\      .sb = tmp,
    \\      .has_comment = has_comment,
    \\      .softline = true,
    \\    };
    \\  } else if (fn_tkn) |ftkn|
    \\    try self.tFnParams(
    \\      id,
    \\      ftkn,
    \\      params,
    \\      lb_has_trailing,
    \\      top_comments,
    \\    )
    \\  else
    \\    try self.tCallArgs(
    \\      id,
    \\      params,
    \\      lb_has_trailing,
    \\      top_comments,
    \\      can_add_trailing_comma,
    \\    );
    \\}
  );
}

test "fundecl 18" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo(x:u32, y:usize, z: usize, ... // abc
  \\ ) void { if (last_tkn) |tkn| flat.decllineIf(self.tknHasTC(tkn))._();}
  \\
  \\ fn bar(x: anytype // abc
  \\ ) void {
  \\ const result =
  \\   if (attr_doc) |doc| blk: {
  \\     var tmp = self.db.seqb();
  \\     if (top_comments) |c_doc| {
  \\       tmp.declline().append(c_doc);
  \\     } else if (lb_has_trailing) {
  \\       tmp.declline()._();
  \\     } else {
  \\       tmp.softline()._();
  \\     }
  \\     tmp.append(doc);
  \\     const has_comment = top_comments != null or lb_has_trailing;
  \\     break :blk CallResult{.sb = tmp, .has_comment = has_comment, .softline = true};
  \\   }
  \\   else if (fn_tkn) |ftkn| try self.tFnParams(id, ftkn, params, lb_has_trailing, top_comments)
  \\   else try self.tCallArgs(id, params, lb_has_trailing, top_comments, can_add_trailing_comma);
  \\}
  ;
  const al = arena.allocator();
  // using width: 30
  const doc = try translate(src, al);
  const res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo(
    \\  x: u32,
    \\  y: usize,
    \\  z: usize,
    \\  ... // abc
    \\) void {
    \\  if (last_tkn) |tkn|
    \\    flat.decllineIf(
    \\      self.tknHasTC(tkn),
    \\    )
    \\      ._();
    \\}
    \\
    \\fn bar(
    \\  x: anytype // abc
    \\) void {
    \\  const result = if (
    \\    attr_doc
    \\  ) |doc| blk: {
    \\    var tmp = self.db.seqb();
    \\    if (
    \\      top_comments
    \\    ) |c_doc| {
    \\      tmp.declline()
    \\        .append(c_doc);
    \\    } else if (
    \\      lb_has_trailing
    \\    ) {
    \\      tmp.declline()._();
    \\    } else {
    \\      tmp.softline()._();
    \\    }
    \\    tmp.append(doc);
    \\    const has_comment = top_comments
    \\      != null
    \\      or lb_has_trailing;
    \\    break :blk CallResult{
    \\      .sb = tmp,
    \\      .has_comment = has_comment,
    \\      .softline = true,
    \\    };
    \\  } else if (fn_tkn) |ftkn|
    \\    try self.tFnParams(
    \\      id,
    \\      ftkn,
    \\      params,
    \\      lb_has_trailing,
    \\      top_comments,
    \\    )
    \\  else
    \\    try self.tCallArgs(
    \\      id,
    \\      params,
    \\      lb_has_trailing,
    \\      top_comments,
    \\      can_add_trailing_comma,
    \\    );
    \\}
  );
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
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\  var x: u3 = 5;
    \\  const a, _ = expr;
    \\  var j = a * b;
    \\  var j = a * b + 5;
    \\  var j = x * x - (x + 5);
    \\  var j = x * x - (x + 5) + k;
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxMM * foom4
    \\    + barm3 * foom3
    \\    + barm2 * foom2
    \\    + barm1 * foom1
    \\    + bar0 * foo0
    \\    + bar1 * foo1
    \\    + bar2 * foo2
    \\    + bar3 / boxN * foo;
    \\  var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo + bar * foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo);
    \\}
  );
  // using width: 100, indent: 4
  res = try format(doc, .{ .width = 100, .indent = 4 }, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\    var x: u3 = 5;
    \\    const a, _ = expr;
    \\    var j = a * b;
    \\    var j = a * b + 5;
    \\    var j = x * x - (x + 5);
    \\    var j = x * x - (x + 5) + k;
    \\    var x = 1 * foo
    \\        + bar
    \\        - car * booh
    \\        - dah / boxMM * foom4
    \\        + barm3 * foom3
    \\        + barm2 * foom2
    \\        + barm1 * foom1
    \\        + bar0 * foo0
    \\        + bar1 * foo1
    \\        + bar2 * foo2
    \\        + bar3 / boxN * foo;
    \\    var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\    var x = 1 * foo
    \\        + bar
    \\        - car * booh
    \\        - dah / boxB * foo
    \\        + bar * foo
    \\        + bar * foo
    \\        + bar * foo
    \\        + (bar * foo + bar * foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
    \\    var x = 1 * foo
    \\        + bar
    \\        - car * booh
    \\        - dah / boxB * foo
    \\        + bar * foo
    \\        + bar * foo
    \\        + bar * foo
    \\        + (bar * foo
    \\            + bar * foo
    \\            + bar * foo
    \\            + bar / boxB * foo * foo
    \\            + bar / boxB * foo * foo
    \\            + bar / boxB * foo);
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\  var x: u3 = 5;
    \\  const a, _ = expr;
    \\  var j = a * b;
    \\  var j = a * b + 5;
    \\  var j = x * x - (x + 5);
    \\  var j = x * x - (x + 5) + k;
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxMM * foom4
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
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo);
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo);
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\  var x: u3 = 5;
    \\  const a, _ = expr;
    \\  var j = a * b;
    \\  var j = a * b + 5;
    \\  var j = x * x - (x + 5);
    \\  var j = x * x - (x + 5) + k;
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxMM * foom4
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
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo);
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo);
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\  var x: u3 = 5;
    \\  const a, _ = expr;
    \\  var j = a * b;
    \\  var j = a * b + 5;
    \\  var j = x * x - (x + 5);
    \\  var j = x * x - (x + 5) + k;
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxMM * foom4
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
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo);
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo);
    \\}
  );
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
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b + 5;
    \\var j = x * x - (x + 5);
    \\var j = x * x - (x + 5) + k;
    \\var x = 1 * foo
    \\  + bar
    \\  - car * booh
    \\  - dah / boxMM * foom4
    \\  + barm3 * foom3
    \\  + barm2 * foom2
    \\  + barm1 * foom1
    \\  + bar0 * foo0
    \\  + bar1 * foo1
    \\  + bar2 * foo2
    \\  + bar3 / boxN * foo;
    \\var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\var x = 1 * foo
    \\  + bar
    \\  - car * booh
    \\  - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo + bar * foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
    \\var x = 1 * foo
    \\  + bar
    \\  - car * booh
    \\  - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo);
  );
  // using width: 100, indent: 4
  res = try format(doc, .{ .width = 100, .indent = 4 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b + 5;
    \\var j = x * x - (x + 5);
    \\var j = x * x - (x + 5) + k;
    \\var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxMM * foom4
    \\    + barm3 * foom3
    \\    + barm2 * foom2
    \\    + barm1 * foom1
    \\    + bar0 * foo0
    \\    + bar1 * foo1
    \\    + bar2 * foo2
    \\    + bar3 / boxN * foo;
    \\var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo + bar * foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
    \\var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\        + bar * foo
    \\        + bar * foo
    \\        + bar / boxB * foo * foo
    \\        + bar / boxB * foo * foo
    \\        + bar / boxB * foo);
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b + 5;
    \\var j = x * x - (x + 5);
    \\var j = x * x - (x + 5) + k;
    \\var x = 1 * foo
    \\  + bar
    \\  - car * booh
    \\  - dah / boxMM * foom4
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
    \\  + bar
    \\  - car * booh
    \\  - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar / boxB * foo);
    \\var x = 1 * foo
    \\  + bar
    \\  - car * booh
    \\  - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo);
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b + 5;
    \\var j = x * x - (x + 5);
    \\var j = x * x - (x + 5) + k;
    \\var x = 1 * foo
    \\  + bar
    \\  - car * booh
    \\  - dah / boxMM * foom4
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
    \\  + bar
    \\  - car * booh
    \\  - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar / boxB * foo);
    \\var x = 1 * foo
    \\  + bar
    \\  - car * booh
    \\  - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo);
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b + 5;
    \\var j = x * x - (x + 5);
    \\var j = x * x - (x + 5) + k;
    \\var x = 1 * foo
    \\  + bar
    \\  - car * booh
    \\  - dah / boxMM * foom4
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
    \\  + bar
    \\  - car * booh
    \\  - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar / boxB * foo);
    \\var x = 1 * foo
    \\  + bar
    \\  - car * booh
    \\  - dah / boxB * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + bar * foo
    \\  + (bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo * foo
    \\    + bar / boxB * foo);
  );
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
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car * booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2 * barm1
    \\  * foom1
    \\  * bar0
    \\  * foo0
    \\  * bar1
    \\  * foo1
    \\  * bar2
    \\  * foo2
    \\  * bar3
    \\  / boxN
    \\  * foo;
    \\var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB * foo);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB * foo * foo * bar
    \\    / boxB
    \\    * foo);
  );
  // using width: 100, indent: 4
  res = try format(doc, .{ .width = 100, .indent = 4 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car * booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2 * barm1
    \\    * foom1
    \\    * bar0
    \\    * foo0
    \\    * bar1
    \\    * foo1
    \\    * bar2
    \\    * foo2
    \\    * bar3
    \\    / boxN
    \\    * foo;
    \\var x = this.is.fancy(a.b().not().so(a, b), a.b().not().so(a, b), a.b().not().so(a, b));
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB * foo);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB * foo * foo * bar
    \\        / boxB
    \\        * foo);
  );
  res = try format(doc, .{ .width = 80, .indent = 4 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car * booh / dah / boxMM * foom4 * barm3 * foom3 * barm2
    \\    * foom2
    \\    * barm1
    \\    * foom1
    \\    * bar0
    \\    * foo0
    \\    * bar1
    \\    * foo1
    \\    * bar2
    \\    * foo2
    \\    * bar3
    \\    / boxN
    \\    * foo;
    \\var x = this.is.fancy(
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo
    \\    * bar
    \\    * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB
    \\        * foo);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo
    \\    * bar
    \\    * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB
    \\        * foo
    \\        * foo
    \\        * bar
    \\        / boxB
    \\        * foo);
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car * booh / dah / boxMM * foom4
    \\  * barm3
    \\  * foom3
    \\  * barm2
    \\  * foom2
    \\  * barm1
    \\  * foom1
    \\  * bar0
    \\  * foo0
    \\  * bar1
    \\  * foo1
    \\  * bar2
    \\  * foo2
    \\  * bar3
    \\  / boxN
    \\  * foo;
    \\var x = this.is.fancy(
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar * foo * bar
    \\    * foo
    \\    * bar
    \\    / boxB
    \\    * foo);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar / boxB * foo
    \\    * foo
    \\    * bar
    \\    / boxB
    \\    * foo
    \\    * foo
    \\    * bar
    \\    / boxB
    \\    * foo);
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car
    \\  * booh
    \\  / dah
    \\  / boxMM
    \\  * foom4
    \\  * barm3
    \\  * foom3
    \\  * barm2
    \\  * foom2
    \\  * barm1
    \\  * foom1
    \\  * bar0
    \\  * foo0
    \\  * bar1
    \\  * foo1
    \\  * bar2
    \\  * foo2
    \\  * bar3
    \\  / boxN
    \\  * foo;
    \\var x = this.is.fancy(
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car
    \\  * booh
    \\  / dah
    \\  / boxB
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * (bar * foo * bar * foo
    \\    * bar
    \\    * foo
    \\    * bar
    \\    * foo
    \\    * bar
    \\    * foo
    \\    * bar
    \\    / boxB
    \\    * foo);
    \\var x = 1 * foo * bar / car
    \\  * booh
    \\  / dah
    \\  / boxB
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * (bar * foo * bar * foo
    \\    * bar
    \\    * foo
    \\    * bar
    \\    / boxB
    \\    * foo
    \\    * foo
    \\    * bar
    \\    / boxB
    \\    * foo
    \\    * foo
    \\    * bar
    \\    / boxB
    \\    * foo);
  );
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
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car
    \\  - booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2 * barm1 * foom1 * bar0 * foo0 * bar1
    \\    * foo1
    \\    * bar2
    \\    * foo2
    \\    * bar3
    \\    / boxN
    \\    * foo;
    \\var x = this.is.fancy(
    \\  a.b((a * b + 5 * 6 / c * 12 / xyz)).not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB * foo);
    \\var x = 1 * foo * bar * car
    \\  + booh / dah / boxB
    \\  - foo * bar * foo * bar * foo * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB * foo * foo * bar
    \\      / boxB
    \\      * foo);
  );
  // using width: 100, indent: 4
  res = try format(doc, .{ .width = 100, .indent = 4 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car
    \\    - booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2 * barm1 * foom1 * bar0 * foo0
    \\        * bar1
    \\        * foo1
    \\        * bar2
    \\        * foo2
    \\        * bar3
    \\        / boxN
    \\        * foo;
    \\var x = this.is.fancy(
    \\    a.b((a * b + 5 * 6 / c * 12 / xyz)).not().so(a, b),
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB * foo);
    \\var x = 1 * foo * bar * car
    \\    + booh / dah / boxB
    \\    - foo * bar * foo * bar * foo * bar * foo
    \\        * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar / boxB * foo * foo * bar
    \\            / boxB
    \\            * foo);
  );
  res = try format(doc, .{ .width = 80, .indent = 4 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car
    \\    - booh / dah / boxMM * foom4 * barm3 * foom3 * barm2 * foom2 * barm1 * foom1
    \\        * bar0
    \\        * foo0
    \\        * bar1
    \\        * foo1
    \\        * bar2
    \\        * foo2
    \\        * bar3
    \\        / boxN
    \\        * foo;
    \\var x = this.is.fancy(
    \\    a.b((a * b + 5 * 6 / c * 12 / xyz)).not().so(a, b),
    \\    a.b().not().so(a, b),
    \\    a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar * foo * bar * foo
    \\    * bar
    \\    * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar * foo * bar * foo * bar / boxB
    \\        * foo);
    \\var x = 1 * foo * bar * car
    \\    + booh / dah / boxB
    \\    - foo * bar * foo * bar * foo * bar * foo
    \\        * (bar * foo * bar * foo * bar * foo * bar / boxB * foo * foo * bar
    \\            / boxB
    \\            * foo
    \\            * foo
    \\            * bar
    \\            / boxB
    \\            * foo);
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car
    \\  - booh / dah / boxMM * foom4 * barm3 * foom3 * barm2
    \\    * foom2
    \\    * barm1
    \\    * foom1
    \\    * bar0
    \\    * foo0
    \\    * bar1
    \\    * foo1
    \\    * bar2
    \\    * foo2
    \\    * bar3
    \\    / boxN
    \\    * foo;
    \\var x = this.is.fancy(
    \\  a.b((a * b + 5 * 6 / c * 12 / xyz)).not().so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car * booh / dah / boxB * foo * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * (bar * foo * bar * foo * bar * foo * bar * foo * bar
    \\    * foo
    \\    * bar
    \\    / boxB
    \\    * foo);
    \\var x = 1 * foo * bar * car
    \\  + booh / dah / boxB
    \\  - foo * bar * foo * bar * foo * bar * foo
    \\    * (bar * foo * bar * foo * bar * foo * bar / boxB * foo
    \\      * foo
    \\      * bar
    \\      / boxB
    \\      * foo
    \\      * foo
    \\      * bar
    \\      / boxB
    \\      * foo);
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var x: u3 = 5;
    \\var j = a * b;
    \\var j = a * b * 5;
    \\var j = x * x / (x * 5);
    \\var j = x * x / (x * 5) * k;
    \\var x = 1 * foo * bar / car
    \\  - booh / dah / boxMM * foom4
    \\    * barm3
    \\    * foom3
    \\    * barm2
    \\    * foom2
    \\    * barm1
    \\    * foom1
    \\    * bar0
    \\    * foo0
    \\    * bar1
    \\    * foo1
    \\    * bar2
    \\    * foo2
    \\    * bar3
    \\    / boxN
    \\    * foo;
    \\var x = this.is.fancy(
    \\  a.b(
    \\    (a * b
    \\      + 5 * 6 / c * 12 / xyz),
    \\  )
    \\    .not()
    \\    .so(a, b),
    \\  a.b().not().so(a, b),
    \\  a.b().not().so(a, b),
    \\);
    \\var x = 1 * foo * bar / car
    \\  * booh
    \\  / dah
    \\  / boxB
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * bar
    \\  * foo
    \\  * (bar * foo * bar * foo
    \\    * bar
    \\    * foo
    \\    * bar
    \\    * foo
    \\    * bar
    \\    * foo
    \\    * bar
    \\    / boxB
    \\    * foo);
    \\var x = 1 * foo * bar * car
    \\  + booh / dah / boxB
    \\  - foo * bar * foo * bar
    \\    * foo
    \\    * bar
    \\    * foo
    \\    * (bar * foo * bar * foo
    \\      * bar
    \\      * foo
    \\      * bar
    \\      / boxB
    \\      * foo
    \\      * foo
    \\      * bar
    \\      / boxB
    \\      * foo
    \\      * foo
    \\      * bar
    \\      / boxB
    \\      * foo);
  );
}

test "expr 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) catch expr();
  \\ var abc = 5 * 4 + 3 - abc + 4 - 3 + (someFunc(1, 2, 3) catch expr());
  \\ var xyz = a + b - c * d;
  \\ var xyz = a + b * c - d;
  \\ var xyz = a * b * c - d;
  \\ var xyz = a * b * c / d * e ;
  \\ var xyz = a * b * c * d * e * ga * b * c * d * e - f;
  \\ var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) * expr();
  \\ var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) * expr() + 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) * expr();
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) catch expr();
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + (someFunc(1, 2, 3) catch expr());
    \\var xyz = a + b - c * d;
    \\var xyz = a + b * c - d;
    \\var xyz = a * b * c - d;
    \\var xyz = a * b * c / d * e;
    \\var xyz = a * b * c * d * e * ga * b * c * d * e - f;
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) * expr();
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + someFunc(1, 2, 3) * expr()
    \\  + 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + someFunc(1, 2, 3) * expr();
  );
  // using width: 100, indent: 4
  res = try format(doc, .{ .width = 100, .indent = 4 }, al);
  try check(
    res,
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) catch expr();
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + (someFunc(1, 2, 3) catch expr());
    \\var xyz = a + b - c * d;
    \\var xyz = a + b * c - d;
    \\var xyz = a * b * c - d;
    \\var xyz = a * b * c / d * e;
    \\var xyz = a * b * c * d * e * ga * b * c * d * e - f;
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) * expr();
    \\var abc = 5 * 4
    \\    + 3
    \\    - abc
    \\    + 4
    \\    - 3
    \\    + someFunc(1, 2, 3) * expr()
    \\    + 5 * 4
    \\    + 3
    \\    - abc
    \\    + 4
    \\    - 3
    \\    + someFunc(1, 2, 3) * expr();
  );
  res = try format(doc, .{ .width = 80, .indent = 4 }, al);
  try check(
    res,
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) catch expr();
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + (someFunc(1, 2, 3) catch expr());
    \\var xyz = a + b - c * d;
    \\var xyz = a + b * c - d;
    \\var xyz = a * b * c - d;
    \\var xyz = a * b * c / d * e;
    \\var xyz = a * b * c * d * e * ga * b * c * d * e - f;
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) * expr();
    \\var abc = 5 * 4
    \\    + 3
    \\    - abc
    \\    + 4
    \\    - 3
    \\    + someFunc(1, 2, 3) * expr()
    \\    + 5 * 4
    \\    + 3
    \\    - abc
    \\    + 4
    \\    - 3
    \\    + someFunc(1, 2, 3) * expr();
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3)
    \\  catch expr();
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + (someFunc(1, 2, 3) catch expr());
    \\var xyz = a + b - c * d;
    \\var xyz = a + b * c - d;
    \\var xyz = a * b * c - d;
    \\var xyz = a * b * c / d * e;
    \\var xyz = a * b * c * d * e * ga * b * c * d * e - f;
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + someFunc(1, 2, 3) * expr();
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + someFunc(1, 2, 3) * expr()
    \\  + 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + someFunc(1, 2, 3) * expr();
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + someFunc(1, 2, 3)
    \\  catch expr();
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + (someFunc(1, 2, 3)
    \\    catch expr());
    \\var xyz = a + b - c * d;
    \\var xyz = a + b * c - d;
    \\var xyz = a * b * c - d;
    \\var xyz = a * b * c / d * e;
    \\var xyz = a * b * c * d * e
    \\  * ga
    \\  * b
    \\  * c
    \\  * d
    \\  * e
    \\  - f;
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + someFunc(1, 2, 3)
    \\    * expr();
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + someFunc(1, 2, 3) * expr()
    \\  + 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + someFunc(1, 2, 3)
    \\    * expr();
  );
}

test "containerdecl 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = struct {
  \\  x: []const u8,
  \\  y: u32
  \\};
  \\ const Ty = struct {
  \\  ab: []const u8,
  \\  xyz: u32,
  \\};
  \\ const Ty = struct(arg) {
  \\  ab: []const u8,
  \\  xyz: u32,
  \\};
  \\ const Ty = packed struct {
  \\  x1: []const u8,
  \\  y1: u32,
  \\};
  \\ const Ty = extern struct {
  \\  x2: []const u8,
  \\  y2: u32,
  \\};
  \\ const Ty = extern struct(arg) {
  \\  x2: []const u8,
  \\  y2: u32,
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = struct { x: []const u8, y: u32 };
    \\const Ty = struct { ab: []const u8, xyz: u32 };
    \\const Ty = struct(arg) { ab: []const u8, xyz: u32 };
    \\const Ty = packed struct { x1: []const u8, y1: u32 };
    \\const Ty = extern struct { x2: []const u8, y2: u32 };
    \\const Ty = extern struct(arg) { x2: []const u8, y2: u32 };
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = struct { x: []const u8, y: u32 };
    \\const Ty = struct { ab: []const u8, xyz: u32 };
    \\const Ty = struct(arg) { ab: []const u8, xyz: u32 };
    \\const Ty = packed struct { x1: []const u8, y1: u32 };
    \\const Ty = extern struct { x2: []const u8, y2: u32 };
    \\const Ty = extern struct(arg) { x2: []const u8, y2: u32 };
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = struct { x: []const u8, y: u32 };
    \\const Ty = struct { ab: []const u8, xyz: u32 };
    \\const Ty = struct(arg) { ab: []const u8, xyz: u32 };
    \\const Ty = packed struct { x1: []const u8, y1: u32 };
    \\const Ty = extern struct { x2: []const u8, y2: u32 };
    \\const Ty = extern struct(arg) { x2: []const u8, y2: u32 };
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = struct {
    \\  x: []const u8,
    \\  y: u32,
    \\};
    \\const Ty = struct {
    \\  ab: []const u8,
    \\  xyz: u32,
    \\};
    \\const Ty = struct(arg) {
    \\  ab: []const u8,
    \\  xyz: u32,
    \\};
    \\const Ty = packed struct {
    \\  x1: []const u8,
    \\  y1: u32,
    \\};
    \\const Ty = extern struct {
    \\  x2: []const u8,
    \\  y2: u32,
    \\};
    \\const Ty = extern struct(
    \\  arg
    \\) {
    \\  x2: []const u8,
    \\  y2: u32,
    \\};
  );
}

test "containerdecl 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = struct {
  \\  xabc: []const u8,
  \\  y123: u32,
  \\
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay"};
  \\ }
  \\
  \\  pub fn foo(self: @This()) !@This(a, b, c, d) {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{  .al = al,       .cfg = cfg,     .mem_writer = std.Io.Writer.Allocating.init(al),     .out_writer = std.fs.File.Writer.init(std.fs.File.stdout(), &WriteBuf),   };
  \\ }
  \\
  \\  pub noinline fn foo(self: @This()) Foo!@This(a, b, c, d) {
  \\   var j = Ty{.x = "yay", .y = 0xff, .y = 0xff, .y = 0xff, .y = 0xff, .y = 0xff, .y = 0xff, .y = 0xff, .y = 0xff};
  \\   return .{.x = "yay"};
  \\ }
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = struct {
    \\  xabc: []const u8,
    \\  y123: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay" };
    \\  }
    \\
    \\  pub fn foo(self: @This()) !@This(a, b, c, d) {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{
    \\      .al = al,
    \\      .cfg = cfg,
    \\      .mem_writer = std.Io.Writer.Allocating.init(al),
    \\      .out_writer = std.fs.File.Writer.init(std.fs.File.stdout(), &WriteBuf),
    \\    };
    \\  }
    \\
    \\  pub noinline fn foo(self: @This()) Foo!@This(a, b, c, d) {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\    };
    \\    return .{ .x = "yay" };
    \\  }
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = struct {
    \\  xabc: []const u8,
    \\  y123: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay" };
    \\  }
    \\
    \\  pub fn foo(self: @This()) !@This(a, b, c, d) {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{
    \\      .al = al,
    \\      .cfg = cfg,
    \\      .mem_writer = std.Io.Writer.Allocating.init(al),
    \\      .out_writer = std.fs.File.Writer.init(std.fs.File.stdout(), &WriteBuf),
    \\    };
    \\  }
    \\
    \\  pub noinline fn foo(self: @This()) Foo!@This(a, b, c, d) {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\    };
    \\    return .{ .x = "yay" };
    \\  }
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = struct {
    \\  xabc: []const u8,
    \\  y123: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay" };
    \\  }
    \\
    \\  pub fn foo(self: @This()) !@This(a, b, c, d) {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{
    \\      .al = al,
    \\      .cfg = cfg,
    \\      .mem_writer = std.Io.Writer.Allocating.init(al),
    \\      .out_writer = std.fs.File.Writer.init(
    \\        std.fs.File.stdout(),
    \\        &WriteBuf,
    \\      ),
    \\    };
    \\  }
    \\
    \\  pub noinline fn foo(self: @This()) Foo!@This(a, b, c, d) {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\    };
    \\    return .{ .x = "yay" };
    \\  }
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = struct {
    \\  xabc: []const u8,
    \\  y123: u32,
    \\
    \\  pub fn foo(
    \\    self: @This(),
    \\  ) @This() {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\    return .{ .x = "yay" };
    \\  }
    \\
    \\  pub fn foo(
    \\    self: @This(),
    \\  ) !@This(a, b, c, d) {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\    return .{
    \\      .al = al,
    \\      .cfg = cfg,
    \\      .mem_writer = std.Io.Writer.Allocating.init(
    \\        al,
    \\      ),
    \\      .out_writer = std.fs.File.Writer.init(
    \\        std.fs.File.stdout(),
    \\        &WriteBuf,
    \\      ),
    \\    };
    \\  }
    \\
    \\  pub noinline fn foo(
    \\    self: @This(),
    \\  ) Foo!@This(a, b, c, d) {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\      .y = 0xff,
    \\    };
    \\    return .{ .x = "yay" };
    \\  }
    \\};
  );
}

test "containerdecl 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\pub const FmtConfig = struct {
  \\  width: u32 = 80,
  \\  indent: u8 = 2,
  \\  decl_line_seps: u8 = 2,
  \\  writer: enum (u3) {
  \\    file,
  \\    out,
  \\    mem,
  \\  } = .mem,
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) { file, out, mem } = .mem,
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) { file, out, mem } = .mem,
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) { file, out, mem } = .mem,
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) {
    \\    file,
    \\    out,
    \\    mem,
    \\  } = .mem,
    \\};
  );
}

test "containerdecl 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = union(enum) {
  \\  x: []const u8,
  \\  y: u32,
  \\
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\};
  \\ const Ty = union(Foo) {
  \\  x: []const u8,
  \\  y: u32,
  \\
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
    \\const Ty = union(Foo) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
    \\const Ty = union(Foo) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
    \\const Ty = union(Foo) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(
    \\    self: @This(),
    \\  ) @This() {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\    return .{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\  }
    \\};
    \\const Ty = union(Foo) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(
    \\    self: @This(),
    \\  ) @This() {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\    return .{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\  }
    \\};
  );
}

test "containerdecl 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = union(enum) {
  \\  x: []const u8,
  \\  y: u32
  \\};
  \\ const Ty = union(Foo) {
  \\  x: []const u8,
  \\  y: u32,
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = union(enum) { x: []const u8, y: u32 };
    \\const Ty = union(Foo) { x: []const u8, y: u32 };
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = union(enum) { x: []const u8, y: u32 };
    \\const Ty = union(Foo) { x: []const u8, y: u32 };
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = union(enum) { x: []const u8, y: u32 };
    \\const Ty = union(Foo) { x: []const u8, y: u32 };
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\};
    \\const Ty = union(Foo) {
    \\  x: []const u8,
    \\  y: u32,
    \\};
  );
}

test "containerdecl 6" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = union(enum(Foo)) {
  \\  x: []const u8,
  \\  y: u32
  \\};
  \\ const Ty = union(enum(Foo)) {
  \\  x: []const u8,
  \\  y: u32,
  \\};
  \\ const Ty = union(enum(Foo(a, b, c))) {
  \\  x: []const u8,
  \\  y: u32,
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = union(enum(Foo)) {
    \\  x: []const u8,
    \\  y: u32,
    \\};
    \\const Ty = union(enum(Foo)) {
    \\  x: []const u8,
    \\  y: u32,
    \\};
    \\const Ty = union(
    \\  enum(Foo(a, b, c))
    \\) {
    \\  x: []const u8,
    \\  y: u32,
    \\  pub fn foo(
    \\    self: @This(),
    \\  ) @This() {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\    return .{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\  }
    \\};
  );
}

test "containerdecl 7" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = struct(arg.foo(xyz, "ok").bar('y').yes(a, b, c, d)) {
  \\  ab: []const u8,
  \\  xyz: u32,
  \\};
  \\ const Ty = struct(Foo) {
  \\  x: []const u8,
  \\  y: u32,
  \\};
  \\ const Ty = struct {
  \\  x: []const u8 align(abc),
  \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
  \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(11, "yes"),
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = struct(arg.foo(xyz, "ok").bar('y').yes(a, b, c, d)) { ab: []const u8, xyz: u32 };
    \\const Ty = struct(Foo) { x: []const u8, y: u32 };
    \\const Ty = struct {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
    \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(11, "yes"),
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = struct(arg.foo(xyz, "ok").bar('y').yes(a, b, c, d)) {
    \\  ab: []const u8,
    \\  xyz: u32,
    \\};
    \\const Ty = struct(Foo) { x: []const u8, y: u32 };
    \\const Ty = struct {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
    \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(11, "yes"),
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = struct(
    \\  arg.foo(xyz, "ok").bar('y').yes(a, b, c, d)
    \\) {
    \\  ab: []const u8,
    \\  xyz: u32,
    \\};
    \\const Ty = struct(Foo) { x: []const u8, y: u32 };
    \\const Ty = struct {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
    \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(
    \\    11,
    \\    "yes",
    \\  ),
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = struct(
    \\  arg.foo(xyz, "ok")
    \\    .bar('y')
    \\    .yes(a, b, c, d)
    \\) {
    \\  ab: []const u8,
    \\  xyz: u32,
    \\};
    \\const Ty = struct(Foo) {
    \\  x: []const u8,
    \\  y: u32,
    \\};
    \\const Ty = struct {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(
    \\    foo(a, b, c, d)
    \\  ) = box(11, "yes"),
    \\  z: u32 align(
    \\    foo(
    \\      bar(1, 'a'),
    \\      yes("joe", xyz),
    \\    )
    \\  ) = box(11, "yes"),
    \\};
  );
}

test "containerdecl 8" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = opaque {
  \\  x: []const u8,
  \\  y: u32,
  \\};
  \\ const Ty = opaque {
  \\  x: []const u8 align(abc),
  \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
  \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(11, "yes"),
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = opaque { x: []const u8, y: u32 };
    \\const Ty = opaque {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
    \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(11, "yes"),
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = opaque { x: []const u8, y: u32 };
    \\const Ty = opaque {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
    \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(11, "yes"),
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = opaque { x: []const u8, y: u32 };
    \\const Ty = opaque {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
    \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(
    \\    11,
    \\    "yes",
    \\  ),
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = opaque {
    \\  x: []const u8,
    \\  y: u32,
    \\};
    \\const Ty = opaque {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(
    \\    foo(a, b, c, d)
    \\  ) = box(11, "yes"),
    \\  z: u32 align(
    \\    foo(
    \\      bar(1, 'a'),
    \\      yes("joe", xyz),
    \\    )
    \\  ) = box(11, "yes"),
    \\};
  );
}

test "containerdecl 9" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = union(enum(Foo(a, b, c))) {
  \\  x: []const u8,
  \\  y: u32,
  \\
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\
  \\ const fox = 0xdeadbeef;
  \\ const fox = enum {a, b, c};
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\
    \\  const fox = 0xdeadbeef;
    \\  const fox = enum { a, b, c };
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\
    \\  const fox = 0xdeadbeef;
    \\  const fox = enum { a, b, c };
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\
    \\  const fox = 0xdeadbeef;
    \\  const fox = enum { a, b, c };
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = union(
    \\  enum(Foo(a, b, c))
    \\) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(
    \\    self: @This(),
    \\  ) @This() {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\    return .{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\  }
    \\
    \\  const fox = 0xdeadbeef;
    \\  const fox = enum {
    \\    a,
    \\    b,
    \\    c,
    \\  };
    \\};
  );
}

test "containerdecl 10" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = union(enum(Foo(a, b, c))) {
  \\  x: []const u8,
  \\  y: u32,
  \\ abc: []const u8,
  \\ x: usize,
  \\
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\
  \\ const fox1 = 0xdeadbeef;
  \\ const fox2 = enum {a, b, c};
  \\ const fox3 = union (big) {a, b, c};
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox2 = enum { a, b, c };
    \\  const fox3 = union(big) { a, b, c };
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox2 = enum { a, b, c };
    \\  const fox3 = union(big) { a, b, c };
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox2 = enum { a, b, c };
    \\  const fox3 = union(big) { a, b, c };
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = union(
    \\  enum(Foo(a, b, c))
    \\) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\
    \\  pub fn foo(
    \\    self: @This(),
    \\  ) @This() {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\    return .{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\  }
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox2 = enum {
    \\    a,
    \\    b,
    \\    c,
    \\  };
    \\  const fox3 = union(big) {
    \\    a,
    \\    b,
    \\    c,
    \\  };
    \\};
  );
}

test "containerdecl 11" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = union(enum) {
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  pub fn foo(
    \\    self: @This(),
    \\  ) @This() {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\    return .{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\  }
    \\
    \\  pub fn foo(
    \\    self: @This(),
    \\  ) @This() {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\    return .{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\  }
    \\};
  );
}

test "containerdecl 12" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = union(enum) {
  \\  x: []const u8,
  \\  y: u32,
  \\ abc: []const u8,
  \\ x: usize,
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\ pub fn x() void {}
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\  pub fn x() void {}
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\  pub fn x() void {}
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{ .x = "yay", .y = 0xff };
    \\    return .{ .x = "yay", .y = 0xff };
    \\  }
    \\  pub fn x() void {}
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\  pub fn foo(
    \\    self: @This(),
    \\  ) @This() {
    \\    var j = Ty{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\    return .{
    \\      .x = "yay",
    \\      .y = 0xff,
    \\    };
    \\  }
    \\  pub fn x() void {}
    \\};
  );
}

test "containerdecl 13" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\y: []u8,
  \\abc: []const u8,
  \\z: u32,
  \\
  \\y: []u8,
  \\abc: []const u8,
  \\z: u32,
  \\
  \\pub const Ty = union(enum) {
  \\  x: []const u8,
  \\  y: u32,
  \\
  \\  const fox1 = 0xdeadbeef;
  \\  const fox1 = struct {};
  \\};
  \\var x = 5;
  \\
  \\pub const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
  \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
  \\const Ty = union(enum(Foo(a, b, c))) {};
  \\var x = 5;
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\pub const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox1 = struct {};
    \\};
    \\var x = 5;
    \\
    \\pub const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {};
    \\var x = 5;
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\pub const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox1 = struct {};
    \\};
    \\var x = 5;
    \\
    \\pub const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {};
    \\var x = 5;
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\pub const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox1 = struct {};
    \\};
    \\var x = 5;
    \\
    \\pub const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {};
    \\var x = 5;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\pub const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox1 = struct {};
    \\};
    \\var x = 5;
    \\
    \\pub const Ty = union(
    \\  enum(Foo)
    \\) {
    \\  x: []const u8,
    \\  y: u32,
    \\};
    \\const Ty = union(enum(Foo)) {
    \\  x: []const u8,
    \\  y: u32,
    \\};
    \\const Ty = union(
    \\  enum(Foo(a, b, c))
    \\) {};
    \\var x = 5;
  );
}

test "containerdecl 14" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ y: []u8,
  \\ abc: []const u8,
  \\ z: u32,
  \\ y: []u8,
  \\ abc: []const u8,
  \\ z: u32,
  \\ var x = 5;
  \\ pub const Ty = 0xff;
  \\ var x = 5;
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\var x = 5;
    \\pub const Ty = 0xff;
    \\var x = 5;
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\var x = 5;
    \\pub const Ty = 0xff;
    \\var x = 5;
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\var x = 5;
    \\pub const Ty = 0xff;
    \\var x = 5;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\var x = 5;
    \\pub const Ty = 0xff;
    \\var x = 5;
  );
}

test "containerdecl 15" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\pub const FmtConfig = struct {
  \\  width: u32 = 80,
  \\  indent: u8 = 2,
  \\  decl_line_seps: u8 = 2,
  \\  writer: enum (u3) {
  \\    file: File,
  \\    out: Out,
  \\    mem: Mem,
  \\  } = .mem,
  \\};
  \\  const fox2 = enum { a, b, c };
  \\  const fox3 = union(big) { a: A(abc, xyz), b: B, c: C(Type("Foo")) };
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) { file: File, out: Out, mem: Mem } = .mem,
    \\};
    \\const fox2 = enum { a, b, c };
    \\const fox3 = union(big) { a: A(abc, xyz), b: B, c: C(Type("Foo")) };
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) { file: File, out: Out, mem: Mem } = .mem,
    \\};
    \\const fox2 = enum { a, b, c };
    \\const fox3 = union(big) { a: A(abc, xyz), b: B, c: C(Type("Foo")) };
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) {
    \\    file: File,
    \\    out: Out,
    \\    mem: Mem,
    \\  } = .mem,
    \\};
    \\const fox2 = enum { a, b, c };
    \\const fox3 = union(big) {
    \\  a: A(abc, xyz),
    \\  b: B,
    \\  c: C(Type("Foo")),
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) {
    \\    file: File,
    \\    out: Out,
    \\    mem: Mem,
    \\  } = .mem,
    \\};
    \\const fox2 = enum { a, b, c };
    \\const fox3 = union(big) {
    \\  a: A(abc, xyz),
    \\  b: B,
    \\  c: C(Type("Foo")),
    \\};
  );
}

test "ptr types 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var j: [*]align(foo(bar.oop(0x12))) rhs = 0xff;
  \\ var j: *align(foo(bar.oop(0x12)):Foo():Bar()) rhs = 0xff;
  \\ var j: *align(foo:Car:Bar) rhs = 0xff;
  \\ var j: *align(foo():Car():Bar()) rhs = 0xff;
  \\ var x: *align(foo("ok")) rhs = 0xff;
  \\ var a: **rhs = 0xff;
  \\ var abc: ***align(foo():Car():Bar()) rhs = 0xff;
  \\ var xyz: **align(foo():Car():Bar()) rhs = 0xff;
  \\ var a: ***rhs = 0xff;
  \\ var y: []rhs = 0xff;
  \\ var y: []const rhs = 0xff;
  \\ var k: [*:lhs]rhs = 0xff;
  \\ var a: [:lhs]rhs = 0xff;
  \\ var j: [lhs:Foo(T, K)] rhs = 0xff;
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var j: [*]align(foo(bar.oop(0x12))) rhs = 0xff;
    \\var j: *align(foo(bar.oop(0x12)):Foo():Bar()) rhs = 0xff;
    \\var j: *align(foo:Car:Bar) rhs = 0xff;
    \\var j: *align(foo():Car():Bar()) rhs = 0xff;
    \\var x: *align(foo("ok")) rhs = 0xff;
    \\var a: **rhs = 0xff;
    \\var abc: ***align(foo():Car():Bar()) rhs = 0xff;
    \\var xyz: **align(foo():Car():Bar()) rhs = 0xff;
    \\var a: ***rhs = 0xff;
    \\var y: []rhs = 0xff;
    \\var y: []const rhs = 0xff;
    \\var k: [*:lhs]rhs = 0xff;
    \\var a: [:lhs]rhs = 0xff;
    \\var j: [lhs:Foo(T, K)]rhs = 0xff;
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\var j: [*]align(foo(bar.oop(0x12))) rhs = 0xff;
    \\var j: *align(foo(bar.oop(0x12)):Foo():Bar()) rhs = 0xff;
    \\var j: *align(foo:Car:Bar) rhs = 0xff;
    \\var j: *align(foo():Car():Bar()) rhs = 0xff;
    \\var x: *align(foo("ok")) rhs = 0xff;
    \\var a: **rhs = 0xff;
    \\var abc: ***align(foo():Car():Bar()) rhs = 0xff;
    \\var xyz: **align(foo():Car():Bar()) rhs = 0xff;
    \\var a: ***rhs = 0xff;
    \\var y: []rhs = 0xff;
    \\var y: []const rhs = 0xff;
    \\var k: [*:lhs]rhs = 0xff;
    \\var a: [:lhs]rhs = 0xff;
    \\var j: [lhs:Foo(T, K)]rhs = 0xff;
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var j: [*]align(foo(bar.oop(0x12))) rhs = 0xff;
    \\var j: *align(foo(bar.oop(0x12)):Foo():Bar()) rhs = 0xff;
    \\var j: *align(foo:Car:Bar) rhs = 0xff;
    \\var j: *align(foo():Car():Bar()) rhs = 0xff;
    \\var x: *align(foo("ok")) rhs = 0xff;
    \\var a: **rhs = 0xff;
    \\var abc: ***align(foo():Car():Bar()) rhs = 0xff;
    \\var xyz: **align(foo():Car():Bar()) rhs = 0xff;
    \\var a: ***rhs = 0xff;
    \\var y: []rhs = 0xff;
    \\var y: []const rhs = 0xff;
    \\var k: [*:lhs]rhs = 0xff;
    \\var a: [:lhs]rhs = 0xff;
    \\var j: [lhs:Foo(T, K)]rhs = 0xff;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var j: [*]align(
    \\  foo(bar.oop(0x12))
    \\)
    \\  rhs = 0xff;
    \\var j: *align(
    \\  foo(bar.oop(0x12))
    \\    :Foo()
    \\    :Bar()
    \\)
    \\  rhs = 0xff;
    \\var j: *align(foo:Car:Bar)
    \\  rhs = 0xff;
    \\var j: *align(
    \\  foo()
    \\    :Car()
    \\    :Bar()
    \\)
    \\  rhs = 0xff;
    \\var x: *align(foo("ok"))
    \\  rhs = 0xff;
    \\var a: **rhs = 0xff;
    \\var abc: ***align(
    \\  foo()
    \\    :Car()
    \\    :Bar()
    \\)
    \\  rhs = 0xff;
    \\var xyz: **align(
    \\  foo()
    \\    :Car()
    \\    :Bar()
    \\)
    \\  rhs = 0xff;
    \\var a: ***rhs = 0xff;
    \\var y: []rhs = 0xff;
    \\var y: []const rhs = 0xff;
    \\var k: [*:lhs]rhs = 0xff;
    \\var a: [:lhs]rhs = 0xff;
    \\var j: [
    \\  lhs:Foo(T, K)
    \\]rhs = 0xff;
  );
}

test "ptr types 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var j: [lhs:Foo(T, K)] rhs = 0xff;
  \\var j: [lhs:Foo(T, K)]Foo(Bar.xyz(abc)) = 0xff;
  \\var j: [*c]align(foo(bar.oop(0x12))) rhs = 0xff;
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var j: [lhs:Foo(T, K)]rhs = 0xff;
    \\var j: [lhs:Foo(T, K)]Foo(Bar.xyz(abc)) = 0xff;
    \\var j: [*c]align(foo(bar.oop(0x12))) rhs = 0xff;
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\var j: [lhs:Foo(T, K)]rhs = 0xff;
    \\var j: [lhs:Foo(T, K)]Foo(Bar.xyz(abc)) = 0xff;
    \\var j: [*c]align(foo(bar.oop(0x12))) rhs = 0xff;
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var j: [lhs:Foo(T, K)]rhs = 0xff;
    \\var j: [lhs:Foo(T, K)]Foo(Bar.xyz(abc)) = 0xff;
    \\var j: [*c]align(foo(bar.oop(0x12))) rhs = 0xff;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var j: [
    \\  lhs:Foo(T, K)
    \\]rhs = 0xff;
    \\var j: [
    \\  lhs:Foo(T, K)
    \\]Foo(Bar.xyz(abc)) = 0xff;
    \\var j: [*c]align(
    \\  foo(bar.oop(0x12))
    \\)
    \\  rhs = 0xff;
  );
}

test "ptr types 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var x: *allowzero align(foo("ok")) Rhs align(64) addrspace(.generic) linksection(".my_custom_section") = undefined;
  \\
  \\ var x: *allowzero align(foo("ok")) Rhs = 0xff;
  \\ var x: *allowzero addrspace(Foo(Bar())) align(foo("ok")) Rhs = 0xff;
  \\ var x: *allowzero addrspace(Foo(Bar())) align(foo("ok")) const Rhs = 0xff;
  \\ var x: *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Rhs = 0xff;
  \\ var x: *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc)) = 0xff;
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var x: *allowzero align(foo("ok")) Rhs
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\
    \\var x: *allowzero align(foo("ok")) Rhs = 0xff;
    \\var x: *allowzero align(foo("ok")) addrspace(Foo(Bar())) Rhs = 0xff;
    \\var x: *allowzero align(foo("ok")) addrspace(Foo(Bar())) const Rhs = 0xff;
    \\var x: *allowzero align(foo("ok")) addrspace(Foo(Bar())) const volatile Rhs = 0xff;
    \\var x: *allowzero align(foo("ok")) addrspace(Foo(Bar())) const volatile Foo(Bar.xyz(abc)) = 0xff;
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\var x: *allowzero align(foo("ok")) Rhs
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\
    \\var x: *allowzero align(foo("ok")) Rhs = 0xff;
    \\var x: *allowzero align(foo("ok")) addrspace(Foo(Bar())) Rhs = 0xff;
    \\var x: *allowzero align(foo("ok")) addrspace(Foo(Bar())) const Rhs = 0xff;
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile Rhs = 0xff;
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile Foo(Bar.xyz(abc)) = 0xff;
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var x: *allowzero align(foo("ok")) Rhs
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(".my_custom_section") = undefined;
    \\
    \\var x: *allowzero align(foo("ok")) Rhs = 0xff;
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  Rhs = 0xff;
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const Rhs = 0xff;
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile Rhs = 0xff;
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile Foo(Bar.xyz(abc)) = 0xff;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  Rhs
    \\  align(64)
    \\  addrspace(.generic)
    \\  linksection(
    \\    ".my_custom_section"
    \\  ) = undefined;
    \\
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  Rhs = 0xff;
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  Rhs = 0xff;
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const Rhs = 0xff;
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile Rhs = 0xff;
    \\var x: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile
    \\  Foo(Bar.xyz(abc)) = 0xff;
  );
}

test "ptr types 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() *allowzero align(foo("ok")) Rhs {
  \\   return 0;
  \\}
  \\
  \\ fn foo() *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc)) {
  \\   return 0;
  \\}
  \\
  \\ fn foo(abc: *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc))) *allowzero align(foo("ok")) Rhs {
  \\   return 0;
  \\}
  \\
  \\ fn foo(abc: *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc))) *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc)) {
  \\   return 0;
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn foo() *allowzero align(foo("ok")) Rhs {
    \\  return 0;
    \\}
    \\
    \\fn foo() *allowzero align(foo("ok")) addrspace(Foo(Bar())) const volatile Foo(Bar.xyz(abc)) {
    \\  return 0;
    \\}
    \\
    \\fn foo(
    \\  abc: *allowzero align(foo("ok")) addrspace(Foo(Bar())) const volatile Foo(Bar.xyz(abc)),
    \\) *allowzero align(foo("ok")) Rhs {
    \\  return 0;
    \\}
    \\
    \\fn foo(
    \\  abc: *allowzero align(foo("ok")) addrspace(Foo(Bar())) const volatile Foo(Bar.xyz(abc)),
    \\) *allowzero align(foo("ok")) addrspace(Foo(Bar())) const volatile Foo(Bar.xyz(abc)) {
    \\  return 0;
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn foo() *allowzero align(foo("ok")) Rhs {
    \\  return 0;
    \\}
    \\
    \\fn foo() *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile Foo(Bar.xyz(abc)) {
    \\  return 0;
    \\}
    \\
    \\fn foo(
    \\  abc: *allowzero
    \\    align(foo("ok"))
    \\    addrspace(Foo(Bar()))
    \\    const volatile Foo(Bar.xyz(abc)),
    \\) *allowzero align(foo("ok")) Rhs {
    \\  return 0;
    \\}
    \\
    \\fn foo(
    \\  abc: *allowzero
    \\    align(foo("ok"))
    \\    addrspace(Foo(Bar()))
    \\    const volatile Foo(Bar.xyz(abc)),
    \\) *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile Foo(Bar.xyz(abc)) {
    \\  return 0;
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn foo() *allowzero align(foo("ok")) Rhs {
    \\  return 0;
    \\}
    \\
    \\fn foo() *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile Foo(Bar.xyz(abc)) {
    \\  return 0;
    \\}
    \\
    \\fn foo(
    \\  abc: *allowzero
    \\    align(foo("ok"))
    \\    addrspace(Foo(Bar()))
    \\    const volatile Foo(Bar.xyz(abc)),
    \\) *allowzero align(foo("ok")) Rhs {
    \\  return 0;
    \\}
    \\
    \\fn foo(
    \\  abc: *allowzero
    \\    align(foo("ok"))
    \\    addrspace(Foo(Bar()))
    \\    const volatile Foo(Bar.xyz(abc)),
    \\) *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile Foo(Bar.xyz(abc)) {
    \\  return 0;
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo() *allowzero
    \\  align(foo("ok"))
    \\  Rhs {
    \\  return 0;
    \\}
    \\
    \\fn foo() *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile
    \\  Foo(Bar.xyz(abc)) {
    \\  return 0;
    \\}
    \\
    \\fn foo(
    \\  abc: *allowzero
    \\    align(foo("ok"))
    \\    addrspace(Foo(Bar()))
    \\    const volatile
    \\    Foo(Bar.xyz(abc)),
    \\) *allowzero
    \\  align(foo("ok"))
    \\  Rhs {
    \\  return 0;
    \\}
    \\
    \\fn foo(
    \\  abc: *allowzero
    \\    align(foo("ok"))
    \\    addrspace(Foo(Bar()))
    \\    const volatile
    \\    Foo(Bar.xyz(abc)),
    \\) *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const volatile
    \\  Foo(Bar.xyz(abc)) {
    \\  return 0;
    \\}
  );
}

test "try/catch 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var abc = try someFunc(1, 2, 3);
  \\ var abc = someTestFunc(try someFunc(1, 2, 3));
  \\ var abc = someTestFunc(try someFunc(1, 2, 3), try someFunc(1, 2, 3));
  \\ var abc = someFunc(1, 2, 3) catch |e| 5;
  \\ var abc = someFunc(1, 2, 3) catch expr();
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var abc = try someFunc(1, 2, 3);
    \\var abc = someTestFunc(try someFunc(1, 2, 3));
    \\var abc = someTestFunc(try someFunc(1, 2, 3), try someFunc(1, 2, 3));
    \\var abc = someFunc(1, 2, 3) catch |e| 5;
    \\var abc = someFunc(1, 2, 3) catch expr();
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\var abc = try someFunc(1, 2, 3);
    \\var abc = someTestFunc(try someFunc(1, 2, 3));
    \\var abc = someTestFunc(try someFunc(1, 2, 3), try someFunc(1, 2, 3));
    \\var abc = someFunc(1, 2, 3) catch |e| 5;
    \\var abc = someFunc(1, 2, 3) catch expr();
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var abc = try someFunc(1, 2, 3);
    \\var abc = someTestFunc(try someFunc(1, 2, 3));
    \\var abc = someTestFunc(
    \\  try someFunc(1, 2, 3),
    \\  try someFunc(1, 2, 3),
    \\);
    \\var abc = someFunc(1, 2, 3) catch |e| 5;
    \\var abc = someFunc(1, 2, 3) catch expr();
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var abc = try someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\);
    \\var abc = someTestFunc(
    \\  try someFunc(1, 2, 3),
    \\);
    \\var abc = someTestFunc(
    \\  try someFunc(1, 2, 3),
    \\  try someFunc(1, 2, 3),
    \\);
    \\var abc = someFunc(1, 2, 3)
    \\  catch |e| 5;
    \\var abc = someFunc(1, 2, 3)
    \\  catch expr();
  );
}

test "try/catch 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var abc = someFunc(1, 2, 3) catch return;
  \\ var abc = someFunc(1, 2, 3) catch |e| {
  \\   someBlock();
  \\ };
  \\ var abc = someFunc(1, 2, 3) catch |e| blk: {
  \\   someBlock();
  \\   break :blk result("okay");
  \\ };
  \\ var abc = someFunc(1, 2, 3) catch {
  \\   someBlock();
  \\ };
  \\ var abc = someFunc(1, 2, 3) catch blk: {
  \\   someBlock();
  \\   break :blk result("okay");
  \\ };
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var abc = someFunc(1, 2, 3) catch return;
    \\var abc = someFunc(1, 2, 3) catch |e| {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) catch |e| blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = someFunc(1, 2, 3) catch {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) catch blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\var abc = someFunc(1, 2, 3) catch return;
    \\var abc = someFunc(1, 2, 3) catch |e| {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) catch |e| blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = someFunc(1, 2, 3) catch {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) catch blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var abc = someFunc(1, 2, 3) catch return;
    \\var abc = someFunc(1, 2, 3) catch |e| {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) catch |e| blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = someFunc(1, 2, 3) catch {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) catch blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var abc = someFunc(1, 2, 3)
    \\  catch return;
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) catch |e| {
    \\  someBlock();
    \\};
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) catch |e| blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) catch {
    \\  someBlock();
    \\};
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) catch blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
  );
}

test "orelse 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var abc = someFunc(1, 2, 3) orelse return;
  \\ var abc = someFunc(1, 2, 3) orelse {
  \\   someBlock();
  \\ };
  \\ var abc = someFunc(1, 2, 3) orelse blk: {
  \\   someBlock();
  \\   break :blk result("okay");
  \\ };
  \\ var abc = someFunc(1, 2, 3) orelse  {
  \\   someBlock();
  \\ };
  \\ var abc = someFunc(1, 2, 3) orelse blk: {
  \\   someBlock();
  \\   break :blk result("okay");
  \\ };
  \\var abc = 5 * 4
  \\  + 3
  \\  - abc
  \\  + 4
  \\  - 3
  \\  + (someFunc(1, 2, 3)
  \\    orelse expr());
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\var abc = someFunc(1, 2, 3) orelse return;
    \\var abc = someFunc(1, 2, 3) orelse {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) orelse blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = someFunc(1, 2, 3) orelse {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) orelse blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + (someFunc(1, 2, 3) orelse expr());
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\var abc = someFunc(1, 2, 3) orelse return;
    \\var abc = someFunc(1, 2, 3) orelse {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) orelse blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = someFunc(1, 2, 3) orelse {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) orelse blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + (someFunc(1, 2, 3) orelse expr());
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\var abc = someFunc(1, 2, 3) orelse return;
    \\var abc = someFunc(1, 2, 3) orelse {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) orelse blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = someFunc(1, 2, 3) orelse {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) orelse blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + (someFunc(1, 2, 3) orelse expr());
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var abc = someFunc(1, 2, 3)
    \\  orelse return;
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) orelse {
    \\  someBlock();
    \\};
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) orelse blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) orelse {
    \\  someBlock();
    \\};
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) orelse blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + (someFunc(1, 2, 3)
    \\    orelse expr());
  );
}

test "if/else 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testing() void {
  \\ if (a) b else d;
  \\ if (a) |x| b else d;
  \\ if (a) |x| b else |y| d;
  \\ if (expr()) doStuff();
  \\ if (expr()) |pl| doStuff();
  \\ var z = if (a) b else d;
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (a) b else d;
    \\  if (a) |x| b else d;
    \\  if (a) |x| b else |y| d;
    \\  if (expr()) doStuff();
    \\  if (expr()) |pl| doStuff();
    \\  var z = if (a) b else d;
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (a) b else d;
    \\  if (a) |x| b else d;
    \\  if (a) |x| b else |y| d;
    \\  if (expr()) doStuff();
    \\  if (expr()) |pl| doStuff();
    \\  var z = if (a) b else d;
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (a) b else d;
    \\  if (a) |x| b else d;
    \\  if (a) |x| b else |y| d;
    \\  if (expr()) doStuff();
    \\  if (expr()) |pl| doStuff();
    \\  var z = if (a) b else d;
    \\}
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (a) b else d;
    \\  if (a) |x|
    \\    b
    \\  else
    \\    d;
    \\  if (a) |x|
    \\    b
    \\  else |y|
    \\    d;
    \\  if (expr())
    \\    doStuff();
    \\  if (expr()) |pl|
    \\    doStuff();
    \\  var z = if (a)
    \\    b
    \\  else
    \\    d;
    \\}
  );
}

test "if/else 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testing() void {
  \\ var z = if (a) b: {var x = y; } else d;
  \\ if (someExpr()) {
  \\ var x = someOther();
  \\} else {
  \\  var y = someWhat();
  \\}
  \\ if (someExpr()) {
  \\ var x = someOther();
  \\} else if (someOtherExpr()) {
  \\  var y = someWhat();
  \\} else {
  \\  var y = someElseWhat();
  \\}
  \\ if (someExpr()) |*payload| {
  \\ var x = someOther();
  \\} else {
  \\  var y = someWhat();
  \\}
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  var z = if (a) b: {
    \\    var x = y;
    \\  } else d;
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else if (someOtherExpr()) {
    \\    var y = someWhat();
    \\  } else {
    \\    var y = someElseWhat();
    \\  }
    \\  if (someExpr()) |*payload| {
    \\    var x = someOther();
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  var z = if (a) b: {
    \\    var x = y;
    \\  } else d;
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else if (someOtherExpr()) {
    \\    var y = someWhat();
    \\  } else {
    \\    var y = someElseWhat();
    \\  }
    \\  if (someExpr()) |*payload| {
    \\    var x = someOther();
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  var z = if (a) b: {
    \\    var x = y;
    \\  } else d;
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else if (someOtherExpr()) {
    \\    var y = someWhat();
    \\  } else {
    \\    var y = someElseWhat();
    \\  }
    \\  if (someExpr()) |*payload| {
    \\    var x = someOther();
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\}
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  var z = if (
    \\    a
    \\  ) b: {
    \\    var x = y;
    \\  } else d;
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else if (
    \\    someOtherExpr()
    \\  ) {
    \\    var y = someWhat();
    \\  } else {
    \\    var y = someElseWhat();
    \\  }
    \\  if (
    \\    someExpr()
    \\  ) |*payload| {
    \\    var x = someOther();
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\}
  );
}

test "if/else 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testing() void {
  \\ if (someExpr()) {
  \\} else {
  \\  var y = someWhat();
  \\}
  \\ if (someExpr()) {
  \\ var x = someOther();
  \\} else {
  \\}
  \\ if (someExpr()) {
  \\} else {
  \\}
  \\ if (someExpr()) |*payload| {
  \\} else {
  \\}
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (someExpr()) {
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else {
    \\  }
    \\  if (someExpr()) {
    \\  } else {
    \\  }
    \\  if (someExpr()) |*payload| {
    \\  } else {
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (someExpr()) {
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else {
    \\  }
    \\  if (someExpr()) {
    \\  } else {
    \\  }
    \\  if (someExpr()) |*payload| {
    \\  } else {
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (someExpr()) {
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else {
    \\  }
    \\  if (someExpr()) {
    \\  } else {
    \\  }
    \\  if (someExpr()) |*payload| {
    \\  } else {
    \\  }
    \\}
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (someExpr()) {
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\  if (someExpr()) {
    \\    var x = someOther();
    \\  } else {
    \\  }
    \\  if (someExpr()) {
    \\  } else {
    \\  }
    \\  if (
    \\    someExpr()
    \\  ) |*payload| {
    \\  } else {
    \\  }
    \\}
  );
}

test "if/else 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testing() void {
  \\ {
  \\ if (someExpr()) {
  \\} else {
  \\}
  \\ if (someExpr()) |payload| {
  \\} else {
  \\}
  \\ }
  \\ if (
  \\      (lhs.isStruct() and lhs.strukt().node.modifier.isFrozen()) or
  \\      (lhs.isData() and lhs.data().node.modifier.isFrozen())
  \\    ) {
  \\      return self.error_(
  \\        true, open.lhs_name.toToken(), "cannot open frozen type '{s}'",
  \\        .{self.getTypename(lhs)}
  \\      );
  \\    }
  \\ if (
  \\      lhs.isStruct() and lhs.strukt().node.modifier.isFrozen() or
  \\      lhs.isData() and lhs.data().node.modifier.isFrozen()
  \\    ) {
  \\      return self.error_(
  \\        true, open.lhs_name.toToken(), "cannot open frozen type '{s}'",
  \\        .{self.getTypename(lhs)}
  \\      );
  \\    }
  \\ if (
  \\      lhs.isStruct() and lhs.strukt().node.modifier.isFrozen() or
  \\      lhs.isData() and lhs.data().node.modifier.isFrozen()
  \\    ) {
  \\      return self.error_(
  \\        true, open.lhs_name.toToken(), "cannot open frozen type '{s}'",
  \\        .{self.getTypename(lhs), self.book(0x101), self.book(0x101), self.book(0x101)}
  \\      );
  \\    }
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  {
    \\    if (someExpr()) {
    \\    } else {
    \\    }
    \\    if (someExpr()) |payload| {
    \\    } else {
    \\    }
    \\  }
    \\  if (
    \\    (lhs.isStruct() and lhs.strukt().node.modifier.isFrozen())
    \\      or (lhs.isData() and lhs.data().node.modifier.isFrozen())
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{self.getTypename(lhs)},
    \\    );
    \\  }
    \\  if (
    \\    lhs.isStruct() and lhs.strukt().node.modifier.isFrozen()
    \\      or lhs.isData() and lhs.data().node.modifier.isFrozen()
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{self.getTypename(lhs)},
    \\    );
    \\  }
    \\  if (
    \\    lhs.isStruct() and lhs.strukt().node.modifier.isFrozen()
    \\      or lhs.isData() and lhs.data().node.modifier.isFrozen()
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{ self.getTypename(lhs), self.book(0x101), self.book(0x101), self.book(0x101) },
    \\    );
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  {
    \\    if (someExpr()) {
    \\    } else {
    \\    }
    \\    if (someExpr()) |payload| {
    \\    } else {
    \\    }
    \\  }
    \\  if (
    \\    (lhs.isStruct() and lhs.strukt().node.modifier.isFrozen())
    \\      or (lhs.isData() and lhs.data().node.modifier.isFrozen())
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{self.getTypename(lhs)},
    \\    );
    \\  }
    \\  if (
    \\    lhs.isStruct() and lhs.strukt().node.modifier.isFrozen()
    \\      or lhs.isData() and lhs.data().node.modifier.isFrozen()
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{self.getTypename(lhs)},
    \\    );
    \\  }
    \\  if (
    \\    lhs.isStruct() and lhs.strukt().node.modifier.isFrozen()
    \\      or lhs.isData() and lhs.data().node.modifier.isFrozen()
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{
    \\        self.getTypename(lhs),
    \\        self.book(0x101),
    \\        self.book(0x101),
    \\        self.book(0x101),
    \\      },
    \\    );
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  {
    \\    if (someExpr()) {
    \\    } else {
    \\    }
    \\    if (someExpr()) |payload| {
    \\    } else {
    \\    }
    \\  }
    \\  if (
    \\    (lhs.isStruct()
    \\      and lhs.strukt().node.modifier.isFrozen())
    \\      or (lhs.isData()
    \\        and lhs.data().node.modifier.isFrozen())
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{self.getTypename(lhs)},
    \\    );
    \\  }
    \\  if (
    \\    lhs.isStruct() and lhs.strukt().node.modifier.isFrozen()
    \\      or lhs.isData()
    \\        and lhs.data().node.modifier.isFrozen()
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{self.getTypename(lhs)},
    \\    );
    \\  }
    \\  if (
    \\    lhs.isStruct() and lhs.strukt().node.modifier.isFrozen()
    \\      or lhs.isData()
    \\        and lhs.data().node.modifier.isFrozen()
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{
    \\        self.getTypename(lhs),
    \\        self.book(0x101),
    \\        self.book(0x101),
    \\        self.book(0x101),
    \\      },
    \\    );
    \\  }
    \\}
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  {
    \\    if (
    \\      someExpr()
    \\    ) {
    \\    } else {
    \\    }
    \\    if (
    \\      someExpr()
    \\    ) |payload| {
    \\    } else {
    \\    }
    \\  }
    \\  if (
    \\    (lhs.isStruct()
    \\      and lhs.strukt()
    \\        .node.modifier.isFrozen())
    \\      or (lhs.isData()
    \\        and lhs.data()
    \\          .node.modifier.isFrozen())
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{
    \\        self.getTypename(
    \\          lhs,
    \\        ),
    \\      },
    \\    );
    \\  }
    \\  if (
    \\    lhs.isStruct()
    \\      and lhs.strukt()
    \\        .node.modifier.isFrozen()
    \\      or lhs.isData()
    \\        and lhs.data()
    \\          .node.modifier.isFrozen()
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{
    \\        self.getTypename(
    \\          lhs,
    \\        ),
    \\      },
    \\    );
    \\  }
    \\  if (
    \\    lhs.isStruct()
    \\      and lhs.strukt()
    \\        .node.modifier.isFrozen()
    \\      or lhs.isData()
    \\        and lhs.data()
    \\          .node.modifier.isFrozen()
    \\  ) {
    \\    return self.error_(
    \\      true,
    \\      open.lhs_name.toToken(),
    \\      "cannot open frozen type '{s}'",
    \\      .{
    \\        self.getTypename(
    \\          lhs,
    \\        ),
    \\        self.book(
    \\          0x101,
    \\        ),
    \\        self.book(
    \\          0x101,
    \\        ),
    \\        self.book(
    \\          0x101,
    \\        ),
    \\      },
    \\    );
    \\  }
    \\}
  );
}

test "if/else 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testing() void {
  \\  if (cond()) { var x = 5; } else voidExpr();
  \\  if (cond()) voidExpr() else {
  \\ var x = 5;
  \\}
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (cond()) {
    \\    var x = 5;
    \\  } else voidExpr();
    \\  if (cond()) voidExpr()
    \\  else {
    \\    var x = 5;
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (cond()) {
    \\    var x = 5;
    \\  } else voidExpr();
    \\  if (cond()) voidExpr()
    \\  else {
    \\    var x = 5;
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (cond()) {
    \\    var x = 5;
    \\  } else voidExpr();
    \\  if (cond()) voidExpr()
    \\  else {
    \\    var x = 5;
    \\  }
    \\}
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if (cond()) {
    \\    var x = 5;
    \\  } else voidExpr();
    \\  if (cond())
    \\    voidExpr()
    \\  else {
    \\    var x = 5;
    \\  }
    \\}
  );
}

test "if/else 6" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ if (some) |*x| lbl : {
  \\  print('yello world');
  \\} else {
  \\  someCall();
  \\  var abc = try testS();
  \\}
  \\ if (some) |*x| _ = lbl : {
  \\  print('yello world');
  \\} else {
  \\  someCall();
  \\  var abc = try testS();
  \\}
  \\if (someCond) |x| _ = blk: {
  \\  std.debug.print("x is: {}\n", .{x});
  \\  break :blk void;
  \\} else {
  \\  std.debug.print("done\n", .{});
  \\}
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (some) |*x| lbl: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (some) |*x|
    \\    _ = lbl: {
    \\      print('yello world');
    \\    }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (someCond) |x|
    \\    _ = blk: {
    \\      std.debug.print("x is: {}\n", .{x});
    \\      break :blk void;
    \\    }
    \\  else {
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (some) |*x| lbl: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (some) |*x|
    \\    _ = lbl: {
    \\      print('yello world');
    \\    }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (someCond) |x|
    \\    _ = blk: {
    \\      std.debug.print("x is: {}\n", .{x});
    \\      break :blk void;
    \\    }
    \\  else {
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (some) |*x| lbl: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (some) |*x|
    \\    _ = lbl: {
    \\      print('yello world');
    \\    }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (someCond) |x|
    \\    _ = blk: {
    \\      std.debug.print("x is: {}\n", .{x});
    \\      break :blk void;
    \\    }
    \\  else {
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (
    \\    some
    \\  ) |*x| lbl: {
    \\    print(
    \\      'yello world',
    \\    );
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (some) |*x|
    \\    _ = lbl: {
    \\      print(
    \\        'yello world',
    \\      );
    \\    }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (someCond) |x|
    \\    _ = blk: {
    \\      std.debug.print(
    \\        "x is: {}\n",
    \\        .{x},
    \\      );
    \\      break :blk void;
    \\    }
    \\  else {
    \\    std.debug.print(
    \\      "done\n",
    \\      .{},
    \\    );
    \\  }
    \\}
  );
}

test "if/else 7" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ if (someNiceCondition(a, b, c)) |x| _ = blk: {
  \\  print('yello world');
  \\};
  \\ if (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (someNiceCondition(a, b, c)) |x| _ = blk: {
    \\    print('yello world');
    \\  };
    \\  if (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (someNiceCondition(a, b, c)) |x| _ = blk: {
    \\    print('yello world');
    \\  };
    \\  if (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (someNiceCondition(a, b, c)) |x|
    \\    _ = blk: {
    \\      print('yello world');
    \\    };
    \\  if (someNiceCondition(a, b, c)) |x|
    \\    someFancy(callExpr(), a, b);
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\    _ = blk: {
    \\      print('yello world');
    \\    };
    \\  if (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\    someFancy(
    \\      callExpr(),
    \\      a,
    \\      b,
    \\    );
    \\}
  );
}

test "if/else 8" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\fn testing() void {
  \\_ = if (k) |x| blk: {
  \\    std.debug.print("x is: {}\n", .{x});
  \\    break :blk void;
  \\} else { //
  \\    std.debug.print("done\n", .{});
  \\};
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testing() void {
    \\  _ = if (k) |x| blk: {
    \\    std.debug.print("x is: {}\n", .{x});
    \\    break :blk void;
    \\  } else { //
    \\    std.debug.print("done\n", .{});
    \\  };
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  _ = if (k) |x| blk: {
    \\    std.debug.print(
    \\      "x is: {}\n",
    \\      .{x},
    \\    );
    \\    break :blk void;
    \\  } else { //
    \\    std.debug.print(
    \\      "done\n",
    \\      .{},
    \\    );
    \\  };
    \\}
  );
}

test "if/else 9" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() void { if (last_tkn) |tkn| flat.decllineIf(self.tknHasTC(tkn))._();}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo() void {
    \\  if (last_tkn) |tkn| flat.decllineIf(self.tknHasTC(tkn))._();
    \\}
  );
  // using width: 50
  res = try format(doc, .{ .width = 50 }, al);
  try check(
    res,
    \\fn foo() void {
    \\  if (last_tkn) |tkn|
    \\    flat.decllineIf(self.tknHasTC(tkn))._();
    \\}
  );
}

test "switch 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\label: switch (expr)  {
  \\  a => a,
  \\  b, c => c,
  \\  inline d...e => e,
  \\  else => f
  \\},
  \\ switch (someExpr(jk)) {}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\label: switch (expr) {
    \\  a => a,
    \\  b, c => c,
    \\  inline d...e => e,
    \\  else => f,
    \\},
    \\switch (someExpr(jk)) {}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\label: switch (expr) {
    \\  a => a,
    \\  b, c => c,
    \\  inline d...e => e,
    \\  else => f,
    \\},
    \\switch (someExpr(jk)) {}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\label: switch (expr) {
    \\  a => a,
    \\  b, c => c,
    \\  inline d...e => e,
    \\  else => f,
    \\},
    \\switch (someExpr(jk)) {}
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\label: switch (
    \\  expr
    \\) {
    \\  a => a,
    \\  b, c => c,
    \\  inline d...e => e,
    \\  else => f,
    \\},
    \\switch (
    \\  someExpr(jk)
    \\) {}
  );
}

test "switch 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn fun(expr: Type) switch (@TypeOf(expr)) {
  \\ .a => TyFoo, .b => TyBar, else => TyBaz} {
  \\   return 
  \\label: switch (expr)  {
  \\  a => a,
  \\  b, c => c,
  \\  inline d...e => e,
  \\  else => f
  \\};
  \\}
  \\
  \\ fn fun(expr: Type) lbl: switch (@TypeOf(expr)) {
  \\ .a => TyFoo, .b => TyBar, else => TyBaz} {
  \\   return 
  \\label: switch (expr)  {
  \\  a => a,
  \\  b, c => c,
  \\  inline d...e => e,
  \\  else => f
  \\};
  \\}
  \\
  \\ fn fun(expr: Type) lbl: switch (@TypeOf(expr)) {
  \\ .a => TyFoo, .b => TyBar, else => TyBaz} {
  \\ switch (expr)  {
  \\  a => a,
  \\  b, c => c,
  \\  inline d...e => e,
  \\  else => f
  \\}
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn fun(expr: Type) switch (@TypeOf(expr)) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  return label: switch (expr) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  };
    \\}
    \\
    \\fn fun(expr: Type) lbl: switch (@TypeOf(expr)) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  return label: switch (expr) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  };
    \\}
    \\
    \\fn fun(expr: Type) lbl: switch (@TypeOf(expr)) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  switch (expr) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn fun(
    \\  expr: Type,
    \\) switch (@TypeOf(expr)) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  return label: switch (expr) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  };
    \\}
    \\
    \\fn fun(
    \\  expr: Type,
    \\) lbl: switch (@TypeOf(expr)) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  return label: switch (expr) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  };
    \\}
    \\
    \\fn fun(
    \\  expr: Type,
    \\) lbl: switch (@TypeOf(expr)) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  switch (expr) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn fun(
    \\  expr: Type,
    \\) switch (@TypeOf(expr)) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  return label: switch (expr) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  };
    \\}
    \\
    \\fn fun(
    \\  expr: Type,
    \\) lbl: switch (@TypeOf(expr)) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  return label: switch (expr) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  };
    \\}
    \\
    \\fn fun(
    \\  expr: Type,
    \\) lbl: switch (@TypeOf(expr)) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  switch (expr) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  }
    \\}
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\fn fun(
    \\  expr: Type,
    \\) switch (
    \\  @TypeOf(expr)
    \\) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  return label: switch (
    \\    expr
    \\  ) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  };
    \\}
    \\
    \\fn fun(
    \\  expr: Type,
    \\) lbl: switch (
    \\  @TypeOf(expr)
    \\) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  return label: switch (
    \\    expr
    \\  ) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  };
    \\}
    \\
    \\fn fun(
    \\  expr: Type,
    \\) lbl: switch (
    \\  @TypeOf(expr)
    \\) {
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} {
    \\  switch (expr) {
    \\    a => a,
    \\    b, c => c,
    \\    inline d...e => e,
    \\    else => f,
    \\  }
    \\}
  );
}

test "switch 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\tag: switch (expr2)  {
  \\  .a => |bar| {},
  \\  inline .x => |*bar, foo| a = call(),
  \\  .y => |bar, foo| myExpr(),
  \\  .b, .c => |*foo| {
  \\  var k = abc;
  \\  if (k * someExpr(expr2) > 0xff) {
  \\    print("yep!");
  \\}
  \\},
  \\  .b, .c, .d, .e, .f, .g, .h => |*foo| {
  \\ if (ty.ast.sentinel.unwrap()) |n| {
  \\   sb.text("[")._();
  \\   var elems = self.db.seqb();
  \\   elems.softline().text("*:")._();
  \\   elems.append(try self.t(n));
  \\   sb.indent(elems.finish()).softline().text("]")._();
  \\ } else {
  \\   sb.text("[*]")._();
  \\ }
  \\ },
  \\  .d ... .e => {},
  \\.add, .add_wrap, .add_sat, .array_cat, .array_mult, .bang_equal,
  \\.bit_and, .bit_or, .shl, .shl_sat, .shr, .bit_xor, .bool_and,
  \\.bool_or, .div, .equal_equal, .greater_or_equal, .greater_than,
  \\.less_or_equal, .less_than, .merge_error_sets, .mod, .mul, .mul_wrap,
  \\.mul_sat, .sub, .sub_wrap, .sub_sat => {
  \\  return self.tBinaryExpr(n, tag);
  \\},
  \\  else => f,
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\tag: switch (expr2) {
    \\  .a => |bar| {},
    \\  inline .x => |*bar, foo| a = call(),
    \\  .y => |bar, foo| myExpr(),
    \\  .b, .c => |*foo| {
    \\    var k = abc;
    \\    if (k * someExpr(expr2) > 0xff) {
    \\      print("yep!");
    \\    }
    \\  },
    \\  .b, .c, .d, .e, .f, .g, .h => |*foo| {
    \\    if (ty.ast.sentinel.unwrap()) |n| {
    \\      sb.text("[")._();
    \\      var elems = self.db.seqb();
    \\      elems.softline().text("*:")._();
    \\      elems.append(try self.t(n));
    \\      sb.indent(elems.finish()).softline().text("]")._();
    \\    } else {
    \\      sb.text("[*]")._();
    \\    }
    \\  },
    \\  .d....e => {},
    \\  .add,
    \\  .add_wrap,
    \\  .add_sat,
    \\  .array_cat,
    \\  .array_mult,
    \\  .bang_equal,
    \\  .bit_and,
    \\  .bit_or,
    \\  .shl,
    \\  .shl_sat,
    \\  .shr,
    \\  .bit_xor,
    \\  .bool_and,
    \\  .bool_or,
    \\  .div,
    \\  .equal_equal,
    \\  .greater_or_equal,
    \\  .greater_than,
    \\  .less_or_equal,
    \\  .less_than,
    \\  .merge_error_sets,
    \\  .mod,
    \\  .mul,
    \\  .mul_wrap,
    \\  .mul_sat,
    \\  .sub,
    \\  .sub_wrap,
    \\  .sub_sat => {
    \\    return self.tBinaryExpr(n, tag);
    \\  },
    \\  else => f,
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\tag: switch (expr2) {
    \\  .a => |bar| {},
    \\  inline .x => |*bar, foo| a = call(),
    \\  .y => |bar, foo| myExpr(),
    \\  .b, .c => |*foo| {
    \\    var k = abc;
    \\    if (k * someExpr(expr2) > 0xff) {
    \\      print("yep!");
    \\    }
    \\  },
    \\  .b, .c, .d, .e, .f, .g, .h => |*foo| {
    \\    if (ty.ast.sentinel.unwrap()) |n| {
    \\      sb.text("[")._();
    \\      var elems = self.db.seqb();
    \\      elems.softline().text("*:")._();
    \\      elems.append(try self.t(n));
    \\      sb.indent(elems.finish()).softline().text("]")._();
    \\    } else {
    \\      sb.text("[*]")._();
    \\    }
    \\  },
    \\  .d....e => {},
    \\  .add,
    \\  .add_wrap,
    \\  .add_sat,
    \\  .array_cat,
    \\  .array_mult,
    \\  .bang_equal,
    \\  .bit_and,
    \\  .bit_or,
    \\  .shl,
    \\  .shl_sat,
    \\  .shr,
    \\  .bit_xor,
    \\  .bool_and,
    \\  .bool_or,
    \\  .div,
    \\  .equal_equal,
    \\  .greater_or_equal,
    \\  .greater_than,
    \\  .less_or_equal,
    \\  .less_than,
    \\  .merge_error_sets,
    \\  .mod,
    \\  .mul,
    \\  .mul_wrap,
    \\  .mul_sat,
    \\  .sub,
    \\  .sub_wrap,
    \\  .sub_sat => {
    \\    return self.tBinaryExpr(n, tag);
    \\  },
    \\  else => f,
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\tag: switch (expr2) {
    \\  .a => |bar| {},
    \\  inline .x => |*bar, foo| a = call(),
    \\  .y => |bar, foo| myExpr(),
    \\  .b, .c => |*foo| {
    \\    var k = abc;
    \\    if (k * someExpr(expr2) > 0xff) {
    \\      print("yep!");
    \\    }
    \\  },
    \\  .b, .c, .d, .e, .f, .g, .h => |*foo| {
    \\    if (ty.ast.sentinel.unwrap()) |n| {
    \\      sb.text("[")._();
    \\      var elems = self.db.seqb();
    \\      elems.softline().text("*:")._();
    \\      elems.append(try self.t(n));
    \\      sb.indent(elems.finish()).softline().text("]")._();
    \\    } else {
    \\      sb.text("[*]")._();
    \\    }
    \\  },
    \\  .d....e => {},
    \\  .add,
    \\  .add_wrap,
    \\  .add_sat,
    \\  .array_cat,
    \\  .array_mult,
    \\  .bang_equal,
    \\  .bit_and,
    \\  .bit_or,
    \\  .shl,
    \\  .shl_sat,
    \\  .shr,
    \\  .bit_xor,
    \\  .bool_and,
    \\  .bool_or,
    \\  .div,
    \\  .equal_equal,
    \\  .greater_or_equal,
    \\  .greater_than,
    \\  .less_or_equal,
    \\  .less_than,
    \\  .merge_error_sets,
    \\  .mod,
    \\  .mul,
    \\  .mul_wrap,
    \\  .mul_sat,
    \\  .sub,
    \\  .sub_wrap,
    \\  .sub_sat => {
    \\    return self.tBinaryExpr(n, tag);
    \\  },
    \\  else => f,
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\tag: switch (expr2) {
    \\  .a => |bar| {},
    \\  inline .x => |*bar, foo| a = call(),
    \\  .y => |bar, foo| myExpr(),
    \\  .b, .c => |*foo| {
    \\    var k = abc;
    \\    if (
    \\      k * someExpr(expr2)
    \\        > 0xff
    \\    ) {
    \\      print("yep!");
    \\    }
    \\  },
    \\  .b,
    \\  .c,
    \\  .d,
    \\  .e,
    \\  .f,
    \\  .g,
    \\  .h => |*foo| {
    \\    if (
    \\      ty.ast.sentinel.unwrap()
    \\    ) |n| {
    \\      sb.text("[")._();
    \\      var elems = self.db.seqb();
    \\      elems.softline()
    \\        .text("*:")
    \\        ._();
    \\      elems.append(
    \\        try self.t(n),
    \\      );
    \\      sb.indent(
    \\        elems.finish(),
    \\      )
    \\        .softline()
    \\        .text("]")
    \\        ._();
    \\    } else {
    \\      sb.text("[*]")._();
    \\    }
    \\  },
    \\  .d....e => {},
    \\  .add,
    \\  .add_wrap,
    \\  .add_sat,
    \\  .array_cat,
    \\  .array_mult,
    \\  .bang_equal,
    \\  .bit_and,
    \\  .bit_or,
    \\  .shl,
    \\  .shl_sat,
    \\  .shr,
    \\  .bit_xor,
    \\  .bool_and,
    \\  .bool_or,
    \\  .div,
    \\  .equal_equal,
    \\  .greater_or_equal,
    \\  .greater_than,
    \\  .less_or_equal,
    \\  .less_than,
    \\  .merge_error_sets,
    \\  .mod,
    \\  .mul,
    \\  .mul_wrap,
    \\  .mul_sat,
    \\  .sub,
    \\  .sub_wrap,
    \\  .sub_sat => {
    \\    return self.tBinaryExpr(
    \\      n,
    \\      tag,
    \\    );
    \\  },
    \\  else => f,
    \\}
  );
}

test "switch 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\tag: switch (expr2)  { // one
  \\  // switching on an expr is good 1
  \\  // switching on an expr is good 2
  \\  // switching on an expr is good 3
  \\  .a => |bar| {},
  \\  inline .x => |*bar, foo| a = call(),
  \\  .y => |bar, foo| myExpr(),
  \\  .b, .c => |*foo| { // two
  \\  var k = abc;
  \\  if (k * someExpr(expr2) > 0xff) {
  \\    print("yep!");
  \\}
  \\},
  \\  .b, .c, .d, .e, .f, .g, .h => |*foo| { // three
  \\ if (ty.ast.sentinel.unwrap()) |n| {
  \\   sb.text("[")._();
  \\   var elems = self.db.seqb();
  \\   elems.softline().text("*:")._();
  \\   elems.append(try self.t(n));
  \\   sb.indent(elems.finish()).softline().text("]")._();
  \\ } else {
  \\   sb.text("[*]")._();
  \\ }
  \\ },
  \\  .d ... .e => {}, // keep
  \\inline .add, .add_wrap, .add_sat, .array_cat, .array_mult, .bang_equal,
  \\.bit_and, .bit_or, .shl, .shl_sat, .shr, .bit_xor, .bool_and,
  \\.bool_or, .div, .equal_equal, .greater_or_equal, .greater_than,
  \\.less_or_equal, .less_than, .merge_error_sets, .mod, .mul, .mul_wrap,
  \\.mul_sat, .sub, .sub_wrap, .sub_sat => {
  \\  return self.tBinaryExpr(n, tag);
  \\}, // yeah same
  \\  inline else => f,
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\tag: switch (expr2) { // one
    \\  // switching on an expr is good 1
    \\  // switching on an expr is good 2
    \\  // switching on an expr is good 3
    \\  .a => |bar| {},
    \\  inline .x => |*bar, foo| a = call(),
    \\  .y => |bar, foo| myExpr(),
    \\  .b, .c => |*foo| { // two
    \\    var k = abc;
    \\    if (k * someExpr(expr2) > 0xff) {
    \\      print("yep!");
    \\    }
    \\  },
    \\  .b, .c, .d, .e, .f, .g, .h => |*foo| { // three
    \\    if (ty.ast.sentinel.unwrap()) |n| {
    \\      sb.text("[")._();
    \\      var elems = self.db.seqb();
    \\      elems.softline().text("*:")._();
    \\      elems.append(try self.t(n));
    \\      sb.indent(elems.finish()).softline().text("]")._();
    \\    } else {
    \\      sb.text("[*]")._();
    \\    }
    \\  },
    \\  .d....e => {}, // keep
    \\  inline .add,
    \\    .add_wrap,
    \\    .add_sat,
    \\    .array_cat,
    \\    .array_mult,
    \\    .bang_equal,
    \\    .bit_and,
    \\    .bit_or,
    \\    .shl,
    \\    .shl_sat,
    \\    .shr,
    \\    .bit_xor,
    \\    .bool_and,
    \\    .bool_or,
    \\    .div,
    \\    .equal_equal,
    \\    .greater_or_equal,
    \\    .greater_than,
    \\    .less_or_equal,
    \\    .less_than,
    \\    .merge_error_sets,
    \\    .mod,
    \\    .mul,
    \\    .mul_wrap,
    \\    .mul_sat,
    \\    .sub,
    \\    .sub_wrap,
    \\    .sub_sat => {
    \\      return self.tBinaryExpr(n, tag);
    \\    }, // yeah same
    \\  inline else => f,
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\tag: switch (expr2) { // one
    \\  // switching on an expr is good 1
    \\  // switching on an expr is good 2
    \\  // switching on an expr is good 3
    \\  .a => |bar| {},
    \\  inline .x => |*bar, foo| a = call(),
    \\  .y => |bar, foo| myExpr(),
    \\  .b, .c => |*foo| { // two
    \\    var k = abc;
    \\    if (k * someExpr(expr2) > 0xff) {
    \\      print("yep!");
    \\    }
    \\  },
    \\  .b, .c, .d, .e, .f, .g, .h => |*foo| { // three
    \\    if (ty.ast.sentinel.unwrap()) |n| {
    \\      sb.text("[")._();
    \\      var elems = self.db.seqb();
    \\      elems.softline().text("*:")._();
    \\      elems.append(try self.t(n));
    \\      sb.indent(elems.finish()).softline().text("]")._();
    \\    } else {
    \\      sb.text("[*]")._();
    \\    }
    \\  },
    \\  .d....e => {}, // keep
    \\  inline .add,
    \\    .add_wrap,
    \\    .add_sat,
    \\    .array_cat,
    \\    .array_mult,
    \\    .bang_equal,
    \\    .bit_and,
    \\    .bit_or,
    \\    .shl,
    \\    .shl_sat,
    \\    .shr,
    \\    .bit_xor,
    \\    .bool_and,
    \\    .bool_or,
    \\    .div,
    \\    .equal_equal,
    \\    .greater_or_equal,
    \\    .greater_than,
    \\    .less_or_equal,
    \\    .less_than,
    \\    .merge_error_sets,
    \\    .mod,
    \\    .mul,
    \\    .mul_wrap,
    \\    .mul_sat,
    \\    .sub,
    \\    .sub_wrap,
    \\    .sub_sat => {
    \\      return self.tBinaryExpr(n, tag);
    \\    }, // yeah same
    \\  inline else => f,
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\tag: switch (expr2) { // one
    \\  // switching on an expr is good 1
    \\  // switching on an expr is good 2
    \\  // switching on an expr is good 3
    \\  .a => |bar| {},
    \\  inline .x => |*bar, foo| a = call(),
    \\  .y => |bar, foo| myExpr(),
    \\  .b, .c => |*foo| { // two
    \\    var k = abc;
    \\    if (k * someExpr(expr2) > 0xff) {
    \\      print("yep!");
    \\    }
    \\  },
    \\  .b, .c, .d, .e, .f, .g, .h => |*foo| { // three
    \\    if (ty.ast.sentinel.unwrap()) |n| {
    \\      sb.text("[")._();
    \\      var elems = self.db.seqb();
    \\      elems.softline().text("*:")._();
    \\      elems.append(try self.t(n));
    \\      sb.indent(elems.finish()).softline().text("]")._();
    \\    } else {
    \\      sb.text("[*]")._();
    \\    }
    \\  },
    \\  .d....e => {}, // keep
    \\  inline .add,
    \\    .add_wrap,
    \\    .add_sat,
    \\    .array_cat,
    \\    .array_mult,
    \\    .bang_equal,
    \\    .bit_and,
    \\    .bit_or,
    \\    .shl,
    \\    .shl_sat,
    \\    .shr,
    \\    .bit_xor,
    \\    .bool_and,
    \\    .bool_or,
    \\    .div,
    \\    .equal_equal,
    \\    .greater_or_equal,
    \\    .greater_than,
    \\    .less_or_equal,
    \\    .less_than,
    \\    .merge_error_sets,
    \\    .mod,
    \\    .mul,
    \\    .mul_wrap,
    \\    .mul_sat,
    \\    .sub,
    \\    .sub_wrap,
    \\    .sub_sat => {
    \\      return self.tBinaryExpr(n, tag);
    \\    }, // yeah same
    \\  inline else => f,
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\tag: switch (expr2) { // one
    \\  // switching on an expr is good 1
    \\  // switching on an expr is good 2
    \\  // switching on an expr is good 3
    \\  .a => |bar| {},
    \\  inline .x => |*bar, foo| a = call(),
    \\  .y => |bar, foo| myExpr(),
    \\  .b, .c => |*foo| { // two
    \\    var k = abc;
    \\    if (
    \\      k * someExpr(expr2)
    \\        > 0xff
    \\    ) {
    \\      print("yep!");
    \\    }
    \\  },
    \\  .b,
    \\  .c,
    \\  .d,
    \\  .e,
    \\  .f,
    \\  .g,
    \\  .h => |*foo| { // three
    \\    if (
    \\      ty.ast.sentinel.unwrap()
    \\    ) |n| {
    \\      sb.text("[")._();
    \\      var elems = self.db.seqb();
    \\      elems.softline()
    \\        .text("*:")
    \\        ._();
    \\      elems.append(
    \\        try self.t(n),
    \\      );
    \\      sb.indent(
    \\        elems.finish(),
    \\      )
    \\        .softline()
    \\        .text("]")
    \\        ._();
    \\    } else {
    \\      sb.text("[*]")._();
    \\    }
    \\  },
    \\  .d....e => {}, // keep
    \\  inline .add,
    \\    .add_wrap,
    \\    .add_sat,
    \\    .array_cat,
    \\    .array_mult,
    \\    .bang_equal,
    \\    .bit_and,
    \\    .bit_or,
    \\    .shl,
    \\    .shl_sat,
    \\    .shr,
    \\    .bit_xor,
    \\    .bool_and,
    \\    .bool_or,
    \\    .div,
    \\    .equal_equal,
    \\    .greater_or_equal,
    \\    .greater_than,
    \\    .less_or_equal,
    \\    .less_than,
    \\    .merge_error_sets,
    \\    .mod,
    \\    .mul,
    \\    .mul_wrap,
    \\    .mul_sat,
    \\    .sub,
    \\    .sub_wrap,
    \\    .sub_sat => {
    \\      return self.tBinaryExpr(
    \\        n,
    \\        tag,
    \\      );
    \\    }, // yeah same
    \\  inline else => f,
    \\}
  );
}

test "for 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ for (some, 0.., a..z) |*x, y, *z| lbl : {
  \\  print('yello world');
  \\}
  \\ for (some, 0.., a..z) |*x, y, *z| {
  \\  print('yello world');
  \\}
  \\ for (expr) |pl| something();
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  }
    \\  for (some, 0.., a..z) |*x, y, *z| {
    \\    print('yello world');
    \\  }
    \\  for (expr) |pl| something();
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  }
    \\  for (some, 0.., a..z) |*x, y, *z| {
    \\    print('yello world');
    \\  }
    \\  for (expr) |pl| something();
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  }
    \\  for (some, 0.., a..z) |*x, y, *z| {
    \\    print('yello world');
    \\  }
    \\  for (expr) |pl| something();
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  }
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) |*x, y, *z| {
    \\    print('yello world');
    \\  }
    \\  for (expr) |pl| something();
    \\}
  );
}

test "for 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ for (some, a..k) |a, b| {} else {var j = testM();}
  \\ for (some, 0.., a..z) |*x, y, *z| lbl : {
  \\  print('yello world');
  \\} else someStuff();
  \\ inline for (some, 0.., a..z) |*x, y, *z| lbl : {
  \\  print('yello world');
  \\} else {
  \\  someCall();
  \\  var abc = try testS();
  \\}
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, a..k) |a, b| {
    \\  } else {
    \\    var j = testM();
    \\  }
    \\  for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  } else someStuff();
    \\  inline for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, a..k) |a, b| {
    \\  } else {
    \\    var j = testM();
    \\  }
    \\  for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  } else someStuff();
    \\  inline for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, a..k) |a, b| {
    \\  } else {
    \\    var j = testM();
    \\  }
    \\  for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  } else someStuff();
    \\  inline for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, a..k) |a, b| {
    \\  } else {
    \\    var j = testM();
    \\  }
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  } else someStuff();
    \\  inline for (
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\}
  );
}

test "for 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ for (some, 0.., a..z) |*x, y, *z| {
  \\  print('yello world');
  \\} else {
  \\  someCall();
  \\  var abc = try testS();
  \\}
  \\ for (some, a..k) |a, b| exprMe() else {var j = testS();}
  \\for (0..10) |x| _ = blk: {
  \\  std.debug.print("x is: {}\n", .{x});
  \\  break :blk void;
  \\} else {
  \\  std.debug.print("done\n", .{});
  \\}
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  for (some, a..k) |a, b| exprMe()
    \\  else {
    \\    var j = testS();
    \\  }
    \\  for (0..10) |x| _ = blk: {
    \\    std.debug.print("x is: {}\n", .{x});
    \\    break :blk void;
    \\  }
    \\  else {
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  for (some, a..k) |a, b| exprMe()
    \\  else {
    \\    var j = testS();
    \\  }
    \\  for (0..10) |x| _ = blk: {
    \\    std.debug.print("x is: {}\n", .{x});
    \\    break :blk void;
    \\  }
    \\  else {
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  for (some, a..k) |a, b| exprMe()
    \\  else {
    \\    var j = testS();
    \\  }
    \\  for (0..10) |x|
    \\    _ = blk: {
    \\      std.debug.print("x is: {}\n", .{x});
    \\      break :blk void;
    \\    }
    \\  else {
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) |*x, y, *z| {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  for (some, a..k) |a, b|
    \\    exprMe()
    \\  else {
    \\    var j = testS();
    \\  }
    \\  for (0..10) |x|
    \\    _ = blk: {
    \\      std.debug.print(
    \\        "x is: {}\n",
    \\        .{x},
    \\      );
    \\      break :blk void;
    \\    }
    \\  else {
    \\    std.debug.print(
    \\      "done\n",
    \\      .{},
    \\    );
    \\  }
    \\}
  );
}

test "for 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ for (some, 0.., a..z) |*x, y, *z| 
  \\  print('yello world')
  \\ else
  \\  someCall();
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| print('yello world') else someCall();
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| print('yello world') else someCall();
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z|
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) |*x, y, *z|
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\}
  );
}

test "for 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ for (some, 0.., a..z) |*x, y, *z| {
  \\ }
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {}
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {}
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {}
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) |*x, y, *z| {}
    \\}
  );
}

test "for 6" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ lbl: for (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
  \\ for (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
  \\ for (someNiceCondition(a, b, c)) |x| _ = blk: {
  \\  print('yello world');
  \\};
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  lbl: for (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) |x| _ = blk: {
    \\    print('yello world');
    \\  };
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  lbl: for (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) |x| _ = blk: {
    \\    print('yello world');
    \\  };
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  lbl: for (someNiceCondition(a, b, c)) |x|
    \\    someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) |x|
    \\    someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) |x|
    \\    _ = blk: {
    \\      print('yello world');
    \\    };
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  lbl: for (
    \\    someNiceCondition(
    \\      a,
    \\      b,
    \\      c,
    \\    ),
    \\  ) |x|
    \\    someFancy(
    \\      callExpr(),
    \\      a,
    \\      b,
    \\    );
    \\  for (
    \\    someNiceCondition(
    \\      a,
    \\      b,
    \\      c,
    \\    ),
    \\  ) |x|
    \\    someFancy(
    \\      callExpr(),
    \\      a,
    \\      b,
    \\    );
    \\  for (
    \\    someNiceCondition(
    \\      a,
    \\      b,
    \\      c,
    \\    ),
    \\  ) |x|
    \\    _ = blk: {
    \\      print('yello world');
    \\    };
    \\}
  );
}

test "while 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ while (someNiceCondition(a, b, c)) |*x| : (j += 5) {
  \\ }
  \\ inline while (someNiceCondition(a, b, c)) |*x| : (j += 5) {
  \\ } else |y| {
  \\ }
  \\ inline while (someNiceCondition(a, b, c)) |x| : (j += 5) {
  \\  print('yello world');
  \\ } else |y| {
  \\  someCall();
  \\ }
  \\ while (someNiceCondition(a, b, c)) |*x| : (j += 5) {
  \\  print('yello world');
  \\ } else |y| {
  \\  someCall();
  \\ }
  \\ while (someNiceCondition(a, b, c)) |x| : (j += 5) {
  \\  print('yello world');
  \\ } else |y| {
  \\  someCall();
  \\ }
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |*x| : (j += 5) {}
    \\  inline while (someNiceCondition(a, b, c)) |*x| : (j += 5) {
    \\  } else |y| {
    \\  }
    \\  inline while (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |*x| : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |*x| : (j += 5) {}
    \\  inline while (someNiceCondition(a, b, c)) |*x| : (j += 5) {
    \\  } else |y| {
    \\  }
    \\  inline while (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |*x| : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |*x| : (j += 5) {}
    \\  inline while (someNiceCondition(a, b, c)) |*x|
    \\  : (j += 5) {
    \\  } else |y| {
    \\  }
    \\  inline while (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |*x| : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |*x|
    \\  : (j += 5) {}
    \\  inline while (
    \\    someNiceCondition(a, b, c)
    \\  ) |*x|
    \\  : (j += 5) {
    \\  } else |y| {
    \\  }
    \\  inline while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |*x|
    \\  : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5) {
    \\    print('yello world');
    \\  } else |y| {
    \\    someCall();
    \\  }
    \\}
  );
}

test "while 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ while (someNiceCondition(a, b, c)) |x| blk: {
  \\  print('yello world');
  \\ } else {
  \\  someCall();
  \\ }
  \\ while (someNiceCondition(a, b, c)) |x| blk: {
  \\  print('yello world');
  \\ } else blk2: {
  \\  someCall();
  \\ }
  \\ inline while (someNiceCondition(a, b, c)) |x| : (j += 5) 
  \\  print('yello world')
  \\  else |y| {
  \\  someCall();
  \\ }
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |x| blk: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| blk: {
    \\    print('yello world');
    \\  } else blk2: {
    \\    someCall();
    \\  }
    \\  inline while (someNiceCondition(a, b, c)) |x| : (j += 5) print('yello world')
    \\  else |y| {
    \\    someCall();
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |x| blk: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| blk: {
    \\    print('yello world');
    \\  } else blk2: {
    \\    someCall();
    \\  }
    \\  inline while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    print('yello world')
    \\  else |y| {
    \\    someCall();
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |x| blk: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| blk: {
    \\    print('yello world');
    \\  } else blk2: {
    \\    someCall();
    \\  }
    \\  inline while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    print('yello world')
    \\  else |y| {
    \\    someCall();
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x| blk: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\  }
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x| blk: {
    \\    print('yello world');
    \\  } else blk2: {
    \\    someCall();
    \\  }
    \\  inline while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5)
    \\    print('yello world')
    \\  else |y| {
    \\    someCall();
    \\  }
    \\}
  );
}

test "while 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ while (someNiceCondition(a, b, c)) |x| : (j += 5) 
  \\  print('yello world')
  \\  else |y| 
  \\  someCall();
  \\ while (someNiceCondition(a, b, c)) |x| : (j += 5) 
  \\  print('yello world')
  \\  else someCall();
  \\ inline while (someNiceCondition(a, b, c))
  \\  print('yello world')
  \\  else someCall();
  \\ while (someNiceCondition(a, b, c)) |x| : (j += 5) 
  \\  print('yello world');
  \\ while (someNiceCondition(a, b, c)) |x| : (j += someExpr(5, abc, jkl)) {
  \\  print('yello world');
  \\  }
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) print('yello world') else |y| someCall();
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) print('yello world') else someCall();
    \\  inline while (someNiceCondition(a, b, c)) print('yello world') else someCall();
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) print('yello world');
    \\  while (someNiceCondition(a, b, c)) |x| : (j += someExpr(5, abc, jkl)) {
    \\    print('yello world');
    \\  }
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    print('yello world')
    \\  else |y|
    \\    someCall();
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\  inline while (someNiceCondition(a, b, c))
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) print('yello world');
    \\  while (someNiceCondition(a, b, c)) |x| : (j += someExpr(5, abc, jkl)) {
    \\    print('yello world');
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    print('yello world')
    \\  else |y|
    \\    someCall();
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\  inline while (someNiceCondition(a, b, c))
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    print('yello world');
    \\  while (someNiceCondition(a, b, c)) |x|
    \\  : (j += someExpr(5, abc, jkl)) {
    \\    print('yello world');
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5)
    \\    print('yello world')
    \\  else |y|
    \\    someCall();
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5)
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\  inline while (
    \\    someNiceCondition(a, b, c)
    \\  )
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5)
    \\    print('yello world');
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (
    \\    j += someExpr(5, abc, jkl)
    \\  ) {
    \\    print('yello world');
    \\  }
    \\}
  );
}

test "while 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ lbl: while (someNiceCondition(a, b, c)) |x| : (j += 5) {
  \\  print('yello world');
  \\}
  \\ while (someNiceCondition(a, b, c)) |x| : (j += 5) blk: {
  \\  print('yello world');
  \\}
  \\ while (someNiceCondition(a, b, c)) |x| : (j += 5) _ = blk: {
  \\  print('yello world');
  \\};
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  lbl: while (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) blk: {
    \\    print('yello world');
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) _ = blk: {
    \\    print('yello world');
    \\  };
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  lbl: while (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) blk: {
    \\    print('yello world');
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    _ = blk: {
    \\      print('yello world');
    \\    };
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  lbl: while (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) blk: {
    \\    print('yello world');
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    _ = blk: {
    \\      print('yello world');
    \\    };
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  lbl: while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5) {
    \\    print('yello world');
    \\  }
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5) blk: {
    \\    print('yello world');
    \\  }
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5)
    \\    _ = blk: {
    \\      print('yello world');
    \\    };
    \\}
  );
}

test "zig 0.16.0" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\const U = packed union(u2) {
  \\    a: i2,
  \\    b: u2,
  \\};
  \\
  \\const u: U = .{ .a = -1 };
  \\switch (u) {
  \\    .{ .b = 3 } => {},
  \\    else => unreachable,
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 100 }, al);
  try check(
    res,
    \\const U = packed union(u2) { a: i2, b: u2 };
    \\
    \\const u: U = .{ .a = -1 };
    \\switch (u) {
    \\  .{ .b = 3 } => {},
    \\  else => unreachable,
    \\}
  );
  res = try format(doc, .{ .width = 80 }, al);
  try check(
    res,
    \\const U = packed union(u2) { a: i2, b: u2 };
    \\
    \\const u: U = .{ .a = -1 };
    \\switch (u) {
    \\  .{ .b = 3 } => {},
    \\  else => unreachable,
    \\}
  );
  // using width: 60
  res = try format(doc, .{ .width = 60 }, al);
  try check(
    res,
    \\const U = packed union(u2) { a: i2, b: u2 };
    \\
    \\const u: U = .{ .a = -1 };
    \\switch (u) {
    \\  .{ .b = 3 } => {},
    \\  else => unreachable,
    \\}
  );
  // using width: 15
  res = try format(doc, .{ .width = 15 }, al);
  try check(
    res,
    \\const U = packed union(
    \\  u2
    \\) {
    \\  a: i2,
    \\  b: u2,
    \\};
    \\
    \\const u: U = .{
    \\  .a = -1,
    \\};
    \\switch (u) {
    \\  .{
    \\    .b = 3,
    \\  } => {},
    \\  else => unreachable,
    \\}
  );
}

test "comments/vardecl 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const // start me
  \\fox3 = // haha
  \\ union ( // open sesame
  \\ big) 
  \\ {// start 
  \\a, b, c};// end
  \\
  \\var buffer
  \\  align( // begin
  \\ 64) // end
  \\  addrspace(.generic)
  \\  linksection(
  \\    ".my_custom_section" // clearance?
  \\  ) = undefined;
  \\
  \\var buffer: Type // my bad
  \\  align( 
  \\ 64) 
  \\  addrspace(. //just testing '.'
  \\ generic)
  \\  linksection(
  \\    ".my_custom_section"
  \\  ) = undefined;
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const // start me
    \\fox3 = // haha
    \\union( // open sesame
    \\  big
    \\) { // start
    \\  a,
    \\  b,
    \\  c,
    \\}; // end
    \\
    \\var buffer
    \\  align( // begin
    \\    64
    \\  ) // end
    \\  addrspace(.generic)
    \\  linksection(
    \\    ".my_custom_section" // clearance?
    \\  ) = undefined;
    \\
    \\var buffer: Type // my bad
    \\  align(64)
    \\  addrspace(
    \\    . //just testing '.'
    \\    generic
    \\  )
    \\  linksection(".my_custom_section") = undefined;
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\const // start me
    \\fox3 = // haha
    \\union( // open sesame
    \\  big
    \\) { // start
    \\  a,
    \\  b,
    \\  c,
    \\}; // end
    \\
    \\var buffer
    \\  align( // begin
    \\    64
    \\  ) // end
    \\  addrspace(
    \\    .generic
    \\  )
    \\  linksection(
    \\    ".my_custom_section" // clearance?
    \\  ) = undefined;
    \\
    \\var buffer: Type // my bad
    \\  align(
    \\    64
    \\  )
    \\  addrspace(
    \\    . //just testing '.'
    \\    generic
    \\  )
    \\  linksection(
    \\    ".my_custom_section"
    \\  ) = undefined;
  );
}

test "comments/vardecl 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const // start me
  \\fox3 = // haha
  \\ union ( // open sesame
  \\ big) 
  \\ {// start 
  \\a, b, c};// end
  \\
  \\var buffer
  \\  align( // begin
  \\ 64) // end
  \\  addrspace(.generic)
  \\  linksection(
  \\    ".my_custom_section" // clearance?
  \\  ) = undefined;
  \\
  \\var buffer: Type // my bad
  \\  align( 
  \\ 64) 
  \\  addrspace(. //just testing '.'
  \\ generic)
  \\  linksection(
  \\    ".my_custom_section"
  \\  ) = undefined;
  \\var // var
  \\ x // x
  \\ = // equal
  \\ foo(abc, bar, baz); // init
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const // start me
    \\fox3 = // haha
    \\union( // open sesame
    \\  big
    \\) { // start
    \\  a,
    \\  b,
    \\  c,
    \\}; // end
    \\
    \\var buffer
    \\  align( // begin
    \\    64
    \\  ) // end
    \\  addrspace(.generic)
    \\  linksection(
    \\    ".my_custom_section" // clearance?
    \\  ) = undefined;
    \\
    \\var buffer: Type // my bad
    \\  align(64)
    \\  addrspace(
    \\    . //just testing '.'
    \\    generic
    \\  )
    \\  linksection(".my_custom_section") = undefined;
    \\var // var
    \\x // x
    \\= // equal
    \\foo(abc, bar, baz); // init
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\const // start me
    \\fox3 = // haha
    \\union( // open sesame
    \\  big
    \\) { // start
    \\  a,
    \\  b,
    \\  c,
    \\}; // end
    \\
    \\var buffer
    \\  align( // begin
    \\    64
    \\  ) // end
    \\  addrspace(
    \\    .generic
    \\  )
    \\  linksection(
    \\    ".my_custom_section" // clearance?
    \\  ) = undefined;
    \\
    \\var buffer: Type // my bad
    \\  align(
    \\    64
    \\  )
    \\  addrspace(
    \\    . //just testing '.'
    \\    generic
    \\  )
    \\  linksection(
    \\    ".my_custom_section"
    \\  ) = undefined;
    \\var // var
    \\x // x
    \\= // equal
    \\foo(
    \\  abc,
    \\  bar,
    \\  baz,
    \\); // init
  );
}

test "comments/call 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ // this is a line comment x
  \\ // this is a line comment y
  \\ // this is a line comment z
  \\
  \\ // this is a line comment a
  \\ // this is a line comment b
  \\ // this is a line comment c
  \\ foo_bar
  // \\ // another
  \\ ( // testing ab12
  \\ // call's doc
  \\call // apologies
  \\( // link
  \\ // psych!
  \\), // testing
  \\ // foo2's doc
  \\ foo2_sync(
  \\ // This fixes abc
  \\ // This is another 123
  \\ // and the last
  \\ 123 , just, "axis"
  \\, // testing e
  \\ "test" // yesterday
  \\, // oh yeah!
  \\),
  \\ call2(), call3(x),
  \\), 
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\// this is a line comment x
    \\// this is a line comment y
    \\// this is a line comment z
    \\
    \\// this is a line comment a
    \\// this is a line comment b
    \\// this is a line comment c
    \\foo_bar( // testing ab12
    \\  // call's doc
    \\  call // apologies
    \\  ( // link
    \\    // psych!
    \\  ), // testing
    \\  // foo2's doc
    \\  foo2_sync(
    \\    // This fixes abc
    \\    // This is another 123
    \\    // and the last
    \\    123,
    \\    just,
    \\    "axis", // testing e
    \\    "test" // yesterday
    \\    , // oh yeah!
    \\  ),
    \\  call2(),
    \\  call3(x),
    \\),
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\// this is a line comment x
    \\// this is a line comment y
    \\// this is a line comment z
    \\
    \\// this is a line comment a
    \\// this is a line comment b
    \\// this is a line comment c
    \\foo_bar( // testing ab12
    \\  // call's doc
    \\  call // apologies
    \\  ( // link
    \\    // psych!
    \\  ), // testing
    \\  // foo2's doc
    \\  foo2_sync(
    \\    // This fixes abc
    \\    // This is another 123
    \\    // and the last
    \\    123,
    \\    just,
    \\    "axis", // testing e
    \\    "test" // yesterday
    \\    , // oh yeah!
    \\  ),
    \\  call2(),
    \\  call3(
    \\    x,
    \\  ),
    \\),
  );
}

test "comments/call 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ doCall( // opening
  \\   // inner
  \\ tst
  \\ ), // closing
  \\ doCall( // opening
  \\   // inner
  \\   // long comment
  \\   // another long comment
  \\   // another long comment
  \\   //
  \\ ), // closing
  \\
  \\ foo(b, a // not end)
  \\), // capture next
  \\  foobar(. //just testing '.'
  \\ generic),
  \\ fox_pot(
  \\call // apologies
  \\( // link
  \\ // psych S!
  \\ // psych!
  \\ // psych!
  \\)
  \\), // testing
  \\ foo2_sync(
  \\ // This fixes abc
  \\ // This is another 123
  \\ // and the last
  \\ 123 , just, "axis"
  \\, // testing e
  \\ "test" // yesterday
  \\, // oh yeah!
  \\),
  \\call // apologies
  \\( // a long trailing
  \\  cricket(a, b())
  \\), // not ya
  \\call // apologies
  \\( // a long trailing
  \\) // not ya
  \\,
  \\
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\doCall( // opening
    \\  // inner
    \\  tst,
    \\), // closing
    \\doCall( // opening
    \\  // inner
    \\  // long comment
    \\  // another long comment
    \\  // another long comment
    \\  //
    \\), // closing
    \\
    \\foo(
    \\  b,
    \\  a // not end)
    \\), // capture next
    \\foobar(
    \\  . //just testing '.'
    \\  generic,
    \\),
    \\fox_pot(
    \\  call // apologies
    \\  ( // link
    \\    // psych S!
    \\    // psych!
    \\    // psych!
    \\  ),
    \\), // testing
    \\foo2_sync(
    \\  // This fixes abc
    \\  // This is another 123
    \\  // and the last
    \\  123,
    \\  just,
    \\  "axis", // testing e
    \\  "test" // yesterday
    \\  , // oh yeah!
    \\),
    \\call // apologies
    \\( // a long trailing
    \\  cricket(a, b()),
    \\), // not ya
    \\call // apologies
    \\( // a long trailing
    \\) // not ya
    \\,
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\doCall( // opening
    \\  // inner
    \\  tst,
    \\), // closing
    \\doCall( // opening
    \\  // inner
    \\  // long comment
    \\  // another long comment
    \\  // another long comment
    \\  //
    \\), // closing
    \\
    \\foo(
    \\  b,
    \\  a // not end)
    \\), // capture next
    \\foobar(
    \\  . //just testing '.'
    \\  generic,
    \\),
    \\fox_pot(
    \\  call // apologies
    \\  ( // link
    \\    // psych S!
    \\    // psych!
    \\    // psych!
    \\  ),
    \\), // testing
    \\foo2_sync(
    \\  // This fixes abc
    \\  // This is another 123
    \\  // and the last
    \\  123,
    \\  just,
    \\  "axis", // testing e
    \\  "test" // yesterday
    \\  , // oh yeah!
    \\),
    \\call // apologies
    \\( // a long trailing
    \\  cricket(
    \\    a,
    \\    b(),
    \\  ),
    \\), // not ya
    \\call // apologies
    \\( // a long trailing
    \\) // not ya
    \\,
  );
}

test "comments/call 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  // builtin calls
  const src =
  \\ fn fun(expr: Type) switch // 0
  \\ (@TypeOf(expr)) { // a
  \\ .a => TyFoo, .b => TyBar, else => TyBaz} { // b
  \\  var x = @This // 0
  \\ (// 1
  \\  // in doc
  \\ a, // one
  \\ b, c.foo(1, 2, "oxff")
  \\  // end doc
  \\ ) // 3
  \\ ;
  \\  var y = @This(a, // two
  \\ b, c.foo(1, 2, "oxff") // last
  \\ );
  \\  var z = @This(a, // three
  \\ b, c.foo(1, 2, "oxff"), // final
  \\ );
  \\   return 
  \\label: switch (expr)  { // 1
  \\  a => a, // 2
  \\  b, c => c, // 3
  \\  inline d...e => e, // 4
  \\  else => f, //foo
  \\}; // 5
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn fun(
    \\  expr: Type,
    \\) switch // 0
    \\(@TypeOf(expr)) { // a
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} { // b
    \\  var x = @This // 0
    \\  ( // 1
    \\    // in doc
    \\    a, // one
    \\    b,
    \\    c.foo(1, 2, "oxff")
    \\    // end doc
    \\  ) // 3
    \\  ;
    \\  var y = @This(
    \\    a, // two
    \\    b,
    \\    c.foo(1, 2, "oxff") // last
    \\  );
    \\  var z = @This(
    \\    a, // three
    \\    b,
    \\    c.foo(1, 2, "oxff"), // final
    \\  );
    \\  return label: switch (expr) { // 1
    \\    a => a, // 2
    \\    b, c => c, // 3
    \\    inline d...e => e, // 4
    \\    else => f, //foo
    \\  }; // 5
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn fun(
    \\  expr: Type,
    \\) switch // 0
    \\(
    \\  @TypeOf(expr)
    \\) { // a
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} { // b
    \\  var x = @This // 0
    \\  ( // 1
    \\    // in doc
    \\    a, // one
    \\    b,
    \\    c.foo(
    \\      1,
    \\      2,
    \\      "oxff",
    \\    )
    \\    // end doc
    \\  ) // 3
    \\  ;
    \\  var y = @This(
    \\    a, // two
    \\    b,
    \\    c.foo(
    \\      1,
    \\      2,
    \\      "oxff",
    \\    ) // last
    \\  );
    \\  var z = @This(
    \\    a, // three
    \\    b,
    \\    c.foo(
    \\      1,
    \\      2,
    \\      "oxff",
    \\    ), // final
    \\  );
    \\  return label: switch (
    \\    expr
    \\  ) { // 1
    \\    a => a, // 2
    \\    b, c => c, // 3
    \\    inline d...e => e, // 4
    \\    else => f, //foo
    \\  }; // 5
    \\}
  );
}

test "comments/chains 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\var sb = self.db.xyz(a, b(),);
  \\var sb = self_db_xyz(a, b(),);
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var sb = self.db.xyz(a, b());
    \\var sb = self_db_xyz(a, b());
  );
  // using width: 15
  res = try format(doc, .{ .width = 15 }, al);
  try check(
    res,
    \\var sb = self.db.xyz(
    \\  a,
    \\  b(),
    \\);
    \\var sb = self_db_xyz(
    \\  a,
    \\  b(),
    \\);
  );
}

test "comments/chains 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var x = foo // yes
  \\ . // two
  \\ bar // a
  \\ ( // first
  \\ a, b, c()
  \\ ) // last
  \\ ; // end
  \\
  \\ var y = foo // yes
  \\ . // two
  \\ bar // a
  \\ ( // first
  \\ a // one
  \\ , // comma
  \\ b // two
  \\ , // comma
  \\ c() // three
  \\ , // last comma
  \\ ) // last
  \\ ; // end
  \\
  \\ var z = foo.bar // yes
  \\ . // two
  \\ bar // a
  \\ ( // first
  \\ // inline comment 1
  \\ // inline comment 2
  \\ a // one
  \\ , // comma
  \\ b // two
  \\ , // comma
  \\ c(
  \\ a // my a
  \\ . // my .
  \\ b // my b
  \\ ( // lbr
  \\ 0x1 // 1
  \\, // comma
  \\ 0x2 // 2
  \\ , // comma
  \\ "three" // 3
  \\ ) // rbr
  \\ , // last comma
  \\ a() // my a
  \\ . // my .
  \\ b // my b
  \\ (1, 2, 3), // my args
  \\) // three
  \\ ).car // last
  \\ ()
  \\ ; // end
  \\
  \\ var z = foo.bar
  \\ . 
  \\ bar 
  \\ ( 
  \\ a
  \\ , 
  \\ b
  \\ ,
  \\ c()
  \\ ).car 
  \\ ()
  \\ ; // end
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var x = foo // yes
    \\. // two
    \\bar // a
    \\( // first
    \\  a,
    \\  b,
    \\  c(),
    \\) // last
    \\; // end
    \\
    \\var y = foo // yes
    \\. // two
    \\bar // a
    \\( // first
    \\  a // one
    \\  , // comma
    \\  b // two
    \\  , // comma
    \\  c() // three
    \\  , // last comma
    \\) // last
    \\; // end
    \\
    \\var z = foo.bar // yes
    \\. // two
    \\bar // a
    \\( // first
    \\  // inline comment 1
    \\  // inline comment 2
    \\  a // one
    \\  , // comma
    \\  b // two
    \\  , // comma
    \\  c(
    \\    a // my a
    \\    . // my .
    \\    b // my b
    \\    ( // lbr
    \\      0x1 // 1
    \\      , // comma
    \\      0x2 // 2
    \\      , // comma
    \\      "three" // 3
    \\    ) // rbr
    \\    , // last comma
    \\    a() // my a
    \\    . // my .
    \\    b // my b
    \\    (1, 2, 3), // my args
    \\  ) // three
    \\)
    \\  .car // last
    \\  (); // end
    \\
    \\var z = foo.bar.bar(a, b, c()).car(); // end
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var x = foo // yes
    \\. // two
    \\bar // a
    \\( // first
    \\  a,
    \\  b,
    \\  c(),
    \\) // last
    \\; // end
    \\
    \\var y = foo // yes
    \\. // two
    \\bar // a
    \\( // first
    \\  a // one
    \\  , // comma
    \\  b // two
    \\  , // comma
    \\  c() // three
    \\  , // last comma
    \\) // last
    \\; // end
    \\
    \\var z = foo.bar // yes
    \\. // two
    \\bar // a
    \\( // first
    \\  // inline comment 1
    \\  // inline comment 2
    \\  a // one
    \\  , // comma
    \\  b // two
    \\  , // comma
    \\  c(
    \\    a // my a
    \\    . // my .
    \\    b // my b
    \\    ( // lbr
    \\      0x1 // 1
    \\      , // comma
    \\      0x2 // 2
    \\      , // comma
    \\      "three" // 3
    \\    ) // rbr
    \\    , // last comma
    \\    a() // my a
    \\      . // my .
    \\      b // my b
    \\      (
    \\        1,
    \\        2,
    \\        3,
    \\      ), // my args
    \\  ) // three
    \\)
    \\  .car // last
    \\  (); // end
    \\
    \\var z = foo.bar.bar(a, b, c())
    \\  .car(); // end
  );
}

test "comments/chains 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\var ky = self.group(
  \\  self.seqb()
  \\    .text("Group(")
  \\    .indent(
  \\      self.seqb()
  \\        .softline()
  \\        .text(id)
  \\        .text(",")
  \\        .normline()
  \\        .appends(_d)
  \\        .finish(),
  \\    )
  \\    .softline()
  \\    .text(")")
  \\    .finish(),
  \\);
  \\var sb = self.db.xyz()
  \\  .pkzy.aaa.seqb()
  \\  .appends(lhs)
  \\  .sb.ifsplit(
  \\ // inline comment 1
  \\ // inline comment 2
  \\
  \\ // inline comment 3
  \\    id,
  \\    self.db.indent(
  \\      self.db // that way
  \\        .seqb() // haha 
  \\      .softline().text(".").text(self._token(rhs)).finish(),
  \\    )
  \\      .self.db.seqb(
  \\
  \\ // inline comment 1
  \\ // inline comment 2
  \\
  \\    )
  \\      .text(".")
  \\      .text(self._token(rhs))
  \\      .finish(),
  \\  )
  \\  ._();
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb().softline().text(id).text(",").normline().appends(_d).finish(),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    // inline comment 1
    \\    // inline comment 2
    \\
    \\    // inline comment 3
    \\    id,
    \\    self.db.indent(
    \\      self.db // that way
    \\      .seqb() // haha
    \\        .softline()
    \\        .text(".")
    \\        .text(self._token(rhs))
    \\        .finish(),
    \\    )
    \\      .self.db.seqb(
    \\        // inline comment 1
    \\        // inline comment 2
    \\      )
    \\      .text(".")
    \\      .text(self._token(rhs))
    \\      .finish(),
    \\  )
    \\  ._();
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\var ky = self.group(
    \\  self.seqb()
    \\    .text("Group(")
    \\    .indent(
    \\      self.seqb()
    \\        .softline()
    \\        .text(id)
    \\        .text(",")
    \\        .normline()
    \\        .appends(_d)
    \\        .finish(),
    \\    )
    \\    .softline()
    \\    .text(")")
    \\    .finish(),
    \\);
    \\var sb = self.db.xyz()
    \\  .pkzy.aaa.seqb()
    \\  .appends(lhs)
    \\  .sb.ifsplit(
    \\    // inline comment 1
    \\    // inline comment 2
    \\
    \\    // inline comment 3
    \\    id,
    \\    self.db.indent(
    \\      self.db // that way
    \\      .seqb() // haha
    \\        .softline()
    \\        .text(".")
    \\        .text(
    \\          self._token(
    \\            rhs,
    \\          ),
    \\        )
    \\        .finish(),
    \\    )
    \\      .self.db.seqb(
    \\        // inline comment 1
    \\        // inline comment 2
    \\      )
    \\      .text(".")
    \\      .text(
    \\        self._token(
    \\          rhs,
    \\        ),
    \\      )
    \\      .finish(),
    \\  )
    \\  ._();
  );
}

test "comments/fundecl 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\fn // comment fn
  \\foo2 // comment name
  \\ ( // comment bracket
  \\  comptime T: type, // comment comptime
  \\  x // before
  \\ : // right there
  \\  ArrayList() // after
  \\, // comma me surprised
  \\  comptime // see me
  \\ x: // again again
  \\ i32, // aha here we are
  \\  noalias // from here
  \\ y: u2, // to here
  \\  k: anytype,
  \\  noalias y: u2,
  \\  k: anytype,
  \\  ... // first time?
  \\, // second time?
  \\) // just for funsies 
  \\ A(T) { // start there
  \\  // nothing to prove
  \\}// good stuff
  \\
  \\pub // comment 1
  \\ fn // comment 2
  \\ fantasticFooBar // comment 3
  \\ (  // comment 4
  \\  comptime   // comment 5
  \\ T  // comment 6
  \\: // comment 6b
  \\ type // comment 7
  \\ , // comment 8
  \\  x: std_ArrayList(T),
  \\  comptime x: i32,
  \\  noalias y: u2,
  \\  k: anytype,
  \\)  // comment a
  \\align(64)  // comment b
  \\addrspace(// copium
  \\.generic)  // comment c
  \\callconv(.c)  // comment d
  \\A(T) // yeah sure
  \\ { // aha!
  \\  // var x = 5;
  \\  print("just testing!");
  \\  var x: i32, const y: u32 = foo_(bar(1, 2));
  \\} // end aha!
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn // comment fn
    \\foo2 // comment name
    \\( // comment bracket
    \\  comptime T: type, // comment comptime
    \\  x // before
    \\  : // right there
    \\  ArrayList() // after
    \\  , // comma me surprised
    \\  comptime // see me
    \\  x: // again again
    \\  i32, // aha here we are
    \\  noalias // from here
    \\  y: u2, // to here
    \\  k: anytype,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  ... // first time?
    \\  , // second time?
    \\) // just for funsies
    \\A(T) { // start there
    \\  // nothing to prove
    \\} // good stuff
    \\
    \\pub // comment 1
    \\fn // comment 2
    \\fantasticFooBar // comment 3
    \\( // comment 4
    \\  comptime // comment 5
    \\  T // comment 6
    \\  : // comment 6b
    \\  type // comment 7
    \\  , // comment 8
    \\  x: std_ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) // comment a
    \\align(64) // comment b
    \\addrspace( // copium
    \\  .generic
    \\) // comment c
    \\callconv(.c) // comment d
    \\A(T) // yeah sure
    \\{ // aha!
    \\  // var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\} // end aha!
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\fn // comment fn
    \\foo2 // comment name
    \\( // comment bracket
    \\  comptime T: type, // comment comptime
    \\  x // before
    \\  : // right there
    \\  ArrayList() // after
    \\  , // comma me surprised
    \\  comptime // see me
    \\  x: // again again
    \\  i32, // aha here we are
    \\  noalias // from here
    \\  y: u2, // to here
    \\  k: anytype,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  ... // first time?
    \\  , // second time?
    \\) // just for funsies
    \\A(
    \\  T,
    \\) { // start there
    \\  // nothing to prove
    \\} // good stuff
    \\
    \\pub // comment 1
    \\fn // comment 2
    \\fantasticFooBar // comment 3
    \\( // comment 4
    \\  comptime // comment 5
    \\  T // comment 6
    \\  : // comment 6b
    \\  type // comment 7
    \\  , // comment 8
    \\  x: std_ArrayList(
    \\    T,
    \\  ),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) // comment a
    \\align(
    \\  64
    \\) // comment b
    \\addrspace( // copium
    \\  .generic
    \\) // comment c
    \\callconv(
    \\  .c
    \\) // comment d
    \\A(
    \\  T,
    \\) // yeah sure
    \\{ // aha!
    \\  // var x = 5;
    \\  print(
    \\    "just testing!",
    \\  );
    \\  var x: i32, const y: u32 = foo_(
    \\    bar(
    \\      1,
    \\      2,
    \\    ),
    \\  );
    \\} // end aha!
  );
}

test "comments/fundecl 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ // last one!
  \\ j: usize,
  \\
  \\ fooIsLong(),
  \\ // yippee!
  \\ fn foo() void {// testing you
  \\ x();
  \\}
  \\
  \\ fn foo() void {// testing you
  \\}
  \\
  \\ fn foo() void {
  \\ var x // dont
  \\ = ( - // haha
  \\ j)(abc);
  \\ var x: Type align(12) // dont
  \\ = ( - // haha
  \\ j)(abc);
  \\ var x: Type align(12)
  \\ = ( - 
  \\ j)(abc);
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\// last one!
    \\j: usize,
    \\
    \\fooIsLong(),
    \\// yippee!
    \\fn foo() void { // testing you
    \\  x();
    \\}
    \\
    \\fn foo() void { // testing you
    \\}
    \\
    \\fn foo() void {
    \\  var x // dont
    \\  = (- // haha
    \\    j)(abc);
    \\  var x: Type
    \\    align(12) // dont
    \\  = (- // haha
    \\    j)(abc);
    \\  var x: Type align(12) = (-j)(abc);
    \\}
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\// last one!
    \\j: usize,
    \\
    \\fooIsLong(),
    \\// yippee!
    \\fn foo() void { // testing you
    \\  x();
    \\}
    \\
    \\fn foo() void { // testing you
    \\}
    \\
    \\fn foo() void {
    \\  var x // dont
    \\  = (- // haha
    \\    j)(
    \\    abc,
    \\  );
    \\  var x: Type
    \\    align(
    \\      12
    \\    ) // dont
    \\  = (- // haha
    \\    j)(
    \\    abc,
    \\  );
    \\  var x: Type
    \\    align(
    \\      12
    \\    ) = (-j)(
    \\    abc,
    \\  );
    \\}
  );
}

test "comments/fundecl 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\pub // comment 1
  \\ fn // comment 2
  \\ fantasticFooBar // comment 3
  \\ (  // comment 4
  \\ // this is a top level comment 1
  \\ // this is a top level comment 2
  \\ // this is a top level comment 3
  \\  comptime   // comment 5
  \\ T  // comment 6
  \\: // comment 6b
  \\ type // comment 7
  \\ , // comment 8
  \\  x: std_ArrayList(T),
  \\  comptime x: i32,
  \\  noalias y: u2,
  \\  k: anytype,
  \\)  // comment a
  \\align(64)  // comment b
  \\addrspace(// copium
  \\.generic)  // comment c
  \\linksection(".my_custom_section")
  \\A(T) // yeah sure
  \\{ // aha!
  \\  // var x = 5;
  \\  print("just testing!");
  \\  var x: i32, const y: u32 = foo_(bar(1, 2));
  \\} // end aha!
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\pub // comment 1
    \\fn // comment 2
    \\fantasticFooBar // comment 3
    \\( // comment 4
    \\  // this is a top level comment 1
    \\  // this is a top level comment 2
    \\  // this is a top level comment 3
    \\  comptime // comment 5
    \\  T // comment 6
    \\  : // comment 6b
    \\  type // comment 7
    \\  , // comment 8
    \\  x: std_ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) // comment a
    \\align(64) // comment b
    \\addrspace( // copium
    \\  .generic
    \\) // comment c
    \\linksection(".my_custom_section")
    \\A(T) // yeah sure
    \\{ // aha!
    \\  // var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\} // end aha!
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\pub // comment 1
    \\fn // comment 2
    \\fantasticFooBar // comment 3
    \\( // comment 4
    \\  // this is a top level comment 1
    \\  // this is a top level comment 2
    \\  // this is a top level comment 3
    \\  comptime // comment 5
    \\  T // comment 6
    \\  : // comment 6b
    \\  type // comment 7
    \\  , // comment 8
    \\  x: std_ArrayList(
    \\    T,
    \\  ),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) // comment a
    \\align(
    \\  64
    \\) // comment b
    \\addrspace( // copium
    \\  .generic
    \\) // comment c
    \\linksection(
    \\  ".my_custom_section"
    \\)
    \\A(
    \\  T,
    \\) // yeah sure
    \\{ // aha!
    \\  // var x = 5;
    \\  print(
    \\    "just testing!",
    \\  );
    \\  var x: i32, const y: u32 = foo_(
    \\    bar(
    \\      1,
    \\      2,
    \\    ),
    \\  );
    \\} // end aha!
  );
}

test "comments/fundecl 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ extern // first one
  \\fn // comment fn
  \\foo2 // comment name
  \\ ( // comment bracket
  \\) // just for funsies 
  \\ A(T); 
  \\
  \\pub extern // first one
  \\fn // comment fn
  \\foo2 // comment name
  \\ ( // comment bracket
  \\ // inside this function
  \\) // just for funsies 
  \\ A(T); 
  \\
  \\ extern // first one
  \\fn // comment fn
  \\foo2 // comment name
  \\ ( // comment bracket
  \\  comptime T: type, // comment comptime
  \\  x // before
  \\ : // right there
  \\  ArrayList(T(A, B)) // after
  \\, // comma me surprised
  \\  comptime // see me
  \\ x: // again again
  \\ i32, // aha here we are
  \\  noalias // from here
  \\ y: u2, // to here
  \\  k: anytype,
  \\  noalias y: u2,
  \\  k: anytype,
  \\  ... // first time?
  \\, // second time?
  \\) // just for funsies 
  \\ A(T); 
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\extern // first one
    \\fn // comment fn
    \\foo2 // comment name
    \\( // comment bracket
    \\) // just for funsies
    \\A(T);
    \\
    \\pub extern // first one
    \\fn // comment fn
    \\foo2 // comment name
    \\( // comment bracket
    \\  // inside this function
    \\) // just for funsies
    \\A(T);
    \\
    \\extern // first one
    \\fn // comment fn
    \\foo2 // comment name
    \\( // comment bracket
    \\  comptime T: type, // comment comptime
    \\  x // before
    \\  : // right there
    \\  ArrayList(T(A, B)) // after
    \\  , // comma me surprised
    \\  comptime // see me
    \\  x: // again again
    \\  i32, // aha here we are
    \\  noalias // from here
    \\  y: u2, // to here
    \\  k: anytype,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  ... // first time?
    \\  , // second time?
    \\) // just for funsies
    \\A(T);
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\extern // first one
    \\fn // comment fn
    \\foo2 // comment name
    \\( // comment bracket
    \\) // just for funsies
    \\A(T);
    \\
    \\pub extern // first one
    \\fn // comment fn
    \\foo2 // comment name
    \\( // comment bracket
    \\  // inside this function
    \\) // just for funsies
    \\A(T);
    \\
    \\extern // first one
    \\fn // comment fn
    \\foo2 // comment name
    \\( // comment bracket
    \\  comptime T: type, // comment comptime
    \\  x // before
    \\  : // right there
    \\  ArrayList(
    \\    T(
    \\      A,
    \\      B,
    \\    ),
    \\  ) // after
    \\  , // comma me surprised
    \\  comptime // see me
    \\  x: // again again
    \\  i32, // aha here we are
    \\  noalias // from here
    \\  y: u2, // to here
    \\  k: anytype,
    \\  noalias y: u2,
    \\  k: anytype,
    \\  ... // first time?
    \\  , // second time?
    \\) // just for funsies
    \\A(T);
  );
}

test "comments/block 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var abc1 = blk: { // opening
  \\   // the first
  \\   someBlock();
  \\   // the second
  \\   someOtherBlock();
  \\   // the third
  \\   break :blk result("okay");
  \\ }; // closing
  \\
  \\ // the top level in the middle
  \\ var abc2 = someFunc(1, 2, 3) catch {
  \\   someBlock();
  \\ };
  \\
  \\ var abc3 = blk // label
  \\ : // colon
  \\ { // block open
  \\   someBlock(); // first
  \\   someOtherBlock(); // second
  \\   break :blk result("okay"); // last
  \\ } // block close
  \\; // semi
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var abc1 = blk: { // opening
    \\  // the first
    \\  someBlock();
    \\  // the second
    \\  someOtherBlock();
    \\  // the third
    \\  break :blk result("okay");
    \\}; // closing
    \\
    \\// the top level in the middle
    \\var abc2 = someFunc(1, 2, 3) catch {
    \\  someBlock();
    \\};
    \\
    \\var abc3 = blk // label
    \\: // colon
    \\{ // block open
    \\  someBlock(); // first
    \\  someOtherBlock(); // second
    \\  break :blk result("okay"); // last
    \\} // block close
    \\; // semi
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var abc1 = blk: { // opening
    \\  // the first
    \\  someBlock();
    \\  // the second
    \\  someOtherBlock();
    \\  // the third
    \\  break :blk result("okay");
    \\}; // closing
    \\
    \\// the top level in the middle
    \\var abc2 = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) catch {
    \\  someBlock();
    \\};
    \\
    \\var abc3 = blk // label
    \\: // colon
    \\{ // block open
    \\  someBlock(); // first
    \\  someOtherBlock(); // second
    \\  break :blk result(
    \\    "okay",
    \\  ); // last
    \\} // block close
    \\; // semi
  );
}

test "comments/containerdecl 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const fox3 = extern // first?
  \\ union // test here
  \\ ( // lbrack
  \\ big // arg
  \\ ) // start 
  \\ // again?
  \\ 
  \\ { // lbrace
  \\ a // first
  \\ , // comma
  \\ b // second
  \\ , // comma
  \\ c // third
  \\ , // comma
  \\ } // rbrace
  \\ ; // semi
  \\
  \\ const fox3 = extern // first?
  \\ union // test here
  \\ ( // lbrack
  \\ enum // abc
  \\ ( // xyz
  \\ big // jkl
  \\ ) // arg
  \\ ) // start 
  \\ { // lbrace
  \\ a // first
  \\ , // comma
  \\ b // second
  \\ , // comma
  \\ c // third
  \\ , // comma
  \\ } // rbrace
  \\ ; // semi
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\  big // arg
    \\) // start
    \\// again?
    \\{ // lbrace
    \\  a // first
    \\  , // comma
    \\  b // second
    \\  , // comma
    \\  c // third
    \\  , // comma
    \\} // rbrace
    \\; // semi
    \\
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\  enum // abc
    \\  ( // xyz
    \\    big // jkl
    \\  ) // arg
    \\) // arg
    \\{ // lbrace
    \\  a // first
    \\  , // comma
    \\  b // second
    \\  , // comma
    \\  c // third
    \\  , // comma
    \\} // rbrace
    \\; // semi
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\  big // arg
    \\) // start
    \\// again?
    \\{ // lbrace
    \\  a // first
    \\  , // comma
    \\  b // second
    \\  , // comma
    \\  c // third
    \\  , // comma
    \\} // rbrace
    \\; // semi
    \\
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\  enum // abc
    \\  ( // xyz
    \\    big // jkl
    \\  ) // arg
    \\) // arg
    \\{ // lbrace
    \\  a // first
    \\  , // comma
    \\  b // second
    \\  , // comma
    \\  c // third
    \\  , // comma
    \\} // rbrace
    \\; // semi
  );
}

test "comments/containerdecl 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const fox3 =
  \\ union // test here
  \\ ( // lbrack
  \\ enum // abc
  \\ ( // xyz
  \\ big // jkl
  \\ ) // arg
  \\ ) // start 
  \\ { // lbrace
  \\ a // first
  \\ , // comma
  \\ b // second
  \\ , // comma
  \\ c // third
  \\ , 
  \\ } // rbrace
  \\ ; // semi
  \\
  \\ const fox3 = extern // first?
  \\ union // test here
  \\ ( // lbrack
  \\ enum // abc
  \\ ( // xyz
  \\ big // jkl
  \\ ) // arg
  \\ ) // start 
  \\ { // lbrace
  \\ a // first
  \\ , // comma
  \\ b // second
  \\ , // comma
  \\ c, 
  \\ } // rbrace
  \\ ; // semi
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const fox3 = union // test here
    \\( // lbrack
    \\  enum // abc
    \\  ( // xyz
    \\    big // jkl
    \\  ) // arg
    \\) // arg
    \\{ // lbrace
    \\  a // first
    \\  , // comma
    \\  b // second
    \\  , // comma
    \\  c // third
    \\  ,
    \\} // rbrace
    \\; // semi
    \\
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\  enum // abc
    \\  ( // xyz
    \\    big // jkl
    \\  ) // arg
    \\) // arg
    \\{ // lbrace
    \\  a // first
    \\  , // comma
    \\  b // second
    \\  , // comma
    \\  c,
    \\} // rbrace
    \\; // semi
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const fox3 = union // test here
    \\( // lbrack
    \\  enum // abc
    \\  ( // xyz
    \\    big // jkl
    \\  ) // arg
    \\) // arg
    \\{ // lbrace
    \\  a // first
    \\  , // comma
    \\  b // second
    \\  , // comma
    \\  c // third
    \\  ,
    \\} // rbrace
    \\; // semi
    \\
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\  enum // abc
    \\  ( // xyz
    \\    big // jkl
    \\  ) // arg
    \\) // arg
    \\{ // lbrace
    \\  a // first
    \\  , // comma
    \\  b // second
    \\  , // comma
    \\  c,
    \\} // rbrace
    \\; // semi
  );
}

test "comments/containerdecl 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const fox3 = extern // first?
  \\ union // test here
  \\ ( // lbrack
  \\ enum // abc
  \\ ( // xyz
  \\ big // jkl
  \\ ) // arg
  \\ ) // start 
  \\ { // lbrace
  \\ a // first
  \\ , // comma
  \\ b // second
  \\ , // comma
  \\ c, 
  \\ } // rbrace
  \\ ; // semi
  \\ const fox2 = enum // start here
  \\ {a, b, c} // the end
  \\ ;
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\  enum // abc
    \\  ( // xyz
    \\    big // jkl
    \\  ) // arg
    \\) // arg
    \\{ // lbrace
    \\  a // first
    \\  , // comma
    \\  b // second
    \\  , // comma
    \\  c,
    \\} // rbrace
    \\; // semi
    \\const fox2 = enum // start here
    \\{
    \\  a,
    \\  b,
    \\  c,
    \\} // the end
    \\;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\  enum // abc
    \\  ( // xyz
    \\    big // jkl
    \\  ) // arg
    \\) // arg
    \\{ // lbrace
    \\  a // first
    \\  , // comma
    \\  b // second
    \\  , // comma
    \\  c,
    \\} // rbrace
    \\; // semi
    \\const fox2 = enum // start here
    \\{
    \\  a,
    \\  b,
    \\  c,
    \\} // the end
    \\;
  );
}

test "comments/containerdecl 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const fox2 = enum {a, b, c} // the end
  \\ ;
  \\ const fox3 = union (big) // start 
  \\ {a, b, c};
  \\ const fox3 = union (big) 
  \\ {// start 
  \\a, b, c}// end
  \\ ; // last
  \\ const fox3 = union ( // open sesame
  \\ big) 
  \\ {// start 
  \\a, b, c};// end
  \\ const fox3 = union (
  \\ big) 
  \\ {
  \\a, b, c};
  \\ const fox3 = struct(
  \\ big) 
  \\ {
  \\ // this could be a doc 1
  \\ // this could be a doc 2
  \\a, b, 
  \\ // this could be a doc 3
  \\ // this could be a doc 4
  \\ c};
  \\ const fox3 = struct(
  \\ big) 
  \\ {
  \\ // this could be a doc 1
  \\ // this could be a doc 2
  \\a, b, 
  \\ // this could be a doc 3
  \\ // this could be a doc 4
  \\ c // this one should trail
  \\};
  \\pub const FmtConfig = struct {
  \\  width: u32 = 80,
  \\  indent: u8 = 2,
  \\  decl_line_seps: u8 = 2,
  \\  writer: enum (u3) {
  \\    file,
  \\    out,
  \\    mem, // meh
  \\  } = .mem
  \\ // testing at end
  \\};
  \\pub const FmtConfig = struct {
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const fox2 = enum {
    \\  a,
    \\  b,
    \\  c,
    \\} // the end
    \\;
    \\const fox3 = union(big) // start
    \\{
    \\  a,
    \\  b,
    \\  c,
    \\};
    \\const fox3 = union(big) { // start
    \\  a,
    \\  b,
    \\  c,
    \\} // end
    \\; // last
    \\const fox3 = union( // open sesame
    \\  big
    \\) { // start
    \\  a,
    \\  b,
    \\  c,
    \\}; // end
    \\const fox3 = union(big) { a, b, c };
    \\const fox3 = struct(big) {
    \\  // this could be a doc 1
    \\  // this could be a doc 2
    \\  a,
    \\  b,
    \\  // this could be a doc 3
    \\  // this could be a doc 4
    \\  c,
    \\};
    \\const fox3 = struct(big) {
    \\  // this could be a doc 1
    \\  // this could be a doc 2
    \\  a,
    \\  b,
    \\  // this could be a doc 3
    \\  // this could be a doc 4
    \\  c // this one should trail
    \\};
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) {
    \\    file,
    \\    out,
    \\    mem, // meh
    \\  } = .mem
    \\  // testing at end
    \\};
    \\pub const FmtConfig = struct {};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const fox2 = enum {
    \\  a,
    \\  b,
    \\  c,
    \\} // the end
    \\;
    \\const fox3 = union(
    \\  big
    \\) // start
    \\{
    \\  a,
    \\  b,
    \\  c,
    \\};
    \\const fox3 = union(
    \\  big
    \\) { // start
    \\  a,
    \\  b,
    \\  c,
    \\} // end
    \\; // last
    \\const fox3 = union( // open sesame
    \\  big
    \\) { // start
    \\  a,
    \\  b,
    \\  c,
    \\}; // end
    \\const fox3 = union(big) {
    \\  a,
    \\  b,
    \\  c,
    \\};
    \\const fox3 = struct(big) {
    \\  // this could be a doc 1
    \\  // this could be a doc 2
    \\  a,
    \\  b,
    \\  // this could be a doc 3
    \\  // this could be a doc 4
    \\  c,
    \\};
    \\const fox3 = struct(big) {
    \\  // this could be a doc 1
    \\  // this could be a doc 2
    \\  a,
    \\  b,
    \\  // this could be a doc 3
    \\  // this could be a doc 4
    \\  c // this one should trail
    \\};
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) {
    \\    file,
    \\    out,
    \\    mem, // meh
    \\  } = .mem
    \\  // testing at end
    \\};
    \\pub const FmtConfig = struct {};
  );
}

test "comments/containerdecl 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ comptime // here here
  \\ x // first
  \\ : // yes
  \\ Ty // the type
  \\ = // seems
  \\ okay() // okay
  \\ , // finally
  \\
  \\ comptime // here here
  \\ x2 // first
  \\ : // yes
  \\ Ty // the type
  \\ = // seems
  \\ okay() // okay
  \\ , // finally
  \\
  \\ const T = struct {
  \\ comptime // here here
  \\ x // first
  \\ : // yes
  \\ Ty // the type
  \\ = // seems
  \\ okay() // okay
  \\ ,// finally
  \\
  \\ comptime // here here
  \\ y // first
  \\ : // yes
  \\ Ty // the type
  \\ = // seems
  \\ cool() // cool
  \\ ,// finally
  \\
  \\ z // first
  \\ : // yes
  \\ Ty // the type
  \\ = // seems
  \\ cool() // cool
  \\ ,// finally
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\comptime // here here
    \\x // first
    \\: // yes
    \\Ty // the type
    \\= // seems
    \\okay() // okay
    \\, // finally
    \\
    \\comptime // here here
    \\x2 // first
    \\: // yes
    \\Ty // the type
    \\= // seems
    \\okay() // okay
    \\, // finally
    \\
    \\const T = struct {
    \\  comptime // here here
    \\  x // first
    \\  : // yes
    \\  Ty // the type
    \\  = // seems
    \\  okay() // okay
    \\  , // finally
    \\
    \\  comptime // here here
    \\  y // first
    \\  : // yes
    \\  Ty // the type
    \\  = // seems
    \\  cool() // cool
    \\  , // finally
    \\
    \\  z // first
    \\  : // yes
    \\  Ty // the type
    \\  = // seems
    \\  cool() // cool
    \\  , // finally
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\comptime // here here
    \\x // first
    \\: // yes
    \\Ty // the type
    \\= // seems
    \\okay() // okay
    \\, // finally
    \\
    \\comptime // here here
    \\x2 // first
    \\: // yes
    \\Ty // the type
    \\= // seems
    \\okay() // okay
    \\, // finally
    \\
    \\const T = struct {
    \\  comptime // here here
    \\  x // first
    \\  : // yes
    \\  Ty // the type
    \\  = // seems
    \\  okay() // okay
    \\  , // finally
    \\
    \\  comptime // here here
    \\  y // first
    \\  : // yes
    \\  Ty // the type
    \\  = // seems
    \\  cool() // cool
    \\  , // finally
    \\
    \\  z // first
    \\  : // yes
    \\  Ty // the type
    \\  = // seems
    \\  cool() // cool
    \\  , // finally
    \\};
  );
}

test "comments/containerdecl 6" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const fox3 = extern // first?
  \\ union // test here
  \\ ( // lbrack
  \\ enum // arg
  \\ // first
  \\
  \\
  \\
  \\ ) // start 
  \\ // again?
  \\ 
  \\ { // lbrace
  \\};
  \\
  \\ const fox3 = extern // first?
  \\ union // test here
  \\ ( // lbrack
  \\ enum // arg
  \\ // first
  \\ ) // start 
  \\ // again?
  \\ 
  \\ {
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\enum // arg
    \\// first
    \\) // start
    \\// again?
    \\{ // lbrace
    \\};
    \\
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\enum // arg
    \\// first
    \\) // start
    \\// again?
    \\{};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\enum // arg
    \\// first
    \\) // start
    \\// again?
    \\{ // lbrace
    \\};
    \\
    \\const fox3 = extern // first?
    \\union // test here
    \\( // lbrack
    \\enum // arg
    \\// first
    \\) // start
    \\// again?
    \\{};
  );
}

test "comments/containerdecl 7" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const T = struct {
  \\  mem: u8, // y
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const T = struct {
    \\  mem: u8, // y
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const T = struct {
    \\  mem: u8, // y
    \\};
  );
}

test "comments/if/else 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testing() void {
  \\ // first one
  \\ if // again 
  \\ ( // lb
  \\ a // cond
  \\ ) //
  \\ { // good
  \\ // nothing here
  \\ } // last
  \\
  \\ if // 1 
  \\ ( // 2
  \\ a // c
  \\ ) // 3
  \\ b // 4
  \\ else // 5
  \\ d // 6
  \\ ; // 7
  \\
  \\ if //
  \\ ( //
  \\ a //
  \\ ) // 
  \\ | //
  \\ x //
  \\
  \\ |//
  \\ b //
  \\ else //
  \\ d //
  \\ ; //
  \\ 
  \\ if //
  \\ ( //
  \\ a //
  \\ ) // 
  \\ | //
  \\ * //
  \\ 
  \\ x //
  \\ |//
  \\ b //
  \\ else //
  \\ d //
  \\ ; //
  \\
  \\ if //
  \\ ( //
  \\ a //
  \\ ) // 
  \\ | //
  \\ x //
  \\ |//
  \\ b //
  \\ else //
  \\ | //
  \\
  \\ y //
  \\
  \\ |//
  \\ d //
  \\ ; // 
  \\
  \\ if // 
  \\ ( //
  \\ expr() //
  \\ ) //
  \\ doStuff() //
  \\ ; //
  \\
  \\ if // 
  \\ ( //
  \\ expr() //
  \\ ) //
  \\ | //
  \\ pl //
  \\ | //
  \\ doStuff() //
  \\ ; //
  \\
  \\ var z = if
  \\ ( 
  \\ a 
  \\ )
  \\ b else d;
  \\
  \\ var z = if
  \\ ( 
  \\ a 
  \\ )
  \\ b else {
  \\ bad();
  \\};
  \\
  \\ var z = if //
  \\ ( //
  \\ a //
  \\ ) //
  \\ b else d;
  \\
  \\ var z = if //
  \\ ( //
  \\ a //
  \\ ) //
  \\ b //
  \\ else //
  \\ d //
  \\ ; //
  \\}
  \\
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testing() void {
    \\  // first one
    \\  if // again
    \\  ( // lb
    \\    a // cond
    \\  ) //
    \\  { // good
    \\    // nothing here
    \\  } // last
    \\
    \\  if // 1
    \\  ( // 2
    \\    a // c
    \\  ) // 3
    \\    b // 4
    \\  else // 5
    \\    d // 6
    \\  ; // 7
    \\
    \\  if //
    \\  ( //
    \\    a //
    \\  ) //
    \\  | //
    \\  x //
    \\  | //
    \\    b //
    \\  else //
    \\    d //
    \\  ; //
    \\
    \\  if //
    \\  ( //
    \\    a //
    \\  ) //
    \\  | //
    \\  * //
    \\  x //
    \\  | //
    \\    b //
    \\  else //
    \\    d //
    \\  ; //
    \\
    \\  if //
    \\  ( //
    \\    a //
    \\  ) //
    \\  | //
    \\  x //
    \\  | //
    \\    b //
    \\  else //
    \\  | //
    \\  y //
    \\  | //
    \\    d //
    \\  ; //
    \\
    \\  if //
    \\  ( //
    \\    expr() //
    \\  ) //
    \\    doStuff() //
    \\  ; //
    \\
    \\  if //
    \\  ( //
    \\    expr() //
    \\  ) //
    \\  | //
    \\  pl //
    \\  | //
    \\    doStuff() //
    \\  ; //
    \\
    \\  var z = if (a) b else d;
    \\
    \\  var z = if (a) b
    \\  else {
    \\    bad();
    \\  };
    \\
    \\  var z = if //
    \\  ( //
    \\    a //
    \\  ) //
    \\    b
    \\  else
    \\    d;
    \\
    \\  var z = if //
    \\  ( //
    \\    a //
    \\  ) //
    \\    b //
    \\  else //
    \\    d //
    \\  ; //
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  // first one
    \\  if // again
    \\  ( // lb
    \\    a // cond
    \\  ) //
    \\  { // good
    \\    // nothing here
    \\  } // last
    \\
    \\  if // 1
    \\  ( // 2
    \\    a // c
    \\  ) // 3
    \\    b // 4
    \\  else // 5
    \\    d // 6
    \\  ; // 7
    \\
    \\  if //
    \\  ( //
    \\    a //
    \\  ) //
    \\  | //
    \\  x //
    \\  | //
    \\    b //
    \\  else //
    \\    d //
    \\  ; //
    \\
    \\  if //
    \\  ( //
    \\    a //
    \\  ) //
    \\  | //
    \\  * //
    \\  x //
    \\  | //
    \\    b //
    \\  else //
    \\    d //
    \\  ; //
    \\
    \\  if //
    \\  ( //
    \\    a //
    \\  ) //
    \\  | //
    \\  x //
    \\  | //
    \\    b //
    \\  else //
    \\  | //
    \\  y //
    \\  | //
    \\    d //
    \\  ; //
    \\
    \\  if //
    \\  ( //
    \\    expr() //
    \\  ) //
    \\    doStuff() //
    \\  ; //
    \\
    \\  if //
    \\  ( //
    \\    expr() //
    \\  ) //
    \\  | //
    \\  pl //
    \\  | //
    \\    doStuff() //
    \\  ; //
    \\
    \\  var z = if (a) b else d;
    \\
    \\  var z = if (a) b
    \\  else {
    \\    bad();
    \\  };
    \\
    \\  var z = if //
    \\  ( //
    \\    a //
    \\  ) //
    \\    b
    \\  else
    \\    d;
    \\
    \\  var z = if //
    \\  ( //
    \\    a //
    \\  ) //
    \\    b //
    \\  else //
    \\    d //
    \\  ; //
    \\}
  );
}

test "comments/if/else 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\fn testing() void {
  \\  var z = if (a) //
  \\ b: {
  \\    var x = y;
  \\  } else //
  \\ d;
  \\
  \\  if //
  \\ ( //
  \\ someExpr() //
  \\ ) //
  \\  { //
  \\    var x = someOther();
  \\  } // 
  \\
  \\  if //
  \\ ( //
  \\ someExpr() //
  \\ ) //
  \\ { //
  \\    var x = someOther();
  \\  } // 
  \\ else //
  \\ |pay| { //
  \\    var y = someWhat();
  \\  } //
  \\
  \\  if //
  \\ ( //
  \\ someExpr() //
  \\ ) //
  \\ { //
  \\    var x = someOther();
  \\  } // 
  \\ else //
  \\ | //
  \\ pay //
  \\ | // 
  \\ { //
  \\    var y = someWhat();
  \\  } //
  \\
  \\  if //
  \\ ( // 
  \\ someExpr() //
  \\ ) // 
  \\ { //
  \\    var x = someOther();
  \\  } //
  \\ else //
  \\ if //
  \\ ( //
  \\ someOtherExpr() //
  \\ ) //
  \\ { //
  \\    var y = someWhat();
  \\  } // 
  \\ else //
  \\ { //
  \\    var y = someElseWhat();
  \\  } //
  \\
  \\  if //
  \\ ( // 
  \\ someExpr() //
  \\ ) // 
  \\ { //
  \\    var x = someOther();
  \\  } //
  \\ else if //
  \\ ( //
  \\ someOtherExpr() //
  \\ ) //
  \\ { //
  \\    var y = someWhat();
  \\  } // 
  \\ else //
  \\ { //
  \\    var y = someElseWhat();
  \\  } //
  \\  if (someExpr()) |*payload| {
  \\    var x = someOther();
  \\  } else {
  \\    var y = someWhat();
  \\  }
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testing() void {
    \\  var z = if (a) //
    \\  b: {
    \\    var x = y;
    \\  } else //
    \\  d;
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther();
    \\  } //
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther();
    \\  } //
    \\  else //
    \\  |pay| { //
    \\    var y = someWhat();
    \\  } //
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther();
    \\  } //
    \\  else //
    \\  | //
    \\  pay //
    \\  | //
    \\  { //
    \\    var y = someWhat();
    \\  } //
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther();
    \\  } //
    \\  else //
    \\  if //
    \\  ( //
    \\    someOtherExpr() //
    \\  ) //
    \\  { //
    \\    var y = someWhat();
    \\  } //
    \\  else //
    \\  { //
    \\    var y = someElseWhat();
    \\  } //
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther();
    \\  } //
    \\  else if //
    \\  ( //
    \\    someOtherExpr() //
    \\  ) //
    \\  { //
    \\    var y = someWhat();
    \\  } //
    \\  else //
    \\  { //
    \\    var y = someElseWhat();
    \\  } //
    \\  if (someExpr()) |*payload| {
    \\    var x = someOther();
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  var z = if (a) //
    \\  b: {
    \\    var x = y;
    \\  } else //
    \\  d;
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther();
    \\  } //
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther();
    \\  } //
    \\  else //
    \\  |pay| { //
    \\    var y = someWhat();
    \\  } //
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther();
    \\  } //
    \\  else //
    \\  | //
    \\  pay //
    \\  | //
    \\  { //
    \\    var y = someWhat();
    \\  } //
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther();
    \\  } //
    \\  else //
    \\  if //
    \\  ( //
    \\    someOtherExpr() //
    \\  ) //
    \\  { //
    \\    var y = someWhat();
    \\  } //
    \\  else //
    \\  { //
    \\    var y = someElseWhat();
    \\  } //
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther();
    \\  } //
    \\  else if //
    \\  ( //
    \\    someOtherExpr() //
    \\  ) //
    \\  { //
    \\    var y = someWhat();
    \\  } //
    \\  else //
    \\  { //
    \\    var y = someElseWhat();
    \\  } //
    \\  if (someExpr()) |*payload| {
    \\    var x = someOther();
    \\  } else {
    \\    var y = someWhat();
    \\  }
    \\}
  );
}

test "comments/if/else 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testing() void {
  \\ if //
  \\ ( //
  \\ someExpr() //
  \\ ) //
  \\ { //
  \\} //
  \\ else //
  \\ { //
  \\  var y = someWhat();
  \\} //
  \\
  \\ if //
  \\ ( //
  \\ someExpr() // 
  \\ ) // 
  \\ { //
  \\ var x = someOther(); //
  \\} //
  \\ else //
  \\ {
  \\}
  \\
  \\ if //
  \\ ( //
  \\ someExpr()
  \\ ) // 
  \\ {
  \\} 
  \\ else //
  \\ {
  \\}
  \\
  \\ if // 
  \\ ( //
  \\ someExpr() //
  \\ ) //
  \\ | //
  \\ * //
  \\
  \\ payload //
  \\ | //
  \\ { //
  \\} //
  \\ else //
  \\ { //
  \\} //
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testing() void {
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\  } //
    \\  else //
    \\  { //
    \\    var y = someWhat();
    \\  } //
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther(); //
    \\  } //
    \\  else //
    \\  {
    \\  }
    \\
    \\  if //
    \\  ( //
    \\    someExpr()
    \\  ) //
    \\  {
    \\  } else //
    \\  {
    \\  }
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  | //
    \\  * //
    \\  payload //
    \\  | //
    \\  { //
    \\  } //
    \\  else //
    \\  { //
    \\  } //
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testing() void {
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\  } //
    \\  else //
    \\  { //
    \\    var y = someWhat();
    \\  } //
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  { //
    \\    var x = someOther(); //
    \\  } //
    \\  else //
    \\  {
    \\  }
    \\
    \\  if //
    \\  ( //
    \\    someExpr()
    \\  ) //
    \\  {
    \\  } else //
    \\  {
    \\  }
    \\
    \\  if //
    \\  ( //
    \\    someExpr() //
    \\  ) //
    \\  | //
    \\  * //
    \\  payload //
    \\  | //
    \\  { //
    \\  } //
    \\  else //
    \\  { //
    \\  } //
    \\}
  );
}

test "comments/if/else 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ if //
  \\ ( //
  \\ some
  \\ ) //
  \\ |*x| //
  \\ lbl : {
  \\  print('yello world');
  \\} else // 
  \\ {
  \\  someCall();
  \\  var abc = try testS();
  \\}
  \\ if (some) |*x| //
  \\ _ = lbl : {
  \\  print('yello world');
  \\} else { //
  \\  someCall();
  \\  var abc = try testS();
  \\}
  \\if (someCond) |x| _ = blk: { //
  \\  std.debug.print("x is: {}\n", .{x});
  \\  break :blk void;
  \\} else { //
  \\  std.debug.print("done\n", .{});
  \\}
  \\
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if //
    \\  ( //
    \\    some
    \\  ) //
    \\  |*x| //
    \\  lbl: {
    \\    print('yello world');
    \\  } else //
    \\  {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (some) |*x| //
    \\    _ = lbl: {
    \\      print('yello world');
    \\    }
    \\  else { //
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (someCond) |x|
    \\    _ = blk: { //
    \\      std.debug.print("x is: {}\n", .{x});
    \\      break :blk void;
    \\    }
    \\  else { //
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if //
    \\  ( //
    \\    some
    \\  ) //
    \\  |*x| //
    \\  lbl: {
    \\    print('yello world');
    \\  } else //
    \\  {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (some) |*x| //
    \\    _ = lbl: {
    \\      print('yello world');
    \\    }
    \\  else { //
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (someCond) |x|
    \\    _ = blk: { //
    \\      std.debug.print(
    \\        "x is: {}\n",
    \\        .{x},
    \\      );
    \\      break :blk void;
    \\    }
    \\  else { //
    \\    std.debug.print(
    \\      "done\n",
    \\      .{},
    \\    );
    \\  }
    \\}
  );
}

test "comments/if/else 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ if //
  \\ ( //
  \\ someNiceCondition(a, b, c)
  \\ ) // 
  \\ |//
  \\ x //
  \\ | //
  \\ _ = blk: { //
  \\  print('yello world');
  \\}; //
  \\ if (someNiceCondition(a, b, c)) |x| //
  \\ someFancy(callExpr(), a, b);
  \\ }
  \\
  \\
  \\
  \\ fn testing() void {
  \\  if //
  \\ ( //
  \\ cond()
  \\ ) // 
  \\ {  var x = 5; } // 
  \\ else //
  \\ voidExpr();
  \\  if (cond()) //
  \\  voidExpr() else //
  \\ {
  \\ var x = 5;
  \\ }
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if //
    \\  ( //
    \\    someNiceCondition(a, b, c)
    \\  ) //
    \\  | //
    \\  x //
    \\  | //
    \\    _ = blk: { //
    \\      print('yello world');
    \\    }; //
    \\  if (someNiceCondition(a, b, c)) |x| //
    \\    someFancy(callExpr(), a, b);
    \\}
    \\
    \\fn testing() void {
    \\  if //
    \\  ( //
    \\    cond()
    \\  ) //
    \\  {
    \\    var x = 5;
    \\  } //
    \\  else //
    \\  voidExpr();
    \\  if (cond()) //
    \\    voidExpr()
    \\  else //
    \\  {
    \\    var x = 5;
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if //
    \\  ( //
    \\    someNiceCondition(a, b, c)
    \\  ) //
    \\  | //
    \\  x //
    \\  | //
    \\    _ = blk: { //
    \\      print('yello world');
    \\    }; //
    \\  if (
    \\    someNiceCondition(a, b, c)
    \\  ) |x| //
    \\    someFancy(
    \\      callExpr(),
    \\      a,
    \\      b,
    \\    );
    \\}
    \\
    \\fn testing() void {
    \\  if //
    \\  ( //
    \\    cond()
    \\  ) //
    \\  {
    \\    var x = 5;
    \\  } //
    \\  else //
    \\  voidExpr();
    \\  if (cond()) //
    \\    voidExpr()
    \\  else //
    \\  {
    \\    var x = 5;
    \\  }
    \\}
  );
}

test "comments/for 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ for //
  \\ ( //
  \\ // some top level comment 1
  \\ // some top level comment 2
  \\ some //
  \\ , //
  \\ 0.. //
  \\ , //
  \\ a //
  \\ .. //
  \\ z //
  \\ // some bottom level comment 1
  \\ // some bottom level comment 2
  \\ ) //
  \\ | //
  \\ * //
  \\ x //
  \\ , //
  \\ y //
  \\ , //
  \\ * //
  \\ z //
  \\ | //
  \\ lbl : {
  \\  print('yello world');
  \\}
  \\
  \\ for //
  \\ ( //
  \\
  \\ some //
  \\ , //
  \\ 0.. //
  \\ , //
  \\ a //
  \\ .. //
  \\ z //
  \\ ) //
  \\ | //
  \\ * //
  \\ x //
  \\ , //
  \\ y //
  \\ , //
  \\ * //
  \\ z //
  \\ | //
  \\ { //
  \\  print('yello world');
  \\}
  \\
  \\ for //
  \\ ( //
  \\
  \\ some //
  \\ , //
  \\ 0.. //
  \\ , //
  \\ a //
  \\ .. //
  \\ z //
  \\ ) //
  \\ | //
  \\ *
  \\ x
  \\ , //
  \\ y
  \\ , //
  \\ *
  \\ z //
  \\ | //
  \\ { //
  \\  print('yello world');
  \\}
  \\
  \\ for //
  \\ (//
  \\ expr//
  \\ ) // 
  \\ | //
  \\ pl //
  \\ | //
  \\ something();
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for //
    \\  ( //
    \\    // some top level comment 1
    \\    // some top level comment 2
    \\    some //
    \\    , //
    \\    0.. //
    \\    , //
    \\    a //
    \\    .. //
    \\    z //
    \\    // some bottom level comment 1
    \\    // some bottom level comment 2
    \\  ) //
    \\  | //
    \\  * //
    \\  x //
    \\  , //
    \\  y //
    \\  , //
    \\  * //
    \\  z //
    \\  | //
    \\  lbl: {
    \\    print('yello world');
    \\  }
    \\
    \\  for //
    \\  ( //
    \\    some //
    \\    , //
    \\    0.. //
    \\    , //
    \\    a //
    \\    .. //
    \\    z //
    \\  ) //
    \\  | //
    \\  * //
    \\  x //
    \\  , //
    \\  y //
    \\  , //
    \\  * //
    \\  z //
    \\  | //
    \\  { //
    \\    print('yello world');
    \\  }
    \\
    \\  for //
    \\  ( //
    \\    some //
    \\    , //
    \\    0.. //
    \\    , //
    \\    a //
    \\    .. //
    \\    z //
    \\  ) //
    \\  | //
    \\  *x, //
    \\  y, //
    \\  *z //
    \\  | //
    \\  { //
    \\    print('yello world');
    \\  }
    \\
    \\  for //
    \\  ( //
    \\    expr //
    \\  ) //
    \\  | //
    \\  pl //
    \\  | //
    \\    something();
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for //
    \\  ( //
    \\    // some top level comment 1
    \\    // some top level comment 2
    \\    some //
    \\    , //
    \\    0.. //
    \\    , //
    \\    a //
    \\    .. //
    \\    z //
    \\    // some bottom level comment 1
    \\    // some bottom level comment 2
    \\  ) //
    \\  | //
    \\  * //
    \\  x //
    \\  , //
    \\  y //
    \\  , //
    \\  * //
    \\  z //
    \\  | //
    \\  lbl: {
    \\    print('yello world');
    \\  }
    \\
    \\  for //
    \\  ( //
    \\    some //
    \\    , //
    \\    0.. //
    \\    , //
    \\    a //
    \\    .. //
    \\    z //
    \\  ) //
    \\  | //
    \\  * //
    \\  x //
    \\  , //
    \\  y //
    \\  , //
    \\  * //
    \\  z //
    \\  | //
    \\  { //
    \\    print('yello world');
    \\  }
    \\
    \\  for //
    \\  ( //
    \\    some //
    \\    , //
    \\    0.. //
    \\    , //
    \\    a //
    \\    .. //
    \\    z //
    \\  ) //
    \\  | //
    \\  *x, //
    \\  y, //
    \\  *z //
    \\  | //
    \\  { //
    \\    print('yello world');
    \\  }
    \\
    \\  for //
    \\  ( //
    \\    expr //
    \\  ) //
    \\  | //
    \\  pl //
    \\  | //
    \\    something();
    \\}
  );
}

test "comments/for 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\fn testMe() void {
  \\for //
  \\( //
  \\some //
  \\, //
  \\a //
  \\.. //
  \\k //
  \\) //
  \\| //
  \\a //
  \\, //
  \\b //
  \\| // 
  \\{ //
  \\} //
  \\else //
  \\{ //
  \\var j = testMe();
  \\} //
  \\
  \\for //
  \\( //
  \\some //
  \\, //
  \\a //
  \\.. //
  \\k //
  \\) //
  \\| //
  \\a //
  \\, //
  \\b //
  \\| // 
  \\{ //
  \\} //
  \\else //
  \\{ //
  \\} //
  \\
  \\for 
  \\(
  \\some, //
  \\0..,
  \\a..z
  \\) //
  \\|*x, y, *z|  //
  \\lbl : {
  \\ print('yello world');
  \\}
  \\ else //
  \\someStuff();
  \\inline //
  \\for //
  \\( //
  \\some //
  \\, 
  \\0 //
  \\.. //
  \\, // 
  \\a..z //
  \\) //
  \\|*x, y, *z| lbl : {
  \\ print('yello world');
  \\}
  \\ // 
  \\else { //
  \\ someCall();
  \\ var abc = try testS();
  \\
  \\inline //
  \\for //
  \\( //
  \\some //
  \\, 
  \\0 //
  \\.. //
  \\, // 
  \\a..z //
  \\) //
  \\|*x, y, *z| lbl : {
  \\ print('yello world');
  \\}
  \\else { //
  \\ someCall();
  \\ var abc = try testS();
  \\
  \\if (foo) lbl : {
  \\ print('yello world');
  \\}// 
  \\else { //
  \\ someCall();
  \\ var abc = try testS();
  \\
  \\if (foo) lbl : {
  \\ print('yello world');
  \\}
  \\else { //
  \\ someCall();
  \\ var abc = try testS();
  \\}
  \\}
  \\}
  \\}
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for //
    \\  ( //
    \\    some //
    \\    , //
    \\    a //
    \\    .. //
    \\    k //
    \\  ) //
    \\  | //
    \\  a //
    \\  , //
    \\  b //
    \\  | //
    \\  { //
    \\  } //
    \\  else //
    \\  { //
    \\    var j = testMe();
    \\  } //
    \\
    \\  for //
    \\  ( //
    \\    some //
    \\    , //
    \\    a //
    \\    .. //
    \\    k //
    \\  ) //
    \\  | //
    \\  a //
    \\  , //
    \\  b //
    \\  | //
    \\  { //
    \\  } //
    \\  else //
    \\  { //
    \\  } //
    \\
    \\  for (
    \\    some, //
    \\    0..,
    \\    a..z,
    \\  ) //
    \\  |*x, y, *z| //
    \\  lbl: {
    \\    print('yello world');
    \\  } else //
    \\  someStuff();
    \\  inline //
    \\  for //
    \\  ( //
    \\    some //
    \\    ,
    \\    0 //
    \\    .. //
    \\    , //
    \\    a..z //
    \\  ) //
    \\  |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  }
    \\  //
    \\  else { //
    \\    someCall();
    \\    var abc = try testS();
    \\
    \\    inline //
    \\    for //
    \\    ( //
    \\      some //
    \\      ,
    \\      0 //
    \\      .. //
    \\      , //
    \\      a..z //
    \\    ) //
    \\    |*x, y, *z| lbl: {
    \\      print('yello world');
    \\    } else { //
    \\      someCall();
    \\      var abc = try testS();
    \\
    \\      if (foo) lbl: {
    \\        print('yello world');
    \\      } //
    \\      else { //
    \\        someCall();
    \\        var abc = try testS();
    \\
    \\        if (foo) lbl: {
    \\          print('yello world');
    \\        } else { //
    \\          someCall();
    \\          var abc = try testS();
    \\        }
    \\      }
    \\    }
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for //
    \\  ( //
    \\    some //
    \\    , //
    \\    a //
    \\    .. //
    \\    k //
    \\  ) //
    \\  | //
    \\  a //
    \\  , //
    \\  b //
    \\  | //
    \\  { //
    \\  } //
    \\  else //
    \\  { //
    \\    var j = testMe();
    \\  } //
    \\
    \\  for //
    \\  ( //
    \\    some //
    \\    , //
    \\    a //
    \\    .. //
    \\    k //
    \\  ) //
    \\  | //
    \\  a //
    \\  , //
    \\  b //
    \\  | //
    \\  { //
    \\  } //
    \\  else //
    \\  { //
    \\  } //
    \\
    \\  for (
    \\    some, //
    \\    0..,
    \\    a..z,
    \\  ) //
    \\  |*x, y, *z| //
    \\  lbl: {
    \\    print('yello world');
    \\  } else //
    \\  someStuff();
    \\  inline //
    \\  for //
    \\  ( //
    \\    some //
    \\    ,
    \\    0 //
    \\    .. //
    \\    , //
    \\    a..z //
    \\  ) //
    \\  |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  }
    \\  //
    \\  else { //
    \\    someCall();
    \\    var abc = try testS();
    \\
    \\    inline //
    \\    for //
    \\    ( //
    \\      some //
    \\      ,
    \\      0 //
    \\      .. //
    \\      , //
    \\      a..z //
    \\    ) //
    \\    |*x, y, *z| lbl: {
    \\      print('yello world');
    \\    } else { //
    \\      someCall();
    \\      var abc = try testS();
    \\
    \\      if (foo) lbl: {
    \\        print('yello world');
    \\      } //
    \\      else { //
    \\        someCall();
    \\        var abc = try testS();
    \\
    \\        if (foo) lbl: {
    \\          print(
    \\            'yello world',
    \\          );
    \\        } else { //
    \\          someCall();
    \\          var abc = try testS();
    \\        }
    \\      }
    \\    }
    \\  }
    \\}
  );
}

test "comments/for 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ for //
  \\ ( //
  \\ some, 0.., a..z
  \\ ) //
  \\ |*x, y, *z| { //
  \\  print('yello world');
  \\} //
  \\ else // 
  \\ { //
  \\  someCall();
  \\  var abc = try testS();
  \\}
  \\ for  //
  \\ (some, x, a..k //
  \\ ) |a, b, c| //
  \\ exprMe() else // 
  \\ {var j = testS();}
  \\for (0..10) |x| // 
  \\ _ = blk: { //
  \\  std.debug.print("x is: {}\n", .{x});
  \\  break :blk void;
  \\} //
  \\ else { //
  \\  std.debug.print("done\n", .{});
  \\}
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for //
    \\  ( //
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) //
    \\  |*x, y, *z| { //
    \\    print('yello world');
    \\  } //
    \\  else //
    \\  { //
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  for //
    \\  (
    \\    some,
    \\    x,
    \\    a..k //
    \\  ) |a, b, c| //
    \\    exprMe()
    \\  else //
    \\  {
    \\    var j = testS();
    \\  }
    \\  for (0..10) |x| //
    \\    _ = blk: { //
    \\      std.debug.print("x is: {}\n", .{x});
    \\      break :blk void;
    \\    } //
    \\  else { //
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for //
    \\  ( //
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) //
    \\  |*x, y, *z| { //
    \\    print('yello world');
    \\  } //
    \\  else //
    \\  { //
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  for //
    \\  (
    \\    some,
    \\    x,
    \\    a..k //
    \\  ) |a, b, c| //
    \\    exprMe()
    \\  else //
    \\  {
    \\    var j = testS();
    \\  }
    \\  for (0..10) |x| //
    \\    _ = blk: { //
    \\      std.debug.print(
    \\        "x is: {}\n",
    \\        .{x},
    \\      );
    \\      break :blk void;
    \\    } //
    \\  else { //
    \\    std.debug.print(
    \\      "done\n",
    \\      .{},
    \\    );
    \\  }
    \\}
  );
}

test "comments/for 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ for (some, 0.., a..z) |*x, y, *z| //
  \\  print('yello world')
  \\ else //
  \\  someCall();
  \\
  \\ for (some, 0.., a..z) |*x, y, *z| //
  \\ {
  \\ }
  \\ }
  \\
  \\ fn testMe() void {
  \\ lbl: //
  \\ for (someNiceCondition(a, b, c)) |x| //
  \\ someFancy(callExpr(), a, b);
  \\ for (someNiceCondition(a, b, c)) // 
  \\ |x| //
  \\ someFancy(callExpr(), a, b);
  \\ for //
  \\ ( //
  \\ someNiceCondition(a, b, c)
  \\ ) // 
  \\ | //
  \\ x //
  \\ | //
  \\ someFancy(callExpr(), a, b);
  \\ for (someNiceCondition(a, b, c)) //
  \\ |x| _ = blk: {
  \\  print('yello world');
  \\}; //
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| //
    \\    print('yello world')
    \\  else //
    \\    someCall();
    \\
    \\  for (some, 0.., a..z) |*x, y, *z| //
    \\  {}
    \\}
    \\
    \\fn testMe() void {
    \\  lbl: //
    \\  for (someNiceCondition(a, b, c)) |x| //
    \\    someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) //
    \\  |x| //
    \\    someFancy(callExpr(), a, b);
    \\  for //
    \\  ( //
    \\    someNiceCondition(a, b, c),
    \\  ) //
    \\  | //
    \\  x //
    \\  | //
    \\    someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) //
    \\  |x|
    \\    _ = blk: {
    \\      print('yello world');
    \\    }; //
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) |*x, y, *z| //
    \\    print('yello world')
    \\  else //
    \\    someCall();
    \\
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z,
    \\  ) |*x, y, *z| //
    \\  {}
    \\}
    \\
    \\fn testMe() void {
    \\  lbl: //
    \\  for (
    \\    someNiceCondition(
    \\      a,
    \\      b,
    \\      c,
    \\    ),
    \\  ) |x| //
    \\    someFancy(
    \\      callExpr(),
    \\      a,
    \\      b,
    \\    );
    \\  for (
    \\    someNiceCondition(
    \\      a,
    \\      b,
    \\      c,
    \\    ),
    \\  ) //
    \\  |x| //
    \\    someFancy(
    \\      callExpr(),
    \\      a,
    \\      b,
    \\    );
    \\  for //
    \\  ( //
    \\    someNiceCondition(
    \\      a,
    \\      b,
    \\      c,
    \\    ),
    \\  ) //
    \\  | //
    \\  x //
    \\  | //
    \\    someFancy(
    \\      callExpr(),
    \\      a,
    \\      b,
    \\    );
    \\  for (
    \\    someNiceCondition(
    \\      a,
    \\      b,
    \\      c,
    \\    ),
    \\  ) //
    \\  |x|
    \\    _ = blk: {
    \\      print('yello world');
    \\    }; //
    \\}
  );
}

test "comments/while 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ while // a
  \\ ( // b
  \\ someNiceCondition(a, b, c) // c
  \\ ) // d
  \\ | // e
  \\ * // f
  \\ x // g
  \\ | // h
  \\ : // i
  \\ (// j
  \\ j
  \\ +=
  \\ 5) // k
  \\ { // l
  \\ } // m
  \\
  \\ inline // a
  \\ while // b
  \\ ( // c
  \\ someNiceCondition(a, b, c)
  \\ ) // d
  \\ | // e
  \\ *x // f
  \\ | // g
  \\ : // h
  \\ ( // i
  \\ j += 5
  \\ ) // j
  \\ { // k
  \\ } // l
  \\ else // m
  \\ // n
  \\ | // o
  \\ y // p
  \\ | // q
  \\ { // r
  \\ } // s
  \\
  \\ inline while (someNiceCondition(a, b, c)) // a
  \\ |x| : (
  \\ // first stuff
  \\ j += 5) {
  \\  print('yello world');
  \\ } else |y| // b
  \\ {
  \\  someCall();
  \\ }
  \\ while (someNiceCondition(a, b, c)) |*x| : (j += 5) {
  \\  print('yello world');
  \\ } // a
  \\ else |y| {
  \\  someCall();
  \\ }
  \\ while (someNiceCondition(a, b, c)) |x| : (j += 5) // a
  \\ {
  \\  print('yello world');
  \\ } else |y| // b
  \\ {
  \\  someCall();
  \\ }
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while // a
    \\  ( // b
    \\    someNiceCondition(a, b, c) // c
    \\  ) // d
    \\  | // e
    \\  * // f
    \\  x // g
    \\  | // h
    \\  : // i
    \\  ( // j
    \\    j += 5
    \\  ) // k
    \\  { // l
    \\  } // m
    \\
    \\  inline // a
    \\  while // b
    \\  ( // c
    \\    someNiceCondition(a, b, c)
    \\  ) // d
    \\  | // e
    \\  *x // f
    \\  | // g
    \\  : // h
    \\  ( // i
    \\    j += 5
    \\  ) // j
    \\  { // k
    \\  } // l
    \\  else // m
    \\  // n
    \\  | // o
    \\  y // p
    \\  | // q
    \\  { // r
    \\  } // s
    \\
    \\  inline while (someNiceCondition(a, b, c)) // a
    \\  |x| : (
    \\    // first stuff
    \\    j += 5
    \\  ) {
    \\    print('yello world');
    \\  } else |y| // b
    \\  {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |*x| : (j += 5) {
    \\    print('yello world');
    \\  } // a
    \\  else |y| {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) // a
    \\  {
    \\    print('yello world');
    \\  } else |y| // b
    \\  {
    \\    someCall();
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while // a
    \\  ( // b
    \\    someNiceCondition(
    \\      a,
    \\      b,
    \\      c,
    \\    ) // c
    \\  ) // d
    \\  | // e
    \\  * // f
    \\  x // g
    \\  | // h
    \\  : // i
    \\  ( // j
    \\    j += 5
    \\  ) // k
    \\  { // l
    \\  } // m
    \\
    \\  inline // a
    \\  while // b
    \\  ( // c
    \\    someNiceCondition(a, b, c)
    \\  ) // d
    \\  | // e
    \\  *x // f
    \\  | // g
    \\  : // h
    \\  ( // i
    \\    j += 5
    \\  ) // j
    \\  { // k
    \\  } // l
    \\  else // m
    \\  // n
    \\  | // o
    \\  y // p
    \\  | // q
    \\  { // r
    \\  } // s
    \\
    \\  inline while (
    \\    someNiceCondition(a, b, c)
    \\  ) // a
    \\  |x|
    \\  : (
    \\    // first stuff
    \\    j += 5
    \\  ) {
    \\    print('yello world');
    \\  } else |y| // b
    \\  {
    \\    someCall();
    \\  }
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |*x|
    \\  : (j += 5) {
    \\    print('yello world');
    \\  } // a
    \\  else |y| {
    \\    someCall();
    \\  }
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5) // a
    \\  {
    \\    print('yello world');
    \\  } else |y| // b
    \\  {
    \\    someCall();
    \\  }
    \\}
  );
}

test "comments/while 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ while (someNiceCondition(a, b, c)) |x| // a
  \\ blk: {
  \\  print('yello world');
  \\ } else {
  \\  someCall();
  \\ }
  \\ while (someNiceCondition(a, b, c)) |x| // a
  \\ blk: {
  \\  print('yello world');
  \\ } else // b
  \\ blk2: {
  \\  someCall();
  \\ }
  \\ inline while (someNiceCondition(a, b, c)) |x| : // a
  \\ (j += 5) 
  \\  print('yello world')
  \\  else |y| { // b
  \\  someCall();
  \\ }
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |x| // a
    \\  blk: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| // a
    \\  blk: {
    \\    print('yello world');
    \\  } else // b
    \\  blk2: {
    \\    someCall();
    \\  }
    \\  inline while (someNiceCondition(a, b, c)) |x| : // a
    \\  (j += 5)
    \\    print('yello world')
    \\  else |y| { // b
    \\    someCall();
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x| // a
    \\  blk: {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\  }
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x| // a
    \\  blk: {
    \\    print('yello world');
    \\  } else // b
    \\  blk2: {
    \\    someCall();
    \\  }
    \\  inline while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : // a
    \\  (j += 5)
    \\    print('yello world')
    \\  else |y| { // b
    \\    someCall();
    \\  }
    \\}
  );
}

test "comments/while 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testme() void {
  \\ while (true) blk: {
  \\     std.debug.print("yello world", .{});
  \\     break :blk voidexpr();
  \\   }
  \\   else {
  \\     std.debug.print("bye world", .{});
  \\   }
  \\ for (true) |*f| blk: {
  \\     std.debug.print("yello world", .{});
  \\     break :blk voidexpr();
  \\   }
  \\   else {
  \\     std.debug.print("bye world", .{});
  \\   }
  \\ if (true) blk: {
  \\     std.debug.print("yello world", .{});
  \\     break :blk voidexpr();
  \\   }
  \\   else {
  \\     std.debug.print("bye world", .{});
  \\   }
  \\ }
  \\ fn testMe() void {
  \\ while (true) blk: // a
  \\ {
  \\     std.debug.print("yello world", .{});
  \\     break :blk voidExpr();
  \\   }
  \\   else { // b
  \\     std.debug.print("bye world", .{});
  \\   }
  \\ while // a
  \\ (someNiceCondition(a, b, c)) |x| : (j += 5) 
  \\  print('yello world')
  \\  else |y| 
  \\  someCall();
  \\ while (someNiceCondition(a, b, c)) | // a
  \\ x| : (j += 5) 
  \\  print('yello world')
  \\  else someCall();
  \\ inline while (someNiceCondition(a, b, c) // a
  \\ )
  \\  print('yello world')
  \\  else // b
  \\ someCall();
  \\ while (someNiceCondition(a, b, c)) |x| : (j += 5) // a
  \\  print('yello world');
  \\ while (someNiceCondition(a, b, c)) |x| : (j += someExpr(5, abc, jkl)) { // a
  \\  print('yello world');
  \\  } // b
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testme() void {
    \\  while (true) blk: {
    \\    std.debug.print("yello world", .{});
    \\    break :blk voidexpr();
    \\  } else {
    \\    std.debug.print("bye world", .{});
    \\  }
    \\  for (true) |*f| blk: {
    \\    std.debug.print("yello world", .{});
    \\    break :blk voidexpr();
    \\  } else {
    \\    std.debug.print("bye world", .{});
    \\  }
    \\  if (true) blk: {
    \\    std.debug.print("yello world", .{});
    \\    break :blk voidexpr();
    \\  } else {
    \\    std.debug.print("bye world", .{});
    \\  }
    \\}
    \\fn testMe() void {
    \\  while (true) blk: // a
    \\  {
    \\    std.debug.print("yello world", .{});
    \\    break :blk voidExpr();
    \\  } else { // b
    \\    std.debug.print("bye world", .{});
    \\  }
    \\  while // a
    \\  (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    print('yello world')
    \\  else |y|
    \\    someCall();
    \\  while (someNiceCondition(a, b, c)) | // a
    \\  x| : (j += 5)
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\  inline while (
    \\    someNiceCondition(a, b, c) // a
    \\  )
    \\    print('yello world')
    \\  else // b
    \\    someCall();
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5) // a
    \\    print('yello world');
    \\  while (someNiceCondition(a, b, c)) |x| : (j += someExpr(5, abc, jkl)) { // a
    \\    print('yello world');
    \\  } // b
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testme() void {
    \\  while (true) blk: {
    \\    std.debug.print(
    \\      "yello world",
    \\      .{},
    \\    );
    \\    break :blk voidexpr();
    \\  } else {
    \\    std.debug.print(
    \\      "bye world",
    \\      .{},
    \\    );
    \\  }
    \\  for (true) |*f| blk: {
    \\    std.debug.print(
    \\      "yello world",
    \\      .{},
    \\    );
    \\    break :blk voidexpr();
    \\  } else {
    \\    std.debug.print(
    \\      "bye world",
    \\      .{},
    \\    );
    \\  }
    \\  if (true) blk: {
    \\    std.debug.print(
    \\      "yello world",
    \\      .{},
    \\    );
    \\    break :blk voidexpr();
    \\  } else {
    \\    std.debug.print(
    \\      "bye world",
    \\      .{},
    \\    );
    \\  }
    \\}
    \\fn testMe() void {
    \\  while (true) blk: // a
    \\  {
    \\    std.debug.print(
    \\      "yello world",
    \\      .{},
    \\    );
    \\    break :blk voidExpr();
    \\  } else { // b
    \\    std.debug.print(
    \\      "bye world",
    \\      .{},
    \\    );
    \\  }
    \\  while // a
    \\  (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5)
    \\    print('yello world')
    \\  else |y|
    \\    someCall();
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) | // a
    \\  x|
    \\  : (j += 5)
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\  inline while (
    \\    someNiceCondition(
    \\      a,
    \\      b,
    \\      c,
    \\    ) // a
    \\  )
    \\    print('yello world')
    \\  else // b
    \\    someCall();
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5) // a
    \\    print('yello world');
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (
    \\    j += someExpr(5, abc, jkl)
    \\  ) { // a
    \\    print('yello world');
    \\  } // b
    \\}
  );
}

test "comments/while 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ lbl // a
  \\ : // b
  \\ while // c 
  \\ (someNiceCondition(a, b, c)) |x| : (j += 5) {
  \\  print('yello world');
  \\}
  \\ while (someNiceCondition2(a, b, c)) |x| : (j += 5) blk: {
  \\  print('yello world');
  \\}
  \\ while (someNiceCondition(a, b, c)) |x| : // a
  \\ (j += 5) // b
  \\ _ = blk: {
  \\  print('yello world');
  \\};
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  lbl // a
    \\  : // b
    \\  while // c
    \\  (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  }
    \\  while (someNiceCondition2(a, b, c)) |x| : (j += 5) blk: {
    \\    print('yello world');
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : // a
    \\  (j += 5) // b
    \\    _ = blk: {
    \\      print('yello world');
    \\    };
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  lbl // a
    \\  : // b
    \\  while // c
    \\  (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : (j += 5) {
    \\    print('yello world');
    \\  }
    \\  while (
    \\    someNiceCondition2(
    \\      a,
    \\      b,
    \\      c,
    \\    )
    \\  ) |x|
    \\  : (j += 5) blk: {
    \\    print('yello world');
    \\  }
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\  : // a
    \\  (j += 5) // b
    \\    _ = blk: {
    \\      print('yello world');
    \\    };
    \\}
  );
}

test "comments/block-label" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ if (true) blk: {
  \\ } else {
  \\   foo();
  \\ }
  \\ for (true) |f| blk: {
  \\ } else {
  \\   foo();
  \\ }
  \\ while (true) blk: {
  \\ } else {
  \\   foo();
  \\ }
  \\ if (true) //
  \\ blk //
  \\ : {
  \\ } else {
  \\   foo();
  \\ }
  \\ for (true) |f| //
  \\ blk //
  \\ : {
  \\ } else {
  \\   foo();
  \\ }
  \\ while (true) //
  \\ blk //
  \\ : {
  \\ } else {
  \\   foo();
  \\ }
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (true) blk: {
    \\  } else {
    \\    foo();
    \\  }
    \\  for (true) |f| blk: {
    \\  } else {
    \\    foo();
    \\  }
    \\  while (true) blk: {
    \\  } else {
    \\    foo();
    \\  }
    \\  if (true) //
    \\  blk //
    \\  : {
    \\  } else {
    \\    foo();
    \\  }
    \\  for (true) |f| //
    \\  blk //
    \\  : {
    \\  } else {
    \\    foo();
    \\  }
    \\  while (true) //
    \\  blk //
    \\  : {
    \\  } else {
    \\    foo();
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (true) blk: {
    \\  } else {
    \\    foo();
    \\  }
    \\  for (true) |f| blk: {
    \\  } else {
    \\    foo();
    \\  }
    \\  while (true) blk: {
    \\  } else {
    \\    foo();
    \\  }
    \\  if (true) //
    \\  blk //
    \\  : {
    \\  } else {
    \\    foo();
    \\  }
    \\  for (true) |f| //
    \\  blk //
    \\  : {
    \\  } else {
    \\    foo();
    \\  }
    \\  while (true) //
    \\  blk //
    \\  : {
    \\  } else {
    \\    foo();
    \\  }
    \\}
  );
}

test "comments/if-for-while 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ if (someCondition()) // a
  \\   myExpr();
  \\ if (someCondition()) // a
  \\   myExpr()
  \\  else // b
  \\    myBar();
  \\ if (someCondition()) |*c| // a
  \\   myExpr()
  \\  else // b
  \\    myBar();
  \\ if (someCondition()) // a
  \\   myExpr()
  \\  else |err| // b
  \\    myBar();
  \\ if (someCondition()) |*c| // a
  \\   myExpr()
  \\  else |err| // b
  \\    myBar();
  \\ var x = if (someCondition()) |*c| // a
  \\   myExpr()
  \\  else |err| // b
  \\    myBar();
  \\ var x = if (someCondition()) |*c|
  \\   myExpr()
  \\  else |err| 
  \\    myBar();
  \\ while (someCondition()) // a
  \\   myExpr();
  \\ while (someCondition()) // a
  \\   myExpr()
  \\ else
  \\   tryMe();
  \\ while (someCondition()) : (x += 5) // a
  \\   myExpr();
  \\ while (someCondition()) : (x += 5) // a
  \\   myExpr()
  \\ else |x|
  \\   tryMe();
  \\ for (someCondition()) |f| // a
  \\   myExpr();
  \\ for (someCondition()) |f| // a
  \\   myExpr()
  \\ else
  \\   tryFor();
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (someCondition()) // a
    \\    myExpr();
    \\  if (someCondition()) // a
    \\    myExpr()
    \\  else // b
    \\    myBar();
    \\  if (someCondition()) |*c| // a
    \\    myExpr()
    \\  else // b
    \\    myBar();
    \\  if (someCondition()) // a
    \\    myExpr()
    \\  else |err| // b
    \\    myBar();
    \\  if (someCondition()) |*c| // a
    \\    myExpr()
    \\  else |err| // b
    \\    myBar();
    \\  var x = if (someCondition()) |*c| // a
    \\    myExpr()
    \\  else |err| // b
    \\    myBar();
    \\  var x = if (someCondition()) |*c| myExpr() else |err| myBar();
    \\  while (someCondition()) // a
    \\    myExpr();
    \\  while (someCondition()) // a
    \\    myExpr()
    \\  else
    \\    tryMe();
    \\  while (someCondition()) : (x += 5) // a
    \\    myExpr();
    \\  while (someCondition()) : (x += 5) // a
    \\    myExpr()
    \\  else |x|
    \\    tryMe();
    \\  for (someCondition()) |f| // a
    \\    myExpr();
    \\  for (someCondition()) |f| // a
    \\    myExpr()
    \\  else
    \\    tryFor();
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  if (someCondition()) // a
    \\    myExpr();
    \\  if (someCondition()) // a
    \\    myExpr()
    \\  else // b
    \\    myBar();
    \\  if (
    \\    someCondition()
    \\  ) |*c| // a
    \\    myExpr()
    \\  else // b
    \\    myBar();
    \\  if (someCondition()) // a
    \\    myExpr()
    \\  else |err| // b
    \\    myBar();
    \\  if (
    \\    someCondition()
    \\  ) |*c| // a
    \\    myExpr()
    \\  else |err| // b
    \\    myBar();
    \\  var x = if (
    \\    someCondition()
    \\  ) |*c| // a
    \\    myExpr()
    \\  else |err| // b
    \\    myBar();
    \\  var x = if (
    \\    someCondition()
    \\  ) |*c|
    \\    myExpr()
    \\  else |err|
    \\    myBar();
    \\  while (someCondition()) // a
    \\    myExpr();
    \\  while (someCondition()) // a
    \\    myExpr()
    \\  else
    \\    tryMe();
    \\  while (someCondition())
    \\  : (x += 5) // a
    \\    myExpr();
    \\  while (someCondition())
    \\  : (x += 5) // a
    \\    myExpr()
    \\  else |x|
    \\    tryMe();
    \\  for (
    \\    someCondition(),
    \\  ) |f| // a
    \\    myExpr();
    \\  for (
    \\    someCondition(),
    \\  ) |f| // a
    \\    myExpr()
    \\  else
    \\    tryFor();
    \\}
  );
}

test "comments/if-for-while 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn testMe() void {
  \\ // More torture tests
  \\ if (someCondition()) // a
  \\ |c| myExpr();
  \\ if (someCondition()) // a
  \\ |c| myExpr()
  \\  else |t|
  \\    myBar();
  \\ if (someCondition())
  \\ |c| // a
  \\ myExpr()
  \\  else |t|
  \\    myBar();
  \\ if (someCondition()) // a
  \\ |c| myExpr()
  \\  else // b
  \\    myBar();
  \\ if (someCondition())
  \\ |c| myExpr()
  \\  else // a
  \\    myBar();
  \\  if (cond()) // a
  \\    voidExpr()
  \\  else
  \\  {
  \\    var x = 5;
  \\  }
  \\ while (someCondition()) // a
  \\ : (x += 5)
  \\   myExpr();
  \\ while (someCondition()) // a
  \\ : (x += 5)
  \\   myExpr()
  \\ else |y|
  \\   tryMe();
  \\ while (someCondition()) // 1
  \\ : (x += 5)
  \\   myExpr()
  \\ else // 2
  \\   tryMe();
  \\ while (someCondition())
  \\ : (x += 5)
  \\   myExpr()
  \\ else // 1
  \\   |x| tryMe();
  \\  while (cond()) |x| // 1
  \\    voidExpr()
  \\  else
  \\  {
  \\    var x = 5;
  \\  }
  \\ for (someCondition()) //a
  \\ |f|
  \\   myExpr();
  \\ for (someCondition()) // a
  \\ |f|
  \\   myExpr()
  \\ else
  \\   tryFor();
  \\ for (someCondition())
  \\ |f|
  \\   myExpr()
  \\ else // 1
  \\   tryFor();
  \\  for (cond()) |x| // 1
  \\    voidExpr()
  \\  else
  \\  {
  \\    var x = 5;
  \\  }
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn testMe() void {
    \\  // More torture tests
    \\  if (someCondition()) // a
    \\  |c|
    \\    myExpr();
    \\  if (someCondition()) // a
    \\  |c|
    \\    myExpr()
    \\  else |t|
    \\    myBar();
    \\  if (someCondition()) |c| // a
    \\    myExpr()
    \\  else |t|
    \\    myBar();
    \\  if (someCondition()) // a
    \\  |c|
    \\    myExpr()
    \\  else // b
    \\    myBar();
    \\  if (someCondition()) |c| myExpr() else // a
    \\  myBar();
    \\  if (cond()) // a
    \\    voidExpr()
    \\  else {
    \\    var x = 5;
    \\  }
    \\  while (someCondition()) // a
    \\  : (x += 5)
    \\    myExpr();
    \\  while (someCondition()) // a
    \\  : (x += 5)
    \\    myExpr()
    \\  else |y|
    \\    tryMe();
    \\  while (someCondition()) // 1
    \\  : (x += 5)
    \\    myExpr()
    \\  else // 2
    \\    tryMe();
    \\  while (someCondition()) : (x += 5) myExpr() else // 1
    \\  |x| tryMe();
    \\  while (cond()) |x| // 1
    \\    voidExpr()
    \\  else {
    \\    var x = 5;
    \\  }
    \\  for (someCondition()) //a
    \\  |f|
    \\    myExpr();
    \\  for (someCondition()) // a
    \\  |f|
    \\    myExpr()
    \\  else
    \\    tryFor();
    \\  for (someCondition()) |f| myExpr() else // 1
    \\  tryFor();
    \\  for (cond()) |x| // 1
    \\    voidExpr()
    \\  else {
    \\    var x = 5;
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn testMe() void {
    \\  // More torture tests
    \\  if (someCondition()) // a
    \\  |c|
    \\    myExpr();
    \\  if (someCondition()) // a
    \\  |c|
    \\    myExpr()
    \\  else |t|
    \\    myBar();
    \\  if (
    \\    someCondition()
    \\  ) |c| // a
    \\    myExpr()
    \\  else |t|
    \\    myBar();
    \\  if (someCondition()) // a
    \\  |c|
    \\    myExpr()
    \\  else // b
    \\    myBar();
    \\  if (someCondition()) |c|
    \\    myExpr()
    \\  else // a
    \\    myBar();
    \\  if (cond()) // a
    \\    voidExpr()
    \\  else {
    \\    var x = 5;
    \\  }
    \\  while (someCondition()) // a
    \\  : (x += 5)
    \\    myExpr();
    \\  while (someCondition()) // a
    \\  : (x += 5)
    \\    myExpr()
    \\  else |y|
    \\    tryMe();
    \\  while (someCondition()) // 1
    \\  : (x += 5)
    \\    myExpr()
    \\  else // 2
    \\    tryMe();
    \\  while (someCondition())
    \\  : (x += 5)
    \\    myExpr()
    \\  else // 1
    \\  |x|
    \\    tryMe();
    \\  while (cond()) |x| // 1
    \\    voidExpr()
    \\  else {
    \\    var x = 5;
    \\  }
    \\  for (someCondition()) //a
    \\  |f|
    \\    myExpr();
    \\  for (someCondition()) // a
    \\  |f|
    \\    myExpr()
    \\  else
    \\    tryFor();
    \\  for (someCondition()) |f|
    \\    myExpr()
    \\  else // 1
    \\    tryFor();
    \\  for (cond()) |x| // 1
    \\    voidExpr()
    \\  else {
    \\    var x = 5;
    \\  }
    \\}
  );
}

test "comments/if-for-while 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() void {
  \\ while (true) {}
  \\ while (true) {} else {}
  \\ if (true) {}
  \\ if (true) {} else {}
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo() void {
    \\  while (true) {}
    \\  while (true) {
    \\  } else {
    \\  }
    \\  if (true) {
    \\  }
    \\  if (true) {
    \\  } else {
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo() void {
    \\  while (true) {}
    \\  while (true) {
    \\  } else {
    \\  }
    \\  if (true) {
    \\  }
    \\  if (true) {
    \\  } else {
    \\  }
    \\}
  );
}

test "comments/if-while 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\const final_qual: enum {
  \\    @"volatile",
  \\    @"const",
  \\    @"addrspace",
  \\    @"align",
  \\    @"allowzero",
  \\    none,
  \\} = if (ptr_type.volatile_token != null)
  \\    .@"volatile"
  \\else if (ptr_type.const_token != null)
  \\    .@"const"
  \\else if (ptr_type.ast.addrspace_node != .none)
  \\    .@"addrspace"
  \\else if (ptr_type.ast.align_node != .none)
  \\    .@"align"
  \\else if (ptr_type.allowzero_token != null)
  \\    .@"allowzero"
  \\else
  \\    .none;
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const final_qual: enum {
    \\  @"volatile",
    \\  @"const",
    \\  @"addrspace",
    \\  @"align",
    \\  @"allowzero",
    \\  none,
    \\} = if (ptr_type.volatile_token != null)
    \\  .@"volatile"
    \\else if (ptr_type.const_token != null)
    \\  .@"const"
    \\else if (ptr_type.ast.addrspace_node != .none)
    \\  .@"addrspace"
    \\else if (ptr_type.ast.align_node != .none)
    \\  .@"align"
    \\else if (ptr_type.allowzero_token != null)
    \\  .@"allowzero"
    \\else
    \\  .none;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const final_qual: enum {
    \\  @"volatile",
    \\  @"const",
    \\  @"addrspace",
    \\  @"align",
    \\  @"allowzero",
    \\  none,
    \\} = if (
    \\  ptr_type.volatile_token
    \\    != null
    \\)
    \\  .@"volatile"
    \\else if (
    \\  ptr_type.const_token != null
    \\)
    \\  .@"const"
    \\else if (
    \\  ptr_type.ast.addrspace_node
    \\    != .none
    \\)
    \\  .@"addrspace"
    \\else if (
    \\  ptr_type.ast.align_node
    \\    != .none
    \\)
    \\  .@"align"
    \\else if (
    \\  ptr_type.allowzero_token
    \\    != null
    \\)
    \\  .@"allowzero"
    \\else
    \\  .none;
  );
}

test "comments/if-while 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() void {
  \\ while (cond) foo()
  \\ else if (someO()) b else if (someB()) c else d;
  \\
  \\ if (cond) foo()
  \\ else if (someO()) b else if (someB()) c else // a
  \\ d;
  \\
  \\ while (cond) foo()
  \\ else if (someO()) b else if (someB()) c else  |t|d;
  \\
  \\ if (cond) foo()
  \\ else if (someO()) b else if (someB()) c else |t| // a
  \\ d;
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo() void {
    \\  while (cond)
    \\    foo()
    \\  else if (someO())
    \\    b
    \\  else if (someB())
    \\    c
    \\  else
    \\    d;
    \\
    \\  if (cond)
    \\    foo()
    \\  else if (someO())
    \\    b
    \\  else if (someB())
    \\    c
    \\  else // a
    \\    d;
    \\
    \\  while (cond)
    \\    foo()
    \\  else if (someO())
    \\    b
    \\  else if (someB())
    \\    c
    \\  else |t|
    \\    d;
    \\
    \\  if (cond)
    \\    foo()
    \\  else if (someO())
    \\    b
    \\  else if (someB())
    \\    c
    \\  else |t| // a
    \\    d;
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo() void {
    \\  while (cond)
    \\    foo()
    \\  else if (someO())
    \\    b
    \\  else if (someB())
    \\    c
    \\  else
    \\    d;
    \\
    \\  if (cond)
    \\    foo()
    \\  else if (someO())
    \\    b
    \\  else if (someB())
    \\    c
    \\  else // a
    \\    d;
    \\
    \\  while (cond)
    \\    foo()
    \\  else if (someO())
    \\    b
    \\  else if (someB())
    \\    c
    \\  else |t|
    \\    d;
    \\
    \\  if (cond)
    \\    foo()
    \\  else if (someO())
    \\    b
    \\  else if (someB())
    \\    c
    \\  else |t| // a
    \\    d;
    \\}
  );
}

test "comments/switch 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\label // 1
  \\ : // 2 
  \\ switch // 3
  \\ (// 4 
  \\ expr // 5
  \\ ) // 6
  \\ { // 7
  \\ // lbrace opener
  \\  a // 8
  \\ => // 9
  \\ a // 10
  \\ , // 11
  \\  b // 12
  \\ , // 13
  \\ c // 14
  \\ => // 15
  \\ c // 16
  \\ , // 17
  \\  inline // 18
  \\ d // 19
  \\ ... // 20
  \\ e // 21
  \\ => // 22
  \\ e //23
  \\ , // 24
  \\  else // 25
  \\ =>// 26
  \\ f // 27
  \\ // rbrace closer 
  \\} // 28
  \\ , // 29
  \\
  \\label // 1
  \\ : // 2 
  \\ switch // 3
  \\ (// 4 
  \\ expr // 5
  \\ ) // 6
  \\ { // 7
  \\ } // 8
  \\ ,
  \\ switch // a
  \\ (// b
  \\ expr // c
  \\ ) // d
  \\ {
  \\ }
  \\ ,
  \\
  \\
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\label // 1
    \\: // 2
    \\switch // 3
    \\( // 4
    \\  expr // 5
    \\) // 6
    \\{ // 7
    \\  // lbrace opener
    \\  a // 8
    \\  => // 9
    \\  a // 10
    \\  , // 11
    \\  b // 12
    \\  , // 13
    \\  c // 14
    \\  => // 15
    \\  c // 16
    \\  , // 17
    \\  inline // 18
    \\  d // 19
    \\    ... // 20
    \\    e // 21
    \\    => // 22
    \\    e //23
    \\  , // 24
    \\  else // 25
    \\  => // 26
    \\  f // 27
    \\  // rbrace closer
    \\} // 28
    \\, // 29
    \\
    \\label // 1
    \\: // 2
    \\switch // 3
    \\( // 4
    \\  expr // 5
    \\) // 6
    \\{ // 7
    \\} // 8
    \\,
    \\switch // a
    \\( // b
    \\  expr // c
    \\) // d
    \\{},
    \\
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\label // 1
    \\: // 2
    \\switch // 3
    \\( // 4
    \\  expr // 5
    \\) // 6
    \\{ // 7
    \\  // lbrace opener
    \\  a // 8
    \\  => // 9
    \\  a // 10
    \\  , // 11
    \\  b // 12
    \\  , // 13
    \\  c // 14
    \\  => // 15
    \\  c // 16
    \\  , // 17
    \\  inline // 18
    \\  d // 19
    \\    ... // 20
    \\    e // 21
    \\    => // 22
    \\    e //23
    \\  , // 24
    \\  else // 25
    \\  => // 26
    \\  f // 27
    \\  // rbrace closer
    \\} // 28
    \\, // 29
    \\
    \\label // 1
    \\: // 2
    \\switch // 3
    \\( // 4
    \\  expr // 5
    \\) // 6
    \\{ // 7
    \\} // 8
    \\,
    \\switch // a
    \\( // b
    \\  expr // c
    \\) // d
    \\{},
    \\
  );
}

test "comments/switch 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ switch (someExpr(jk)) {},
  \\
  \\ switch // a
  \\ (someExpr(jk)) {}, // b
  \\
  \\ fn fun(expr: Type) switch // 0
  \\ (TypeOf(expr)) { // a
  \\ .a => TyFoo, .b => TyBar, else => TyBaz} { // b
  \\   return 
  \\label: switch (expr)  { // 1
  \\  a => a, // 2
  \\  b, c => c, // 3
  \\  inline d...e => e, // 4
  \\  else => f, //foo
  \\}; // 5
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\switch (someExpr(jk)) {},
    \\
    \\switch // a
    \\(someExpr(jk)) {}, // b
    \\
    \\fn fun(
    \\  expr: Type,
    \\) switch // 0
    \\(TypeOf(expr)) { // a
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} { // b
    \\  return label: switch (expr) { // 1
    \\    a => a, // 2
    \\    b, c => c, // 3
    \\    inline d...e => e, // 4
    \\    else => f, //foo
    \\  }; // 5
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\switch (someExpr(jk)) {},
    \\
    \\switch // a
    \\(
    \\  someExpr(jk)
    \\) {}, // b
    \\
    \\fn fun(
    \\  expr: Type,
    \\) switch // 0
    \\(
    \\  TypeOf(expr)
    \\) { // a
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} { // b
    \\  return label: switch (
    \\    expr
    \\  ) { // 1
    \\    a => a, // 2
    \\    b, c => c, // 3
    \\    inline d...e => e, // 4
    \\    else => f, //foo
    \\  }; // 5
    \\}
  );
}

test "comments/switch 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn fun(expr: Type) lbl// ok
  \\: // first
  \\ switch // 0
  \\ (TypeOf(expr)) { // a
  \\ .a => TyFoo, .b => TyBar, else => TyBaz} { // b
  \\   return 
  \\ switch (expr)  { // 1
  \\  a => a, // 2
  \\  b, c => c, // 3
  \\  inline d...e => e, // 4
  \\  else => f, //foo
  \\}; // 5
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn fun(
    \\  expr: Type,
    \\) lbl // ok
    \\: // first
    \\switch // 0
    \\(TypeOf(expr)) { // a
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} { // b
    \\  return switch (expr) { // 1
    \\    a => a, // 2
    \\    b, c => c, // 3
    \\    inline d...e => e, // 4
    \\    else => f, //foo
    \\  }; // 5
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn fun(
    \\  expr: Type,
    \\) lbl // ok
    \\: // first
    \\switch // 0
    \\(
    \\  TypeOf(expr)
    \\) { // a
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} { // b
    \\  return switch (expr) { // 1
    \\    a => a, // 2
    \\    b, c => c, // 3
    \\    inline d...e => e, // 4
    \\    else => f, //foo
    \\  }; // 5
    \\}
  );
}

test "comments/switch 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\tag: switch (expr2)  { // one
  \\  // switching on an expr is good 1
  \\  // switching on an expr is good 2
  \\  // switching on an expr is good 3
  \\  .a => |bar| {},
  \\  inline .x => |*bar, foo| a = call(),
  \\  .y => |bar, foo| myExpr(),
  \\  .b, .c => |*foo| { // two
  \\  var k = abc;
  \\  if (k * someExpr(expr2) > 0xff) {
  \\    print("yep!");
  \\}
  \\},
  \\  .b, .c, .d, .e, .f, .g, .h => |*foo| { // three
  \\ if (ty.ast.sentinel.unwrap()) |n| {
  \\   sb.text("[")._();
  \\   var elems = self.db.seqb();
  \\   elems.softline().text("*:")._();
  \\   elems.append(try self.t(n));
  \\   sb.indent(elems.finish()).softline().text("]")._();
  \\ } else {
  \\   sb.text("[*]")._();
  \\ }
  \\ },
  \\  .d ... .e => {}, // keep
  \\.add, .add_wrap, .add_sat, .array_cat, .array_mult, .bang_equal,
  \\.bit_and, .bit_or, .shl, .shl_sat, .shr, .bit_xor, .bool_and,
  \\.bool_or, .div, .equal_equal, .greater_or_equal, .greater_than,
  \\.less_or_equal, .less_than, .merge_error_sets, .mod, .mul, .mul_wrap,
  \\.mul_sat, .sub, .sub_wrap, .sub_sat => {
  \\  return self.tBinaryExpr(n, tag);
  \\}, // yeah same
  \\  else => f,
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\tag: switch (expr2) { // one
    \\  // switching on an expr is good 1
    \\  // switching on an expr is good 2
    \\  // switching on an expr is good 3
    \\  .a => |bar| {},
    \\  inline .x => |*bar, foo| a = call(),
    \\  .y => |bar, foo| myExpr(),
    \\  .b, .c => |*foo| { // two
    \\    var k = abc;
    \\    if (k * someExpr(expr2) > 0xff) {
    \\      print("yep!");
    \\    }
    \\  },
    \\  .b, .c, .d, .e, .f, .g, .h => |*foo| { // three
    \\    if (ty.ast.sentinel.unwrap()) |n| {
    \\      sb.text("[")._();
    \\      var elems = self.db.seqb();
    \\      elems.softline().text("*:")._();
    \\      elems.append(try self.t(n));
    \\      sb.indent(elems.finish()).softline().text("]")._();
    \\    } else {
    \\      sb.text("[*]")._();
    \\    }
    \\  },
    \\  .d....e => {}, // keep
    \\  .add,
    \\  .add_wrap,
    \\  .add_sat,
    \\  .array_cat,
    \\  .array_mult,
    \\  .bang_equal,
    \\  .bit_and,
    \\  .bit_or,
    \\  .shl,
    \\  .shl_sat,
    \\  .shr,
    \\  .bit_xor,
    \\  .bool_and,
    \\  .bool_or,
    \\  .div,
    \\  .equal_equal,
    \\  .greater_or_equal,
    \\  .greater_than,
    \\  .less_or_equal,
    \\  .less_than,
    \\  .merge_error_sets,
    \\  .mod,
    \\  .mul,
    \\  .mul_wrap,
    \\  .mul_sat,
    \\  .sub,
    \\  .sub_wrap,
    \\  .sub_sat => {
    \\    return self.tBinaryExpr(n, tag);
    \\  }, // yeah same
    \\  else => f,
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\tag: switch (expr2) { // one
    \\  // switching on an expr is good 1
    \\  // switching on an expr is good 2
    \\  // switching on an expr is good 3
    \\  .a => |bar| {},
    \\  inline .x => |*bar, foo| a = call(),
    \\  .y => |bar, foo| myExpr(),
    \\  .b, .c => |*foo| { // two
    \\    var k = abc;
    \\    if (
    \\      k * someExpr(expr2)
    \\        > 0xff
    \\    ) {
    \\      print("yep!");
    \\    }
    \\  },
    \\  .b,
    \\  .c,
    \\  .d,
    \\  .e,
    \\  .f,
    \\  .g,
    \\  .h => |*foo| { // three
    \\    if (
    \\      ty.ast.sentinel.unwrap()
    \\    ) |n| {
    \\      sb.text("[")._();
    \\      var elems = self.db.seqb();
    \\      elems.softline()
    \\        .text("*:")
    \\        ._();
    \\      elems.append(
    \\        try self.t(n),
    \\      );
    \\      sb.indent(
    \\        elems.finish(),
    \\      )
    \\        .softline()
    \\        .text("]")
    \\        ._();
    \\    } else {
    \\      sb.text("[*]")._();
    \\    }
    \\  },
    \\  .d....e => {}, // keep
    \\  .add,
    \\  .add_wrap,
    \\  .add_sat,
    \\  .array_cat,
    \\  .array_mult,
    \\  .bang_equal,
    \\  .bit_and,
    \\  .bit_or,
    \\  .shl,
    \\  .shl_sat,
    \\  .shr,
    \\  .bit_xor,
    \\  .bool_and,
    \\  .bool_or,
    \\  .div,
    \\  .equal_equal,
    \\  .greater_or_equal,
    \\  .greater_than,
    \\  .less_or_equal,
    \\  .less_than,
    \\  .merge_error_sets,
    \\  .mod,
    \\  .mul,
    \\  .mul_wrap,
    \\  .mul_sat,
    \\  .sub,
    \\  .sub_wrap,
    \\  .sub_sat => {
    \\    return self.tBinaryExpr(
    \\      n,
    \\      tag,
    \\    );
    \\  }, // yeah same
    \\  else => f,
    \\}
  );
}

test "comments/switch 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ switch (expr(jla)) // 0
  \\ {
  \\  inline // 1
  \\ foo, bar => a,
  \\ arg, foo, bar // 1b
  \\ => a,
  \\  inline // 2
  \\ foo, bar => b,
  \\  inline // 3
  \\ else // 4
  \\ => c,
  \\ },
  \\
  \\ // control
  \\ switch (expr(jla)) {
  \\  cool, foo, bar, dah => 12,
  \\  inline cool, foo, bar, dah => 12,
  \\  inline foo, bar => 12,
  \\  inline foo, bar => 13,
  \\  inline else => 13,
  \\ },
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\switch (expr(jla)) // 0
    \\{
    \\  inline // 1
    \\  foo, bar => a,
    \\  arg, foo, bar // 1b
    \\  => a,
    \\  inline // 2
    \\  foo, bar => b,
    \\  inline // 3
    \\  else // 4
    \\  => c,
    \\},
    \\
    \\// control
    \\switch (expr(jla)) {
    \\  cool, foo, bar, dah => 12,
    \\  inline cool, foo, bar, dah => 12,
    \\  inline foo, bar => 12,
    \\  inline foo, bar => 13,
    \\  inline else => 13,
    \\},
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\switch (
    \\  expr(
    \\    jla,
    \\  )
    \\) // 0
    \\{
    \\  inline // 1
    \\  foo,
    \\    bar => a,
    \\  arg,
    \\  foo,
    \\  bar // 1b
    \\  => a,
    \\  inline // 2
    \\  foo,
    \\    bar => b,
    \\  inline // 3
    \\  else // 4
    \\  => c,
    \\},
    \\
    \\// control
    \\switch (
    \\  expr(
    \\    jla,
    \\  )
    \\) {
    \\  cool,
    \\  foo,
    \\  bar,
    \\  dah => 12,
    \\  inline cool,
    \\    foo,
    \\    bar,
    \\    dah => 12,
    \\  inline foo,
    \\    bar => 12,
    \\  inline foo,
    \\    bar => 13,
    \\  inline else => 13,
    \\},
  );
}

test "comments/error-union" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn fun(expr: Type) Foo // 1
  \\ ! // 2
  \\ switch // 0
  \\ (@TypeOf(expr)) { // a
  \\ .a => TyFoo, .b => TyBar, else => TyBaz} { // b
  \\   return 
  \\label: switch (expr)  { // 1
  \\  a => a, // 2
  \\  b, c => c, // 3
  \\  inline d...e => e, // 4
  \\  else => f, //foo
  \\}; // 5
  \\}
  \\
  \\ fn fun() Bar // 1
  \\ ! // 2
  \\ expr(a, b, c) { // 3
  \\ }
  \\
  \\ fn fun() Bar
  \\ ! 
  \\ expr(a, b, c) { // 3
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn fun(
    \\  expr: Type,
    \\) Foo // 1
    \\! // 2
    \\switch // 0
    \\(@TypeOf(expr)) { // a
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} { // b
    \\  return label: switch (expr) { // 1
    \\    a => a, // 2
    \\    b, c => c, // 3
    \\    inline d...e => e, // 4
    \\    else => f, //foo
    \\  }; // 5
    \\}
    \\
    \\fn fun() Bar // 1
    \\! // 2
    \\expr(a, b, c) { // 3
    \\}
    \\
    \\fn fun() Bar!expr(a, b, c) { // 3
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn fun(
    \\  expr: Type,
    \\) Foo // 1
    \\! // 2
    \\switch // 0
    \\(
    \\  @TypeOf(expr)
    \\) { // a
    \\  .a => TyFoo,
    \\  .b => TyBar,
    \\  else => TyBaz,
    \\} { // b
    \\  return label: switch (
    \\    expr
    \\  ) { // 1
    \\    a => a, // 2
    \\    b, c => c, // 3
    \\    inline d...e => e, // 4
    \\    else => f, //foo
    \\  }; // 5
    \\}
    \\
    \\fn fun() Bar // 1
    \\! // 2
    \\expr(a, b, c) { // 3
    \\}
    \\
    \\fn fun() Bar!expr(
    \\  a,
    \\  b,
    \\  c,
    \\) { // 3
    \\}
  );
}

test "struct-array-init" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\const J = .{.abc = 12, .xyz = "ok", .oops = boy};
  \\const J = .{.abc, "ok", 15};
  \\const J = Foo{.abc = 12, .xyz = "ok", .oops = boy};
  \\const J = .{};
  \\const J = .{ .abc = 12 };
  \\const J = .{.abc};
  \\const J = &.{buf[0..size]};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const J = .{ .abc = 12, .xyz = "ok", .oops = boy };
    \\const J = .{ .abc, "ok", 15 };
    \\const J = Foo{ .abc = 12, .xyz = "ok", .oops = boy };
    \\const J = .{};
    \\const J = .{ .abc = 12 };
    \\const J = .{.abc};
    \\const J = &.{buf[0..size]};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const J = .{
    \\  .abc = 12,
    \\  .xyz = "ok",
    \\  .oops = boy,
    \\};
    \\const J = .{ .abc, "ok", 15 };
    \\const J = Foo{
    \\  .abc = 12,
    \\  .xyz = "ok",
    \\  .oops = boy,
    \\};
    \\const J = .{};
    \\const J = .{ .abc = 12 };
    \\const J = .{.abc};
    \\const J = &.{buf[0..size]};
  );
}

test "comments/struct-init" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\   var a = Ty // 1
  \\ { // 2
  \\ . // 3
  \\ x // 4 
  \\ = // 5
  \\ "yay" // 6
  \\ , // 7
  \\ . // 8
  \\ y // 9
  \\ = // 10
  \\ 0xff // 11
  \\ } // 12
  \\ ; // last
  \\
  \\   var a2 = Ty // 1
  \\ { // 2
  \\ . // 3
  \\ x // 4 
  \\ = // 5
  \\ "yay" // 6
  \\ , // 7
  \\ . // 8
  \\ y // 9
  \\ = // 10
  \\ 0xff, // 11
  \\ } // 12
  \\ ; // last
  \\
  \\   var b = Ty // 1
  \\ { // 2
  \\ // very merry many comments - there
  \\ // very merry many comments - here
  \\ . // 3
  \\ x // 4 
  \\ = // 5
  \\ "yay" // 6
  \\ } // 7
  \\ ; // last
  \\
  \\   var c = Ty // 1
  \\ { // 2
  \\ // very merry many comments - there
  \\ // very merry many comments - here
  \\ . // 3
  \\ x // 4 
  \\ = // 5
  \\ "yay", // 6
  \\ } // 7
  \\ ; // last
  \\
  \\   var c = foo.bar(ab, cd())// 1
  \\ { // 2
  \\ // very merry many comments - there
  \\ // very merry many comments - here
  \\ . // 3
  \\ x // 4 
  \\ = // 5
  \\ "yay", // 6
  \\ // e - very merry many comments - there
  \\ // e - very merry many comments - here
  \\ } // 7
  \\ ; // last
  \\
  \\   var p = foo.bar(ab, cd()) {.x = "yay", .y = 0xff};
  \\   var q = foo // ok
  \\ .bar(ab, cd()) {.x = "yay", .y = 0xff};
  \\
  \\   var d = . // 1
  \\ { // 2
  \\ . // 3
  \\ x // 4 
  \\ = // 5
  \\ "yay" // 6
  \\ , // 7
  \\ . // 8
  \\ y // 9
  \\ = // 10
  \\ 0xff // 11
  \\ } // 12
  \\ ; // last
  \\
  \\   var e = . // 1
  \\ { // 2
  \\ . // 3
  \\ x // 4 
  \\ = // 5
  \\ "yay" // 6
  \\ , // 7
  \\ . // 8
  \\ y // 9
  \\ = // 10
  \\ 0xff, // 11
  \\ } // 12
  \\ ; // last
  \\
  \\   const e = . // 1
  \\ { // trail here 2
  \\ .
  \\ x
  \\ =
  \\ "yay"
  \\ ,
  \\ .
  \\ y
  \\ =
  \\ 0xff,
  \\ }
  \\ ; // last
  \\
  \\   var k = Ty // 1
  \\ { // 2
  \\ } // 3
  \\ ;
  \\
  \\   var g = . // 1
  \\ { // 2
  \\ } // 3
  \\ ;
  \\
  \\   var g = . // 1
  \\ {
  \\ }
  \\ ;
  \\
  \\ var g = . // 1
  \\ { // 2
  \\ }
  \\ ;
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var a = Ty // 1
    \\{ // 2
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay" // 6
    \\  , // 7
    \\  . // 8
    \\  y // 9
    \\  = // 10
    \\  0xff // 11
    \\} // 12
    \\; // last
    \\
    \\var a2 = Ty // 1
    \\{ // 2
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay" // 6
    \\  , // 7
    \\  . // 8
    \\  y // 9
    \\  = // 10
    \\  0xff, // 11
    \\} // 12
    \\; // last
    \\
    \\var b = Ty // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay" // 6
    \\} // 7
    \\; // last
    \\
    \\var c = Ty // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay", // 6
    \\} // 7
    \\; // last
    \\
    \\var c = foo.bar(ab, cd()) // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay", // 6
    \\  // e - very merry many comments - there
    \\  // e - very merry many comments - here
    \\} // 7
    \\; // last
    \\
    \\var p = foo.bar(ab, cd()){ .x = "yay", .y = 0xff };
    \\var q = foo // ok
    \\.bar(ab, cd()){ .x = "yay", .y = 0xff };
    \\
    \\var d = . // 1
    \\{ // 2
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay" // 6
    \\  , // 7
    \\  . // 8
    \\  y // 9
    \\  = // 10
    \\  0xff // 11
    \\} // 12
    \\; // last
    \\
    \\var e = . // 1
    \\{ // 2
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay" // 6
    \\  , // 7
    \\  . // 8
    \\  y // 9
    \\  = // 10
    \\  0xff, // 11
    \\} // 12
    \\; // last
    \\
    \\const e = . // 1
    \\{ // trail here 2
    \\  .x = "yay",
    \\  .y = 0xff,
    \\}; // last
    \\
    \\var k = Ty // 1
    \\{ // 2
    \\} // 3
    \\;
    \\
    \\var g = . // 1
    \\{ // 2
    \\} // 3
    \\;
    \\
    \\var g = . // 1
    \\{};
    \\
    \\var g = . // 1
    \\{ // 2
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var a = Ty // 1
    \\{ // 2
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay" // 6
    \\  , // 7
    \\  . // 8
    \\  y // 9
    \\  = // 10
    \\  0xff // 11
    \\} // 12
    \\; // last
    \\
    \\var a2 = Ty // 1
    \\{ // 2
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay" // 6
    \\  , // 7
    \\  . // 8
    \\  y // 9
    \\  = // 10
    \\  0xff, // 11
    \\} // 12
    \\; // last
    \\
    \\var b = Ty // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay" // 6
    \\} // 7
    \\; // last
    \\
    \\var c = Ty // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay", // 6
    \\} // 7
    \\; // last
    \\
    \\var c = foo.bar(ab, cd()) // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay", // 6
    \\  // e - very merry many comments - there
    \\  // e - very merry many comments - here
    \\} // 7
    \\; // last
    \\
    \\var p = foo.bar(ab, cd()){
    \\  .x = "yay",
    \\  .y = 0xff,
    \\};
    \\var q = foo // ok
    \\.bar(
    \\  ab,
    \\  cd(),
    \\){
    \\  .x = "yay",
    \\  .y = 0xff,
    \\};
    \\
    \\var d = . // 1
    \\{ // 2
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay" // 6
    \\  , // 7
    \\  . // 8
    \\  y // 9
    \\  = // 10
    \\  0xff // 11
    \\} // 12
    \\; // last
    \\
    \\var e = . // 1
    \\{ // 2
    \\  . // 3
    \\  x // 4
    \\  = // 5
    \\  "yay" // 6
    \\  , // 7
    \\  . // 8
    \\  y // 9
    \\  = // 10
    \\  0xff, // 11
    \\} // 12
    \\; // last
    \\
    \\const e = . // 1
    \\{ // trail here 2
    \\  .x = "yay",
    \\  .y = 0xff,
    \\}; // last
    \\
    \\var k = Ty // 1
    \\{ // 2
    \\} // 3
    \\;
    \\
    \\var g = . // 1
    \\{ // 2
    \\} // 3
    \\;
    \\
    \\var g = . // 1
    \\{};
    \\
    \\var g = . // 1
    \\{ // 2
    \\};
  );
}

test "comments/array-init" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\   var a = Ty // 1
  \\ { // 2
  \\ "yay" // 3
  \\ , // 4
  \\ 0xff // 5 
  \\ } // 6
  \\ ; // last
  \\
  \\   var a2 = Ty // 1
  \\ { // 2
  \\ . // 3
  \\ x // 4 
  \\ , // 5
  \\ . // 6
  \\ y // 7
  \\ } // 8 
  \\ ; // last
  \\
  \\   var b = Ty // 1
  \\ { // 2
  \\ // very merry many comments - there
  \\ // very merry many comments - here
  \\ "yay" // 3
  \\ } // 4
  \\ ; // last
  \\
  \\   var c = Ty // 1
  \\ { // 2
  \\ // very merry many comments - there
  \\ // very merry many comments - here
  \\ . // 3
  \\ x, // 4 
  \\ } // 5
  \\ ; // last
  \\
  \\   var c2 = foo.bar(ab, cd())// 1
  \\ { // 2
  \\ // very merry many comments - there
  \\ // very merry many comments - here
  \\ "yay", // 3
  \\ // e - very merry many comments - there
  \\ // e - very merry many comments - here
  \\ } // 4
  \\ ; // last
  \\
  \\   var p = foo.bar(ab, cd()) {x("yay"), y(0xff)};
  \\   var q = foo // ok
  \\ .bar(ab, cd()) {.x("yay"), .y(0xff) // cool
  \\ };
  \\
  \\   var d = . // 1
  \\ { // 2
  \\ joe // 3
  \\ , // 4
  \\ 123, // 5
  \\ "yay" // 6
  \\ , // 7
  \\ . // 8
  \\ y // 9
  \\ } // 10
  \\ ; // last
  \\
  \\   var e = . // 1
  \\ { // 2
  \\ "yay" // 3
  \\ , // 4
  \\ 0xff, // 5 
  \\ } // 6
  \\ ; // last
  \\
  \\   const e = . // 1
  \\ { // trail here 2
  \\ .
  \\ x 
  \\ ,
  \\ .
  \\ y,
  \\ }
  \\ ; // last
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var a = Ty // 1
    \\{ // 2
    \\  "yay" // 3
    \\  , // 4
    \\  0xff // 5
    \\} // 6
    \\; // last
    \\
    \\var a2 = Ty // 1
    \\{ // 2
    \\  . // 3
    \\  x // 4
    \\  , // 5
    \\  . // 6
    \\  y // 7
    \\} // 8
    \\; // last
    \\
    \\var b = Ty // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  "yay" // 3
    \\} // 4
    \\; // last
    \\
    \\var c = Ty // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  . // 3
    \\  x, // 4
    \\} // 5
    \\; // last
    \\
    \\var c2 = foo.bar(ab, cd()) // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  "yay", // 3
    \\  // e - very merry many comments - there
    \\  // e - very merry many comments - here
    \\} // 4
    \\; // last
    \\
    \\var p = foo.bar(ab, cd()){ x("yay"), y(0xff) };
    \\var q = foo // ok
    \\.bar(ab, cd()){
    \\  .x("yay"),
    \\  .y(0xff) // cool
    \\};
    \\
    \\var d = . // 1
    \\{ // 2
    \\  joe // 3
    \\  , // 4
    \\  123, // 5
    \\  "yay" // 6
    \\  , // 7
    \\  . // 8
    \\  y // 9
    \\} // 10
    \\; // last
    \\
    \\var e = . // 1
    \\{ // 2
    \\  "yay" // 3
    \\  , // 4
    \\  0xff, // 5
    \\} // 6
    \\; // last
    \\
    \\const e = . // 1
    \\{ // trail here 2
    \\  .x,
    \\  .y,
    \\}; // last
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var a = Ty // 1
    \\{ // 2
    \\  "yay" // 3
    \\  , // 4
    \\  0xff // 5
    \\} // 6
    \\; // last
    \\
    \\var a2 = Ty // 1
    \\{ // 2
    \\  . // 3
    \\  x // 4
    \\  , // 5
    \\  . // 6
    \\  y // 7
    \\} // 8
    \\; // last
    \\
    \\var b = Ty // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  "yay" // 3
    \\} // 4
    \\; // last
    \\
    \\var c = Ty // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  . // 3
    \\  x, // 4
    \\} // 5
    \\; // last
    \\
    \\var c2 = foo.bar(
    \\  ab,
    \\  cd(),
    \\) // 1
    \\{ // 2
    \\  // very merry many comments - there
    \\  // very merry many comments - here
    \\  "yay", // 3
    \\  // e - very merry many comments - there
    \\  // e - very merry many comments - here
    \\} // 4
    \\; // last
    \\
    \\var p = foo.bar(ab, cd()){
    \\  x("yay"),
    \\  y(0xff),
    \\};
    \\var q = foo // ok
    \\.bar(
    \\  ab,
    \\  cd(),
    \\){
    \\  .x("yay"),
    \\  .y(0xff) // cool
    \\};
    \\
    \\var d = . // 1
    \\{ // 2
    \\  joe // 3
    \\  , // 4
    \\  123, // 5
    \\  "yay" // 6
    \\  , // 7
    \\  . // 8
    \\  y // 9
    \\} // 10
    \\; // last
    \\
    \\var e = . // 1
    \\{ // 2
    \\  "yay" // 3
    \\  , // 4
    \\  0xff, // 5
    \\} // 6
    \\; // last
    \\
    \\const e = . // 1
    \\{ // trail here 2
    \\  .x,
    \\  .y,
    \\}; // last
  );
}

test "comments/break-return" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() void {
  \\ // this is true
  \\ return // my ret
  \\  expr();
  \\ }
  \\
  \\ fn foo() void {
  \\ // this is true
  \\ return // my ret
  \\  ;
  \\ }
  \\
  \\
  \\ fn foo() void {
  \\ break // my ret
  \\  expr();
  \\ }
  \\
  \\ fn foo() void {
  \\ break // my ret
  \\  : // colon
  \\  lbl // lbl
  \\  expr();
  \\ }
  \\
  \\ fn foo() void {
  \\ break // my ret
  \\  : // colon
  \\  lbl // lbl
  \\  ;
  \\ }
  \\
  \\ fn foo() void {
  \\ break // my ret
  \\  ;
  \\ }
  \\
  \\ fn foo() void {
  \\ break expr(); // my ret
  \\ }
  \\
  \\ fn foo() void {
  \\ break : lbl expr();
  \\ }
  \\ 
  \\ fn foo() void {
  \\ return expr();
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo() void {
    \\  // this is true
    \\  return // my ret
    \\  expr();
    \\}
    \\
    \\fn foo() void {
    \\  // this is true
    \\  return // my ret
    \\  ;
    \\}
    \\
    \\fn foo() void {
    \\  break // my ret
    \\  expr();
    \\}
    \\
    \\fn foo() void {
    \\  break // my ret
    \\  : // colon
    \\  lbl // lbl
    \\  expr();
    \\}
    \\
    \\fn foo() void {
    \\  break // my ret
    \\  : // colon
    \\  lbl // lbl
    \\  ;
    \\}
    \\
    \\fn foo() void {
    \\  break // my ret
    \\  ;
    \\}
    \\
    \\fn foo() void {
    \\  break expr(); // my ret
    \\}
    \\
    \\fn foo() void {
    \\  break :lbl expr();
    \\}
    \\
    \\fn foo() void {
    \\  return expr();
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo() void {
    \\  // this is true
    \\  return // my ret
    \\  expr();
    \\}
    \\
    \\fn foo() void {
    \\  // this is true
    \\  return // my ret
    \\  ;
    \\}
    \\
    \\fn foo() void {
    \\  break // my ret
    \\  expr();
    \\}
    \\
    \\fn foo() void {
    \\  break // my ret
    \\  : // colon
    \\  lbl // lbl
    \\  expr();
    \\}
    \\
    \\fn foo() void {
    \\  break // my ret
    \\  : // colon
    \\  lbl // lbl
    \\  ;
    \\}
    \\
    \\fn foo() void {
    \\  break // my ret
    \\  ;
    \\}
    \\
    \\fn foo() void {
    \\  break expr(); // my ret
    \\}
    \\
    \\fn foo() void {
    \\  break :lbl expr();
    \\}
    \\
    \\fn foo() void {
    \\  return expr();
    \\}
  );
}

test "comments/assign-destructure" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() void {
  \\ // this is true
  \\ const // 1
  \\ tkn // 2
  \\ , // 3
  \\ const // 4
  \\ node // 5
  \\ = // 6
  \\ self.tree.nodeData(n).opt_token_and_opt_node; // 7
  \\
  \\ var // 1
  \\ a // 2
  \\ , // 3
  \\ const // 4
  \\ b // 5
  \\ , // 6
  \\ _ // 7
  \\ = // 8
  \\ some.expr(that.is(cool, yeah)); // 9
  \\
  \\ _, // 1
  \\ const b, // 2
  \\ _ // 3
  \\ = // 4
  \\ some.expr(that.is(cool, yeah));
  \\
  \\ var a, // 1
  \\ var b // 2 
  \\ = some.expr(that.is(cool, yeah));
  \\
  \\ var a, var b, var c = // 1
  \\ some.expr(that.is(cool, yeah));
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo() void {
    \\  // this is true
    \\  const // 1
    \\  tkn // 2
    \\  , // 3
    \\  const // 4
    \\  node // 5
    \\  = // 6
    \\  self.tree.nodeData(n).opt_token_and_opt_node; // 7
    \\
    \\  var // 1
    \\  a // 2
    \\  , // 3
    \\  const // 4
    \\  b // 5
    \\  , // 6
    \\  _ // 7
    \\  = // 8
    \\  some.expr(that.is(cool, yeah)); // 9
    \\
    \\  _, // 1
    \\  const b, // 2
    \\  _ // 3
    \\  = // 4
    \\  some.expr(that.is(cool, yeah));
    \\
    \\  var a, // 1
    \\  var b // 2
    \\  = some.expr(that.is(cool, yeah));
    \\
    \\  var a, var b, var c = // 1
    \\  some.expr(that.is(cool, yeah));
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo() void {
    \\  // this is true
    \\  const // 1
    \\  tkn // 2
    \\  , // 3
    \\  const // 4
    \\  node // 5
    \\  = // 6
    \\  self
    \\    .tree
    \\    .nodeData(n)
    \\    .opt_token_and_opt_node; // 7
    \\
    \\  var // 1
    \\  a // 2
    \\  , // 3
    \\  const // 4
    \\  b // 5
    \\  , // 6
    \\  _ // 7
    \\  = // 8
    \\  some.expr(
    \\    that.is(cool, yeah),
    \\  ); // 9
    \\
    \\  _, // 1
    \\  const b, // 2
    \\  _ // 3
    \\  = // 4
    \\  some.expr(
    \\    that.is(cool, yeah),
    \\  );
    \\
    \\  var a, // 1
    \\  var b // 2
    \\  = some.expr(
    \\    that.is(cool, yeah),
    \\  );
    \\
    \\  var a, var b, var c = // 1
    \\  some.expr(
    \\    that.is(cool, yeah),
    \\  );
    \\}
  );
}

test "comments/assign-add" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() void {
  \\ // this is true
  \\ const // 1
  \\ tkn // 2
  \\ = // 3
  \\ self.tree.nodeData(n).opt_token_and_opt_node; // 4
  \\
  \\ var // 1
  \\ a // 2
  \\ = // 3
  \\ some.expr(that.is(cool, yeah)); // 4
  \\
  \\ _ // 1
  \\ = // 2
  \\ some.expr(that.is(cool, yeah));
  \\
  \\ var b // 1
  \\ = some.expr(that.is(cool, yeah));
  \\
  \\ var c = // 1
  \\ some.expr(that.is(cool, yeah));
  \\ }
  \\
  \\ fn foo() void {
  \\ // this is true
  \\ tkn // 2
  \\ += // 3
  \\ self.tree.nodeData(n).opt_token_and_opt_node; // 4
  \\
  \\ a // 2
  \\ += // 3
  \\ some.expr(that.is(cool, yeah)); // 4
  \\
  \\ _ // 1
  \\ += // 2
  \\ some.expr(that.is(cool, yeah));
  \\
  \\ b // 1
  \\ += some.expr(that.is(cool, yeah));
  \\
  \\ c += // 1
  \\ some.expr(that.is(cool, yeah));
  \\ }
  \\
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo() void {
    \\  // this is true
    \\  const // 1
    \\  tkn // 2
    \\  = // 3
    \\  self.tree.nodeData(n).opt_token_and_opt_node; // 4
    \\
    \\  var // 1
    \\  a // 2
    \\  = // 3
    \\  some.expr(that.is(cool, yeah)); // 4
    \\
    \\  _ // 1
    \\  = // 2
    \\  some.expr(that.is(cool, yeah));
    \\
    \\  var b // 1
    \\  = some.expr(that.is(cool, yeah));
    \\
    \\  var c = // 1
    \\  some.expr(that.is(cool, yeah));
    \\}
    \\
    \\fn foo() void {
    \\  // this is true
    \\  tkn // 2
    \\  += // 3
    \\  self.tree.nodeData(n).opt_token_and_opt_node; // 4
    \\
    \\  a // 2
    \\  += // 3
    \\  some.expr(that.is(cool, yeah)); // 4
    \\
    \\  _ // 1
    \\  += // 2
    \\  some.expr(that.is(cool, yeah));
    \\
    \\  b // 1
    \\  += some.expr(that.is(cool, yeah));
    \\
    \\  c += // 1
    \\  some.expr(that.is(cool, yeah));
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo() void {
    \\  // this is true
    \\  const // 1
    \\  tkn // 2
    \\  = // 3
    \\  self
    \\    .tree
    \\    .nodeData(n)
    \\    .opt_token_and_opt_node; // 4
    \\
    \\  var // 1
    \\  a // 2
    \\  = // 3
    \\  some.expr(
    \\    that.is(cool, yeah),
    \\  ); // 4
    \\
    \\  _ // 1
    \\  = // 2
    \\  some.expr(
    \\    that.is(cool, yeah),
    \\  );
    \\
    \\  var b // 1
    \\  = some.expr(
    \\    that.is(cool, yeah),
    \\  );
    \\
    \\  var c = // 1
    \\  some.expr(
    \\    that.is(cool, yeah),
    \\  );
    \\}
    \\
    \\fn foo() void {
    \\  // this is true
    \\  tkn // 2
    \\  += // 3
    \\  self
    \\    .tree
    \\    .nodeData(n)
    \\    .opt_token_and_opt_node; // 4
    \\
    \\  a // 2
    \\  += // 3
    \\  some.expr(
    \\    that.is(cool, yeah),
    \\  ); // 4
    \\
    \\  _ // 1
    \\  += // 2
    \\  some.expr(
    \\    that.is(cool, yeah),
    \\  );
    \\
    \\  b // 1
    \\  += some.expr(
    \\    that.is(cool, yeah),
    \\  );
    \\
    \\  c += // 1
    \\  some.expr(
    \\    that.is(cool, yeah),
    \\  );
    \\}
  );
}

test "comments/field-access" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() void {
  \\  var x = self.tree.nodeData1.nodeData2.nodeData3.nodeData4.nodeData5.nodeData6.opt_token_and_opt_node.opts.c_opts;
  \\  var x = self//1
  \\ .//2
  \\ tree// 3
  \\ .//4
  \\ nodeData1//5
  \\ .//6
  \\ nodeData2//7
  \\ .//8
  \\ nodeData3//9
  \\ .//10
  \\ nodeData4//11
  \\ .//12
  \\ nodeData5//13
  \\ .//14
  \\ nodeData6//15
  \\ .//16
  \\ opt_token_and_opt_node//17
  \\ .//18
  \\ opts//19
  \\ .//20
  \\ c_opts//21
  \\;
  \\var sb = self.db.xyz(
  \\  a,
  \\  b(),
  \\);
  \\  const // 4
  \\  node // 5
  \\  = // 6
  \\  self.tree.nodeData(n).opt_token_and_opt_node; // 7
  \\ }
  \\
  \\ fn foo() void {
  \\ // this is true
  \\ tkn // 2
  \\ += // 3
  \\ self.tree.nodeData(n) // a
  \\ . // b
  \\ opt_token_and_opt_node // c
  \\ ; // d
  \\
  \\ self.tree.nodeData(n) // a
  \\ . 
  \\ opt_token_and_opt_node // b
  \\ ; // c
  \\
  \\ self.tree.nodeData(n)
  \\ .  // a
  \\ opt_token_and_opt_node // b
  \\ ; // c
  \\
  \\ self.tree.nodeData(n) // 0
  \\ .  // a
  \\ opt_token_and_opt_node // b
  \\ . // c
  \\ opts // d
  \\ ;
  \\
  \\ self.tree.nodeData(n) // 0
  \\ .
  \\ opt_token_and_opt_node // a
  \\ .
  \\ opts() // b
  \\ ;
  \\
  \\ self.tree.nodeData(n) // 0
  \\ .
  \\ opt_token_and_opt_node // a
  \\ .
  \\ opts // b
  \\ .
  \\ c_opts // c
  \\ ;
  \\
  \\ }
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo() void {
    \\  var x = self
    \\    .tree
    \\    .nodeData1
    \\    .nodeData2
    \\    .nodeData3
    \\    .nodeData4
    \\    .nodeData5
    \\    .nodeData6
    \\    .opt_token_and_opt_node
    \\    .opts
    \\    .c_opts;
    \\  var x = self //1
    \\    . //2
    \\    tree // 3
    \\    . //4
    \\    nodeData1 //5
    \\    . //6
    \\    nodeData2 //7
    \\    . //8
    \\    nodeData3 //9
    \\    . //10
    \\    nodeData4 //11
    \\    . //12
    \\    nodeData5 //13
    \\    . //14
    \\    nodeData6 //15
    \\    . //16
    \\    opt_token_and_opt_node //17
    \\    . //18
    \\    opts //19
    \\    . //20
    \\    c_opts //21
    \\  ;
    \\  var sb = self.db.xyz(a, b());
    \\  const // 4
    \\  node // 5
    \\  = // 6
    \\  self.tree.nodeData(n).opt_token_and_opt_node; // 7
    \\}
    \\
    \\fn foo() void {
    \\  // this is true
    \\  tkn // 2
    \\  += // 3
    \\  self.tree.nodeData(n) // a
    \\  . // b
    \\  opt_token_and_opt_node // c
    \\  ; // d
    \\
    \\  self.tree.nodeData(n) // a
    \\  .opt_token_and_opt_node // b
    \\  ; // c
    \\
    \\  self.tree.nodeData(n). // a
    \\  opt_token_and_opt_node // b
    \\  ; // c
    \\
    \\  self.tree.nodeData(n) // 0
    \\  . // a
    \\  opt_token_and_opt_node // b
    \\  . // c
    \\  opts // d
    \\  ;
    \\
    \\  self.tree.nodeData(n) // 0
    \\  .opt_token_and_opt_node // a
    \\  .opts() // b
    \\  ;
    \\
    \\  self.tree.nodeData(n) // 0
    \\  .opt_token_and_opt_node // a
    \\  .opts // b
    \\  .c_opts // c
    \\  ;
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo() void {
    \\  var x = self
    \\    .tree
    \\    .nodeData1
    \\    .nodeData2
    \\    .nodeData3
    \\    .nodeData4
    \\    .nodeData5
    \\    .nodeData6
    \\    .opt_token_and_opt_node
    \\    .opts
    \\    .c_opts;
    \\  var x = self //1
    \\    . //2
    \\    tree // 3
    \\    . //4
    \\    nodeData1 //5
    \\    . //6
    \\    nodeData2 //7
    \\    . //8
    \\    nodeData3 //9
    \\    . //10
    \\    nodeData4 //11
    \\    . //12
    \\    nodeData5 //13
    \\    . //14
    \\    nodeData6 //15
    \\    . //16
    \\    opt_token_and_opt_node //17
    \\    . //18
    \\    opts //19
    \\    . //20
    \\    c_opts //21
    \\  ;
    \\  var sb = self.db.xyz(
    \\    a,
    \\    b(),
    \\  );
    \\  const // 4
    \\  node // 5
    \\  = // 6
    \\  self
    \\    .tree
    \\    .nodeData(n)
    \\    .opt_token_and_opt_node; // 7
    \\}
    \\
    \\fn foo() void {
    \\  // this is true
    \\  tkn // 2
    \\  += // 3
    \\  self
    \\    .tree
    \\    .nodeData(n) // a
    \\    . // b
    \\    opt_token_and_opt_node // c
    \\  ; // d
    \\
    \\  self
    \\    .tree
    \\    .nodeData(n) // a
    \\    .opt_token_and_opt_node // b
    \\  ; // c
    \\
    \\  self
    \\    .tree
    \\    .nodeData(n)
    \\    . // a
    \\    opt_token_and_opt_node // b
    \\  ; // c
    \\
    \\  self
    \\    .tree
    \\    .nodeData(n) // 0
    \\    . // a
    \\    opt_token_and_opt_node // b
    \\    . // c
    \\    opts // d
    \\  ;
    \\
    \\  self.tree.nodeData(n) // 0
    \\    .opt_token_and_opt_node // a
    \\    .opts() // b
    \\  ;
    \\
    \\  self
    \\    .tree
    \\    .nodeData(n) // 0
    \\    .opt_token_and_opt_node // a
    \\    .opts // b
    \\    .c_opts // c
    \\  ;
    \\}
  );
}

test "comments/binexpr" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo(bar: T) void {
  \\    var x: u3 = 5;
  \\    const a, _ = expr;
  \\   var j = a // 1
  \\ * // 2
  \\ b //3
  \\;
  \\   var j = a // 1
  \\ * // 2
  \\ b // 3
  \\ + // 4
  \\ 5 // 5
  \\ ;
  \\    var j = x // 1 
  \\ * // 2
  \\ x // 3
  \\ - // 4
  \\ (// 5
  \\ // top lvl opener
  \\ x // a
  \\ + // b
  \\ 5 // c
  \\ // bottom lvl closer
  \\ ) // 6
  \\ ;
  \\ foo(
  \\ a + 
  \\ 5 // c
  \\ // bottom lvl closer
  \\ ) // 6
  \\ ;
  \\  var j = x // 1 
  \\ * x - // 2
  \\ (x + 5) // 3
  \\ ;
  \\    var j = x * x - (x + 5) + k;
  \\   var x = 1 * foo + bar - car * booh - dah / boxMM * foom4 + barm3 * foom3 + barm2 * foom2 + barm1 * foom1 + bar0 * foo0 + bar1 * foo1 + bar2 * foo2 + //stable?
  \\ bar3 / boxN * foo;
  \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo + bar * foo + bar * foo + bar * foo + (bar  * foo + bar * // stable?
  \\ foo + bar * foo + bar * foo + bar * foo + bar / boxB * foo);
  \\  var x = 1 * foo + bar - car * booh - dah / boxB * foo + // stable?
  \\ bar * foo + bar * foo + bar * foo + (bar * foo + bar * foo + bar * foo + bar / boxB * foo * foo + bar / boxB * foo * foo + bar / boxB * foo);
  \\ var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) // a
  \\ * expr();
  \\ var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc( // a
  \\ 1, 2, 3) * expr() + 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3 // b
  \\ ) * expr();
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\  var x: u3 = 5;
    \\  const a, _ = expr;
    \\  var j = a // 1
    \\    * // 2
    \\    b //3
    \\  ;
    \\  var j = a // 1
    \\    * // 2
    \\    b // 3
    \\    + // 4
    \\    5 // 5
    \\  ;
    \\  var j = x // 1
    \\    * // 2
    \\    x // 3
    \\    - // 4
    \\    ( // 5
    \\      // top lvl opener
    \\      x // a
    \\        + // b
    \\        5 // c
    \\        // bottom lvl closer
    \\    ) // 6
    \\  ;
    \\  foo(
    \\    a + 5 // c
    \\      // bottom lvl closer
    \\  ) // 6
    \\  ;
    \\  var j = x // 1
    \\    * x - // 2
    \\    (x + 5) // 3
    \\  ;
    \\  var j = x * x - (x + 5) + k;
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxMM * foom4
    \\    + barm3 * foom3
    \\    + barm2 * foom2
    \\    + barm1 * foom1
    \\    + bar0 * foo0
    \\    + bar1 * foo1
    \\    + bar2 * foo2
    \\    + //stable?
    \\    bar3 / boxN * foo;
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\        + bar * // stable?
    \\          foo
    \\        + bar * foo
    \\        + bar * foo
    \\        + bar * foo
    \\        + bar / boxB * foo);
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + // stable?
    \\    bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo);
    \\  var abc = 5 * 4 + 3 - abc + 4 - 3 + someFunc(1, 2, 3) // a
    \\      * expr();
    \\  var abc = 5 * 4
    \\    + 3
    \\    - abc
    \\    + 4
    \\    - 3
    \\    + someFunc( // a
    \\      1,
    \\      2,
    \\      3,
    \\    ) * expr()
    \\    + 5 * 4
    \\    + 3
    \\    - abc
    \\    + 4
    \\    - 3
    \\    + someFunc(
    \\      1,
    \\      2,
    \\      3 // b
    \\    ) * expr();
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo(bar: T) void {
    \\  var x: u3 = 5;
    \\  const a, _ = expr;
    \\  var j = a // 1
    \\    * // 2
    \\    b //3
    \\  ;
    \\  var j = a // 1
    \\    * // 2
    \\    b // 3
    \\    + // 4
    \\    5 // 5
    \\  ;
    \\  var j = x // 1
    \\    * // 2
    \\    x // 3
    \\    - // 4
    \\    ( // 5
    \\      // top lvl opener
    \\      x // a
    \\        + // b
    \\        5 // c
    \\        // bottom lvl closer
    \\    ) // 6
    \\  ;
    \\  foo(
    \\    a
    \\      + 5 // c
    \\      // bottom lvl closer
    \\  ) // 6
    \\  ;
    \\  var j = x // 1
    \\    * x
    \\    - // 2
    \\    (x + 5) // 3
    \\  ;
    \\  var j = x * x - (x + 5) + k;
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxMM * foom4
    \\    + barm3 * foom3
    \\    + barm2 * foom2
    \\    + barm1 * foom1
    \\    + bar0 * foo0
    \\    + bar1 * foo1
    \\    + bar2 * foo2
    \\    + //stable?
    \\    bar3 / boxN * foo;
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\        + bar * // stable?
    \\          foo
    \\        + bar * foo
    \\        + bar * foo
    \\        + bar * foo
    \\        + bar / boxB * foo);
    \\  var x = 1 * foo
    \\    + bar
    \\    - car * booh
    \\    - dah / boxB * foo
    \\    + // stable?
    \\    bar * foo
    \\    + bar * foo
    \\    + bar * foo
    \\    + (bar * foo
    \\      + bar * foo
    \\      + bar * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo * foo
    \\      + bar / boxB * foo);
    \\  var abc = 5 * 4
    \\    + 3
    \\    - abc
    \\    + 4
    \\    - 3
    \\    + someFunc(1, 2, 3) // a
    \\      * expr();
    \\  var abc = 5 * 4
    \\    + 3
    \\    - abc
    \\    + 4
    \\    - 3
    \\    + someFunc( // a
    \\      1,
    \\      2,
    \\      3,
    \\    ) * expr()
    \\    + 5 * 4
    \\    + 3
    \\    - abc
    \\    + 4
    \\    - 3
    \\    + someFunc(
    \\      1,
    \\      2,
    \\      3 // b
    \\    ) * expr();
    \\}
  );
}

test "comments/try-catch" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var abc = try // my try
  \\ someFunc(1, 2, 3); // stuff
  \\ var abc = someTestFunc(try // again?
  \\ someFunc(1, 2, 3));
  \\ var abc = someTestFunc(try // 1
  \\ someFunc(1, 2, 3), try // 2
  \\ someFunc(1, 2, 3));
  \\
  \\ var abc = someFunc(1, 2, 3) catch // 1
  \\ | // 2
  \\ e // 3
  \\ | // 4
  \\ 5 // 5
  \\ ;
  \\ var abc = someFunc(1, 2, 3) catch // 1
  \\ expr();
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var abc = try // my try
    \\someFunc(1, 2, 3); // stuff
    \\var abc = someTestFunc(
    \\  try // again?
    \\  someFunc(1, 2, 3),
    \\);
    \\var abc = someTestFunc(
    \\  try // 1
    \\  someFunc(1, 2, 3),
    \\  try // 2
    \\  someFunc(1, 2, 3),
    \\);
    \\
    \\var abc = someFunc(1, 2, 3) catch // 1
    \\  | // 2
    \\  e // 3
    \\  | // 4
    \\  5 // 5
    \\;
    \\var abc = someFunc(1, 2, 3) catch // 1
    \\  expr();
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var abc = try // my try
    \\someFunc(1, 2, 3); // stuff
    \\var abc = someTestFunc(
    \\  try // again?
    \\  someFunc(1, 2, 3),
    \\);
    \\var abc = someTestFunc(
    \\  try // 1
    \\  someFunc(1, 2, 3),
    \\  try // 2
    \\  someFunc(1, 2, 3),
    \\);
    \\
    \\var abc = someFunc(1, 2, 3)
    \\  catch // 1
    \\  | // 2
    \\  e // 3
    \\  | // 4
    \\  5 // 5
    \\;
    \\var abc = someFunc(1, 2, 3)
    \\  catch // 1
    \\  expr();
  );
}

test "comments/orelse" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var abc = someFunc(1, 2, 3) orelse // 1
  \\ return;
  \\ var abc = someFunc(1, 2, 3) orelse // 1
  \\ {
  \\   someBlock();
  \\ };
  \\ var abc = someFunc(1, 2, 3) orelse // 1
  \\ blk: {
  \\   someBlock();
  \\   break :blk result("okay");
  \\ };
  \\ var abc = someFunc(1, 2, 3) // 0
  \\ catch // 1
  \\ {
  \\   someBlock();
  \\ };
  \\ var abc = someFunc(1, 2, 3) // 0
  \\ orelse // 1
  \\ {
  \\   someBlock();
  \\ };
  \\ var abc = someFunc(1, 2, 3) orelse // x
  \\ blk: // y
  \\ {
  \\   someBlock();
  \\   break :blk result("okay");
  \\ };
  \\var abc = 5 * 4
  \\  + 3
  \\  - abc
  \\  + 4
  \\  - 3
  \\  + (someFunc(1, 2, 3)
  \\    orelse // a
  \\ expr());
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var abc = someFunc(1, 2, 3) orelse // 1
    \\  return;
    \\var abc = someFunc(1, 2, 3) orelse // 1
    \\  {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) orelse // 1
    \\  blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = someFunc(1, 2, 3) // 0
    \\  catch // 1
    \\  {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) // 0
    \\  orelse // 1
    \\  {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) orelse // x
    \\  blk: // y
    \\  {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = 5 * 4 + 3 - abc + 4 - 3 + (someFunc(1, 2, 3) orelse // a
    \\      expr());
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var abc = someFunc(1, 2, 3)
    \\  orelse // 1
    \\  return;
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) orelse // 1
    \\  {
    \\  someBlock();
    \\};
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) orelse // 1
    \\  blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) // 0
    \\  catch // 1
    \\  {
    \\  someBlock();
    \\};
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) // 0
    \\  orelse // 1
    \\  {
    \\  someBlock();
    \\};
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) orelse // x
    \\  blk: // y
    \\  {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + (someFunc(1, 2, 3)
    \\      orelse // a
    \\      expr());
  );
}

test "comments/addressop-optional" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var x = & // a
  \\ foo(1, 2, 3);
  \\
  \\ var x = // abc
  \\ & // def
  \\ foo(1, 2, 3);
  \\
  \\ var x = ? // a
  \\ foo(1, 2, 3);
  \\
  \\ var x = // abc
  \\ ? // def
  \\ foo(1, 2, 3);
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var x = & // a
    \\foo(1, 2, 3);
    \\
    \\var x = // abc
    \\& // def
    \\foo(1, 2, 3);
    \\
    \\var x = ? // a
    \\foo(1, 2, 3);
    \\
    \\var x = // abc
    \\? // def
    \\foo(1, 2, 3);
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var x = & // a
    \\foo(1, 2, 3);
    \\
    \\var x = // abc
    \\& // def
    \\foo(1, 2, 3);
    \\
    \\var x = ? // a
    \\foo(1, 2, 3);
    \\
    \\var x = // abc
    \\? // def
    \\foo(1, 2, 3);
  );
}

test "comments/pointer-type 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var j: [// 1
  \\ * // 2
  \\ ] // 3
  \\ align // 4
  \\ ( // 5 - opener
  \\ // toplevel
  \\ foo(bar.oop(0x12))  // inner
  \\ ) // 6 - closer
  \\ rhs // 7
  \\ = 0xff;
  \\
  \\ var j: * // 1
  \\ align // 2
  \\ ( // 3
  \\ // headers
  \\ foo(bar.oop(0x12)) // 4
  \\ : // 5
  \\ Foo() // 6
  \\ : // 7
  \\ Bar() // 8
  \\ ) // 9
  \\ rhs // 10 
  \\ = 0xff;
  \\
  \\ var y: [ // a
  \\ ] // b
  \\ const rhs = 0xff;
  \\
  \\ var j: *align( // 1
  \\ foo:Car:Bar
  \\ // 2
  \\ ) rhs = 0xff;
  \\
  \\ var j: *align(foo():Car():Bar()) // 1
  \\ rhs // 2
  \\ = 0xff;
  \\
  \\ var x: *align( // 1
  \\ foo("ok") // 2
  \\ ) // 3
  \\ rhs = 0xff;
  \\
  \\ var a: ** // 1
  \\ rhs = 0xff;
  \\
  \\ var abc: *** // 1
  \\ align(foo():Car():Bar()) rhs = 0xff;
  \\
  \\ var xyz: ** // 1
  \\ align // 2
  \\ (foo():Car():Bar()) // 3
  \\ rhs = 0xff;
  \\
  \\ var a: * // 0
  \\ ** // 1
  \\ rhs // 2
  \\ = 0xff;
  \\
  \\ var y: [
  \\ ]
  \\ const // 3
  \\ rhs // 4
  \\ = 0xff;
  \\
  \\ var y: [ // 1
  \\ ] // 2
  \\ const // 3
  \\ rhs // 4
  \\ = 0xff;
  \\
  \\ var k: [ // 1
  \\ * // 2
  \\ : // 3
  \\ lhs // 4
  \\ ] // 5
  \\ rhs // 6
  \\ = 0xff;
  \\
  \\ var a: [ // 1
  \\ : // 2
  \\ lhs // 3
  \\ ]rhs // 4
  \\ = 0xff;
  \\
  \\ var j: [lhs:Foo(T, K) // 1
  \\ ] rhs // 2
  \\ = 0xff;
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var j: [ // 1
    \\  * // 2
    \\] // 3
    \\align // 4
    \\( // 5 - opener
    \\  // toplevel
    \\  foo(bar.oop(0x12)) // inner
    \\) // 6 - closer
    \\  rhs // 7
    \\= 0xff;
    \\
    \\var j: * // 1
    \\align // 2
    \\( // 3
    \\  // headers
    \\  foo(bar.oop(0x12)) // 4
    \\    : // 5
    \\    Foo() // 6
    \\    : // 7
    \\    Bar() // 8
    \\) // 9
    \\  rhs // 10
    \\= 0xff;
    \\
    \\var y: [ // a
    \\] // b
    \\const rhs = 0xff;
    \\
    \\var j: *align( // 1
    \\  foo:Car:Bar
    \\  // 2
    \\) rhs = 0xff;
    \\
    \\var j: *align(foo():Car():Bar()) // 1
    \\rhs // 2
    \\= 0xff;
    \\
    \\var x: *align( // 1
    \\  foo("ok") // 2
    \\) // 3
    \\rhs = 0xff;
    \\
    \\var a: ** // 1
    \\rhs = 0xff;
    \\
    \\var abc: *** // 1
    \\align(foo():Car():Bar()) rhs = 0xff;
    \\
    \\var xyz: ** // 1
    \\align // 2
    \\(foo():Car():Bar()) // 3
    \\rhs = 0xff;
    \\
    \\var a: * // 0
    \\** // 1
    \\rhs // 2
    \\= 0xff;
    \\
    \\var y: []const // 3
    \\rhs // 4
    \\= 0xff;
    \\
    \\var y: [ // 1
    \\] // 2
    \\const // 3
    \\rhs // 4
    \\= 0xff;
    \\
    \\var k: [ // 1
    \\  * // 2
    \\  : // 3
    \\  lhs // 4
    \\] // 5
    \\rhs // 6
    \\= 0xff;
    \\
    \\var a: [ // 1
    \\  : // 2
    \\  lhs // 3
    \\]rhs // 4
    \\= 0xff;
    \\
    \\var j: [
    \\  lhs:Foo(T, K) // 1
    \\]rhs // 2
    \\= 0xff;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var j: [ // 1
    \\  * // 2
    \\] // 3
    \\align // 4
    \\( // 5 - opener
    \\  // toplevel
    \\  foo(bar.oop(0x12)) // inner
    \\) // 6 - closer
    \\  rhs // 7
    \\= 0xff;
    \\
    \\var j: * // 1
    \\align // 2
    \\( // 3
    \\  // headers
    \\  foo(bar.oop(0x12)) // 4
    \\    : // 5
    \\    Foo() // 6
    \\    : // 7
    \\    Bar() // 8
    \\) // 9
    \\  rhs // 10
    \\= 0xff;
    \\
    \\var y: [ // a
    \\] // b
    \\const rhs = 0xff;
    \\
    \\var j: *align( // 1
    \\  foo
    \\    :Car
    \\    :Bar
    \\    // 2
    \\)
    \\  rhs = 0xff;
    \\
    \\var j: *align(
    \\  foo()
    \\    :Car()
    \\    :Bar()
    \\) // 1
    \\  rhs // 2
    \\= 0xff;
    \\
    \\var x: *align( // 1
    \\  foo("ok") // 2
    \\) // 3
    \\  rhs = 0xff;
    \\
    \\var a: ** // 1
    \\rhs = 0xff;
    \\
    \\var abc: *** // 1
    \\align(foo():Car():Bar())
    \\  rhs = 0xff;
    \\
    \\var xyz: ** // 1
    \\align // 2
    \\(
    \\  foo()
    \\    :Car()
    \\    :Bar()
    \\) // 3
    \\  rhs = 0xff;
    \\
    \\var a: * // 0
    \\** // 1
    \\rhs // 2
    \\= 0xff;
    \\
    \\var y: []const // 3
    \\rhs // 4
    \\= 0xff;
    \\
    \\var y: [ // 1
    \\] // 2
    \\const // 3
    \\rhs // 4
    \\= 0xff;
    \\
    \\var k: [ // 1
    \\  * // 2
    \\  : // 3
    \\  lhs // 4
    \\] // 5
    \\rhs // 6
    \\= 0xff;
    \\
    \\var a: [ // 1
    \\  : // 2
    \\  lhs // 3
    \\]rhs // 4
    \\= 0xff;
    \\
    \\var j: [
    \\  lhs:Foo(T, K) // 1
    \\]rhs // 2
    \\= 0xff;
  );
}

test "comments/pointer-type 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var j: [lhs
  \\ : // only
  \\ Foo(T, K)] rhs = 0xff;
  \\
  \\var j: [lhs:Foo(T, K)]Foo( // cas
  \\ Bar.xyz(abc)) = 0xff;
  \\
  \\var j: [ // 1
  \\ *
  \\ c 
  \\ ]align( // 2
  \\ foo(bar.oop(0x12))) rhs // 3
  \\ = 0xff;
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var j: [
    \\  lhs: // only
    \\  Foo(T, K)
    \\]rhs = 0xff;
    \\
    \\var j: [lhs:Foo(T, K)]Foo( // cas
    \\  Bar.xyz(abc),
    \\) = 0xff;
    \\
    \\var j: [ // 1
    \\  *c
    \\]align( // 2
    \\  foo(bar.oop(0x12))
    \\) rhs // 3
    \\= 0xff;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var j: [
    \\  lhs: // only
    \\  Foo(T, K)
    \\]rhs = 0xff;
    \\
    \\var j: [
    \\  lhs:Foo(T, K)
    \\]Foo( // cas
    \\  Bar.xyz(abc),
    \\) = 0xff;
    \\
    \\var j: [ // 1
    \\  *c
    \\]align( // 2
    \\  foo(bar.oop(0x12))
    \\)
    \\  rhs // 3
    \\= 0xff;
  );
}

test "comments/pointer-type 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var x: * // 1
  \\ allowzero // 2
  \\ align( // 3
  \\ foo("ok")) Rhs // 4
  \\ align(64 // 5
  \\ ) addrspace // 5b
  \\ (// 6
  \\ .generic) // 6b
  \\ linksection( // 7
  \\ ".my_custom_section" // 8
  \\ ) // 9 
  \\ = undefined;
  \\
  \\ var x: *allowzero // 1
  \\ align(foo("ok")) // 2
  \\ Rhs // 3
  \\ = 0xff;
  \\
  \\ var x: * // 1
  \\ allowzero // 2
  \\ addrspace // 2b
  \\ ( // 2c
  \\ // hey
  \\ Foo(Bar())
  \\ // hah
  \\ ) // 3
  \\ align(foo("ok")) // 4
  \\ Rhs = 0xff;
  \\ 
  \\ var x1: * // 1
  \\ allowzero // 2
  \\ addrspace(Foo(Bar())) // 4
  \\ align(foo("ok")) // 3
  \\ Rhs = 0xff;
  \\ 
  \\ var x2: ** // 1
  \\ allowzero // 2
  \\ addrspace(Foo(Bar())) // 4
  \\ align(foo("ok")) // 3
  \\ Rhs = 0xff;
  \\ 
  \\ var x3: *** // 1
  \\ allowzero // 2
  \\ addrspace(Foo(Bar())) // 4
  \\ align(foo("ok")) // 3
  \\ Rhs = 0xff;
  \\ 
  \\ var x4: **** // 1
  \\ allowzero // 2
  \\ addrspace(Foo(Bar())) // 4
  \\ align(foo("ok")) // 3
  \\ Rhs = 0xff;
  \\ 
  \\ var xt: *allowzero addrspace(Foo(Bar())) align(foo("ok")) // 1
  \\ const Rhs = 0xff;
  \\ 
  \\ var xt2: *allowzero align(foo("ok")) addrspace(Foo(Bar())) // 1
  \\ const Rhs = 0xff;
  \\ 
  \\ var xt3: *allowzero align(foo("ok")) addrspace(Foo(Bar()))
  \\ const Rhs = 0xff;
  \\ 
  \\ var xy: *allowzero // 1
  \\ addrspace(Foo(Bar())) align(foo("ok")) volatile const // 2
  \\ Rhs = 0xff;
  \\
  \\ var xv: * volatile // 0
  \\ allowzero // 1
  \\ addrspace(Foo(Bar())) align(foo("ok")) const // 2
  \\ Rhs = 0xff;
  \\
  \\ var xv2: * // a
  \\ volatile // 0
  \\ allowzero // 1
  \\ addrspace(Foo(Bar())) align(foo("ok")) const // 2
  \\ Rhs = 0xff;
  \\ 
  \\ var xv3: ** // a
  \\ volatile // 0
  \\ allowzero // 1
  \\ addrspace(Foo(Bar())) align(foo("ok")) const // 2
  \\ Rhs = 0xff;
  \\ 
  \\ var xv4: ** // a
  \\ volatile // 0
  \\ allowzero
  \\ addrspace(Foo(Bar())) align(foo("ok")) const // 2
  \\ Rhs = 0xff;
  \\ 
  \\ var xk: *allowzero // 1
  \\ addrspace(Foo(Bar())) align(foo("ok")) volatile // 2
  \\ const // 3
  \\ Rhs = 0xff;
  \\ 
  \\ var x: *allowzero addrspace(Foo(Bar())) align(foo("ok")) // 1
  \\ volatile const // 2
  \\ Foo(Bar.xyz(abc)) // 3
  \\ = 0xff;
  \\
  \\ var x: *allowzero addrspace(Foo(Bar())) align(foo("ok")) // 0
  \\ volatile // 1
  \\ const // 2
  \\ Foo(Bar.xyz(abc)) // 3
  \\ = 0xff;
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var x: * // 1
    \\allowzero // 2
    \\align( // 3
    \\  foo("ok")
    \\) Rhs // 4
    \\  align(
    \\    64 // 5
    \\  )
    \\  addrspace // 5b
    \\  ( // 6
    \\    .generic
    \\  ) // 6b
    \\  linksection( // 7
    \\    ".my_custom_section" // 8
    \\  ) // 9
    \\= undefined;
    \\
    \\var x: *allowzero // 1
    \\align(foo("ok")) // 2
    \\Rhs // 3
    \\= 0xff;
    \\
    \\var x: * // 1
    \\allowzero // 2
    \\  align(foo("ok")) // 4
    \\  addrspace // 2b
    \\  ( // 2c
    \\    // hey
    \\    Foo(Bar())
    \\    // hah
    \\  ) // 3
    \\  Rhs = 0xff;
    \\
    \\var x1: * // 1
    \\allowzero // 2
    \\  align(foo("ok")) // 3
    \\  addrspace(Foo(Bar())) // 4
    \\  Rhs = 0xff;
    \\
    \\var x2: ** // 1
    \\allowzero // 2
    \\  align(foo("ok")) // 3
    \\  addrspace(Foo(Bar())) // 4
    \\  Rhs = 0xff;
    \\
    \\var x3: *** // 1
    \\allowzero // 2
    \\  align(foo("ok")) // 3
    \\  addrspace(Foo(Bar())) // 4
    \\  Rhs = 0xff;
    \\
    \\var x4: **** // 1
    \\allowzero // 2
    \\  align(foo("ok")) // 3
    \\  addrspace(Foo(Bar())) // 4
    \\  Rhs = 0xff;
    \\
    \\var xt: *allowzero align(foo("ok")) // 1
    \\addrspace(Foo(Bar())) const Rhs = 0xff;
    \\
    \\var xt2: *allowzero align(foo("ok")) addrspace(Foo(Bar())) // 1
    \\const Rhs = 0xff;
    \\
    \\var xt3: *allowzero align(foo("ok")) addrspace(Foo(Bar())) const Rhs = 0xff;
    \\
    \\var xy: *allowzero // 1
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile Rhs = 0xff;
    \\
    \\var xv: *allowzero // 1
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile // 0
    \\  Rhs = 0xff;
    \\
    \\var xv2: * // a
    \\allowzero // 1
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile // 0
    \\  Rhs = 0xff;
    \\
    \\var xv3: ** // a
    \\allowzero // 1
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile // 0
    \\  Rhs = 0xff;
    \\
    \\var xv4: ** // a
    \\allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile // 0
    \\  Rhs = 0xff;
    \\
    \\var xk: *allowzero // 1
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 3
    \\  volatile // 2
    \\  Rhs = 0xff;
    \\
    \\var x: *allowzero
    \\  align(foo("ok")) // 1
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile Foo(Bar.xyz(abc)) // 3
    \\= 0xff;
    \\
    \\var x: *allowzero
    \\  align(foo("ok")) // 0
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile // 1
    \\  Foo(Bar.xyz(abc)) // 3
    \\= 0xff;
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var x: * // 1
    \\allowzero // 2
    \\  align( // 3
    \\    foo("ok")
    \\  )
    \\  Rhs // 4
    \\  align(
    \\    64 // 5
    \\  )
    \\  addrspace // 5b
    \\  ( // 6
    \\    .generic
    \\  ) // 6b
    \\  linksection( // 7
    \\    ".my_custom_section" // 8
    \\  ) // 9
    \\= undefined;
    \\
    \\var x: *allowzero // 1
    \\  align(foo("ok")) // 2
    \\  Rhs // 3
    \\= 0xff;
    \\
    \\var x: * // 1
    \\allowzero // 2
    \\  align(foo("ok")) // 4
    \\  addrspace // 2b
    \\  ( // 2c
    \\    // hey
    \\    Foo(Bar())
    \\    // hah
    \\  ) // 3
    \\  Rhs = 0xff;
    \\
    \\var x1: * // 1
    \\allowzero // 2
    \\  align(foo("ok")) // 3
    \\  addrspace(Foo(Bar())) // 4
    \\  Rhs = 0xff;
    \\
    \\var x2: ** // 1
    \\allowzero // 2
    \\  align(foo("ok")) // 3
    \\  addrspace(Foo(Bar())) // 4
    \\  Rhs = 0xff;
    \\
    \\var x3: *** // 1
    \\allowzero // 2
    \\  align(foo("ok")) // 3
    \\  addrspace(Foo(Bar())) // 4
    \\  Rhs = 0xff;
    \\
    \\var x4: **** // 1
    \\allowzero // 2
    \\  align(foo("ok")) // 3
    \\  addrspace(Foo(Bar())) // 4
    \\  Rhs = 0xff;
    \\
    \\var xt: *allowzero
    \\  align(foo("ok")) // 1
    \\  addrspace(Foo(Bar()))
    \\  const Rhs = 0xff;
    \\
    \\var xt2: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar())) // 1
    \\  const Rhs = 0xff;
    \\
    \\var xt3: *allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const Rhs = 0xff;
    \\
    \\var xy: *allowzero // 1
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile
    \\  Rhs = 0xff;
    \\
    \\var xv: *allowzero // 1
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile // 0
    \\  Rhs = 0xff;
    \\
    \\var xv2: * // a
    \\allowzero // 1
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile // 0
    \\  Rhs = 0xff;
    \\
    \\var xv3: ** // a
    \\allowzero // 1
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile // 0
    \\  Rhs = 0xff;
    \\
    \\var xv4: ** // a
    \\allowzero
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile // 0
    \\  Rhs = 0xff;
    \\
    \\var xk: *allowzero // 1
    \\  align(foo("ok"))
    \\  addrspace(Foo(Bar()))
    \\  const // 3
    \\  volatile // 2
    \\  Rhs = 0xff;
    \\
    \\var x: *allowzero
    \\  align(foo("ok")) // 1
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile
    \\  Foo(Bar.xyz(abc)) // 3
    \\= 0xff;
    \\
    \\var x: *allowzero
    \\  align(foo("ok")) // 0
    \\  addrspace(Foo(Bar()))
    \\  const // 2
    \\  volatile // 1
    \\  Foo(Bar.xyz(abc)) // 3
    \\= 0xff;
  );
}

test "comments/pointer-type 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ var j: [
  \\ * // 2
  \\ ] // 3
  \\ allowzero
  \\ align // 4
  \\ ( // 5 - opener
  \\ // toplevel
  \\ foo(bar.oop(0x12))  // inner
  \\ ) // 6 - closer
  \\ rhs // 7
  \\ = 0xff;
  \\
  \\ fn foo() * // 1
  \\ allowzero // 2
  \\ align // 2b
  \\ (foo("ok")) // 3
  \\ Rhs {
  \\   return 0;
  \\}
  \\ fn foo() *allowzero // 1
  \\ addrspace(Foo(Bar())) // 2
  \\ align(foo("ok")) // 3
  \\ volatile // 4
  \\ const // 5
  \\ Foo(Bar.xyz(abc)) //6
  \\ {
  \\   return 0;
  \\}
  \\ fn foo(abc: *allowzero addrspace(Foo(Bar())) align(foo("ok")) // 1
  \\ volatile const Foo(Bar.xyz(abc))) *allowzero align(foo("ok")) // 2
  \\ Rhs {
  \\   return 0;
  \\}
  \\ fn foo(abc: *allowzero addrspace // 1
  \\ (Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc))) *allowzero addrspace(Foo(Bar())) align(foo("ok") // 2
  \\ ) volatile const Foo(Bar.xyz(abc)) {
  \\   return 0;
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var j: [
    \\  * // 2
    \\] // 3
    \\allowzero
    \\  align // 4
    \\  ( // 5 - opener
    \\    // toplevel
    \\    foo(bar.oop(0x12)) // inner
    \\  ) // 6 - closer
    \\  rhs // 7
    \\= 0xff;
    \\
    \\fn foo() * // 1
    \\allowzero // 2
    \\align // 2b
    \\(foo("ok")) // 3
    \\Rhs {
    \\  return 0;
    \\}
    \\fn foo() *allowzero // 1
    \\  align(foo("ok")) // 3
    \\  addrspace(Foo(Bar())) // 2
    \\  const // 5
    \\  volatile // 4
    \\  Foo(Bar.xyz(abc)) //6
    \\{
    \\  return 0;
    \\}
    \\fn foo(
    \\  abc: *allowzero
    \\    align(foo("ok")) // 1
    \\    addrspace(Foo(Bar()))
    \\    const volatile Foo(Bar.xyz(abc)),
    \\) *allowzero align(foo("ok")) // 2
    \\Rhs {
    \\  return 0;
    \\}
    \\fn foo(
    \\  abc: *allowzero
    \\    align(foo("ok"))
    \\    addrspace // 1
    \\    (Foo(Bar()))
    \\    const volatile Foo(Bar.xyz(abc)),
    \\) *allowzero
    \\  align(
    \\    foo("ok") // 2
    \\  )
    \\  addrspace(Foo(Bar()))
    \\  const volatile Foo(Bar.xyz(abc)) {
    \\  return 0;
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\var j: [
    \\  * // 2
    \\] // 3
    \\allowzero
    \\  align // 4
    \\  ( // 5 - opener
    \\    // toplevel
    \\    foo(
    \\      bar.oop(0x12),
    \\    ) // inner
    \\  ) // 6 - closer
    \\  rhs // 7
    \\= 0xff;
    \\
    \\fn foo() * // 1
    \\allowzero // 2
    \\  align // 2b
    \\  (foo("ok")) // 3
    \\  Rhs {
    \\  return 0;
    \\}
    \\fn foo() *allowzero // 1
    \\  align(foo("ok")) // 3
    \\  addrspace(Foo(Bar())) // 2
    \\  const // 5
    \\  volatile // 4
    \\  Foo(Bar.xyz(abc)) //6
    \\{
    \\  return 0;
    \\}
    \\fn foo(
    \\  abc: *allowzero
    \\    align(foo("ok")) // 1
    \\    addrspace(Foo(Bar()))
    \\    const volatile
    \\    Foo(Bar.xyz(abc)),
    \\) *allowzero
    \\  align(foo("ok")) // 2
    \\  Rhs {
    \\  return 0;
    \\}
    \\fn foo(
    \\  abc: *allowzero
    \\    align(foo("ok"))
    \\    addrspace // 1
    \\    (Foo(Bar()))
    \\    const volatile
    \\    Foo(Bar.xyz(abc)),
    \\) *allowzero
    \\  align(
    \\    foo("ok") // 2
    \\  )
    \\  addrspace(Foo(Bar()))
    \\  const volatile
    \\  Foo(Bar.xyz(abc)) {
    \\  return 0;
    \\}
  );
}

test "comments/doc-comment 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ /// This is a doc comment 1
  \\ // abc
  \\ // xyz
  \\ /// This is a doc comment 2
  \\ fn foo() void {
  \\   testOne();
  \\ }
  \\
  \\ /// first T
  \\ const T = struct {
  \\ /// the mem member
  \\  mem: u8,
  \\
  \\ /// the x member
  \\  x: u8,
  \\ /// the y member
  \\  y: u8,
  \\
  \\ /// This function does nothing
  \\ pub fn foo() void {}
  \\
  \\};
  \\ 
  \\ /// my stuff
  \\ x: usize,
  \\ 
  \\ /// my stuff y
  \\ y: usize,
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\/// This is a doc comment 1
    \\// abc
    \\// xyz
    \\/// This is a doc comment 2
    \\fn foo() void {
    \\  testOne();
    \\}
    \\
    \\/// first T
    \\const T = struct {
    \\  /// the mem member
    \\  mem: u8,
    \\
    \\  /// the x member
    \\  x: u8,
    \\  /// the y member
    \\  y: u8,
    \\
    \\  /// This function does nothing
    \\  pub fn foo() void {}
    \\};
    \\
    \\/// my stuff
    \\x: usize,
    \\
    \\/// my stuff y
    \\y: usize,
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\/// This is a doc comment 1
    \\// abc
    \\// xyz
    \\/// This is a doc comment 2
    \\fn foo() void {
    \\  testOne();
    \\}
    \\
    \\/// first T
    \\const T = struct {
    \\  /// the mem member
    \\  mem: u8,
    \\
    \\  /// the x member
    \\  x: u8,
    \\  /// the y member
    \\  y: u8,
    \\
    \\  /// This function does nothing
    \\  pub fn foo() void {}
    \\};
    \\
    \\/// my stuff
    \\x: usize,
    \\
    \\/// my stuff y
    \\y: usize,
  );
}

test "comments/doc-comment 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ /// first T
  \\ const T = struct {
  \\ /// the mem member
  \\  mem: u8, // abc
  \\
  \\
  \\
  \\ /// the x member
  \\  x: u8,
  \\ /// the y member
  \\  y: u8,
  \\
  \\ /// This function does nothing
  \\ pub fn foo() void {}
  \\
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\/// first T
    \\const T = struct {
    \\  /// the mem member
    \\  mem: u8, // abc
    \\
    \\  /// the x member
    \\  x: u8,
    \\  /// the y member
    \\  y: u8,
    \\
    \\  /// This function does nothing
    \\  pub fn foo() void {}
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\/// first T
    \\const T = struct {
    \\  /// the mem member
    \\  mem: u8, // abc
    \\
    \\  /// the x member
    \\  x: u8,
    \\  /// the y member
    \\  y: u8,
    \\
    \\  /// This function does nothing
    \\  pub fn foo() void {}
    \\};
  );
}

test "comments/doc-comment 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ /// first T
  \\ const T = struct {
  \\ /// the mem member
  \\  mem: u8, // abc
  \\        xyz: usize,
  \\
  \\ /// the x member
  \\  x: u8,
  \\ /// the y member
  \\  y: u8,
  \\
  \\ /// This function does nothing
  \\ pub fn foo() void {}
  \\
  \\ fn foo() void {   testOne(); }
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\/// first T
    \\const T = struct {
    \\  /// the mem member
    \\  mem: u8, // abc
    \\  xyz: usize,
    \\
    \\  /// the x member
    \\  x: u8,
    \\  /// the y member
    \\  y: u8,
    \\
    \\  /// This function does nothing
    \\  pub fn foo() void {}
    \\
    \\  fn foo() void {
    \\    testOne();
    \\  }
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\/// first T
    \\const T = struct {
    \\  /// the mem member
    \\  mem: u8, // abc
    \\  xyz: usize,
    \\
    \\  /// the x member
    \\  x: u8,
    \\  /// the y member
    \\  y: u8,
    \\
    \\  /// This function does nothing
    \\  pub fn foo() void {}
    \\
    \\  fn foo() void {
    \\    testOne();
    \\  }
    \\};
  );
}

test "comments/doc-comment 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo(
  \\ /// The first param, x
  \\ x:u32,
  \\ /// The second param, y
  \\ y:usize,
  \\ /// The third param, z 
  \\ z: usize,
  \\ /// The last param, varargs 
  \\ ..., // abc
  \\ ) void { if (last_tkn) |tkn| flat.decllineIf(self.tknHasTC(tkn))._();}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo(
    \\  /// The first param, x
    \\  x: u32,
    \\  /// The second param, y
    \\  y: usize,
    \\  /// The third param, z
    \\  z: usize,
    \\  /// The last param, varargs
    \\  ..., // abc
    \\) void {
    \\  if (last_tkn) |tkn| flat.decllineIf(self.tknHasTC(tkn))._();
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo(
    \\  /// The first param, x
    \\  x: u32,
    \\  /// The second param, y
    \\  y: usize,
    \\  /// The third param, z
    \\  z: usize,
    \\  /// The last param, varargs
    \\  ..., // abc
    \\) void {
    \\  if (last_tkn) |tkn|
    \\    flat.decllineIf(
    \\      self.tknHasTC(tkn),
    \\    )
    \\      ._();
    \\}
  );
}

test "comments/mint-off-on 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ // mint fmt: off
  \\ // xyz
  \\ /// This is a doc comment 2
  \\ fn foo() void {   testOne(); }
  \\
  \\ /// first T
  \\ const T = struct {
  \\ /// the mem member
  \\  mem: u8, // abc
  \\        xyz: usize,
  \\
  \\ /// the x member
  \\  x: u8,
  \\ /// the y member
  \\  y: u8,
  \\
  \\ /// This function does nothing
  \\ pub fn foo() void {}
  \\
  \\ fn foo() void {   testOne(); }
  \\};
  \\
  \\ /// my stuff
  \\ x: usize,
  \\
  \\ /// my stuff y
  \\ y: usize,
  \\
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\// mint fmt: off
    \\ // xyz
    \\ /// This is a doc comment 2
    \\ fn foo() void {   testOne(); }
    \\
    \\ /// first T
    \\ const T = struct {
    \\ /// the mem member
    \\  mem: u8, // abc
    \\        xyz: usize,
    \\
    \\ /// the x member
    \\  x: u8,
    \\ /// the y member
    \\  y: u8,
    \\
    \\ /// This function does nothing
    \\ pub fn foo() void {}
    \\
    \\ fn foo() void {   testOne(); }
    \\};
    \\
    \\ /// my stuff
    \\ x: usize,
    \\
    \\ /// my stuff y
    \\ y: usize,
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\// mint fmt: off
    \\ // xyz
    \\ /// This is a doc comment 2
    \\ fn foo() void {   testOne(); }
    \\
    \\ /// first T
    \\ const T = struct {
    \\ /// the mem member
    \\  mem: u8, // abc
    \\        xyz: usize,
    \\
    \\ /// the x member
    \\  x: u8,
    \\ /// the y member
    \\  y: u8,
    \\
    \\ /// This function does nothing
    \\ pub fn foo() void {}
    \\
    \\ fn foo() void {   testOne(); }
    \\};
    \\
    \\ /// my stuff
    \\ x: usize,
    \\
    \\ /// my stuff y
    \\ y: usize,
  );
}

test "comments/mint-off-on 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ // mint fmt: off
  \\ // xyz
  \\ /// This is a doc comment 2
  \\ fn foo() void {   testOne(); }
  \\
  \\ /// first T
  \\ const T = struct {
  \\ /// the mem member
  \\  mem: u8, // abc
  \\ // mint fmt: on
  \\        xyz: usize,
  \\
  \\ /// the x member
  \\  x: u8,
  \\ /// the y member
  \\  y: u8,
  \\
  \\ /// This function does nothing
  \\ pub fn foo() void {}
  \\
  \\ fn foo() void {   testOne(); }
  \\};
  \\
  \\ /// my stuff
  \\ x: usize,
  \\
  \\ /// my stuff y
  \\ y: usize,
  \\
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\// mint fmt: off
    \\ // xyz
    \\ /// This is a doc comment 2
    \\ fn foo() void {   testOne(); }
    \\
    \\ /// first T
    \\ const T = struct {
    \\ /// the mem member
    \\  mem: u8, // abc
    \\  // mint fmt: on
    \\  xyz: usize,
    \\
    \\  /// the x member
    \\  x: u8,
    \\  /// the y member
    \\  y: u8,
    \\
    \\  /// This function does nothing
    \\  pub fn foo() void {}
    \\
    \\  fn foo() void {
    \\    testOne();
    \\  }
    \\};
    \\
    \\/// my stuff
    \\x: usize,
    \\
    \\/// my stuff y
    \\y: usize,
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\// mint fmt: off
    \\ // xyz
    \\ /// This is a doc comment 2
    \\ fn foo() void {   testOne(); }
    \\
    \\ /// first T
    \\ const T = struct {
    \\ /// the mem member
    \\  mem: u8, // abc
    \\  // mint fmt: on
    \\  xyz: usize,
    \\
    \\  /// the x member
    \\  x: u8,
    \\  /// the y member
    \\  y: u8,
    \\
    \\  /// This function does nothing
    \\  pub fn foo() void {}
    \\
    \\  fn foo() void {
    \\    testOne();
    \\  }
    \\};
    \\
    \\/// my stuff
    \\x: usize,
    \\
    \\/// my stuff y
    \\y: usize,
  );
}

test "comments/mint-off-on 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\pub const Foo = struct {
  \\
  \\  // mint fmt: off
  \\  pub const ptable = [_]ExprParseTable{
  \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_plus
  \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_minus
  \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_slash
  \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_star
  \\    .{.bp = .bp_call_access, .prefix = Self.grouping, .infix = Self.call},    // tk_lbracket
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rbracket
  \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_lsqr_bracket
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rsqr_bracket
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_semic
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_colon
  \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lthan
  \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gthan
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_equal
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_lcurly
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rcurly
  \\    .{.bp = .bp_bitand, .prefix = null, .infix = Self.binary},                // tk_amp
  \\    .{.bp = .bp_bitand, .prefix = null, .infix = null},                       // tk_qmark
  \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_perc
  \\    .{.bp = .bp_factor, .prefix = null, .infix = null},                       // tk_hash
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_comma
  \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_exmark
  \\    .{.bp = .bp_bitxor, .prefix = null, .infix = Self.binary},                // tk_caret
  \\    .{.bp = .bp_bitor, .prefix = null, .infix = Self.binary},                 // tk_pipe
  \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_tilde
  \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_dot
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_2hash
  \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2plus
  \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2minus
  \\    .{.bp = .bp_and, .prefix = null, .infix = Self.binary},                   // tk_2amp
  \\    .{.bp = .bp_or, .prefix = null, .infix = Self.binary},                    // tk_2pipe
  \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lequal
  \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gequal
  \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_2equal
  \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_nequal
  \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2lthan
  \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2gthan
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_if
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_for
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_if
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_else
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_case
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_break
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_else
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_elif
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_while
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_extern
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifdef
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_endif
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_return
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_undef
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifndef
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_define
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_include
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_continue
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_sep
  \\    .{.bp = .bp_none, .prefix = Self.integer, .infix = null},                 // tk_integer
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_decimal
  \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_string
  \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_esc_string
  \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_ident
  \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_unknown
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_eof
  \\  };
  \\  // mint fmt: on
  \\// TODO: see we if we can add a generic implementation of _parse() in here
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\pub const Foo = struct {
    \\  // mint fmt: off
    \\  pub const ptable = [_]ExprParseTable{
    \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_plus
    \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_minus
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_slash
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_star
    \\    .{.bp = .bp_call_access, .prefix = Self.grouping, .infix = Self.call},    // tk_lbracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rbracket
    \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_lsqr_bracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rsqr_bracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_semic
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_colon
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lthan
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gthan
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_equal
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_lcurly
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rcurly
    \\    .{.bp = .bp_bitand, .prefix = null, .infix = Self.binary},                // tk_amp
    \\    .{.bp = .bp_bitand, .prefix = null, .infix = null},                       // tk_qmark
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_perc
    \\    .{.bp = .bp_factor, .prefix = null, .infix = null},                       // tk_hash
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_comma
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_exmark
    \\    .{.bp = .bp_bitxor, .prefix = null, .infix = Self.binary},                // tk_caret
    \\    .{.bp = .bp_bitor, .prefix = null, .infix = Self.binary},                 // tk_pipe
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_tilde
    \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_dot
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_2hash
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2plus
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2minus
    \\    .{.bp = .bp_and, .prefix = null, .infix = Self.binary},                   // tk_2amp
    \\    .{.bp = .bp_or, .prefix = null, .infix = Self.binary},                    // tk_2pipe
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lequal
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gequal
    \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_2equal
    \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_nequal
    \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2lthan
    \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2gthan
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_if
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_for
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_if
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_else
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_case
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_break
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_else
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_elif
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_while
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_extern
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifdef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_endif
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_return
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_undef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifndef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_define
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_include
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_continue
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_sep
    \\    .{.bp = .bp_none, .prefix = Self.integer, .infix = null},                 // tk_integer
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_decimal
    \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_string
    \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_esc_string
    \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_ident
    \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_unknown
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_eof
    \\  };
    \\  // mint fmt: on
    \\  // TODO: see we if we can add a generic implementation of _parse() in here
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\pub const Foo = struct {
    \\  // mint fmt: off
    \\  pub const ptable = [_]ExprParseTable{
    \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_plus
    \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_minus
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_slash
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_star
    \\    .{.bp = .bp_call_access, .prefix = Self.grouping, .infix = Self.call},    // tk_lbracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rbracket
    \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_lsqr_bracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rsqr_bracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_semic
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_colon
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lthan
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gthan
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_equal
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_lcurly
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rcurly
    \\    .{.bp = .bp_bitand, .prefix = null, .infix = Self.binary},                // tk_amp
    \\    .{.bp = .bp_bitand, .prefix = null, .infix = null},                       // tk_qmark
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_perc
    \\    .{.bp = .bp_factor, .prefix = null, .infix = null},                       // tk_hash
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_comma
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_exmark
    \\    .{.bp = .bp_bitxor, .prefix = null, .infix = Self.binary},                // tk_caret
    \\    .{.bp = .bp_bitor, .prefix = null, .infix = Self.binary},                 // tk_pipe
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_tilde
    \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_dot
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_2hash
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2plus
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2minus
    \\    .{.bp = .bp_and, .prefix = null, .infix = Self.binary},                   // tk_2amp
    \\    .{.bp = .bp_or, .prefix = null, .infix = Self.binary},                    // tk_2pipe
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lequal
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gequal
    \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_2equal
    \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_nequal
    \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2lthan
    \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2gthan
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_if
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_for
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_if
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_else
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_case
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_break
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_else
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_elif
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_while
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_extern
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifdef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_endif
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_return
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_undef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifndef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_define
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_include
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_continue
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_sep
    \\    .{.bp = .bp_none, .prefix = Self.integer, .infix = null},                 // tk_integer
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_decimal
    \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_string
    \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_esc_string
    \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_ident
    \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_unknown
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_eof
    \\  };
    \\  // mint fmt: on
    \\  // TODO: see we if we can add a generic implementation of _parse() in here
    \\};
  );
}

test "comments/mint-off-on 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\pub const Foo = struct {
  \\
  \\  // mint fmt: off
  \\  pub const ptable = [_]ExprParseTable{
  \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_plus
  \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_minus
  \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_slash
  \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_star
  \\    .{.bp = .bp_call_access, .prefix = Self.grouping, .infix = Self.call},    // tk_lbracket
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rbracket
  \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_lsqr_bracket
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rsqr_bracket
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_semic
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_colon
  \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lthan
  \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gthan
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_equal
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_lcurly
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rcurly
  \\    .{.bp = .bp_bitand, .prefix = null, .infix = Self.binary},                // tk_amp
  \\    .{.bp = .bp_bitand, .prefix = null, .infix = null},                       // tk_qmark
  \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_perc
  \\    .{.bp = .bp_factor, .prefix = null, .infix = null},                       // tk_hash
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_comma
  \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_exmark
  \\    .{.bp = .bp_bitxor, .prefix = null, .infix = Self.binary},                // tk_caret
  \\    .{.bp = .bp_bitor, .prefix = null, .infix = Self.binary},                 // tk_pipe
  \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_tilde
  \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_dot
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_2hash
  \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2plus
  \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2minus
  \\    .{.bp = .bp_and, .prefix = null, .infix = Self.binary},                   // tk_2amp
  \\    .{.bp = .bp_or, .prefix = null, .infix = Self.binary},                    // tk_2pipe
  \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lequal
  \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gequal
  \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_2equal
  \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_nequal
  \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2lthan
  \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2gthan
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_if
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_for
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_if
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_else
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_case
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_break
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_else
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_elif
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_while
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_extern
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifdef
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_endif
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_return
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_undef
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifndef
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_define
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_include
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_continue
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_sep
  \\    .{.bp = .bp_none, .prefix = Self.integer, .infix = null},                 // tk_integer
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_decimal
  \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_string
  \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_esc_string
  \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_ident
  \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_unknown
  \\  // mint fmt: on
  \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_eof
  \\  };
  \\// TODO: see we if we can add a generic implementation of _parse() in here
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\pub const Foo = struct {
    \\  // mint fmt: off
    \\  pub const ptable = [_]ExprParseTable{
    \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_plus
    \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_minus
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_slash
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_star
    \\    .{.bp = .bp_call_access, .prefix = Self.grouping, .infix = Self.call},    // tk_lbracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rbracket
    \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_lsqr_bracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rsqr_bracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_semic
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_colon
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lthan
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gthan
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_equal
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_lcurly
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rcurly
    \\    .{.bp = .bp_bitand, .prefix = null, .infix = Self.binary},                // tk_amp
    \\    .{.bp = .bp_bitand, .prefix = null, .infix = null},                       // tk_qmark
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_perc
    \\    .{.bp = .bp_factor, .prefix = null, .infix = null},                       // tk_hash
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_comma
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_exmark
    \\    .{.bp = .bp_bitxor, .prefix = null, .infix = Self.binary},                // tk_caret
    \\    .{.bp = .bp_bitor, .prefix = null, .infix = Self.binary},                 // tk_pipe
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_tilde
    \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_dot
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_2hash
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2plus
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2minus
    \\    .{.bp = .bp_and, .prefix = null, .infix = Self.binary},                   // tk_2amp
    \\    .{.bp = .bp_or, .prefix = null, .infix = Self.binary},                    // tk_2pipe
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lequal
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gequal
    \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_2equal
    \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_nequal
    \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2lthan
    \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2gthan
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_if
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_for
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_if
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_else
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_case
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_break
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_else
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_elif
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_while
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_extern
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifdef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_endif
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_return
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_undef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifndef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_define
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_include
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_continue
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_sep
    \\    .{.bp = .bp_none, .prefix = Self.integer, .infix = null},                 // tk_integer
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_decimal
    \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_string
    \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_esc_string
    \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_ident
    \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_unknown
    \\    // mint fmt: on
    \\    .{ .bp = .bp_none, .prefix = null, .infix = null }, // tk_eof
    \\  };
    \\  // TODO: see we if we can add a generic implementation of _parse() in here
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\pub const Foo = struct {
    \\  // mint fmt: off
    \\  pub const ptable = [_]ExprParseTable{
    \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_plus
    \\    .{.bp = .bp_term, .prefix = Self.unary, .infix = Self.binary},            // tk_minus
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_slash
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_star
    \\    .{.bp = .bp_call_access, .prefix = Self.grouping, .infix = Self.call},    // tk_lbracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rbracket
    \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_lsqr_bracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rsqr_bracket
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_semic
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_colon
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lthan
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gthan
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_equal
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_lcurly
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_rcurly
    \\    .{.bp = .bp_bitand, .prefix = null, .infix = Self.binary},                // tk_amp
    \\    .{.bp = .bp_bitand, .prefix = null, .infix = null},                       // tk_qmark
    \\    .{.bp = .bp_factor, .prefix = null, .infix = Self.binary},                // tk_perc
    \\    .{.bp = .bp_factor, .prefix = null, .infix = null},                       // tk_hash
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_comma
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_exmark
    \\    .{.bp = .bp_bitxor, .prefix = null, .infix = Self.binary},                // tk_caret
    \\    .{.bp = .bp_bitor, .prefix = null, .infix = Self.binary},                 // tk_pipe
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_tilde
    \\    .{.bp = .bp_call_access, .prefix = null, .infix = null},                  // tk_dot
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_2hash
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2plus
    \\    .{.bp = .bp_unary, .prefix = Self.unary, .infix = null},                  // tk_2minus
    \\    .{.bp = .bp_and, .prefix = null, .infix = Self.binary},                   // tk_2amp
    \\    .{.bp = .bp_or, .prefix = null, .infix = Self.binary},                    // tk_2pipe
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_lequal
    \\    .{.bp = .bp_comparison, .prefix = null, .infix = Self.binary},            // tk_gequal
    \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_2equal
    \\    .{.bp = .bp_equality, .prefix = null, .infix = Self.binary},              // tk_nequal
    \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2lthan
    \\    .{.bp = .bp_shift, .prefix = null, .infix = Self.binary},                 // tk_2gthan
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_if
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_for
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_if
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_else
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_case
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_break
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_else
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_elif
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_while
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_extern
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifdef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_endif
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_return
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_undef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_ifndef
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_define
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_include
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_continue
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_p_sep
    \\    .{.bp = .bp_none, .prefix = Self.integer, .infix = null},                 // tk_integer
    \\    .{.bp = .bp_none, .prefix = null, .infix = null},                         // tk_decimal
    \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_string
    \\    .{.bp = .bp_none, .prefix = Self.string, .infix = null},                  // tk_esc_string
    \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_ident
    \\    .{.bp = .bp_none, .prefix = Self.variable, .infix = null},                // tk_unknown
    \\    // mint fmt: on
    \\    .{
    \\      .bp = .bp_none,
    \\      .prefix = null,
    \\      .infix = null,
    \\    }, // tk_eof
    \\  };
    \\  // TODO: see we if we can add a generic implementation of _parse() in here
    \\};
  );
}

test "comments/mint-off-on 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\fn tAsmIO() *Doc {
  \\  if (true) {
  \\    foo();
  \\  } else { // tests bug of disappearing else token
  \\    sb.text("  ")._();
  \\  }
  \\  // mint fmt: off
  \\  sb.append(self.ttknWithSTL(a - 1));       // `[`
  \\}
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn tAsmIO() *Doc {
    \\  if (true) {
    \\    foo();
    \\  } else { // tests bug of disappearing else token
    \\    sb.text("  ")._();
    \\  }
    \\  // mint fmt: off
    \\  sb.append(self.ttknWithSTL(a - 1));       // `[`
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn tAsmIO() *Doc {
    \\  if (true) {
    \\    foo();
    \\  } else { // tests bug of disappearing else token
    \\    sb.text("  ")._();
    \\  }
    \\  // mint fmt: off
    \\  sb.append(self.ttknWithSTL(a - 1));       // `[`
    \\}
  );
}

test "slice" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ foo() // 1
  \\ [ // 2
  \\  // 3
  \\ bar() // 4
  \\ .. // 5
  \\ dah() // 6
  \\ : // 7
  \\ pixie // 8
  \\ ] // 9
  \\ ,
  \\
  \\ foo() // 1
  \\ [ // 2
  \\  // 3
  \\ bar() // 4
  \\ .. // 5
  \\ dah() // 6
  \\ ] // 7 
  \\ ,
  \\
  \\ foo() // 1
  \\ [ // 2
  \\  // 3
  \\ bar() // 4
  \\ .. // 5
  \\ ] // 6
  \\ ,
  \\
  \\ foo() // 1
  \\ [ // 2
  \\  // 3
  \\ bar() // 4
  \\ .. // 5
  \\ : // 6
  \\ dah() // 7
  \\ ] // 8
  \\ ,
  \\
  \\ foo() // 1
  \\ [ // 2
  \\  // 3
  \\ fox().bar() // 4
  \\ .. // 5
  \\ : // 6
  \\ dah() // 7
  \\ ], // 8
  \\
  \\ // control
  \\ foo()[bar()..dah():pixie],
  \\ foo()[bar()..dah()],
  \\ foo()[bar()..],
  \\ var j = foo()[bar()..:bar()];
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\foo() // 1
    \\[ // 2
    \\  // 3
    \\  bar() // 4
    \\  .. // 5
    \\  dah() // 6
    \\  : // 7
    \\  pixie // 8
    \\] // 9
    \\,
    \\
    \\foo() // 1
    \\[ // 2
    \\  // 3
    \\  bar() // 4
    \\  .. // 5
    \\  dah() // 6
    \\] // 7
    \\,
    \\
    \\foo() // 1
    \\[ // 2
    \\  // 3
    \\  bar() // 4
    \\  .. // 5
    \\] // 6
    \\,
    \\
    \\foo() // 1
    \\[ // 2
    \\  // 3
    \\  bar() // 4
    \\  .. // 5
    \\  : // 6
    \\  dah() // 7
    \\] // 8
    \\,
    \\
    \\foo() // 1
    \\[ // 2
    \\  // 3
    \\  fox().bar() // 4
    \\  .. // 5
    \\  : // 6
    \\  dah() // 7
    \\], // 8
    \\
    \\// control
    \\foo()[bar()..dah():pixie],
    \\foo()[bar()..dah()],
    \\foo()[bar()..],
    \\var j = foo()[bar()..:bar()];
  );
  // using width: 10
  res = try format(doc, .{ .width = 10 }, al);
  try check(
    res,
    \\foo() // 1
    \\[ // 2
    \\  // 3
    \\  bar() // 4
    \\  .. // 5
    \\  dah() // 6
    \\  : // 7
    \\  pixie // 8
    \\] // 9
    \\,
    \\
    \\foo() // 1
    \\[ // 2
    \\  // 3
    \\  bar() // 4
    \\  .. // 5
    \\  dah() // 6
    \\] // 7
    \\,
    \\
    \\foo() // 1
    \\[ // 2
    \\  // 3
    \\  bar() // 4
    \\  .. // 5
    \\] // 6
    \\,
    \\
    \\foo() // 1
    \\[ // 2
    \\  // 3
    \\  bar() // 4
    \\  .. // 5
    \\  : // 6
    \\  dah() // 7
    \\] // 8
    \\,
    \\
    \\foo() // 1
    \\[ // 2
    \\  // 3
    \\  fox()
    \\    .bar() // 4
    \\  .. // 5
    \\  : // 6
    \\  dah() // 7
    \\], // 8
    \\
    \\// control
    \\foo()[
    \\  bar()..dah()
    \\  :pixie
    \\],
    \\foo()[
    \\  bar()..dah()
    \\],
    \\foo()[
    \\  bar()..
    \\],
    \\var j = foo()[
    \\  bar()..
    \\  :bar()
    \\];
  );
}

test "catch-orelse 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\const p = paths  orelse blk: {
  \\    const size = try std.Io.Dir.cwd().realPath(io, &buf);
  \\    break :blk &.{buf[0..size]};
  \\  };
  \\const p = paths  orelse blkMe();
  \\var abc = someFunc(1, 2, 3) orelse blk: {
  \\  someBlock1();
  \\  break :blk result("okay");
  \\};
  \\
  \\var abc = someFunc(1, 2, 3) catch |b| blk: {
  \\  someBlock1();
  \\  break :blk result("okay");
  \\};
  \\
  \\var abc = someFunc(1, 2, 3) orelse {
  \\  someBlock1();
  \\  someBlock2();
  \\  someBlock3();
  \\  someBlock4();
  \\  break :blk result("okay");
  \\};
  \\
  \\var abc = someFunc(1, 2, 3) catch |x| {
  \\  someBlock1();
  \\  someBlock2();
  \\  someBlock3();
  \\  someBlock4();
  \\  break :blk result("okay");
  \\ };
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const p = paths orelse blk: {
    \\  const size = try std.Io.Dir.cwd().realPath(io, &buf);
    \\  break :blk &.{buf[0..size]};
    \\};
    \\const p = paths orelse blkMe();
    \\var abc = someFunc(1, 2, 3) orelse blk: {
    \\  someBlock1();
    \\  break :blk result("okay");
    \\};
    \\
    \\var abc = someFunc(1, 2, 3) catch |b| blk: {
    \\  someBlock1();
    \\  break :blk result("okay");
    \\};
    \\
    \\var abc = someFunc(1, 2, 3) orelse {
    \\  someBlock1();
    \\  someBlock2();
    \\  someBlock3();
    \\  someBlock4();
    \\  break :blk result("okay");
    \\};
    \\
    \\var abc = someFunc(1, 2, 3) catch |x| {
    \\  someBlock1();
    \\  someBlock2();
    \\  someBlock3();
    \\  someBlock4();
    \\  break :blk result("okay");
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const p = paths orelse blk: {
    \\  const size = try std.Io.Dir.cwd()
    \\    .realPath(io, &buf);
    \\  break :blk &.{buf[0..size]};
    \\};
    \\const p = paths
    \\  orelse blkMe();
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) orelse blk: {
    \\  someBlock1();
    \\  break :blk result("okay");
    \\};
    \\
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) catch |b| blk: {
    \\  someBlock1();
    \\  break :blk result("okay");
    \\};
    \\
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) orelse {
    \\  someBlock1();
    \\  someBlock2();
    \\  someBlock3();
    \\  someBlock4();
    \\  break :blk result("okay");
    \\};
    \\
    \\var abc = someFunc(
    \\  1,
    \\  2,
    \\  3,
    \\) catch |x| {
    \\  someBlock1();
    \\  someBlock2();
    \\  someBlock3();
    \\  someBlock4();
    \\  break :blk result("okay");
    \\};
  );
}

test "catch-orelse 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() void {
  \\writer.flush() catch {};
  \\writer.flush() orelse {};
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo() void {
    \\  writer.flush() catch {};
    \\  writer.flush() orelse {};
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo() void {
    \\  writer.flush() catch {};
    \\  writer.flush() orelse {};
    \\}
  );
}

test "catch-orelse 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\const foxybar_len = std.unicode.utf8CountCodepoints(foxybar.text) orelse foxybar.text.len;
  \\const foxybarr_len = std.unicode.utf8CountCodepoints(foxybar.text) catch error.ThisIsSoLongICantBreak;
  \\
  \\ fn foo() void {
  \\writer.flush() catch {};
  \\writer.flush() orelse {};
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const foxybar_len = std.unicode.utf8CountCodepoints(foxybar.text)
    \\  orelse foxybar.text.len;
    \\const foxybarr_len = std.unicode.utf8CountCodepoints(foxybar.text)
    \\  catch error.ThisIsSoLongICantBreak;
    \\
    \\fn foo() void {
    \\  writer.flush() catch {};
    \\  writer.flush() orelse {};
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const foxybar_len = std.unicode.utf8CountCodepoints(
    \\  foxybar.text,
    \\)
    \\  orelse foxybar.text.len;
    \\const foxybarr_len = std.unicode.utf8CountCodepoints(
    \\  foxybar.text,
    \\)
    \\  catch error.ThisIsSoLongICantBreak;
    \\
    \\fn foo() void {
    \\  writer.flush() catch {};
    \\  writer.flush() orelse {};
    \\}
  );
}

test "array-access" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\_ = buf // 1
  \\ [ // 2
  \\ // toplevel stuff 1
  \\ // toplevel stuff 2
  \\ size(a, b, c, d) // 3
  \\ ] // 4
  \\,
  \\
  \\buf // 1
  \\ [
  \\ // top
  \\ size
  \\ // bottom 
  \\ ] // 2
  \\ = 0,
  \\
  \\buf
  \\ [
  \\ size // 1
  \\ ]
  \\ = 0,
  \\
  \\buf
  \\ [
  \\ // oxff
  \\ size
  \\ ]
  \\ = 0,
  \\
  \\_ = buf[size(a, b, c, d)],
  \\buf[size] = 0,
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\_ = buf // 1
    \\[ // 2
    \\  // toplevel stuff 1
    \\  // toplevel stuff 2
    \\  size(a, b, c, d) // 3
    \\] // 4
    \\,
    \\
    \\buf // 1
    \\[
    \\  // top
    \\  size
    \\  // bottom
    \\] // 2
    \\= 0,
    \\
    \\buf[
    \\  size // 1
    \\] = 0,
    \\
    \\buf[
    \\  // oxff
    \\  size
    \\] = 0,
    \\
    \\_ = buf[size(a, b, c, d)],
    \\buf[size] = 0,
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\_ = buf // 1
    \\[ // 2
    \\  // toplevel stuff 1
    \\  // toplevel stuff 2
    \\  size(
    \\    a,
    \\    b,
    \\    c,
    \\    d,
    \\  ) // 3
    \\] // 4
    \\,
    \\
    \\buf // 1
    \\[
    \\  // top
    \\  size
    \\  // bottom
    \\] // 2
    \\= 0,
    \\
    \\buf[
    \\  size // 1
    \\] = 0,
    \\
    \\buf[
    \\  // oxff
    \\  size
    \\] = 0,
    \\
    \\_ = buf[
    \\  size(a, b, c, d)
    \\],
    \\buf[size] = 0,
  );
}

test "error-value" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\var x = error // 1
  \\ . // 2
  \\ FooIsInvalid // 3
  \\ ;
  \\var x = error.FooIsInvalid;
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\var x = error // 1
    \\. // 2
    \\FooIsInvalid // 3
    \\;
    \\var x = error.FooIsInvalid;
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\var x = error // 1
    \\. // 2
    \\FooIsInvalid // 3
    \\;
    \\var x = error.FooIsInvalid;
  );
}

test "multiline-string 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn MyFoo() void {
  \\ var x = // my foo
  \\ \\ j
  \\ ;
  \\ y +
  \\ \\ j
  \\ ;
  \\ y +
  \\ \\ j
  \\ \\ b
  \\ \\ c // yes
  \\ ;
  \\ _ = x ++ // my foo
  \\ \\ j
  \\ ;
  \\ const t =
  \\ // good?
  \\ \\ this is a multi // 1
  \\ \\ line string // 2
  \\ ;
  \\ const s =
  \\ \\ this is a multi
  \\ \\ line string
  \\ ;
  \\ const s = \\ this is a multi
  \\ \\ line string
  \\ ;
  \\ 
  \\  var tbd = foo.bar(abc, def, 123,
  \\ \\ a wall of text
  \\ \\ is a fun wall
  \\ \\ but not a narwhal
  \\);
  \\ 
  \\  var tbd2 = foo.bar(abc, def, 123,
  \\ \\ a wall of text
  \\ \\ is a fun wall
  \\ \\ but not a narwhal
  \\  ,
  \\  bar()
  \\);
  \\ 
  \\  var tbd3 = foo.bar(abc, def, 123,
  \\ \\ a wall of text
  \\ \\ is a fun wall
  \\ \\ but not a narwhal
  \\  ,
  \\);
  \\
  \\  var tbd4 = foo.bar(abc, def, 123,
  \\ \\ a wall of text
  \\ \\ is a fun wall
  \\ \\ but not a narwhal
  \\  , // xy
  \\);
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn MyFoo() void {
    \\  var x = // my foo
    \\  \\ j
    \\  ;
    \\  y +
    \\    \\ j
    \\  ;
    \\  y +
    \\    \\ j
    \\    \\ b
    \\    \\ c // yes
    \\  ;
    \\  _ = x ++ // my foo
    \\    \\ j
    \\  ;
    \\  const t =
    \\  // good?
    \\  \\ this is a multi // 1
    \\  \\ line string // 2
    \\  ;
    \\  const s =
    \\  \\ this is a multi
    \\  \\ line string
    \\  ;
    \\  const s =
    \\  \\ this is a multi
    \\  \\ line string
    \\  ;
    \\
    \\  var tbd = foo.bar(
    \\    abc,
    \\    def,
    \\    123,
    \\    \\ a wall of text
    \\    \\ is a fun wall
    \\    \\ but not a narwhal
    \\  );
    \\
    \\  var tbd2 = foo.bar(
    \\    abc,
    \\    def,
    \\    123,
    \\    \\ a wall of text
    \\    \\ is a fun wall
    \\    \\ but not a narwhal
    \\    ,
    \\    bar(),
    \\  );
    \\
    \\  var tbd3 = foo.bar(
    \\    abc,
    \\    def,
    \\    123,
    \\    \\ a wall of text
    \\    \\ is a fun wall
    \\    \\ but not a narwhal
    \\    ,
    \\  );
    \\
    \\  var tbd4 = foo.bar(
    \\    abc,
    \\    def,
    \\    123,
    \\    \\ a wall of text
    \\    \\ is a fun wall
    \\    \\ but not a narwhal
    \\    , // xy
    \\  );
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn MyFoo() void {
    \\  var x = // my foo
    \\  \\ j
    \\  ;
    \\  y +
    \\    \\ j
    \\  ;
    \\  y +
    \\    \\ j
    \\    \\ b
    \\    \\ c // yes
    \\  ;
    \\  _ = x ++ // my foo
    \\    \\ j
    \\  ;
    \\  const t =
    \\  // good?
    \\  \\ this is a multi // 1
    \\  \\ line string // 2
    \\  ;
    \\  const s =
    \\  \\ this is a multi
    \\  \\ line string
    \\  ;
    \\  const s =
    \\  \\ this is a multi
    \\  \\ line string
    \\  ;
    \\
    \\  var tbd = foo.bar(
    \\    abc,
    \\    def,
    \\    123,
    \\    \\ a wall of text
    \\    \\ is a fun wall
    \\    \\ but not a narwhal
    \\  );
    \\
    \\  var tbd2 = foo.bar(
    \\    abc,
    \\    def,
    \\    123,
    \\    \\ a wall of text
    \\    \\ is a fun wall
    \\    \\ but not a narwhal
    \\    ,
    \\    bar(),
    \\  );
    \\
    \\  var tbd3 = foo.bar(
    \\    abc,
    \\    def,
    \\    123,
    \\    \\ a wall of text
    \\    \\ is a fun wall
    \\    \\ but not a narwhal
    \\    ,
    \\  );
    \\
    \\  var tbd4 = foo.bar(
    \\    abc,
    \\    def,
    \\    123,
    \\    \\ a wall of text
    \\    \\ is a fun wall
    \\    \\ but not a narwhal
    \\    , // xy
    \\  );
    \\}
  );
}

test "multiline-string 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\pub const ArgParse = struct {
  \\const info =
  \\\\Usage:
  \\\\  mint <command> [<args>]
  \\\\    init                        -  create a `mint.zon` config file
  \\\\    fmt [filename|directory]    -  format a file or directory of files
  \\\\    watch [filename|directory]  -  format in watch mode
  \\\\    help                        -  display usage information
  \\;
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\pub const ArgParse = struct {
    \\  const info =
    \\  \\Usage:
    \\  \\  mint <command> [<args>]
    \\  \\    init                        -  create a `mint.zon` config file
    \\  \\    fmt [filename|directory]    -  format a file or directory of files
    \\  \\    watch [filename|directory]  -  format in watch mode
    \\  \\    help                        -  display usage information
    \\  ;
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\pub const ArgParse = struct {
    \\  const info =
    \\  \\Usage:
    \\  \\  mint <command> [<args>]
    \\  \\    init                        -  create a `mint.zon` config file
    \\  \\    fmt [filename|directory]    -  format a file or directory of files
    \\  \\    watch [filename|directory]  -  format in watch mode
    \\  \\    help                        -  display usage information
    \\  ;
    \\};
  );
}

test "bang-return" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\pub inline fn getStatMTime(io: std.Io, f: []const u8) !std.Io.Timestamp {
  \\  const stat = try std.Io.Dir.cwd().statFile(io, f, .{});
  \\  return stat.mtime;
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\pub inline fn getStatMTime(io: std.Io, f: []const u8) !std.Io.Timestamp {
    \\  const stat = try std.Io.Dir.cwd().statFile(io, f, .{});
    \\  return stat.mtime;
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\pub inline fn getStatMTime(
    \\  io: std.Io,
    \\  f: []const u8,
    \\) !std.Io.Timestamp {
    \\  const stat = try std.Io.Dir.cwd()
    \\    .statFile(io, f, .{});
    \\  return stat.mtime;
    \\}
  );
}

test "rbrace-trailing-comment 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() void {
  \\var seen_dec = false;
  \\if (self.peek() == '.') {
  \\  const c = self.peekN(1);
  \\  if (c == '.' or (!std.ascii.isDigit(c) and std.ascii.toLower(c) != 'e')) {
  \\    return self.newToken(.tk_integer);
  \\  }
  \\  // "." dec_int
  \\  seen_dec = true;
  \\  self.adv(); // skip '.'
  \\  if (std.ascii.isDigit(self.peek())) {
  \\    while (std.ascii.isDigit(self.peek())) {
  \\      self.adv();
  \\      if (self.peek() == '_') {
  \\        self.adv();
  \\        if (!std.ascii.isDigit(self.peek())) {
  \\          return err_;
  \\        }
  \\      }
  \\    }
  \\  } else {
  \\    // hack for: 0.e1234 i.e. dec+ "." e dec+ since zig supports this
  \\    if (std.ascii.toLower(self.peek()) != 'e') return err_;
  \\  }
  \\}
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo() void {
    \\  var seen_dec = false;
    \\  if (self.peek() == '.') {
    \\    const c = self.peekN(1);
    \\    if (c == '.' or (!std.ascii.isDigit(c) and std.ascii.toLower(c) != 'e')) {
    \\      return self.newToken(.tk_integer);
    \\    }
    \\    // "." dec_int
    \\    seen_dec = true;
    \\    self.adv(); // skip '.'
    \\    if (std.ascii.isDigit(self.peek())) {
    \\      while (std.ascii.isDigit(self.peek())) {
    \\        self.adv();
    \\        if (self.peek() == '_') {
    \\          self.adv();
    \\          if (!std.ascii.isDigit(self.peek())) {
    \\            return err_;
    \\          }
    \\        }
    \\      }
    \\    } else {
    \\      // hack for: 0.e1234 i.e. dec+ "." e dec+ since zig supports this
    \\      if (std.ascii.toLower(self.peek()) != 'e') return err_;
    \\    }
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\fn foo() void {
    \\  var seen_dec = false;
    \\  if (self.peek() == '.') {
    \\    const c = self.peekN(1);
    \\    if (
    \\      c == '.'
    \\        or (!std.ascii.isDigit(
    \\          c,
    \\        )
    \\          and std.ascii.toLower(
    \\            c,
    \\          ) != 'e')
    \\    ) {
    \\      return self.newToken(
    \\        .tk_integer,
    \\      );
    \\    }
    \\    // "." dec_int
    \\    seen_dec = true;
    \\    self.adv(); // skip '.'
    \\    if (
    \\      std.ascii.isDigit(
    \\        self.peek(),
    \\      )
    \\    ) {
    \\      while (
    \\        std.ascii.isDigit(
    \\          self.peek(),
    \\        )
    \\      ) {
    \\        self.adv();
    \\        if (
    \\          self.peek() == '_'
    \\        ) {
    \\          self.adv();
    \\          if (
    \\            !std.ascii.isDigit(
    \\              self.peek(),
    \\            )
    \\          ) {
    \\            return err_;
    \\          }
    \\        }
    \\      }
    \\    } else {
    \\      // hack for: 0.e1234 i.e. dec+ "." e dec+ since zig supports this
    \\      if (
    \\        std.ascii.toLower(
    \\          self.peek(),
    \\        ) != 'e'
    \\      )
    \\        return err_;
    \\    }
    \\  }
    \\}
  );
}

test "rbrace-trailing-comment 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const J = struct {
  \\  fn fox() void {
  \\  print("nothing");
  \\ } // my trail
  \\ fn foo() void {}
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const J = struct {
    \\  fn fox() void {
    \\    print("nothing");
    \\  } // my trail
    \\  fn foo() void {}
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const J = struct {
    \\  fn fox() void {
    \\    print("nothing");
    \\  } // my trail
    \\  fn foo() void {}
    \\};
  );
}

test "rbrace-trailing-comment 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const J = struct {
  \\  fn fox() void {
  \\  print("nothing");
  \\ } // my trail
  \\
  \\
  \\
  \\ fn foo() void {}
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const J = struct {
    \\  fn fox() void {
    \\    print("nothing");
    \\  } // my trail
    \\
    \\  fn foo() void {}
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const J = struct {
    \\  fn fox() void {
    \\    print("nothing");
    \\  } // my trail
    \\
    \\  fn foo() void {}
    \\};
  );
}

test "rbrace-trailing-comment 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const J = struct {
  \\  fn fox() void {
  \\  print("nothing");
  \\ }
  \\ // my trail
  \\ fn foo() void {}
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const J = struct {
    \\  fn fox() void {
    \\    print("nothing");
    \\  }
    \\  // my trail
    \\  fn foo() void {}
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const J = struct {
    \\  fn fox() void {
    \\    print("nothing");
    \\  }
    \\  // my trail
    \\  fn foo() void {}
    \\};
  );
}

test "rbrace-trailing-comment 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const J = struct {
  \\  fn fox() void {
  \\  print("nothing");
  \\ }
  \\ // my trail
  \\
  \\
  \\
  \\ fn foo() void {}
  \\};
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const J = struct {
    \\  fn fox() void {
    \\    print("nothing");
    \\  }
    \\  // my trail
    \\
    \\  fn foo() void {}
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const J = struct {
    \\  fn fox() void {
    \\    print("nothing");
    \\  }
    \\  // my trail
    \\
    \\  fn foo() void {}
    \\};
  );
}

test "field termination 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\const ConcreteTypes = struct {
  \\  const num = tir.Concrete.init(.ck_num_literal, Token.getDefaultToken());
  \\  const str = tir.Concrete.init(.ck_str_literal, Token.getDefaultToken());
  \\  const void_ = tir.Concrete.init(.ck_void, scratchIdentToken(ks.VoidVar));
  \\  const unit = tir.Concrete.init(.ck_unit, scratchIdentToken(ks.UnitVar));
  \\  const never = tir.Concrete.init(.ck_never, scratchIdentToken(ks.NeverVar));
  \\
  \\  var ty_number: Type = Type.init(.{.ty_concrete = num});
  \\  var ty_string: Type = Type.init(.{.ty_concrete = str});
  \\  var ty_void: Type = Type.init(.{.ty_concrete = void_});
  \\  var ty_unit: Type = Type.init(.{.ty_concrete = unit});
  \\  var ty_never: Type = Type.init(.{.ty_concrete = never});
  \\};
  \\
  \\ const Ty = union(enum) {
  \\  x: []const u8,
  \\  y: u32,
  \\ abc: []const u8,
  \\ x: usize,
  \\ comptime {const x = 5;}
  \\};
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 120 }, al);
  try check(
    res,
    \\const ConcreteTypes = struct {
    \\  const num = tir.Concrete.init(.ck_num_literal, Token.getDefaultToken());
    \\  const str = tir.Concrete.init(.ck_str_literal, Token.getDefaultToken());
    \\  const void_ = tir.Concrete.init(.ck_void, scratchIdentToken(ks.VoidVar));
    \\  const unit = tir.Concrete.init(.ck_unit, scratchIdentToken(ks.UnitVar));
    \\  const never = tir.Concrete.init(.ck_never, scratchIdentToken(ks.NeverVar));
    \\
    \\  var ty_number: Type = Type.init(.{ .ty_concrete = num });
    \\  var ty_string: Type = Type.init(.{ .ty_concrete = str });
    \\  var ty_void: Type = Type.init(.{ .ty_concrete = void_ });
    \\  var ty_unit: Type = Type.init(.{ .ty_concrete = unit });
    \\  var ty_never: Type = Type.init(.{ .ty_concrete = never });
    \\};
    \\
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\  comptime {
    \\    const x = 5;
    \\  }
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const ConcreteTypes = struct {
    \\  const num = tir.Concrete.init(
    \\    .ck_num_literal,
    \\    Token.getDefaultToken(),
    \\  );
    \\  const str = tir.Concrete.init(
    \\    .ck_str_literal,
    \\    Token.getDefaultToken(),
    \\  );
    \\  const void_ = tir.Concrete.init(
    \\    .ck_void,
    \\    scratchIdentToken(
    \\      ks.VoidVar,
    \\    ),
    \\  );
    \\  const unit = tir.Concrete.init(
    \\    .ck_unit,
    \\    scratchIdentToken(
    \\      ks.UnitVar,
    \\    ),
    \\  );
    \\  const never = tir.Concrete.init(
    \\    .ck_never,
    \\    scratchIdentToken(
    \\      ks.NeverVar,
    \\    ),
    \\  );
    \\
    \\  var ty_number: Type = Type.init(
    \\    .{ .ty_concrete = num },
    \\  );
    \\  var ty_string: Type = Type.init(
    \\    .{ .ty_concrete = str },
    \\  );
    \\  var ty_void: Type = Type.init(
    \\    .{ .ty_concrete = void_ },
    \\  );
    \\  var ty_unit: Type = Type.init(
    \\    .{ .ty_concrete = unit },
    \\  );
    \\  var ty_never: Type = Type.init(
    \\    .{ .ty_concrete = never },
    \\  );
    \\};
    \\
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\  comptime {
    \\    const x = 5;
    \\  }
    \\};
  );
}

test "field termination 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ const Ty = union(enum) {
  \\  x: []const u8,
  \\  y: u32,
  \\ abc: []const u8,
  \\ x: usize,
  \\ comptime  x = 5,
  \\};
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  var res = try format(doc, .{ .width = 120 }, al);
  try check(
    res,
    \\const Ty = union(enum) { x: []const u8, y: u32, abc: []const u8, x: usize, comptime x = 5 };
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\  abc: []const u8,
    \\  x: usize,
    \\  comptime x = 5,
    \\};
  );
}

test "asm 1" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  // from ziglang's Assembly page:
  \\ comptime {
  \\const t = asm volatile ("syscall"
  \\        : [ret] "={rax}" (-> usize),
  \\        : [number] "{rax}" (number),
  \\          [arg1] "{rdi}" (arg1),
  \\        : .{ .rcx = true, .r11 = true });
  \\
  \\asm (
  \\        \\.global my_func;
  \\        \\.type my_func, @function;
  \\        \\my_func:
  \\        \\  lea (%rdi,%rsi,1),%eax
  \\        \\  retq
  \\    );
  \\}
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\comptime {
    \\  const t = asm volatile(
    \\    "syscall"
    \\    : [ret] "={rax}" (->usize),
    \\    : [number] "{rax}" (number),
    \\      [arg1] "{rdi}" (arg1),
    \\    : .{ .rcx = true, .r11 = true }
    \\  );
    \\
    \\  asm(
    \\    \\.global my_func;
    \\    \\.type my_func, @function;
    \\    \\my_func:
    \\    \\  lea (%rdi,%rsi,1),%eax
    \\    \\  retq
    \\  );
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\comptime {
    \\  const t = asm volatile(
    \\    "syscall"
    \\    : [ret] "={rax}" (->usize),
    \\    : [number] "{rax}" (number),
    \\      [arg1] "{rdi}" (arg1),
    \\    : .{
    \\      .rcx = true,
    \\      .r11 = true,
    \\    }
    \\  );
    \\
    \\  asm(
    \\    \\.global my_func;
    \\    \\.type my_func, @function;
    \\    \\my_func:
    \\    \\  lea (%rdi,%rsi,1),%eax
    \\    \\  retq
    \\  );
    \\}
  );
}

test "asm 2" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  // from ziglang's Assembly page:
  \\ pub fn syscall3(number: usize, arg1: usize, arg2: usize, arg3: usize) usize {
  \\    return asm volatile ("syscall"
  \\        : [ret] "={rax}" (-> usize),
  \\        : [number] "{rax}" (number),
  \\          [arg1] "{rdi}" (arg1),
  \\          [arg2] "{rsi}" (arg2),
  \\          [arg3] "{rdx}" (arg3),
  \\        : .{ .rcx = true, .r11 = true });
  \\}
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\pub fn syscall3(number: usize, arg1: usize, arg2: usize, arg3: usize) usize {
    \\  return asm volatile(
    \\    "syscall"
    \\    : [ret] "={rax}" (->usize),
    \\    : [number] "{rax}" (number),
    \\      [arg1] "{rdi}" (arg1),
    \\      [arg2] "{rsi}" (arg2),
    \\      [arg3] "{rdx}" (arg3),
    \\    : .{ .rcx = true, .r11 = true }
    \\  );
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\pub fn syscall3(
    \\  number: usize,
    \\  arg1: usize,
    \\  arg2: usize,
    \\  arg3: usize,
    \\) usize {
    \\  return asm volatile(
    \\    "syscall"
    \\    : [ret] "={rax}" (->usize),
    \\    : [number] "{rax}" (number),
    \\      [arg1] "{rdi}" (arg1),
    \\      [arg2] "{rsi}" (arg2),
    \\      [arg3] "{rdx}" (arg3),
    \\    : .{
    \\      .rcx = true,
    \\      .r11 = true,
    \\    }
    \\  );
    \\}
  );
}

test "asm 3" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  // from ziglang's Assembly page:
  \\ comptime {
  \\const t = asm volatile ("syscall" // 1
  \\        : // 1b
  \\ [ret] "={rax}" (-> usize), // 2
  \\        : // 2b
  \\ [number] "{rax}" (number), // 3
  \\          [arg1] "{rdi}" (arg1) // 4
  \\ ,
  \\        : // 4b
  \\ .{ .rcx = true, .r11 = true } // 5
  \\ );
  \\
  \\asm ( // 1
  \\      // I'm top
  \\        \\.global my_func;
  \\        \\.type my_func, @function; // 2
  \\        \\my_func:
  \\        \\  lea (%rdi,%rsi,1),%eax
  \\        \\  retq
  \\      // I'm bottom
  \\    ); // 3
  \\}
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\comptime {
    \\  const t = asm volatile(
    \\    "syscall" // 1
    \\    : // 1b
    \\    [ret] "={rax}" (->usize), // 2
    \\    : // 2b
    \\    [number] "{rax}" (number), // 3
    \\      [arg1] "{rdi}" (arg1) // 4
    \\    ,
    \\    : // 4b
    \\    .{ .rcx = true, .r11 = true } // 5
    \\  );
    \\
    \\  asm( // 1
    \\    // I'm top
    \\    \\.global my_func;
    \\    \\.type my_func, @function; // 2
    \\    \\my_func:
    \\    \\  lea (%rdi,%rsi,1),%eax
    \\    \\  retq
    \\    // I'm bottom
    \\  ); // 3
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\comptime {
    \\  const t = asm volatile(
    \\    "syscall" // 1
    \\    : // 1b
    \\    [ret] "={rax}" (->usize), // 2
    \\    : // 2b
    \\    [number] "{rax}" (number), // 3
    \\      [arg1] "{rdi}" (arg1) // 4
    \\    ,
    \\    : // 4b
    \\    .{
    \\      .rcx = true,
    \\      .r11 = true,
    \\    } // 5
    \\  );
    \\
    \\  asm( // 1
    \\    // I'm top
    \\    \\.global my_func;
    \\    \\.type my_func, @function; // 2
    \\    \\my_func:
    \\    \\  lea (%rdi,%rsi,1),%eax
    \\    \\  retq
    \\    // I'm bottom
    \\  ); // 3
    \\}
  );
}

test "asm 4" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  // from ziglang's Assembly page:
  \\ comptime {
  \\const t = asm // -2 
  \\ volatile // -1
  \\ ( // 0
  \\ "syscall" // 1
  \\        : // 1b
  \\ [ret] "={rax}" (-> usize), // 2
  \\        : // 2b
  \\ [number] "{rax}" (number), // 3
  \\          [arg1] "{rdi}" (arg1) // 4
  \\ , //4x
  \\        : // 4b
  \\ .{ .rcx = true, .r11 = true } // 5
  \\ );
  \\
  \\asm // 0
  \\ ( // 1
  \\      // I'm top
  \\        \\.global my_func;
  \\        \\.type my_func, @function; // 2
  \\        \\my_func:
  \\        \\  lea (%rdi,%rsi,1),%eax
  \\        \\  retq
  \\      // I'm bottom
  \\    ) // 3
  \\;
  \\}
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\comptime {
    \\  const t = asm // -2
    \\  volatile // -1
    \\  ( // 0
    \\    "syscall" // 1
    \\    : // 1b
    \\    [ret] "={rax}" (->usize), // 2
    \\    : // 2b
    \\    [number] "{rax}" (number), // 3
    \\      [arg1] "{rdi}" (arg1) // 4
    \\    , //4x
    \\    : // 4b
    \\    .{ .rcx = true, .r11 = true } // 5
    \\  );
    \\
    \\  asm // 0
    \\  ( // 1
    \\    // I'm top
    \\    \\.global my_func;
    \\    \\.type my_func, @function; // 2
    \\    \\my_func:
    \\    \\  lea (%rdi,%rsi,1),%eax
    \\    \\  retq
    \\    // I'm bottom
    \\  ) // 3
    \\  ;
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\comptime {
    \\  const t = asm // -2
    \\  volatile // -1
    \\  ( // 0
    \\    "syscall" // 1
    \\    : // 1b
    \\    [ret] "={rax}" (->usize), // 2
    \\    : // 2b
    \\    [number] "{rax}" (number), // 3
    \\      [arg1] "{rdi}" (arg1) // 4
    \\    , //4x
    \\    : // 4b
    \\    .{
    \\      .rcx = true,
    \\      .r11 = true,
    \\    } // 5
    \\  );
    \\
    \\  asm // 0
    \\  ( // 1
    \\    // I'm top
    \\    \\.global my_func;
    \\    \\.type my_func, @function; // 2
    \\    \\my_func:
    \\    \\  lea (%rdi,%rsi,1),%eax
    \\    \\  retq
    \\    // I'm bottom
    \\  ) // 3
    \\  ;
    \\}
  );
}

test "asm 5" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  // from ziglang's Assembly page:
  \\ pub fn syscall3(number: usize, arg1: usize, arg2: usize, arg3: usize) usize {
  \\    return asm volatile ("syscall" // 1
  \\        : [ret] "={rax}" (-> usize), // 2
  \\        : [number] "{rax}" (number), // 3
  \\          [ // 1
  \\ arg1 // 2
  \\ ] // 3
  \\ "{rdi}" // 4
  \\ ( // 1
  \\ arg1 // 2
  \\ ) // 3
  \\ ,
  \\          [arg2] "{rsi}" (arg2),
  \\          [arg3] "{rdx}" (arg3), // 4
  \\        : .{ .rcx = true, .r11 = true });
  \\}
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\pub fn syscall3(number: usize, arg1: usize, arg2: usize, arg3: usize) usize {
    \\  return asm volatile(
    \\    "syscall" // 1
    \\    : [ret] "={rax}" (->usize), // 2
    \\    : [number] "{rax}" (number), // 3
    \\      [ // 1
    \\    arg1 // 2
    \\    ] // 3
    \\    "{rdi}" // 4
    \\    ( // 1
    \\    arg1 // 2
    \\    ) // 3
    \\    ,
    \\      [arg2] "{rsi}" (arg2),
    \\      [arg3] "{rdx}" (arg3), // 4
    \\    : .{ .rcx = true, .r11 = true }
    \\  );
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\pub fn syscall3(
    \\  number: usize,
    \\  arg1: usize,
    \\  arg2: usize,
    \\  arg3: usize,
    \\) usize {
    \\  return asm volatile(
    \\    "syscall" // 1
    \\    : [ret] "={rax}" (->usize), // 2
    \\    : [number] "{rax}" (number), // 3
    \\      [ // 1
    \\    arg1 // 2
    \\    ] // 3
    \\    "{rdi}" // 4
    \\    ( // 1
    \\    arg1 // 2
    \\    ) // 3
    \\    ,
    \\      [arg2] "{rsi}" (arg2),
    \\      [arg3] "{rdx}" (arg3), // 4
    \\    : .{
    \\      .rcx = true,
    \\      .r11 = true,
    \\    }
    \\  );
    \\}
  );
}

test "extern-fn-with-string-lit" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  // from zigdown project
  \\const W = struct {
  \\    extern "kernel32" fn SetConsoleOutputCP(wCodePageID: c_uint) c_int;
  \\};
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\const W = struct {
    \\  extern "kernel32" fn SetConsoleOutputCP(wCodePageID: c_uint) c_int;
    \\};
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\const W = struct {
    \\  extern "kernel32" fn SetConsoleOutputCP(
    \\    wCodePageID: c_uint,
    \\  ) c_int;
    \\};
  );
}

test "for-trailing-comma" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\comptime {
  \\for (
  \\    some_foo.bar(123),
  \\    some_foo.bar(123),
  \\) |*abc, *efg| {
  \\  doSomeWork();
  \\}
  \\}
  ;
  const al = arena.allocator();
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\comptime {
    \\  for (some_foo.bar(123), some_foo.bar(123)) |*abc, *efg| {
    \\    doSomeWork();
    \\  }
    \\}
  );
  // using width: 30
  res = try format(doc, .{ .width = 30 }, al);
  try check(
    res,
    \\comptime {
    \\  for (
    \\    some_foo.bar(123),
    \\    some_foo.bar(123),
    \\  ) |*abc, *efg| {
    \\    doSomeWork();
    \\  }
    \\}
  );
}

test "misc" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ fn foo() void {
  \\lhs <<|= // x
  \\ rhs;
  \\ continue // 0
  \\ : // 1
  \\ lbl // 2 
  \\ expr();
  \\ var t = ! // 1
  \\ foo;
  \\ var y = ~ // 0
  \\ foo;
  \\ var z = -% // 1
  \\ foo;
  \\ var a = expr().*;
  \\ var a = expr // 1
  \\ .* // 2
  \\ ;
  \\ var j = foo // 0
  \\ . // 1
  \\ ? // 2
  \\ .bar.?.cat;
  \\ var j = foo.?.bar.?.cat;
  \\ var j = foo().?.bar.?.cat;
  \\ defer // 1
  \\ foo().?.bar.?.cat;
  \\ errdefer // 2
  \\ foo().?.bar.?.cat;
  \\ defer foo().?.bar.?.cat;
  \\ errdefer foo().?.bar.?.cat;
  \\ defer {foo().?.bar.?.cat;}
  \\ errdefer foo().?.bar.?.cat;
  \\ errdefer // 1
  \\ | // 2
  \\ // xyz ok
  \\ f // 3
  \\ | // 4
  \\ foo().cat;
  \\ comptime var x = 5;
  \\ comptime  {
  \\var x = 5;
  \\ }
  \\ comptime  // 1
  \\ {
  \\var x = 5;
  \\ }
  \\  suspend // 1
  \\ foo();
  \\  resume // 1
  \\ foo();
  \\  anyframe // 1
  \\ -> // 2
  \\ foo(1, 2, 4);
  \\}
  \\ const E = error { // a
  \\ /// just some stuff
  \\ a, b, 
  \\ /// another?
  \\c,
  \\
  \\ } // last
  \\;
  \\ const E = error {a, b, c};
  \\
  \\ test // 1
  \\ "foo" // 2 
  \\ { // 3
  \\  var x = check(abc);
  \\} // 4
  \\
  \\ test // 1
  \\ MyFoo // 2
  \\ {
  \\  var x = check(abc);
  \\} // 3
  \\
  \\ test "foo" {
  \\  var x = check(abc);
  \\}
  \\
  \\ test MyFoo {
  \\  suspend foo();
  \\  resume foo();
  \\  var x = check(abc);
  \\  anyframe -> foo(1, 2, 4);
  \\}
  ;
  const al = arena.allocator();
  // default width: 85
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(
    res,
    \\fn foo() void {
    \\  lhs <<|= // x
    \\  rhs;
    \\  continue // 0
    \\  : // 1
    \\  lbl // 2
    \\  expr();
    \\  var t = ! // 1
    \\  foo;
    \\  var y = ~ // 0
    \\  foo;
    \\  var z = -% // 1
    \\  foo;
    \\  var a = expr().*;
    \\  var a = expr // 1
    \\  .* // 2
    \\  ;
    \\  var j = foo // 0
    \\  . // 1
    \\  ? // 2
    \\  .bar.?.cat;
    \\  var j = foo.?.bar.?.cat;
    \\  var j = foo().?.bar.?.cat;
    \\  defer // 1
    \\  foo().?.bar.?.cat;
    \\  errdefer // 2
    \\  foo().?.bar.?.cat;
    \\  defer foo().?.bar.?.cat;
    \\  errdefer foo().?.bar.?.cat;
    \\  defer {
    \\    foo().?.bar.?.cat;
    \\  }
    \\  errdefer foo().?.bar.?.cat;
    \\  errdefer // 1
    \\  | // 2
    \\  // xyz ok
    \\  f // 3
    \\  | // 4
    \\  foo().cat;
    \\  comptime var x = 5;
    \\  comptime {
    \\    var x = 5;
    \\  }
    \\  comptime // 1
    \\  {
    \\    var x = 5;
    \\  }
    \\  suspend // 1
    \\  foo();
    \\  resume // 1
    \\  foo();
    \\  anyframe // 1
    \\  -> // 2
    \\  foo(1, 2, 4);
    \\}
    \\const E = error{ // a
    \\  /// just some stuff
    \\  a,
    \\  b,
    \\  /// another?
    \\  c,
    \\} // last
    \\;
    \\const E = error{ a, b, c };
    \\
    \\test // 1
    \\"foo" // 2
    \\{ // 3
    \\  var x = check(abc);
    \\} // 4
    \\
    \\test // 1
    \\MyFoo // 2
    \\{
    \\  var x = check(abc);
    \\} // 3
    \\
    \\test "foo" {
    \\  var x = check(abc);
    \\}
    \\
    \\test MyFoo {
    \\  suspend foo();
    \\  resume foo();
    \\  var x = check(abc);
    \\  anyframe->foo(1, 2, 4);
    \\}
  );
  // using width: 20
  res = try format(doc, .{ .width = 20 }, al);
  try check(
    res,
    \\fn foo() void {
    \\  lhs <<|= // x
    \\  rhs;
    \\  continue // 0
    \\  : // 1
    \\  lbl // 2
    \\  expr();
    \\  var t = ! // 1
    \\  foo;
    \\  var y = ~ // 0
    \\  foo;
    \\  var z = -% // 1
    \\  foo;
    \\  var a = expr().*;
    \\  var a = expr // 1
    \\  .* // 2
    \\  ;
    \\  var j = foo // 0
    \\    . // 1
    \\    ? // 2
    \\    .bar
    \\    .?
    \\    .cat;
    \\  var j = foo
    \\    .?
    \\    .bar
    \\    .?
    \\    .cat;
    \\  var j = foo()
    \\    .?
    \\    .bar
    \\    .?
    \\    .cat;
    \\  defer // 1
    \\  foo().?.bar.?.cat;
    \\  errdefer // 2
    \\  foo().?.bar.?.cat;
    \\  defer foo()
    \\    .?
    \\    .bar
    \\    .?
    \\    .cat;
    \\  errdefer foo()
    \\    .?
    \\    .bar
    \\    .?
    \\    .cat;
    \\  defer {
    \\    foo()
    \\      .?
    \\      .bar
    \\      .?
    \\      .cat;
    \\  }
    \\  errdefer foo()
    \\    .?
    \\    .bar
    \\    .?
    \\    .cat;
    \\  errdefer // 1
    \\  | // 2
    \\  // xyz ok
    \\  f // 3
    \\  | // 4
    \\  foo().cat;
    \\  comptime var x = 5;
    \\  comptime {
    \\    var x = 5;
    \\  }
    \\  comptime // 1
    \\  {
    \\    var x = 5;
    \\  }
    \\  suspend // 1
    \\  foo();
    \\  resume // 1
    \\  foo();
    \\  anyframe // 1
    \\  -> // 2
    \\  foo(1, 2, 4);
    \\}
    \\const E = error{ // a
    \\  /// just some stuff
    \\  a,
    \\  b,
    \\  /// another?
    \\  c,
    \\} // last
    \\;
    \\const E = error{
    \\  a,
    \\  b,
    \\  c,
    \\};
    \\
    \\test // 1
    \\"foo" // 2
    \\{ // 3
    \\  var x = check(
    \\    abc,
    \\  );
    \\} // 4
    \\
    \\test // 1
    \\MyFoo // 2
    \\{
    \\  var x = check(
    \\    abc,
    \\  );
    \\} // 3
    \\
    \\test "foo" {
    \\  var x = check(
    \\    abc,
    \\  );
    \\}
    \\
    \\test MyFoo {
    \\  suspend foo();
    \\  resume foo();
    \\  var x = check(
    \\    abc,
    \\  );
    \\  anyframe->foo(
    \\    1,
    \\    2,
    \\    4,
    \\  );
    \\}
  );
}
