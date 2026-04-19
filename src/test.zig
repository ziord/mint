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
  var t = try ts.Translate.init(src, al, .zig);
  return t.translate();
}

fn format(doc: *fmt.Doc, cfg: fmt.FmtConfig, al: Allocator) ![]const u8 {
  var f = fmt.Format.init(std.testing.io, al, cfg);
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
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
    \\var x = foo(abc, bar, baz);
  );
  // using width: 10
  res = try format(doc, .{.width = 10}, al);
  try check(res,
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
  // default width: 80
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
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
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
    \\const g: [
    \\  *:Bar
    \\]const Foo = x.box(
    \\  abc(),
    \\  bar,
    \\  baz,
    \\);
    \\const Foo = box(
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
  // default width: 80
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
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
  // using width: 100
  res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  // default width: 80
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
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
    \\
    \\var buffer align(64) = undefined;
    \\var buffer
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\    .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var a align(b) = c;
    \\
    \\var a: b align(c) = d;
  );
  // using width: 100
  res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const buffer: [1024]u8
    \\  align(64) = text(self.token_token_token_token_token_token_token_token_token_token(rhs, abc, lhs));
    \\const buffer: [1024]u8
    \\  align(64) = text(
    \\  self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\
    \\var buffer align(64) = undefined;
    \\var buffer
    \\  align(64) = text(
    \\  self.token_token.token2_token().token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var a align(b) = c;
    \\
    \\var a: b align(c) = d;
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
    \\
    \\var buffer align(64) = undefined;
    \\var buffer
    \\  align(64) = text(
    \\  self.token_token.token2_token()
    \\    .token_token_token_token_token_token(rhs, abc, lhs),
    \\);
    \\var a align(b) = c;
    \\
    \\var a: b align(c) = d;
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
    \\
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
    \\
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
  // default width: 80
  const doc = try translate(src, al);
  const res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  // default width: 80
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  // default width: 80
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  // default width: 80
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  // default width: 80
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  // default width: 80
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  // default width: 80
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
    \\var q = fox()().hahah(a, b, "yes").bar(abc());
    \\var q = fox()().hahah(a, b, "yes").bar(compute_something(long_arg1, long_arg2));
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(compute_something(long_arg1, xlong_arg2));
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\var q = fox()().hahah(a, b, "yes").bar(abc());
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(compute_something(long_arg1, long_arg2));
    \\var q = fox()()
    \\  .hahah(a, b, "yes")
    \\  .bar(compute_something(long_arg1, xlong_arg2));
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  // default width: 80
  const doc = try translate(src, al);
  var res = try format(doc, .{}, al);
  try check(res,
    \\var sb = self.db.seqb().appends(compute_value(lhs, rhs));
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\var sb = self.db.seqb().appends(compute_value(lhs, rhs));
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  // using width: 100
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  // using width: 100
  try check(res,
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
  res = try format(doc, .{.width = 90}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  // default width: 80
  const doc = try translate(src, al);
  const res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  \\ fn foo(x: std.ArrayList(T), comptime x: i32, ..., noalias y: u2, k: anytype,) A(T) {
  \\  var x = 5;
  \\    print("just testing!");
  \\   var x: i32, const y: u32 = foo_(bar(1, 2));
  \\   x = 5;
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn foo(x: std.ArrayList(T), comptime x: i32, ..., noalias y: u2, k: anytype) A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\  x = 5;
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn foo3(comptime T: type, x: std.ArrayList(T), comptime x: i32, ...) A(T) {}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\fn foo3(comptime T: type, x: std.ArrayList(T), comptime x: i32, ...) A(T) {}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\pub fn foo4(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\pub fn foo4(
    \\  comptime T: type,
    \\  x: std.ArrayList(T),
    \\  comptime x: i32,
    \\  noalias y: u2,
    \\  k: anytype,
    \\) A(T) {}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  \\ pub inline fn foo6(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  \\ pub export fn foo8(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T) {
  \\ }
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  \\ pub extern fn foo10(comptime T: type, x: std.ArrayList(T), comptime x: i32, noalias y: u2, k: anytype) A(T);
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\pub fn fan() align(64) addrspace(.generic) callconv(.c) linksection(".my_custom_section") A(T) {
    \\  var x = 5;
    \\  print("just testing!");
    \\  var x: i32, const y: u32 = foo_(bar(1, 2));
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const T = fn (a: anytype, comptime T: type, x: i32) u32;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) u32;
    \\const T = fn (a: anytype, comptime T: type, x: i32) void;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) []const u8;
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const T = fn (a: anytype, comptime T: type, x: i32) u32;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) u32;
    \\const T = fn (a: anytype, comptime T: type, x: i32) void;
    \\const T = fn abc(a: anytype, comptime T: type, x: i32) []const u8;
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\fn foo(bar: T) void {
    \\  comptime const x, var y = expr;
    \\  comptime const x, const y = expr;
    \\}
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  const res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  const res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\fn ship(x: u32, y: TypeExpr) b: {var x = getType(); break :b setType(x);} {
  \\ return voidExpr();  
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  res = try format(doc, .{.width = 100, .indent = 4}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  res = try format(doc, .{.width = 100, .indent = 4}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  res = try format(doc, .{.width = 100, .indent = 4}, al);
  try check(res,
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
  // default width: 80, indent: 4
  res = try format(doc, .{.width = 80, .indent = 4}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  res = try format(doc, .{.width = 100, .indent = 4}, al);
  try check(res,
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
  // default width: 80, indent: 4
  res = try format(doc, .{.width = 80, .indent = 4}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  res = try format(doc, .{.width = 100, .indent = 4}, al);
  try check(res,
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
  // default width: 80, indent: 4
  res = try format(doc, .{.width = 80, .indent = 4}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = struct { x: []const u8, y: u32 };
    \\const Ty = struct { ab: []const u8, xyz: u32 };
    \\const Ty = struct(arg) { ab: []const u8, xyz: u32 };
    \\const Ty = packed struct { x1: []const u8, y1: u32 };
    \\const Ty = extern struct { x2: []const u8, y2: u32 };
    \\const Ty = extern struct(arg) { x2: []const u8, y2: u32 };
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const Ty = struct { x: []const u8, y: u32 };
    \\const Ty = struct { ab: []const u8, xyz: u32 };
    \\const Ty = struct(arg) { ab: []const u8, xyz: u32 };
    \\const Ty = packed struct { x1: []const u8, y1: u32 };
    \\const Ty = extern struct { x2: []const u8, y2: u32 };
    \\const Ty = extern struct(arg) { x2: []const u8, y2: u32 };
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\const Ty = struct { x: []const u8, y: u32 };
    \\const Ty = struct { ab: []const u8, xyz: u32 };
    \\const Ty = struct(arg) { ab: []const u8, xyz: u32 };
    \\const Ty = packed struct { x1: []const u8, y1: u32 };
    \\const Ty = extern struct { x2: []const u8, y2: u32 };
    \\const Ty = extern struct(arg) { x2: []const u8, y2: u32 };
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay"};
  \\ }
  \\  pub fn foo(self: @This()) !@This(a, b, c, d) {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{  .al = al,       .cfg = cfg,     .mem_writer = std.Io.Writer.Allocating.init(al),     .out_writer = std.fs.File.Writer.init(std.fs.File.stdout(), &WriteBuf),   };
  \\ }
  \\  pub noinline fn foo(self: @This()) Foo!@This(a, b, c, d) {
  \\   var j = Ty{.x = "yay", .y = 0xff, .y = 0xff, .y = 0xff, .y = 0xff, .y = 0xff, .y = 0xff, .y = 0xff, .y = 0xff};
  \\   return .{.x = "yay"};
  \\ }
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = struct {
    \\  xabc: []const u8,
    \\  y123: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay"};
    \\  }
    \\
    \\  pub fn foo(self: @This()) !@This(a, b, c, d) {
    \\    var j = Ty{.x = "yay", .y = 0xff};
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
    \\    return .{.x = "yay"};
    \\  }
    \\};
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const Ty = struct {
    \\  xabc: []const u8,
    \\  y123: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay"};
    \\  }
    \\
    \\  pub fn foo(self: @This()) !@This(a, b, c, d) {
    \\    var j = Ty{.x = "yay", .y = 0xff};
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
    \\    return .{.x = "yay"};
    \\  }
    \\};
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\const Ty = struct {
    \\  xabc: []const u8,
    \\  y123: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay"};
    \\  }
    \\
    \\  pub fn foo(self: @This()) !@This(a, b, c, d) {
    \\    var j = Ty{.x = "yay", .y = 0xff};
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
    \\    return .{.x = "yay"};
    \\  }
    \\};
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
    \\    return .{.x = "yay"};
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
    \\    return .{.x = "yay"};
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) { file, out, mem } = .mem,
    \\};
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) { file, out, mem } = .mem,
    \\};
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) { file, out, mem } = .mem,
    \\};
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\};
  \\ const Ty = union(Foo) {
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
    \\const Ty = union(Foo) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
    \\const Ty = union(Foo) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
    \\const Ty = union(Foo) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = union(enum) { x: []const u8, y: u32 };
    \\const Ty = union(Foo) { x: []const u8, y: u32 };
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const Ty = union(enum) { x: []const u8, y: u32 };
    \\const Ty = union(Foo) { x: []const u8, y: u32 };
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\const Ty = union(enum) { x: []const u8, y: u32 };
    \\const Ty = union(Foo) { x: []const u8, y: u32 };
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = struct(arg.foo(xyz, "ok").bar('y').yes(a, b, c, d)) { ab: []const u8, xyz: u32 };
    \\const Ty = struct(Foo) { x: []const u8, y: u32 };
    \\const Ty = struct {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
    \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(11, "yes"),
    \\};
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = opaque { x: []const u8, y: u32 };
    \\const Ty = opaque {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
    \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(11, "yes"),
    \\};
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const Ty = opaque { x: []const u8, y: u32 };
    \\const Ty = opaque {
    \\  x: []const u8 align(abc),
    \\  y: u32 align(foo(a, b, c, d)) = box(11, "yes"),
    \\  z: u32 align(foo(bar(1, 'a'), yes("joe", xyz))) = box(11, "yes"),
    \\};
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\ const fox = 0xdeadbeef;
  \\ const fox = enum {a, b, c};
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  const fox = 0xdeadbeef;
    \\  const fox = enum { a, b, c };
    \\};
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  const fox = 0xdeadbeef;
    \\  const fox = enum { a, b, c };
    \\};
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  const fox = 0xdeadbeef;
    \\  const fox = enum { a, b, c };
    \\};
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\ abc: []const u8,
  \\ const fox1 = 0xdeadbeef;
  \\ const fox2 = enum {a, b, c};
  \\ const fox3 = union (big) {a, b, c};
  \\ x: usize,
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  abc: []const u8,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox2 = enum { a, b, c };
    \\  const fox3 = union(big) { a, b, c };
    \\
    \\  x: usize,
    \\};
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  abc: []const u8,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox2 = enum { a, b, c };
    \\  const fox3 = union(big) { a, b, c };
    \\
    \\  x: usize,
    \\};
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\const Ty = union(enum(Foo(a, b, c))) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  abc: []const u8,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox2 = enum { a, b, c };
    \\  const fox3 = union(big) { a, b, c };
    \\
    \\  x: usize,
    \\};
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
    \\  abc: []const u8,
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
    \\
    \\  x: usize,
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
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = union(enum) {
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const Ty = union(enum) {
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\const Ty = union(enum) {
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\};
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\  pub fn foo(self: @This()) @This() {
  \\   var j = Ty{.x = "yay", .y = 0xff};
  \\   return .{.x = "yay", .y = 0xff};
  \\ }
  \\ abc: []const u8,
  \\ x: usize,
  \\ pub fn x() void {}
  \\};
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  abc: []const u8,
    \\  x: usize,
    \\
    \\  pub fn x() void {}
    \\};
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  abc: []const u8,
    \\  x: usize,
    \\
    \\  pub fn x() void {}
    \\};
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  pub fn foo(self: @This()) @This() {
    \\    var j = Ty{.x = "yay", .y = 0xff};
    \\    return .{.x = "yay", .y = 0xff};
    \\  }
    \\
    \\  abc: []const u8,
    \\  x: usize,
    \\
    \\  pub fn x() void {}
    \\};
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
    \\
    \\  abc: []const u8,
    \\  x: usize,
    \\
    \\  pub fn x() void {}
    \\};
  );
}

