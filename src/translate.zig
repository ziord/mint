const std = @import("std");
const d = @import("doc.zig");
const util = @import("util.zig");
const config = @import("config.zig");

const log = std.log.scoped(.translate);
const assert = std.debug.assert;
const FmtConfig = config.FmtConfig;
const Doc = d.Doc;
const SeqBuilder = d.SeqBuilder;
const DocBuilder = d.DocBuilder;
const Allocator = std.mem.Allocator;
const Ast = std.zig.Ast;
const Node = Ast.Node;
const NodeIndexList = std.ArrayList(Node.Index);
const StrList = std.ArrayList([]const u8);

pub const Translate = struct {
  al: Allocator,
  tree: Ast,
  db: DocBuilder,
  _in_call_args: u16 = 0,
  _in_block: u16 = 0,

  const Self = @This();
  const NodeData = struct{tag: Node.Tag, idx: Node.Index};
  const TranslateError = error{Translate};

  pub fn init(src: [:0]const u8, al: Allocator, mode: Ast.Mode) !Self {
    return .{
      .al = al,
      .tree = try Ast.parse(al, src, mode),
      .db = DocBuilder.init(al),
    };
  }

  inline fn isVarDecl(tag: Node.Tag) bool {
    return switch (tag) {
      .simple_var_decl, .global_var_decl,
      .local_var_decl, .aligned_var_decl => true,
      else => false,
    };
  }

  fn nodeIsVarDecl(self: *Self, n: Node.Index) bool {
    return isVarDecl(self.tree.nodeTag(n));
  }

  fn isEmptyBlock(self: *Self, n: Node.Index) bool {
    switch (self.tree.nodeTag(n)) {
      .block_two, .block_two_semicolon => {
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        return first.unwrap() == null and second.unwrap() == null;
      },
      .block_semicolon, .block => {
        const rng = self.tree.nodeData(n).extra_range;
        const stmts = self.tree.extraDataSlice(rng, Node.Index);
        return stmts.len == 0;
      },
      else => return false,
    }
  }

  fn isBlock(self: *Self, tkn: Ast.TokenIndex) bool {
    return self.tree.tokenTag(tkn) == .l_brace and self.tree.tokenTag(tkn - 1) != .colon;
  }

  fn shouldAddTerminator(self: *Self, n: Node.Index) bool {
    return self.tree.tokenTag(self.tree.lastToken(n) + 1) == .semicolon;
  }

  fn unwrapTwo(
    args: [*]Node.Index,
    first: Node.OptionalIndex,
    second: Node.OptionalIndex,
  ) []Node.Index {
    const _f = first.unwrap();
    const _s = second.unwrap();
    var i: usize = 0;
    if (_f) |_n| {
      args[i] = _n;
      i += 1;
    }
    if (_s) |_n| {
      args[i] = _n;
      i += 1;
    }
    return args[0..i];
  }

  const MinSep = 2;

  inline fn getCustomDeclSep(self: *Self, seps: u8) *Doc {
    var sb = self.db.seqb();
    for (0..seps) |_| {
      sb.declline()._();
    }
    return sb.finishSeq();
  }

  inline fn getCustomNormSep(self: *Self, seps: u8) *Doc {
    var sb = self.db.seqb();
    for (0..seps) |_| {
      sb.normline()._();
    }
    return sb.finishSeq();
  }

  fn getDeclSep(self: *Self) *Doc {
    return self.getCustomDeclSep(MinSep);
  }

  fn getNormSep(self: *Self) *Doc {
    return self.getCustomNormSep(MinSep);
  }

  fn tagPrec(tag: Node.Tag) u8 {
    // NOTE: https://ziglang.org/documentation/master/#Precedence
    return switch (tag) {
      // lowest is assign
      .bool_or => 1,
      .bool_and => 2,
      .bang_equal, .equal_equal, .less_or_equal,
      .less_than, .greater_or_equal, .greater_than => 3,
      .bit_or, .bit_xor, .bit_and, .@"orelse", .@"catch" => 4,
      .shl_sat, .shl, .shr => 5,
      .add, .add_wrap, .add_sat, .array_cat, .sub, .sub_wrap, .sub_sat => 6,
      .div, .mul, .mul_sat, .mul_wrap, .mod, .array_mult, .merge_error_sets => 7,
      .negation, .negation_wrap, .address_of, .bit_not, .bool_not, .optional_type => 8,
      else => 0,
    };
  }

  inline fn _token(self: *Self, i: Ast.TokenIndex) [] const u8 {
    return self.tree.tokenSlice(i);
  }

  inline fn canAddSep(curr: Node.Tag, prev: Node.Tag) bool {
    const a = @tagName(prev);
    const b = @tagName(curr);
    if (std.mem.startsWith(u8, a, "fn") or std.mem.startsWith(u8, a, "fn")) {
      return true;
    }
    return (!(std.mem.startsWith(u8, a, b) or std.mem.startsWith(u8, a, b)));
  }

  /// simple abstraction over call chains
  const Chain = union(enum) {
    ident: Ast.TokenIndex,
    idents: []const u8,
    call: struct {
      expr: union(enum) {
        str: []const u8,
        chain: *Chain,
        node: Node.Index,
      },
      params: []const Node.Index
    },
    expr: Node.Index,

    pub const Call = struct {
      expr: Node.Index,
      params: []const Node.Index,
    };

    pub inline fn isIdent(self: Chain) bool {
      return switch (self) {
        .ident => true,
        else => false,
      };
    }

    pub inline fn is(self: Chain, k: anytype) bool {
      return self == k;
    }

    pub inline fn isCall(self: Chain) bool {
      return self.is(.call);
    }
  };

  const ChainList = std.ArrayList(Chain);

  fn getCallOneInfo(self: *Self, _n: Node.Index) struct{Node.Index, []Node.Index} {
    const fn_expr, const arg = self.tree.nodeData(_n).node_and_opt_node;
    var args = NodeIndexList.empty;
    if (arg.unwrap()) |p| {
      util.listAppend(p, &args, self.al);
    }
    return .{fn_expr, args.items};
  }

  fn getCallInfo(self: *Self, _n: Node.Index) Ast.full.Call {
    switch (self.tree.nodeTag(_n)) {
      .call, .call_comma => {
        return self.tree.callFull(_n);
      },
      .call_one, .call_one_comma => {
        const fn_expr, const params = self.getCallOneInfo(_n);
        return Ast.full.Call{
          .ast = .{
            .fn_expr = fn_expr,
            .params = params,
            .lparen = undefined,
          },
        };
      },
      else => unreachable,
    }
  }

  fn _handleChainCall(self: *Self, last: Chain, call: Ast.full.Call, list: *ChainList) void {
    switch (last) {
      .idents => |lhs| {
        const c = Chain{.call = .{.expr = .{.str = lhs}, .params = call.ast.params}};
        util.listAppend(c, list, self.al);
      }, 
      .ident => |idx| {
        const c = Chain{.call = .{.expr = .{.str = self._token(idx)}, .params = call.ast.params}};
        util.listAppend(c, list, self.al);
      },
      else => {
        const e = util.box(last, self.al);
        const c = Chain{.call = .{.expr = .{.chain = e}, .params = call.ast.params}};
        util.listAppend(c, list, self.al);
      }
    }
  }

  fn _collectChainsStep(self: *Self, n: Node.Index, list: *ChainList) !void {
    switch (self.tree.nodeTag(n)) {
      .identifier => {
        const ident = Chain{.ident = self.tree.nodeMainToken(n)};
        util.listAppend(ident, list, self.al);
      },
      .call, .call_comma, .call_one, .call_one_comma => {
        const call = self.getCallInfo(n);
        try self._collectChainsStep(call.ast.fn_expr, list);
        const last = list.pop().?;
        self._handleChainCall(last, call, list);
      },
      .field_access => {
        const lhs, const _rhs = self.tree.nodeData(n).node_and_token;
        try self._collectChainsStep(lhs, list);
        const last = list.getLast();
        switch (last) {
          .ident => |idx| {
            _ = list.pop().?;
            const lhs_tkn = self._token(idx);
            const rhs_tkn = self._token(_rhs);
            const merged = std.fmt.allocPrint(
              self.al, "{s}.{s}", .{lhs_tkn, rhs_tkn}
            ) catch unreachable;
            util.listAppend(Chain{.idents = merged}, list, self.al);
          },
          .idents => |id| {
            _ = list.pop().?;
            const lhs_tkn = id;
            const rhs_tkn = self._token(_rhs);
            const merged = std.fmt.allocPrint(
              self.al, "{s}.{s}", .{lhs_tkn, rhs_tkn}
            ) catch unreachable;
            util.listAppend(Chain{.idents = merged}, list, self.al);
          },
          else => {
            const ident = Chain{.ident = _rhs};
            util.listAppend(ident, list, self.al);
          }
        }
      },
      else => {
        util.listAppend(Chain{.expr = n}, list, self.al);
      },
    }
  }

  fn collectChains(self: *Self, n: Node.Index) ?[]Chain {
    var list = ChainList.empty;
    switch (self.tree.nodeTag(n)) {
      .field_access => {
        self._collectChainsStep(n, &list) catch return null;
      },
      else => return null,
    }
    return if (list.items.len > 0) list.items else null;
  }

  fn flattenChains(self: *Self, call: Ast.full.Call) ?[]Chain {
    // NOTE: foo().bar(..) | <expr>.bar(..)
    //       `--> [foo(), bar(..)] | [<expr>, bar(..)]
    // For example:
    // foo().bar() -> foo(), bar()
    // foo.bar().cat() -> foo.bar(), cat()
    // foo().bar().cat(a, b) -> foo(), bar(), cat(a, b)
    // NOTE: we combine idents as much as possible:
    // foo.bar() -> foo.bar()
    // foo.bar.cat() -> foo.bar.cat()
    // foo.bar.cat(a, b) -> foo.bar.cat(a, b)
    var list = ChainList.empty;
    if (self.collectChains(call.ast.fn_expr)) |segments| {
      const last = segments[segments.len - 1];
      util.listAppendSlice(Chain, &list, segments[0..segments.len - 1], self.al);
      self._handleChainCall(last, call, &list);
    }
    return if (list.items.len > 0) list.items else null;
  }

  fn tChain(self: *Self, chain: Chain) !*Doc {
    switch (chain) {
      .ident => |idx| {
        return self.db.text(self._token(idx));
      },
      .idents => |tkns| {
        return self.db.text(tkns);
      },
      .expr => |_n| {
        return self.t(_n);
      },
      .call => |c| {
        var sb = self.db.seqb();
        switch (c.expr) {
          .str => |s| {
            sb.text(s)._();
          },
          .chain => |chn| {
            sb.append(try self.tChain(chn.*));
          },
          .node => |nd| {
            sb.append(try self.t(nd));
          },
        }
        sb.text("(")._();
        const should_softline = c.params.len > 0;
        const id = d.genGroupID();
        var args = try self.tCallArgs(id, .root, c.params, should_softline);
        sb.indent(args.finish())._();
        sb.softlineIf(should_softline).text(")")._();
        return self.db.groupi(id, sb.finish());
      },
    }
  }

  fn tCallChain(self: *Self, call: Ast.full.Call) TranslateError!?*Doc {
    if (self.flattenChains(call)) |chains| {
      var sbs: std.ArrayList(*Doc) = .empty;
      for (chains) |chain| {
        const doc = try self.tChain(chain);
        util.listAppend(doc, &sbs, self.al);
      }
      const id = d.genGroupID();
      var flat = self.db.seqb();
      for (sbs.items, 0..) |doc, i| {
        if (i > 0) {
          flat.text(".")._();
        }
        flat.append(doc);
      }
      var split = self.db.seqb();
      split.append(sbs.items[0]);
      var rest = self.db.seqb();
      for (sbs.items[1..], 1..) |doc, i| {
        if (i > 0) {
          rest.softline().text(".")._();
        }
        rest.append(doc);
      }
      split.indent(rest.finish())._();
      const db = self.db.seqb().ifsplit(
        id,
        split.finishSeq(),
        flat.finishSeq(),
      );
      return self.db.groupi(id, db.finish());
    }
    return null;
  }

  const Binary = struct {
    op: ?Node.Index,
    node: Node.Index,
  };

  const BinaryList = std.ArrayList(Binary);

  fn _collectBinaryExprStep(self: *Self, n: Node.Index, prev_op: Node.Tag, list: *BinaryList) bool {
    const curr_op = self.tree.nodeTag(n);
    switch (curr_op) {
      .add, .add_wrap, .add_sat, .array_cat, .array_mult, .bang_equal,
      .bit_and, .bit_or, .shl, .shl_sat, .shr, .bit_xor, .bool_and,
      .bool_or, .div, .equal_equal, .greater_or_equal, .greater_than,
      .less_or_equal, .less_than, .merge_error_sets, .mod, .mul, .mul_wrap,
      .mul_sat, .sub, .sub_wrap, .sub_sat => {
        if (tagPrec(prev_op) == tagPrec(curr_op)) {
          const lhs, const rhs = self.tree.nodeData(n).node_and_node;
          const a = self._collectBinaryExprStep(lhs, curr_op, list);
          const b = self._collectBinaryExprStep(rhs, curr_op, list);
          assert(list.getLast().op == null);
          list.items[list.items.len - 1].op = n;
          return a and b;
        } else {
          // preserve the tree.
          util.listAppend(Binary{.op = null, .node = n}, list, self.al);
        }
      },
      else => {
        util.listAppend(Binary{.op = null, .node = n}, list, self.al);
        return true;
      }
    }
    return false;
  }

  fn tBinaryExpr(self: *Self, n: Node.Index, tag: Node.Tag) TranslateError!*Doc {
    var list: BinaryList = .empty;
    const all_same_precs = self._collectBinaryExprStep(n, tag,  &list);
    const nodes = list.items;
    const first = nodes[0];
    assert(first.op == null);
    var sb = self.db.seqb();
    sb.append(try self.t(first.node));
    var rest = self.db.seqb();
    var tmp = self.db.seqb();
    const group = all_same_precs or nodes.len > 12;
    if (nodes.len > 1) {
      var last: ?*Doc = null;
      for (nodes[1..]) |bin| {
        const op = self._token(self.tree.nodeMainToken(bin.op.?));
        const doc = try self.t(bin.node);
        if (last) |lhs| {
          tmp.appends(lhs).normline().text(op).space().append(doc);
          last = self.db.group(tmp.finish());
          tmp.reset();
        } else if (group) {
          tmp.normline().text(op).space().append(doc);
          last = self.db.group(tmp.finish());
          tmp.reset();
        } else {
          rest.normline().text(op).space().append(doc);
        }
      }
      if (last) |doc| {
        rest.append(doc);
      }
    }
    _ = tmp.finish(); // discard because of .reset()
    sb.indent(rest.finish())._();
    return self.db.group(sb.finish());
  }

  fn tAttribute(self: *Self, n: Node.Index, name: ?[]const u8) !*Doc {
    var sb = self.db.seqb();
    var args = self.db.seqb().softline().appends(try self.t(n));
    if (name) |id| {
      sb.text(id)._();
    }
    sb.text("(").indent(args.finish()).softline().text(")")._();
    return self.db.group(sb.finish());
  }

  fn tCallArgs(
    self: *Self,
    id: u32,
    tag: Node.Tag,
    params: []const Node.Index,
    should_softline: bool,
  ) TranslateError!*SeqBuilder {
    var sb_args = self.db.seqb();
    sb_args.softlineIf(should_softline)._();
    self._in_call_args += 1;
    for (params, 0..) |_n, i| {
      if (i > 0) {
        sb_args.text(",")._();
        if (should_softline) {
          sb_args.normline()._();
        } else {
          sb_args.space()._();
        }
      }
      sb_args.append(try self.t(_n));
    }
    self._in_call_args -= 1;
    if ((params.len > 0 and should_softline) or tag == .call_one_comma) {
      // add trailing comma for complex args or if we break
      sb_args.ifsplit(id, self.db.text(","), self.db.softline())._();
    }
    return sb_args;
  }

  fn tFnParams(
    self: *Self,
    id: u32,
    fn_tkn: Ast.TokenIndex,
    params: []const Node.Index,
  ) TranslateError!*SeqBuilder {
    var _sb_prms = self.db.seqb();
    var tkn = fn_tkn + 1;
    if (self.tree.tokenTag(tkn) == .identifier) {
      tkn += 1;
    }
    assert(self.tree.tokenTag(tkn) == .l_paren);
    tkn += 1;
    self._in_call_args += 1;
    var tmp = self.db.seqb();
    var i = @as(usize, 0);
    while (true) : (tkn += 1) {
      switch (self.tree.tokenTag(tkn)) {
        .doc_comment => {
          util.todo("doc comment");
        },
        .keyword_noalias, .keyword_comptime => {
          tmp.text(self._token(tkn)).space()._();
        },
        .keyword_anytype => {
          tmp.text(self._token(tkn))._();
        },
        .identifier => {
          const prev = self.tree.tokenTag(tkn - 1);
          if (
            prev == .l_paren or
            prev == .comma or
            prev == .keyword_comptime or
            prev == .keyword_noalias
          ) {
            tmp.text(self._token(tkn))._();
          } else if (i < params.len) {
            const p = params[i];
            tmp.append(try self.t(p));
            tkn = self.tree.lastToken(p);
            i += 1;
          }
        },
        .colon => {
          tmp.text(": ")._();
        },
        .comma => {
          if (self.tree.tokenTag(tkn + 1) != .r_paren) {
            tmp.text(",")._();
            _sb_prms.group(tmp.finish()).normline()._();
          } else {
            _sb_prms.group(tmp.finish())._();
          }
          tmp.reset();
        },
        .ellipsis3 => {
          tmp.text(self._token(tkn))._();
        },
        .r_paren => {
          if (tmp.isNotEmpty()) {
            _sb_prms.group(tmp.finish())._();
          } else if (!tmp.done) {
            _ = tmp.finish();
          }
          break;
        },
        else => {
          if (i < params.len) {
            const p = params[i];
            tmp.append(try self.t(p));
            tkn = self.tree.lastToken(p);
            i += 1;
          }
        }
      }
    }
    self._in_call_args -= 1;
    const should_softline = _sb_prms.isNotEmpty();
    if (should_softline) {
      // add trailing comma for complex args or if we break
      _sb_prms.ifsplit(id, self.db.text(","), self.db.softline())._();
    }
    return self.db.seqb().softlineIf(should_softline).extends(_sb_prms.finish());
  }

  fn tVarDeclProto(self: *Self, vd: Ast.full.VarDecl) TranslateError!*SeqBuilder {
    var sb = self.db.seqb();
    var tmp = self.db.seqb();
    if (vd.visib_token) |idx| {
      sb.text(self._token(idx)).space()._();
    }
    if (vd.extern_export_token) |idx| {
      sb.text(self._token(idx)).space()._();
      if (vd.lib_name) |_idx| {
        sb.text(self._token(_idx)).space()._();
      }
    }
    if (vd.threadlocal_token) |idx| {
      sb.text(self._token(idx)).space()._();
    }
    if (vd.comptime_token) |idx| {
      sb.text(self._token(idx)).space()._();
    }
    sb.text(self._token(vd.ast.mut_token))
    .space().text(self._token(vd.ast.mut_token + 1))._();
    if (vd.ast.type_node.unwrap()) |_n| {
      sb.text(": ")._();
      sb.append(try self.t(_n));
    }
    if (vd.ast.align_node.unwrap()) |_n| {
      tmp.normline().append(try self.tAttribute(_n, "align"));
    }
    if (vd.ast.addrspace_node.unwrap()) |_n| {
      tmp.normline().append(try self.tAttribute(_n, "addrspace"));
    }
    if (vd.ast.section_node.unwrap()) |_n| {
      tmp.normline().append(try self.tAttribute(_n, "linksection"));
    }
    sb.append(self.db.indent(tmp.finish()));
    return sb;
  }

  fn tVarDecl(self: *Self, vd: Ast.full.VarDecl) TranslateError!*Doc {
    var sb = try self.tVarDeclProto(vd);
    if (vd.ast.init_node.unwrap()) |_n| {
      sb.text(" = ")._();
      sb.append(try self.t(_n));
    }
    return self.db.group(sb.finish());
  }

  fn tFnProto(
    self: *Self,
    fn_tkn: Ast.TokenIndex,
    params: []const Node.Index,
    byte_align: ?Node.Index,
    addr_space: ?Node.Index,
    link_section: ?Node.Index,
    call_conv: ?Node.Index,
    ret_ty: ?Node.Index,
  ) TranslateError!*Doc {
    // KEYWORD_fn IDENTIFIER? LPAREN ParamDeclList RPAREN ByteAlign? AddrSpace? LinkSection? CallConv? EXCLAMATIONMARK? TypeExpr
    // `fn (a: b, c: d) addrspace(e) linksection(f) callconv(g) return_type`.
    var sb = self.db.seqb();
    var curr = if (fn_tkn > 0) fn_tkn - 1 else fn_tkn;
    loop: while (true) : (curr -= 1) {
      switch (self.tree.tokenTag(curr)) {
        .keyword_inline, .keyword_export, .keyword_pub, .keyword_noinline => {
          sb.space().text(self._token(curr))._();
        },
        .keyword_extern => {
          sb.space().text(self._token(curr))._();
        },
        else => {
          std.mem.reverse(*Doc, sb.docs.items);
          break :loop;
        }
      }
      if (curr == 0) {
        std.mem.reverse(*Doc, sb.docs.items);
        break;
      }
    }
    sb.text("fn ")._();
    const next_tkn = fn_tkn + 1;
    if (self.tree.tokenTag(next_tkn) == .identifier) {
      sb.text(self._token(next_tkn))._();
    }
    sb.text("(")._();
    const id = d.genGroupID();
    var sb_args = try self.tFnParams(id, fn_tkn, params);
    sb.indent(sb_args.finish())._();
    sb.softlineIf(sb_args.isNotEmpty()).text(")")._();
    var tmp = self.db.seqb();
    if (byte_align) |_n| {
      tmp.normline().append(try self.tAttribute(_n, "align"));
    }
    if (addr_space) |_n| {
      tmp.normline().append(try self.tAttribute(_n, "addrspace"));
    }
    if (call_conv) |_n| {
      tmp.normline().append(try self.tAttribute(_n, "callconv"));
    }
    if (link_section) |_n| {
      tmp.normline().append(try self.tAttribute(_n, "linksection"));
    }
    if (ret_ty) |_n| {
      if (tmp.isNotEmpty() or params.len > 0) {
        sb.group(tmp.normline().finish())._();
        const tkn = self.tree.nodeMainToken(_n) - 1;
        if (self.tree.tokenTag(tkn) == .bang) {
          sb.text(self._token(tkn))._();
        }
        sb.append(try self.t(_n));
      } else {
        _ = tmp.finish();
        sb.space()._();
        const tkn = self.tree.nodeMainToken(_n) - 1;
        if (self.tree.tokenTag(tkn) == .bang) {
          sb.text(self._token(tkn))._();
        }
        sb.append(try self.t(_n));
      }
    } else {
      sb.group(tmp.finish())._();
    }
    return self.db.groupi(id, sb.finish());
  }

  fn tContainerDecl(
    self: *Self,
    mlayout: ?Ast.TokenIndex,
    container: Ast.TokenIndex,
    enum_token: ?Ast.TokenIndex,
    container_arg: ?Node.Index,
    members: []const Node.Index,
  ) TranslateError!*Doc {
    // `struct {}`, `union {}`, `opaque {}`, `enum {}`.
    var sb = self.db.seqb();
    if (mlayout) |tkn| {
      sb.text(self._token(tkn)).space()._();
    } else {
      const layout = container - 1;
      switch (self.tree.tokenTag(layout)) {
        .keyword_packed, .keyword_extern => {
          sb.text(self._token(layout)).space()._();
        },
        else => {}
      }
    }
    sb.text(self._token(container))._();
    if (enum_token) |tkn| {
      sb.text("(")._();
      if (container_arg) |arg| {
        var tmp = self.db.seqb();
        tmp.softline().append(try self.tAttribute(arg, self._token(tkn)));
        sb.group(self.db.seqb().indent(tmp.finish()).softline().text(")").finish())._();
      } else {
        sb.text(self._token(tkn)).text(")")._();
      }
    } else if (container_arg) |arg| {
      sb.append(try self.tAttribute(arg, null));
    }
    sb.space().text("{")._();
    if (members.len == 0) {
      return self.db.group(sb.text("}").finish());
    }
    var tmp = self.db.seqb();
    tmp.normline()._();
    const id = d.genGroupID();
    for (members, 1..) |_n, i| {
      const doc = try self.t(_n);
      const node_tag = self.tree.nodeTag(_n);
      if (self.shouldAddTerminator(_n)) {
        tmp.group(self.db.seqb().appends(doc).text(";").finish())._();
      } else {
        const tag = self.tree.tokenTag(self.tree.firstToken(_n));
        if (std.mem.startsWith(u8, @tagName(tag), "keyword")) {
          tmp.append(doc);
        } else if (i < members.len) {
          tmp.group(self.db.seqb().appends(doc).text(",").finish())._();
        } else {
          const flat = self.db.seqb().appends(doc).finishSeq();
          const split = self.db.seqb().appends(doc).text(",").finishSeq();
          tmp.ifsplit(id, split, flat)._();
        }
      }
      if (i < members.len) {
        if (canAddSep(self.tree.nodeTag(members[i]), node_tag)) {
          tmp.append(self.getNormSep());
        } else {
          tmp.normline()._();
        }
      }
    }
    sb.indent(tmp.finish()).normline().text("}")._();
    return self.db.groupi(id, sb.finish());
  }

  fn tOpenContainerDecl(
    self: *Self,
    members: []const Node.Index,
  ) TranslateError!*Doc {
    // `struct {}`, `union {}`, `opaque {}`, `enum {}`.
    var sb = self.db.seqb();
    for (members, 1..) |_n, i| {
      const doc = try self.t(_n);
      const node_tag = self.tree.nodeTag(_n);
      if (self.shouldAddTerminator(_n)) {
        sb.group(self.db.seqb().appends(doc).text(";").finish())._();
      } else {
        const tag = self.tree.tokenTag(self.tree.firstToken(_n));
        if (std.mem.startsWith(u8, @tagName(tag), "keyword")) {
          sb.append(doc);
        } else {
          sb.group(self.db.seqb().appends(doc).text(",").finish())._();
        } 
      }
      if (i < members.len) {
        if (canAddSep(self.tree.nodeTag(members[i]), node_tag)) {
          sb.append(self.getDeclSep());
        } else {
          sb.declline()._();
        }
      } else {
        sb.declline()._();
      }
    }
    return sb.finishSeq();
  }

  fn tContainerField(self: *Self, cf: Ast.full.ContainerField) TranslateError!*Doc {
    var sb = self.db.seqb();
    if (cf.comptime_token) |idx| {
      sb.text(self._token(idx)).space()._();
    }
    if (!cf.ast.tuple_like) {
      sb.text(self._token(cf.ast.main_token))._();
      if (cf.ast.type_expr.unwrap()) |_n| {
        sb.text(": ").append(try self.t(_n));
      }
    } else if (cf.ast.type_expr.unwrap()) |_n| {
      sb.append(try self.t(_n));
    }

    if (cf.ast.align_expr.unwrap()) |_n| {
      sb.space().append(try self.tAttribute(_n, "align"));
    }
    if (cf.ast.value_expr.unwrap()) |_n| {
      sb.text(" = ").append(try self.t(_n));
    }
    return self.db.group(sb.finish());
  }

  fn tIf(self: *Self, ifn: Ast.full.If) TranslateError!*Doc {
    const cond_expr = try self.t(ifn.ast.cond_expr);
    var sb = self.db.seqb();
    var tmp = self.db.seqb();
    tmp.text("if (")._();
    var cond = self.db.seqb();
    cond.softline().append(cond_expr);
    tmp.indent(cond.finish()).softline().text(")")._();
    if (ifn.payload_token) |tkn| {
      tmp.text(" |").text(self._token(tkn))._();
      if (self.tree.tokenTag(tkn) == .asterisk) {
        tmp.text(self._token(tkn + 1))._();
      }
      tmp.text("|")._();
    }
    sb.group(tmp.finish())._();
    var if_has_braces = false;
    const id = d.genGroupID();
    if (self.isEmptyBlock(ifn.ast.then_expr)) {
      if_has_braces = true;
      sb.text(" {").declline().text("}")._();
    } else {
      const then_expr = try self.t(ifn.ast.then_expr);
      const tkn = self.tree.nodeMainToken(ifn.ast.then_expr);
      if (self.isBlock(tkn)) {
        if_has_braces = true;
        sb.space().append(then_expr);
      } else {
        var flat = self.db.seqb();
        var split = self.db.seqb();
        flat.space().append(then_expr);
        split.softline().append(then_expr);
        sb.ifsplit(id, self.db.indent(split.finish()), flat.finishSeq())._();
      }
    }
    if (ifn.ast.else_expr.unwrap()) |els| {
      if (self.isEmptyBlock(els)) {
        sb.text(" else ")._();
        if (ifn.error_token) |tkn| {
          sb.text("|").text(self._token(tkn)).text("| ")._();
        }
        sb.text("{").declline().text("}")._();
      } else {
        const else_expr = try self.t(els);
        const tkn = self.tree.nodeMainToken(els);
        if (if_has_braces or self.isBlock(tkn)) {
          if (if_has_braces) {
            sb.text(" else ")._();
            if (ifn.error_token) |err_tkn| {
              sb.text("|").text(self._token(err_tkn)).text("| ")._();
            }
            sb.append(else_expr);
          } else {
            var els_sb = self.db.seqb();
            els_sb.declline().text("else ")._();
            if (ifn.error_token) |err_tkn| {
              els_sb.text("|").text(self._token(err_tkn)).text("| ")._();
            }
            els_sb.append(else_expr);
            sb.group(els_sb.finish())._();
          }
        } else {
          var flat = self.db.seqb();
          var split = self.db.seqb();
          var rest = self.db.seqb();
          flat.text(" else ")._();
          split.softline().text("else")._();
          if (ifn.error_token) |err_tkn| {
            flat.text("|").text(self._token(err_tkn)).text("| ")._();
            split.text(" |").text(self._token(err_tkn)).text("|")._();
          }
          flat.append(else_expr);
          rest.softline().append(else_expr);
          split.indent(rest.finish())._();
          sb.ifsplit(id, split.finishSeq(), flat.finishSeq())._();
        }
      }
    }
    return self.db.groupi(id, sb.finish());
  }

  fn tFor(self: *Self, fl: Ast.full.For) TranslateError!*Doc {
    var sb = self.db.seqb();
    var tmp = self.db.seqb();
    if (fl.label_token) |tkn| {
      tmp.text(self._token(tkn)).text(": ")._();
    }
    if (fl.inline_token) |tkn| {
      tmp.text(self._token(tkn)).space()._();
    }
    tmp.text("for (")._();
    var cond = self.db.seqb().softline();
    for (fl.ast.inputs, 0..) |n, i| {
      if (i > 0) cond.text(",").normline()._();
      cond.append(try self.t(n));
    }
    tmp.indent(cond.finish()).softline().text(")")._();
    sb.group(tmp.finish())._();
    {
      tmp = self.db.seqb();
      tmp.text(" |").text(self._token(fl.payload_token))._();
      var idx = fl.payload_token + 1;
      while (self.tree.tokenTag(idx) != .pipe) {
        tmp.text(self._token(idx))._();
        if (self.tree.tokenTag(idx) == .comma) {
          tmp.space()._();
        }
        idx += 1;
      }
      tmp.text(self._token(idx))._();
      sb.group(tmp.finish())._();
    }
    var then_has_braces = false;
    const id = d.genGroupID();
    if (fl.ast.else_expr.unwrap()) |els| {
      if (self.isEmptyBlock(fl.ast.then_expr)) {
        then_has_braces = true;
        sb.text(" {").declline().text("}")._();
      } else {
        const then_expr = try self.t(fl.ast.then_expr);
        const tkn = self.tree.nodeMainToken(fl.ast.then_expr);
        if (self.isBlock(tkn)) {
          then_has_braces = true;
          sb.space().append(then_expr);
        } else {
          var flat = self.db.seqb().space().appends(then_expr);
          var split = self.db.seqb().softline().appends(then_expr);
          sb.ifsplit(id, self.db.indent(split.finish()), flat.finishSeq())._();
        }
      }
      if (self.isEmptyBlock(els)) {
        sb.text(" else {").declline().text("}")._();
      } else {
        const else_expr = try self.t(els);
        const tkn = self.tree.nodeMainToken(els);
        if (then_has_braces or self.isBlock(tkn)) {
          if (then_has_braces) {
            sb.text(" else ").append(else_expr);
          } else {
            var els_sb = self.db.seqb();
            els_sb.declline().text("else ").append(else_expr);
            sb.group(els_sb.finish())._();
          }
        } else {
          var flat = self.db.seqb();
          var split = self.db.seqb();
          var rest = self.db.seqb();
          flat.text(" else ").append(else_expr);
          split.softline().text("else")._();
          rest.softline().append(else_expr);
          split.indent(rest.finish())._();
          sb.ifsplit(id, split.finishSeq(), flat.finishSeq())._();
        }
      }
    } else {
      const tkn = self.tree.nodeMainToken(fl.ast.then_expr);
      const then = try self.t(fl.ast.then_expr);
      if (self.isBlock(tkn)) {
        sb.space().append(then);
      } else {
        var flat_e = self.db.seqb().space().appends(then);
        var split = self.db.seqb().softline().appends(then);
        sb.ifsplit(id, self.db.indent(split.finish()), flat_e.finishSeq())._();
      }
    }
    return self.db.groupi(id, sb.finish());
  }

  fn tWhile(self: *Self, wl: Ast.full.While) TranslateError!*Doc {
    var sb = self.db.seqb();
    var flat = self.db.seqb();
    if (wl.label_token) |tkn| {
      flat.text(self._token(tkn)).text(": ")._();
    }
    if (wl.inline_token) |tkn| {
      flat.text(self._token(tkn)).space()._();
    }
    var tmp = self.db.seqb();
    tmp.text("while (")._();
    var cond_sb = self.db.seqb();
    cond_sb.softline().append(try self.t(wl.ast.cond_expr));
    tmp.indent(cond_sb.finish()).softline().text(")")._();
    flat.group(tmp.finish())._();
    if (wl.payload_token) |tkn| {
      flat.text(" |").text(self._token(tkn))._();
      if (self.tree.tokenTag(tkn) == .asterisk) {
        flat.text(self._token(tkn + 1))._();
      }
      flat.text("|")._();
    }
    const id0 = d.genGroupID();
    if (wl.ast.cont_expr.unwrap()) |cnt| {
      var split = flat.copy();
      var expr_sb = self.db.seqb();
      expr_sb.softline().append(try self.t(cnt));
      const expr_d = expr_sb.finish();
      tmp = self.db.seqb();
      tmp.text(": (").indent(expr_d).softline().text(")")._();
      const cont_d = tmp.finish();
      flat.append(self.db.group(self.db.seqb().space().extends(cont_d).finish()));
      split.softline().group(cont_d)._();
      const db = self.db.seqb().ifsplit(id0, split.finishSeq(), flat.finishSeq());
      sb.groupi(id0, db.finish())._();
    } else {
      sb.groupi(id0, flat.finish())._();
    }
    var then_has_braces = false;
    const id = d.genGroupID();
    if (wl.ast.else_expr.unwrap()) |els| {
      if (self.isEmptyBlock(wl.ast.then_expr)) {
        then_has_braces = true;
        sb.text(" {").declline().text("}")._();
      } else {
        const then_expr = try self.t(wl.ast.then_expr);
        const tkn = self.tree.nodeMainToken(wl.ast.then_expr);
        if (self.isBlock(tkn)) {
          then_has_braces = true;
          sb.space().append(then_expr);
        } else {
          var flat_t = self.db.seqb().space().appends(then_expr);
          var split = self.db.seqb().softline().appends(then_expr);
          sb.ifsplit(id, self.db.indent(split.finish()), flat_t.finishSeq())._();
        }
      }
      if (self.isEmptyBlock(els)) {
        sb.text(" else ")._();
        if (wl.error_token) |tkn| {
          sb.text("|").text(self._token(tkn)).text("| ")._();
        }
        sb.text("{").declline().text("}")._();
      } else {
        const else_expr = try self.t(els);
        const tkn = self.tree.nodeMainToken(els);
        if (then_has_braces or self.isBlock(tkn)) {
          if (then_has_braces) {
            sb.text(" else ")._();
            if (wl.error_token) |err_tkn| {
              sb.text("|").text(self._token(err_tkn)).text("| ")._();
            }
            sb.append(else_expr);
          } else {
            var els_sb = self.db.seqb();
            els_sb.declline().text("else ")._();
            if (wl.error_token) |err_tkn| {
              els_sb.text("|").text(self._token(err_tkn)).text("| ")._();
            }
            els_sb.append(else_expr);
            sb.group(els_sb.finish())._();
          }
        } else {
          var flat_e = self.db.seqb();
          var split = self.db.seqb();
          var rest = self.db.seqb();
          flat_e.text(" else ")._();
          split.softline().text("else")._();
          if (wl.error_token) |err_tkn| {
            flat_e.text("|").text(self._token(err_tkn)).text("| ")._();
            split.text(" |").text(self._token(err_tkn)).text("|")._();
          }
          flat_e.append(else_expr);
          rest.softline().append(else_expr);
          split.indent(rest.finish())._();
          sb.ifsplit(id, split.finishSeq(), flat_e.finishSeq())._();
        }
      }
    } else {
      const tkn = self.tree.nodeMainToken(wl.ast.then_expr);
      const then = try self.t(wl.ast.then_expr);
      if (self.isBlock(tkn)) {
        sb.space().append(then);
      } else {
        var flat_e = self.db.seqb().space().appends(then);
        var split = self.db.seqb().softline().appends(then);
        sb.ifsplit(id, self.db.indent(split.finish()), flat_e.finishSeq())._();
      }
    }
    return self.db.groupi(id, sb.finish());
  }

  fn tSwitch(self: *Self, sw: Ast.full.Switch) TranslateError!*Doc {
    var sb = self.db.seqb();
    var tmp = self.db.seqb();
    if (sw.label_token) |tkn| {
      tmp.text(self._token(tkn)).text(": ")._();
    }
    tmp.text(self._token(sw.ast.switch_token))._();
    tmp.text(" (")._();
    var cond = self.db.seqb();
    cond.softline().append(try self.t(sw.ast.condition));
    tmp.indent(cond.finish()).softline().text(")")._();
    sb.group(tmp.finish())._();
    if (sw.ast.cases.len == 0) {
      sb.text(" {}")._();
      return self.db.group(sb.finish());
    }
    sb.text(" {")._();
    var cases = self.db.seqb().declline();
    for (sw.ast.cases, 0..) |cs, i| {
      if (i > 0) cases.text(",").declline()._();
      cases.append(try self.t(cs));
    }
    cases.text(",")._();
    sb.indent(cases.finish()).declline()._();
    sb.text("}")._();
    return self.db.group(sb.finish());
  }

  fn tSwitchCase(self: *Self, sc: Ast.full.SwitchCase) TranslateError!*Doc {
    var sb = self.db.seqb();
    if (sc.inline_token) |tkn| {
      sb.text(self._token(tkn)).space()._();
    }
    if (sc.ast.values.len > 0) {
      var tmp = self.db.seqb();
      for (sc.ast.values, 0..) |v, i| {
        if (i > 0) tmp.text(",").normline()._();
        tmp.append(try self.t(v));
      }
      sb.group(tmp.finish())._();
    } else {
      sb.text("else")._();
    }
    sb.space().text(self._token(sc.ast.arrow_token))._();
    if (sc.payload_token) |tkn| {
      sb.text(" |").text(self._token(tkn))._();
      var idx = tkn + 1;
      while (self.tree.tokenTag(idx) != .pipe) {
        sb.text(self._token(idx))._();
        if (self.tree.tokenTag(idx) == .comma) {
          sb.space()._();
        }
        idx += 1;
      }
      sb.text(self._token(idx))._();
    }
    sb.space().append(try self.t(sc.ast.target_expr));
    return self.db.group(sb.finish());
  }

  fn tPtrType(self: *Self, ty: Ast.full.PtrType) TranslateError!*Doc {
    var sb = self.db.seqb();
    switch (ty.size) {
      .c => sb.text("[*c]")._(),
      .one => {
        sb.text("*")._();
      },
      .many => {
        if (ty.ast.sentinel.unwrap()) |n| {
          sb.text("[")._();
          var elems = self.db.seqb();
          elems.softline().text("*:")._();
          elems.append(try self.t(n));
          sb.indent(elems.finish()).softline().text("]")._();
        } else {
          sb.text("[*]")._();
        }
      },
      .slice => {
        if (ty.ast.sentinel.unwrap()) |n| {
          sb.text("[")._();
          var elems = self.db.seqb();
          elems.softline().text(":")._();
          elems.append(try self.t(n));
          sb.indent(elems.finish()).softline().text("]")._();
        } else {
           sb.text("[]")._();
        }
      }
    }
    var allow: ?*Doc = null;
    var alig: ?*Doc = null;
    var addr: ?*Doc = null;
    var cnst: ?*Doc = null;
    var vol: ?*Doc = null;
    if (ty.allowzero_token) |i| {
      allow = self.db.text(self._token(i));
    }
    if (ty.ast.align_node.unwrap()) |nd| {
      var tmp = self.db.seqb().text("align(");
      var args = self.db.seqb().softline(); 
      if (ty.ast.bit_range_start.unwrap()) |brs| {
        const bre = ty.ast.bit_range_end.unwrap().?;
        const f_doc = try self.t(nd);
        const s_doc = try self.t(brs);
        const e_doc = try self.t(bre);
        const id = d.genGroupID();
        var split_d = self.db.seqb().appends(f_doc);
        var rest = self.db.seqb().softline().text(":").appends(s_doc);
        rest.softline().text(":").append(e_doc);
        split_d.indent(rest.finish())._();
        var flat_d = self.db.seqb().appends(f_doc);
        flat_d.text(":").appends(s_doc).text(":").append(e_doc);
        args.ifsplit(id, split_d.finishSeq(), flat_d.finishSeq())._();
        tmp.indent(args.finish()).softline().text(")")._();
        alig = self.db.groupi(id, tmp.finish());
      } else {
        args.append(try self.t(nd));
        tmp.indent(args.finish()).softline().text(")")._();
        alig = self.db.group(tmp.finish());
      }
    }
    if (ty.ast.addrspace_node.unwrap()) |nd| {
      addr = try self.tAttribute(nd, "addrspace");
    }
    if (ty.const_token) |i| {
      cnst = self.db.text(self._token(i));
    }
    if (ty.volatile_token) |i| {
      vol = self.db.text(self._token(i));
    }
    var split = self.db.seqb();
    var flat = self.db.seqb();
    var rest = self.db.seqb();
    if (allow) |_n| {
      split.append(_n);
      flat.appends(_n).space()._();
    }
    if (alig) |_n| {
      if (split.isNotEmpty()) {
        rest.normline().append(_n);
      } else {
        split.append(_n);
      }
      flat.appends(_n).space()._();
    }
    if (addr) |_n| {
      if (split.isNotEmpty()) {
        rest.normline().append(_n);
      } else {
        split.append(_n);
      }
      flat.appends(_n).space()._();
    }
    var skip_vol = false;
    var skip_child = false;
    const c = try self.t(ty.ast.child_type);
    if (cnst) |_n| {
      skip_vol = vol != null;
      skip_child = true;
      if (vol) |_n2| {
        const b = self.db.seqb().appends(_n).space().appends(_n2).normline().appends(c);
        const g = self.db.group(b.finish());
        if (split.isNotEmpty()) {
          rest.normline().append(g);
        } else {
          split.append(g);
        }
      } else {
        const g = self.db.group(self.db.seqb().appends(_n).space().appends(c).finish());
        if (split.isNotEmpty()) {
          rest.normline().append(g);
        } else {
          split.append(g);
        }
      }
      flat.appends(_n).space()._();
    }
    if (vol) |_n| {
      if (!skip_vol) {
        if (split.isNotEmpty()) {
          rest.normline().append(_n);
        } else {
          split.append(_n);
        }
      }
      flat.appends(_n).space()._();
    }
    if (!skip_child) {
      if (split.isNotEmpty()) {
        rest.normline().append(c);
      } else {
        split.append(c);
      }
    }
    flat.append(c);
    split.indent(rest.finish())._();
    const id = d.genGroupID();
    sb.ifsplit(id, split.finishSeq(), flat.finishSeq())._();
    return self.db.groupi(id, sb.finish());
  }

  fn tStructInit(
    self: *Self,
    n: Node.Index,
    texpr: ?Node.Index,
    fields: []const Node.Index,
  ) TranslateError!*Doc {
    var sb = self.db.seqb();
    const should_softline = fields.len > 0;
    if (texpr) |te| {
      sb.appends(try self.t(te)).text("{")._();
    } else {
      // main token is '{'
      const name = self.tree.nodeMainToken(n) - 1;
      sb.text(self._token(name)).text("{")._();
    }
    var args = self.db.seqb().softlineIf(should_softline);
    for (fields, 0..) |val, i| {
      var tmp = self.db.seqb();
      const idx = self.tree.firstToken(val) - 2;
      tmp.text(".").text(self._token(idx))._();
      tmp.text(" = ").append(try self.t(val));
      if (i < fields.len - 1) {
        args.group(tmp.text(",").finish()).normline()._();
      } else {
        args.group(tmp.finish())._();
      }
    }
    if (fields.len == 0) {
      _ = args.finish();
      sb.text("}")._();
      return self.db.group(sb.finish());
    }
    const id = d.genGroupID();
    args.ifsplit(id, self.db.text(","), self.db.seq(&.{}))._();
    sb.indent(args.finish()).softlineIf(should_softline).text("}")._();
    return self.db.groupi(id, sb.finish());
  }

  fn tArrayInit(
    self: *Self,
    n: Node.Index,
    texpr: ?Node.Index,
    fields: []const Node.Index,
  ) TranslateError!*Doc {
    var sb = self.db.seqb();
    if (texpr) |te| {
      sb.appends(try self.t(te)).text("{")._();
    } else {
      // main token is '{'
      const name = self.tree.nodeMainToken(n) - 1;
      sb.text(self._token(name)).text("{")._();
    }
    const should_softline = fields.len > 0;
    var args = self.db.seqb().softlineIf(should_softline);
    for (fields, 0..) |val, i| {
      var tmp = self.db.seqb();
      tmp.append(try self.t(val));
      if (i < fields.len - 1) {
        args.group(tmp.text(",").finish()).normline()._();
      } else {
        args.group(tmp.finish())._();
      }
    }
    if (fields.len == 0) {
      _ = args.finish();
      sb.text("}")._();
      return self.db.group(sb.finish());
    }
    const id = d.genGroupID();
    args.ifsplit(id, self.db.text(","), self.db.seq(&.{}))._();
    sb.indent(args.finish()).softlineIf(should_softline).text("}")._();
    return self.db.groupi(id, sb.finish());
  }

  fn t(self: *Self, n: Node.Index) !*Doc {
    const tag = self.tree.nodeTag(n);
    assert(tag != self.tree.nodeTag(Node.Index.root));
    switch (tag) {
      .identifier, .number_literal,
      .string_literal, .char_literal, .unreachable_literal => {
        return self.db.text(self._token(self.tree.nodeMainToken(n)));
      },
      .negation => {
        const expr = self.tree.nodeData(n).node;
        var sb = self.db.seqb();
        sb.text("-").append(try self.t(expr));
        return self.db.group(sb.finish());
      },
      .simple_var_decl, .global_var_decl, .local_var_decl, .aligned_var_decl => {
        const vd = self.tree.fullVarDecl(n).?;
        return self.tVarDecl(vd);
      },
      .enum_literal => {
        const tk = self._token(self.tree.nodeMainToken(n));
        var sb = self.db.seqb().text(".").text(tk);
        return sb.finishSeq();
      },
      .call_one, .call_one_comma, .call, .call_comma => {
        const call = self.getCallInfo(n);
        if (try self.tCallChain(call)) |doc| return doc;
        const id = d.genGroupID();
        var sb = self.db.seqb();
        const expr = try self.t(call.ast.fn_expr);
        sb.appends(expr).text("(")._();
        const should_softline = call.ast.params.len > 0;
        var sb_args = try self.tCallArgs(id, tag, call.ast.params, should_softline);
        sb.indent(sb_args.finish())._();
        sb.softlineIf(should_softline).text(")")._();
        return self.db.groupi(id, sb.finish());
      },
      .fn_proto_simple => {
        // `fn (a: type_expr) return_type`.
        const typ, const ret = self.tree.nodeData(n).opt_node_and_opt_node;
        const fn_tkn = self.tree.nodeMainToken(n);
        const params = if (typ.unwrap()) |idx| &.{idx} else &.{};
        return self.tFnProto(fn_tkn, params, null, null, null, null, ret.unwrap());
      },
      .fn_proto_multi => {
        // `fn (a: b, c: d) return_type`.
        const proto = self.tree.fnProtoMulti(n);
        const fn_tkn = self.tree.nodeMainToken(n);
        return self.tFnProto(
          fn_tkn, proto.ast.params,
          proto.ast.align_expr.unwrap(),
          proto.ast.addrspace_expr.unwrap(),
          proto.ast.section_expr.unwrap(),
          proto.ast.callconv_expr.unwrap(),
          proto.ast.return_type.unwrap(),
        );
      },
      .fn_proto_one => {
        // `fn (a: b) addrspace(e) linksection(f) callconv(g) return_type`.
        const extra_index, const ret = self.tree.nodeData(n).extra_and_opt_node;
        const proto = self.tree.extraData(extra_index, Node.FnProtoOne);
        const fn_tkn = self.tree.nodeMainToken(n);
        const params = if (proto.param.unwrap()) |idx| &.{idx} else &.{};
        return self.tFnProto(
          fn_tkn, params,
          proto.align_expr.unwrap(),
          proto.addrspace_expr.unwrap(),
          proto.section_expr.unwrap(),
          proto.callconv_expr.unwrap(),
          ret.unwrap(),
        );
      },
      .fn_proto => {
        // `fn (a: b, c: d) addrspace(e) linksection(f) callconv(g) return_type`.
        const proto = self.tree.fnProto(n);
        const fn_tkn = self.tree.nodeMainToken(n);
        return self.tFnProto(
          fn_tkn, proto.ast.params,
          proto.ast.align_expr.unwrap(),
          proto.ast.addrspace_expr.unwrap(),
          proto.ast.section_expr.unwrap(),
          proto.ast.callconv_expr.unwrap(),
          proto.ast.return_type.unwrap(),
        );
      },
      .fn_decl => {
        const proto, const body = self.tree.nodeData(n).node_and_node;
        const hdr = try self.t(proto);
        var sb = self.db.seqb();
        sb.appends(hdr).space().append(try self.t(body));
        return self.db.group(sb.finish());
      },
      .block_two, .block_two_semicolon => {
        self._in_block += 1;
        defer self._in_block -= 1;
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        var sb = self.db.seqb();
        const tkn = self.tree.nodeMainToken(n);
        if (self.tree.tokenTag(tkn - 1) == .colon) {
          if (self.tree.tokenTag(tkn - 2) == .identifier) {
            sb.text(self._token(tkn - 2)).text(": ")._();
          }
        }
        sb.text("{")._();
        var tmp = self.db.seqb();
        if (first.unwrap()) |_n| {
          tmp.declline().append(try self.t(_n));
          if (self.shouldAddTerminator(_n)) {
            tmp.text(";")._();
          }
        }
        if (second.unwrap()) |_n| {
          tmp.declline().append(try self.t(_n));
          if (self.shouldAddTerminator(_n)) {
            tmp.text(";")._();
          }
        }
        if (tmp.isEmpty()) {
          _ = tmp.finish();
          return sb.text("}").finishSeq();
        }
        return sb.indent(tmp.finish()).hardline().text("}").finishSeq();
      },
      .block, .block_semicolon => {
        self._in_block += 1;
        defer self._in_block -= 1;
        const rng = self.tree.nodeData(n).extra_range;
        const stmts = self.tree.extraDataSlice(rng, Node.Index);
        var sb = self.db.seqb();
        const tkn = self.tree.nodeMainToken(n);
        if (self.tree.tokenTag(tkn - 1) == .colon) {
          if (self.tree.tokenTag(tkn - 2) == .identifier) {
            sb.text(self._token(tkn - 2)).text(": ")._();
          }
        }
        sb.text("{")._();
        var tmp = self.db.seqb();
        if (stmts.len > 0) tmp.declline()._();
        for (stmts, 0..) |stmt, i| {
          if (i > 0) {
            tmp.declline()._();
          }
          tmp.append(try self.t(stmt));
          if (self.shouldAddTerminator(stmt)) {
            tmp.text(";")._();
          }
        }
        if (tmp.isEmpty()) {
          _ = tmp.finish();
          return sb.text("}").finishSeq();
        }
        return sb.indent(tmp.finish()).hardline().text("}").finishSeq();
      },
      .container_decl_arg, .container_decl_arg_trailing => {
        const decl = self.tree.containerDeclArg(n);
        return self.tContainerDecl(
          decl.layout_token,
          decl.ast.main_token,
          decl.ast.enum_token,
          decl.ast.arg.unwrap(),
          decl.ast.members,
        );
      },
      .container_decl_two, .container_decl_two_trailing,
      .tagged_union_two, .tagged_union_two_trailing => {
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        const main_tkn = self.tree.nodeMainToken(n);
        var buf: [2]Node.Index = undefined;
        const members = unwrapTwo(&buf, first, second);
        var enum_tkn: ?Ast.TokenIndex = null;
        if (self.tree.tokenTag(main_tkn + 1) == .l_paren) {
          // past '(' is the enum token
          enum_tkn = main_tkn + 2;
        }
        return self.tContainerDecl(
          null,
          main_tkn,
          enum_tkn,
          null,
          members,
        );
      },
      .tagged_union_enum_tag, .tagged_union_enum_tag_trailing => {
        const decl = self.tree.taggedUnionEnumTag(n);
        return self.tContainerDecl(
          decl.layout_token,
          decl.ast.main_token,
          decl.ast.enum_token,
          decl.ast.arg.unwrap(),
          decl.ast.members,
        );
      },
      .container_decl, .container_decl_trailing => {
        // `struct {}`, `union {}`, `opaque {}`, `enum {}`.
        const decl = self.tree.containerDecl(n);
        return self.tContainerDecl(
          decl.layout_token,
          decl.ast.main_token,
          decl.ast.enum_token,
          decl.ast.arg.unwrap(),
          decl.ast.members,
        );
      },
      .tagged_union, .tagged_union_trailing => {
        const decl = self.tree.taggedUnion(n);
        return self.tContainerDecl(
          decl.layout_token,
          decl.ast.main_token,
          decl.ast.enum_token,
          decl.ast.arg.unwrap(),
          decl.ast.members,
        );
      },
      .container_field_init => {
        return self.tContainerField(self.tree.containerFieldInit(n));
      },
      .container_field_align => {
        return self.tContainerField(self.tree.containerFieldAlign(n));
      },
      .container_field => {
        return self.tContainerField(self.tree.containerField(n));
      },
      .if_simple => {
        const ifn = self.tree.ifSimple(n);
        return self.tIf(ifn);
      },
      .@"if" => {
        const ifn = self.tree.ifFull(n);
        return self.tIf(ifn);
      },
      .for_simple => {
        const fl = self.tree.forSimple(n);
        return self.tFor(fl);
      },
      .@"for" => {
        const fl = self.tree.forFull(n);
        return self.tFor(fl);
      },
      .while_cont => {
        const wl = self.tree.whileCont(n);
        return self.tWhile(wl);
      },
      .while_simple => {
        const wl = self.tree.whileSimple(n);
        return self.tWhile(wl);
      },
      .@"while" => {
        const wl = self.tree.whileFull(n);
        return self.tWhile(wl);
      },
      .@"switch", .switch_comma => {
        const sw = self.tree.switchFull(n);
        return self.tSwitch(sw);
      },
      .switch_case_one, .switch_case_inline_one => {
        const sc = self.tree.switchCaseOne(n);
        return self.tSwitchCase(sc);
      },
      .switch_case => {
        const sc = self.tree.switchCase(n);
        return self.tSwitchCase(sc);
      },
      .switch_range => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        var sb = self.db.seqb();
        sb.append(try self.t(lhs));
        sb.text(self._token(self.tree.nodeMainToken(n)))._();
        sb.append(try self.t(rhs));
        return self.db.group(sb.finish());
      },
      .for_range => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_opt_node;
        var sb = self.db.seqb();
        sb.append(try self.t(lhs));
        sb.text(self._token(self.tree.nodeMainToken(n)))._();
        if (rhs.unwrap()) |_n| {
          sb.append(try self.t(_n));
        }
        return self.db.group(sb.finish());
      },
      .builtin_call_two, .builtin_call_two_comma => {
        const id = d.genGroupID();
        var sb = self.db.seqb();
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        sb.text(self._token(self.tree.nodeMainToken(n)))._();
        sb.text("(")._();
        var buf: [2]Node.Index = undefined;
        const args = unwrapTwo(&buf, first, second);
        const should_softline = args.len > 0;
        var sb_args = try self.tCallArgs(id, tag, args, should_softline);
        sb.indent(sb_args.finish())._();
        sb.softlineIf(should_softline).text(")")._();
        return self.db.groupi(id, sb.finish());
      },
      .builtin_call, .builtin_call_comma => {
        const id = d.genGroupID();
        var sb = self.db.seqb();
        const rng = self.tree.nodeData(n).extra_range;
        const prms = self.tree.extraDataSlice(rng, Node.Index);
        sb.text(self._token(self.tree.nodeMainToken(n)))._();
        sb.text("(")._();
        const should_softline = prms.len != 0;
        var sb_args = try self.tCallArgs(id, tag, prms, should_softline);
        sb.indent(sb_args.finish())._();
        sb.softlineIf(should_softline).text(")")._();
        return self.db.groupi(id, sb.finish());
      },
      .error_union => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        var sb = self.db.seqb();
        sb.appends(try self.t(lhs)).text("!").append(try self.t(rhs));
        return self.db.group(sb.finish());
      },
      .struct_init, .struct_init_comma => {
        const decl = self.tree.structInit(n);
        return self.tStructInit(n, null, decl.ast.fields);
      },
      .struct_init_one, .struct_init_one_comma => {
        const first, const second = self.tree.nodeData(n).node_and_opt_node;
        const fields = if (second.unwrap()) |_n| &.{_n} else &.{};
        return self.tStructInit(n, first, fields);
      },
      .struct_init_dot, .struct_init_dot_comma => {
        const decl = self.tree.structInitDot(n);
        return self.tStructInit(n, null, decl.ast.fields);
      },
      .struct_init_dot_two, .struct_init_dot_two_comma => {
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        var buf: [2]Node.Index = undefined;
        const args = unwrapTwo(&buf, first, second);
        return self.tStructInit(n, null, args);
      },
      .array_init, .array_init_comma => {
        const decl = self.tree.arrayInit(n);
        return self.tArrayInit(n, decl.ast.type_expr.unwrap(), decl.ast.elements);
      },
      .array_init_one, .array_init_one_comma => {
        const first, const second = self.tree.nodeData(n).node_and_opt_node;
        const elements = if (second.unwrap()) |_n| &.{_n} else &.{};
        return self.tArrayInit(n, first, elements);
      },
      .array_init_dot, .array_init_dot_comma => {
        const decl = self.tree.arrayInitDot(n);
        return self.tArrayInit(n, decl.ast.type_expr.unwrap(), decl.ast.elements);
      },
      .array_init_dot_two, .array_init_dot_two_comma => {
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        var buf: [2]Node.Index = undefined;
        const args = unwrapTwo(&buf, first, second);
        return self.tArrayInit(n, null,  args);
      },
      .@"return" => {
        var sb = self.db.seqb().text("return");
        const expr = self.tree.nodeData(n).opt_node;
        if (expr.unwrap()) |_n| {
          sb.space().append(try self.t(_n));
        }
        return self.db.group(sb.finish());
      },
      .@"break" => {
        // `break :label expr`, `break expr`, `break :label`, `break`.
        var sb = self.db.seqb().text("break");
        const tkn, const node = self.tree.nodeData(n).opt_token_and_opt_node;
        if (tkn.unwrap()) |idx| {
          sb.text(" :").text(self._token(idx)).space()._();
        }
        if (node.unwrap()) |_n| {
          sb.append(try self.t(_n));
        }
        return self.db.group(sb.finish());
      },
      .assign_destructure => {
        const ad = self.tree.assignDestructure(n);
        var sb = self.db.seqb();
        for (ad.ast.variables, 0..) |vr, i| {
          if (i > 0) {
            sb.text(", ")._();
          }
          sb.append(try self.t(vr));
        }
        sb.space().text(self._token(ad.ast.equal_token)).space()._();
        sb.append(try self.t(ad.ast.value_expr));
        return self.db.group(sb.finish());
      },
      .assign => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        var sb = self.db.seqb();
        sb.append(try self.t(lhs));
        sb.text(" = ")._();
        sb.append(try self.t(rhs));
        return self.db.group(sb.finish());
      },
      .assign_add => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        var sb = self.db.seqb();
        sb.append(try self.t(lhs));
        sb.text(" += ")._();
        sb.append(try self.t(rhs));
        return self.db.group(sb.finish());
      },
      .field_access => {
        // lhs.a
        // TODO:
        unreachable;
      },
      // ops
      .add, .add_wrap, .add_sat, .array_cat, .array_mult, .bang_equal,
      .bit_and, .bit_or, .shl, .shl_sat, .shr, .bit_xor, .bool_and,
      .bool_or, .div, .equal_equal, .greater_or_equal, .greater_than,
      .less_or_equal, .less_than, .merge_error_sets, .mod, .mul, .mul_wrap,
      .mul_sat, .sub, .sub_wrap, .sub_sat => {
        return self.tBinaryExpr(n, tag);
      },
      .@"try" => {
        const tkn = self._token(self.tree.nodeMainToken(n));
        const _n = self.tree.nodeData(n).node;
        var sb = self.db.seqb().text(tkn).space();
        sb.append(try self.t(_n));
        return self.db.group(sb.finish());
      },
      .@"catch" => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        var sb = self.db.seqb();
        const lhs_d = try self.t(lhs);
        const rhs_d = try self.t(rhs);
        const tkn = self.tree.nodeMainToken(n);
        const catch_tkn = self._token(tkn);
        var flat = self.db.seqb().appends(lhs_d).space().text(catch_tkn).space();
        var split = self.db.seqb().appends(lhs_d);
        var rest = self.db.seqb().softline().text(catch_tkn).space();
        if (self.tree.tokenTag(tkn + 1) == .pipe) {
          const payload = self._token(tkn + 2);
          flat.text("|").text(payload).text("|").space()._();
          rest.text("|").text(payload).text("|").space()._();
        }
        flat.append(rhs_d);
        rest.append(rhs_d);
        split.indent(rest.finish())._();
        const id = d.genGroupID();
        sb.ifsplit(id, split.finishSeq(), flat.finishSeq())._();
        return self.db.groupi(id, sb.finish());
      },
      .@"orelse" => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        var sb = self.db.seqb();
        const lhs_d = try self.t(lhs);
        const rhs_d = try self.t(rhs);
        const tkn = self.tree.nodeMainToken(n);
        const orelse_tkn = self._token(tkn);
        var flat = self.db.seqb().appends(lhs_d).space().text(orelse_tkn).space().appends(rhs_d);
        var split = self.db.seqb().appends(lhs_d);
        var rest = self.db.seqb().softline().text(orelse_tkn).space().appends(rhs_d);
        split.indent(rest.finish())._();
        const id = d.genGroupID();
        sb.ifsplit(id, split.finishSeq(), flat.finishSeq())._();
        return self.db.groupi(id, sb.finish());
      },
      .address_of => {
        const tkn = self._token(self.tree.nodeMainToken(n));
        const _n = self.tree.nodeData(n).node;
        var sb = self.db.seqb().text(tkn);
        sb.append(try self.t(_n));
        return self.db.group(sb.finish());
      },
      .grouped_expression => {
        // `(expr)`
        const expr, _ = self.tree.nodeData(n).node_and_token;
        var sb = self.db.seqb();
        sb.text("(").appends(try self.t(expr)).text(")")._();
        return self.db.group(sb.finish());
      },
      //: Type Nodes
      .optional_type => {
        // ?expr
        const ty = try self.t(self.tree.nodeData(n).node);
        return self.db.group(self.db.seqb().text("?").appends(ty).finish());
      },
      .array_type_sentinel, .array_type => {
        const _n = (
          if (tag == .array_type) self.tree.arrayType(n)
          else self.tree.arrayTypeSentinel(n)
        );
        var sb = self.db.seqb().text("[");
        const cnt = try self.t(_n.ast.elem_count);
        var elems = self.db.seqb().softline().appends(cnt);
        if (_n.ast.sentinel.unwrap()) |s| {
          elems.text(":").append(try self.t(s));
        }
        const ty = try self.t(_n.ast.elem_type);
        sb.indent(elems.finish()).softline().text("]").appends(ty)._();
        return self.db.group(sb.finish());
      },
      .ptr_type_aligned => {
        const _n = self.tree.ptrTypeAligned(n);
        return self.tPtrType(_n);
      },
      .ptr_type_sentinel => {
        const _n = self.tree.ptrTypeSentinel(n);
        return self.tPtrType(_n);
      },
      .ptr_type_bit_range => {
        const _n = self.tree.ptrTypeBitRange(n);
        return self.tPtrType(_n);
      },
      .ptr_type => {
        const _n = self.tree.ptrType(n);
        return self.tPtrType(_n);
      },
      else => {
        log.debug("found unhandled node: {}", .{tag});
        unreachable;
      }
    }
  }

  pub fn translate(self: *Self) !*Doc {
    const doc = try self.tOpenContainerDecl(self.tree.rootDecls());
    // verify that all builders are successfully consumed
    self.db.verify();
    return doc;
  }
};