test "containerdecl 13" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ pub const Ty = union(enum) {
  \\  x: []const u8,
  \\  y: u32,
  \\ const fox1 = 0xdeadbeef;
  \\ const fox1 = struct{};
  \\};
  \\ var x = 5;
  \\ y: []u8,
  \\ abc: []const u8,
  \\ z: u32,
  \\pub const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
  \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
  \\const Ty = union(enum(Foo(a, b, c))) {};
  \\ var x = 5;
  \\ y: []u8,
  \\ abc: []const u8,
  \\ z: u32,
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\pub const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox1 = struct {};
    \\};
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\pub const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {};
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\pub const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox1 = struct {};
    \\};
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\pub const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {};
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\pub const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox1 = struct {};
    \\};
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\pub const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo)) { x: []const u8, y: u32 };
    \\const Ty = union(enum(Foo(a, b, c))) {};
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\pub const Ty = union(enum) {
    \\  x: []const u8,
    \\  y: u32,
    \\
    \\  const fox1 = 0xdeadbeef;
    \\  const fox1 = struct {};
    \\};
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
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
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
  );
}

test "containerdecl 14" {
  var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
  defer arena.deinit();
  const src =
  \\ pub const Ty = 0xff;
  \\ var x = 5;
  \\ y: []u8,
  \\ abc: []const u8,
  \\ z: u32,
  \\ var x = 5;
  \\ y: []u8,
  \\ abc: []const u8,
  \\ z: u32,
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\pub const Ty = 0xff;
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\pub const Ty = 0xff;
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\pub const Ty = 0xff;
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\pub const Ty = 0xff;
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
    \\
    \\var x = 5;
    \\
    \\y: []u8,
    \\abc: []const u8,
    \\z: u32,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\pub const FmtConfig = struct {
    \\  width: u32 = 80,
    \\  indent: u8 = 2,
    \\  decl_line_seps: u8 = 2,
    \\  writer: enum(u3) { file: File, out: Out, mem: Mem } = .mem,
    \\};
    \\const fox2 = enum { a, b, c };
    \\const fox3 = union(big) { a: A(abc, xyz), b: B, c: C(Type("Foo")) };
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\
  \\ var x: *align(foo("ok")) rhs = 0xff;
  \\ var a: **rhs = 0xff;
  \\ var abc: ***align(foo():Car():Bar()) rhs = 0xff;
  \\ var xyz: **align(foo():Car():Bar()) rhs = 0xff;
  \\ var a: ***rhs = 0xff;
  \\
  \\ var y: []rhs = 0xff;
  \\ var y: []const rhs = 0xff;
  \\
  \\ var k: [*:lhs]rhs = 0xff;
  \\ var a: [:lhs]rhs = 0xff;
  \\ var j: [lhs:Foo(T, K)] rhs = 0xff;
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\var j: [lhs:Foo(T, K)]rhs = 0xff;
    \\var j: [lhs:Foo(T, K)]Foo(Bar.xyz(abc)) = 0xff;
    \\var j: [*c]align(foo(bar.oop(0x12))) rhs = 0xff;
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\var j: [lhs:Foo(T, K)]rhs = 0xff;
    \\var j: [lhs:Foo(T, K)]Foo(Bar.xyz(abc)) = 0xff;
    \\var j: [*c]align(foo(bar.oop(0x12))) rhs = 0xff;
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\var j: [lhs:Foo(T, K)]rhs = 0xff;
    \\var j: [lhs:Foo(T, K)]Foo(Bar.xyz(abc)) = 0xff;
    \\var j: [*c]align(foo(bar.oop(0x12))) rhs = 0xff;
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\ var x: *allowzero align(foo("ok")) Rhs = 0xff;
  \\ var x: *allowzero addrspace(Foo(Bar())) align(foo("ok")) Rhs = 0xff;
  \\ var x: *allowzero addrspace(Foo(Bar())) align(foo("ok")) const Rhs = 0xff;
  \\ var x: *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Rhs = 0xff;
  \\ var x: *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc)) = 0xff;
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\ fn foo() *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc)) {
  \\   return 0;
  \\}
  \\ fn foo(abc: *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc))) *allowzero align(foo("ok")) Rhs {
  \\   return 0;
  \\}
  \\ fn foo(abc: *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc))) *allowzero addrspace(Foo(Bar())) align(foo("ok")) volatile const Foo(Bar.xyz(abc)) {
  \\   return 0;
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\
  \\ var abc = someFunc(1, 2, 3) catch |e| 5;
  \\ var abc = someFunc(1, 2, 3) catch expr();
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\var abc = try someFunc(1, 2, 3);
    \\var abc = someTestFunc(try someFunc(1, 2, 3));
    \\var abc = someTestFunc(try someFunc(1, 2, 3), try someFunc(1, 2, 3));
    \\var abc = someFunc(1, 2, 3) catch |e| 5;
    \\var abc = someFunc(1, 2, 3) catch expr();
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\var abc = try someFunc(1, 2, 3);
    \\var abc = someTestFunc(try someFunc(1, 2, 3));
    \\var abc = someTestFunc(try someFunc(1, 2, 3), try someFunc(1, 2, 3));
    \\var abc = someFunc(1, 2, 3) catch |e| 5;
    \\var abc = someFunc(1, 2, 3) catch expr();
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\var abc = someFunc(1, 2, 3) catch return;
    \\var abc = someFunc(1, 2, 3) catch |e| {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3)
    \\  catch |e| blk: {
    \\    someBlock();
    \\    break :blk result("okay");
    \\  };
    \\var abc = someFunc(1, 2, 3) catch {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3) catch blk: {
    \\  someBlock();
    \\  break :blk result("okay");
    \\};
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\var abc = someFunc(1, 2, 3) catch return;
    \\var abc = someFunc(1, 2, 3) catch |e| {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3)
    \\  catch |e| blk: {
    \\    someBlock();
    \\    break :blk result("okay");
    \\  };
    \\var abc = someFunc(1, 2, 3) catch {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3)
    \\  catch blk: {
    \\    someBlock();
    \\    break :blk result("okay");
    \\  };
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\var abc = someFunc(1, 2, 3)
    \\  catch return;
    \\var abc = someFunc(1, 2, 3)
    \\  catch |e| {
    \\    someBlock();
    \\  };
    \\var abc = someFunc(1, 2, 3)
    \\  catch |e| blk: {
    \\    someBlock();
    \\    break :blk result("okay");
    \\  };
    \\var abc = someFunc(1, 2, 3)
    \\  catch {
    \\    someBlock();
    \\  };
    \\var abc = someFunc(1, 2, 3)
    \\  catch blk: {
    \\    someBlock();
    \\    break :blk result("okay");
    \\  };
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\var abc = someFunc(1, 2, 3) orelse return;
    \\var abc = someFunc(1, 2, 3) orelse {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3)
    \\  orelse blk: {
    \\    someBlock();
    \\    break :blk result("okay");
    \\  };
    \\var abc = someFunc(1, 2, 3) orelse {
    \\  someBlock();
    \\};
    \\var abc = someFunc(1, 2, 3)
    \\  orelse blk: {
    \\    someBlock();
    \\    break :blk result("okay");
    \\  };
    \\var abc = 5 * 4
    \\  + 3
    \\  - abc
    \\  + 4
    \\  - 3
    \\  + (someFunc(1, 2, 3) orelse expr());
  );
  // using width: 30
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\var abc = someFunc(1, 2, 3)
    \\  orelse return;
    \\var abc = someFunc(1, 2, 3)
    \\  orelse {
    \\    someBlock();
    \\  };
    \\var abc = someFunc(1, 2, 3)
    \\  orelse blk: {
    \\    someBlock();
    \\    break :blk result("okay");
    \\  };
    \\var abc = someFunc(1, 2, 3)
    \\  orelse {
    \\    someBlock();
    \\  };
    \\var abc = someFunc(1, 2, 3)
    \\  orelse blk: {
    \\    someBlock();
    \\    break :blk result("okay");
    \\  };
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn testing() void {
    \\  if (a) b else d;
    \\  if (a) |x| b else d;
    \\  if (a) |x| b else |y| d;
    \\  if (expr()) doStuff();
    \\  if (expr()) |pl| doStuff();
    \\  var z = if (a) b else d;
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 20}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 20}, al);
  try check(res,
    \\fn testing() void {
    \\  var z = if (a)
    \\    b: {
    \\      var x = y;
    \\    }
    \\  else
    \\    d;
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 20}, al);
  try check(res,
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
  \\}
  ;
  const al = arena.allocator();
  // using width: 100
  const doc = try translate(src, al);
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn testing() void {
    \\  {
    \\    if (someExpr()) {
    \\    } else {
    \\    }
    \\    if (someExpr()) |payload| {
    \\    } else {
    \\    }
    \\  }
    \\  if ((lhs.isStruct() and lhs.strukt().node.modifier.isFrozen()) or (lhs.isData() and lhs.data().node.modifier.isFrozen())) {
    \\    return self.error_(true, open.lhs_name.toToken(), "cannot open frozen type '{s}'", .{self.getTypename(lhs)});
    \\  }
    \\  if (lhs.isStruct() and lhs.strukt().node.modifier.isFrozen() or lhs.isData() and lhs.data().node.modifier.isFrozen()) {
    \\    return self.error_(true, open.lhs_name.toToken(), "cannot open frozen type '{s}'", .{self.getTypename(lhs)});
    \\  }
    \\  if (lhs.isStruct() and lhs.strukt().node.modifier.isFrozen() or lhs.isData() and lhs.data().node.modifier.isFrozen()) {
    \\    return self.error_(true, open.lhs_name.toToken(), "cannot open frozen type '{s}'", .{self.getTypename(lhs), self.book(0x101), self.book(0x101), self.book(0x101)});
    \\  }
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 20}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 20}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn testMe() void {
    \\  if (some) |*x| lbl: {
    \\    print('yello world');
    \\  }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (some) |*x| _ = lbl: {
    \\    print('yello world');
    \\  }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (someCond) |x| _ = blk: {
    \\    std.debug.print("x is: {}\n", .{x});
    \\    break :blk void;
    \\  }
    \\  else {
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\fn testMe() void {
    \\  if (some) |*x| lbl: {
    \\    print('yello world');
    \\  }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (some) |*x| _ = lbl: {
    \\    print('yello world');
    \\  }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (someCond) |x| _ = blk: {
    \\    std.debug.print("x is: {}\n", .{x});
    \\    break :blk void;
    \\  }
    \\  else {
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\fn testMe() void {
    \\  if (some) |*x| lbl: {
    \\    print('yello world');
    \\  }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (some) |*x| _ = lbl: {
    \\    print('yello world');
    \\  }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  if (someCond) |x| _ = blk: {
    \\    std.debug.print("x is: {}\n", .{x});
    \\    break :blk void;
    \\  }
    \\  else {
    \\    std.debug.print("done\n", .{});
    \\  }
    \\}
  );
  // using width: 20 
  res = try format(doc, .{.width = 20}, al);
  try check(res,
    \\fn testMe() void {
    \\  if (some) |*x|
    \\    lbl: {
    \\      print(
    \\        'yello world',
    \\      );
    \\    }
    \\  else {
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn testMe() void {
    \\  if (someNiceCondition(a, b, c)) |x| _ = blk: {
    \\    print('yello world');
    \\  };
    \\  if (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\fn testMe() void {
    \\  if (someNiceCondition(a, b, c)) |x| _ = blk: {
    \\    print('yello world');
    \\  };
    \\  if (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\label: switch (expr) {
    \\  a => a,
    \\  b, c => c,
    \\  inline d...e => e,
    \\  else => f,
    \\},
    \\switch (someExpr(jk)) {}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\label: switch (expr) {
    \\  a => a,
    \\  b, c => c,
    \\  inline d...e => e,
    \\  else => f,
    \\},
    \\switch (someExpr(jk)) {}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\label: switch (expr) {
    \\  a => a,
    \\  b, c => c,
    \\  inline d...e => e,
    \\  else => f,
    \\},
    \\switch (someExpr(jk)) {}
  );
  // using width: 20 
  res = try format(doc, .{.width = 20}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 20}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
    \\},
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
    \\},
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
    \\},
  );
  // using width: 30 
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
    \\},
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z|
    \\    lbl: {
    \\      print('yello world');
    \\    }
    \\  for (some, 0.., a..z) |*x, y, *z| {
    \\    print('yello world');
    \\  }
    \\  for (expr) |pl| something();
    \\}
  );
  // using width: 30 
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z
    \\  ) |*x, y, *z|
    \\    lbl: {
    \\      print('yello world');
    \\    }
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z
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
  \\ for (some, a..k) |a, b, c| {} else {var j = testM(;)}
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, a..k) |a, b, c| {
    \\  } else {
    \\  }
    \\  for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  } else someStuff();
    \\  inline for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, a..k) |a, b, c| {
    \\  } else {
    \\  }
    \\  for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  } else someStuff();
    \\  inline for (some, 0.., a..z) |*x, y, *z| lbl: {
    \\    print('yello world');
    \\  }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, a..k) |a, b, c| {
    \\  } else {
    \\  }
    \\  for (some, 0.., a..z) |*x, y, *z|
    \\    lbl: {
    \\      print('yello world');
    \\    }
    \\  else
    \\    someStuff();
    \\  inline for (some, 0.., a..z) |*x, y, *z|
    \\    lbl: {
    \\      print('yello world');
    \\    }
    \\  else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\}
  );
  // using width: 30 
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, a..k) |a, b, c| {
    \\  } else {
    \\  }
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z
    \\  ) |*x, y, *z|
    \\    lbl: {
    \\      print('yello world');
    \\    }
    \\  else
    \\    someStuff();
    \\  inline for (
    \\    some,
    \\    0..,
    \\    a..z
    \\  ) |*x, y, *z|
    \\    lbl: {
    \\      print('yello world');
    \\    }
    \\  else {
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
  \\ for (some, a..k) |a, b, c| exprMe() else {var j = testS();}
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  for (some, a..k) |a, b, c| exprMe()
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  for (some, a..k) |a, b, c| exprMe()
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  for (some, a..k) |a, b, c| exprMe()
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z
    \\  ) |*x, y, *z| {
    \\    print('yello world');
    \\  } else {
    \\    someCall();
    \\    var abc = try testS();
    \\  }
    \\  for (some, a..k) |a, b, c|
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| print('yello world') else someCall();
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| print('yello world') else someCall();
    \\}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z|
    \\    print('yello world')
    \\  else
    \\    someCall();
    \\}
  );
  // using width: 30 
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {}
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {}
    \\}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (some, 0.., a..z) |*x, y, *z| {}
    \\}
  );
  // using width: 30 
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\fn testMe() void {
    \\  for (
    \\    some,
    \\    0..,
    \\    a..z
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn testMe() void {
    \\  lbl: for (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) |x| _ = blk: {
    \\    print('yello world');
    \\  };
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\fn testMe() void {
    \\  lbl: for (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) |x| someFancy(callExpr(), a, b);
    \\  for (someNiceCondition(a, b, c)) |x| _ = blk: {
    \\    print('yello world');
    \\  };
    \\}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\fn testMe() void {
    \\  lbl: for (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\    someFancy(
    \\      callExpr(),
    \\      a,
    \\      b,
    \\    );
    \\  for (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\    someFancy(
    \\      callExpr(),
    \\      a,
    \\      b,
    \\    );
    \\  for (
    \\    someNiceCondition(a, b, c)
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  \\ };
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |x| blk: {
    \\    print('yello world');
    \\  }
    \\  else {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| blk: {
    \\    print('yello world');
    \\  } else blk2: {
    \\    someCall();
    \\  };
    \\  inline while (someNiceCondition(a, b, c)) |x| : (j += 5) print('yello world')
    \\  else |y| {
    \\    someCall();
    \\  }
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |x| blk: {
    \\    print('yello world');
    \\  }
    \\  else {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| blk: {
    \\    print('yello world');
    \\  } else blk2: {
    \\    someCall();
    \\  };
    \\  inline while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    print('yello world')
    \\  else |y| {
    \\    someCall();
    \\  }
    \\}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\fn testMe() void {
    \\  while (someNiceCondition(a, b, c)) |x|
    \\    blk: {
    \\      print('yello world');
    \\    }
    \\  else {
    \\    someCall();
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x|
    \\    blk: {
    \\      print('yello world');
    \\    }
    \\  else
    \\    blk2: {
    \\      someCall();
    \\    };
    \\  inline while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    print('yello world')
    \\  else |y| {
    \\    someCall();
    \\  }
    \\}
  );
  // using width: 30 
  res = try format(doc, .{.width = 30}, al);
  try check(res,
    \\fn testMe() void {
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\    blk: {
    \\      print('yello world');
    \\    }
    \\  else {
    \\    someCall();
    \\  }
    \\  while (
    \\    someNiceCondition(a, b, c)
    \\  ) |x|
    \\    blk: {
    \\      print('yello world');
    \\    }
    \\  else
    \\    blk2: {
    \\      someCall();
    \\    };
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
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
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res, 
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
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res, 
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
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\fn testMe() void {
    \\  lbl: while (someNiceCondition(a, b, c)) |x| : (j += 5) {
    \\    print('yello world');
    \\  }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    blk: {
    \\      print('yello world');
    \\    }
    \\  while (someNiceCondition(a, b, c)) |x| : (j += 5)
    \\    _ = blk: {
    \\      print('yello world');
    \\    };
    \\}
  );
  // using width: 30 
  res = try format(doc, .{.width = 30}, al);
  try check(res,
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
    \\  : (j += 5)
    \\    blk: {
    \\      print('yello world');
    \\    }
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
  var res = try format(doc, .{.width = 100}, al);
  try check(res,
    \\const U = packed union(u2) { a: i2, b: u2 };
    \\const u: U = .{.a = -1};
    \\
    \\switch (u) {
    \\  .{.b = 3} => {},
    \\  else => unreachable,
    \\}
  );
  // default width: 80
  res = try format(doc, .{.width = 80}, al);
  try check(res,
    \\const U = packed union(u2) { a: i2, b: u2 };
    \\const u: U = .{.a = -1};
    \\
    \\switch (u) {
    \\  .{.b = 3} => {},
    \\  else => unreachable,
    \\}
  );
  // using width: 60
  res = try format(doc, .{.width = 60}, al);
  try check(res,
    \\const U = packed union(u2) { a: i2, b: u2 };
    \\const u: U = .{.a = -1};
    \\
    \\switch (u) {
    \\  .{.b = 3} => {},
    \\  else => unreachable,
    \\}
  );
  // using width: 15
  res = try format(doc, .{.width = 15}, al);
  try check(res,
    \\const U = packed union(
    \\  u2
    \\) {
    \\  a: i2,
    \\  b: u2,
    \\};
    \\const u: U = .{
    \\  .a = -1,
    \\};
    \\
    \\switch (u) {
    \\  .{
    \\    .b = 3,
    \\  } => {},
    \\  else => unreachable,
    \\}
  );
}
