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
        self.db.group(split.finish()),
        self.db.group(flat.finish()),
      );
      return self.db.groupi(id, db.finish());
    }
    return null;
  }

  fn _collectBinopExprStep(self: *Self, n: Node.Index, list: *NodeIndexList) void {
    switch (self.tree.nodeTag(n)) {
      .add, .add_wrap, .add_sat, .array_cat, .array_mult, .bang_equal,
      .bit_and, .bit_or, .shl, .shl_sat, .shr, .bit_xor, .bool_and,
      .bool_or, .div, .equal_equal, .greater_or_equal, .greater_than,
      .less_or_equal, .less_than, .merge_error_sets, .mod, .mul, .mul_wrap,
      .mul_sat, .sub, .sub_wrap, .sub_sat, .@"orelse" => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        self._collectBinopExprStep(lhs, list);
        util.listAppend(n, list, self.al);
        self._collectBinopExprStep(rhs, list);
      },
      else => {
        util.listAppend(n, list, self.al);
      }
    }
  }

  fn collectBinopExprs(self: *Self, n: Node.Index) []Node.Index {
    var list: NodeIndexList = .empty;
    self._collectBinopExprStep(n, &list);
    return list.items;
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

  fn tVarDecl(self: *Self, vd: Ast.full.VarDecl) TranslateError!*SeqBuilder {
    var sb = try self.tVarDeclProto(vd);
    if (vd.ast.init_node.unwrap()) |_n| {
      sb.text(" = ")._();
      sb.append(try self.t(_n));
    }
    return sb;
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
    var has_extern = false;
    loop: while (true) : (curr -= 1) {
      switch (self.tree.tokenTag(curr)) {
        .keyword_inline, .keyword_export, .keyword_pub, .keyword_noinline => {
          sb.space().text(self._token(curr))._();
        },
        .keyword_extern => {
          sb.space().text(self._token(curr))._();
          has_extern = true;
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
      sb.group(tmp.normline().finish())._();
      const tkn = self.tree.nodeMainToken(_n) - 1;
      if (self.tree.tokenTag(tkn) == .bang) {
        sb.text(self._token(tkn))._();
      }
      sb.append(try self.t(_n));
    } else {
      sb.group(tmp.finish())._();
    }
    if (has_extern) {
      sb.text(";")._();
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
      if (self.nodeIsVarDecl(_n)) {
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
      if (self.nodeIsVarDecl(_n)) {
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
    sb.text(self._token(cf.ast.main_token))._();
    if (cf.ast.type_expr.unwrap()) |_n| {
      sb.text(": ").append(try self.t(_n));
    }
    if (cf.ast.align_expr.unwrap()) |_n| {
      sb.space().append(try self.tAttribute(_n, "align"));
    }
    if (cf.ast.value_expr.unwrap()) |_n| {
      sb.text(" = ").append(try self.t(_n));
    }
    return self.db.group(sb.finish());
  }

  fn tStructInit(
    self: *Self,
    n: Node.Index,
    texpr: ?Node.Index,
    should_softline: bool,
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
    if (args.isEmpty()) {
      _ = args.finish();
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
      .identifier, .number_literal, .string_literal, .char_literal => {
        return self.db.text(self._token(self.tree.nodeMainToken(n)));
      },
      .simple_var_decl, .global_var_decl, .local_var_decl, .aligned_var_decl => {
        const vd = self.tree.fullVarDecl(n).?;
        var sb = try self.tVarDecl(vd);
        return self.db.group(sb.finish());
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
        var sb = self.db.seqb().text("{");
        var tmp = self.db.seqb();
        if (first.unwrap()) |_n| {
          tmp.declline().append(try self.t(_n));
          tmp.text(";")._();
        }
        if (second.unwrap()) |_n| {
          tmp.declline().append(try self.t(_n));
          tmp.text(";")._();
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
        var sb = self.db.seqb().text("{");
        var tmp = self.db.seqb();
        if (stmts.len > 0) tmp.declline()._();
        for (stmts, 0..) |stmt, i| {
          if (i > 0) {
            tmp.declline()._();
          }
          tmp.appends(try self.t(stmt)).text(";")._();
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
        return self.tStructInit(n, null, decl.ast.fields.len > 0, decl.ast.fields);
      },
      .struct_init_one, .struct_init_one_comma => {
        const first, const second = self.tree.nodeData(n).node_and_opt_node;
        const fields = if (second.unwrap()) |_n| &.{_n} else &.{};
        return self.tStructInit(n, first, fields.len > 0, fields);
      },
      .struct_init_dot, .struct_init_dot_comma => {
        const decl = self.tree.structInitDot(n);
        return self.tStructInit(n, null, decl.ast.fields.len > 0, decl.ast.fields);
      },
      .struct_init_dot_two, .struct_init_dot_two_comma => {
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        var buf: [2]Node.Index = undefined;
        const args = unwrapTwo(&buf, first, second);
        const should_softline = args.len > 0;
        return self.tStructInit(n, null, should_softline, args);
      },
      .@"return" => {
        var sb = self.db.seqb().text("return");
        const expr = self.tree.nodeData(n).opt_node;
        if (expr.unwrap()) |_n| {
          sb.space().append(try self.t(_n));
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
      .field_access => {
        // lhs.a
        // TODO:
        unreachable;
      },
      //: Expr Nodes
      // ops
      .add, .add_wrap, .add_sat, .array_cat, .array_mult, .bang_equal,
      .bit_and, .bit_or, .shl, .shl_sat, .shr, .bit_xor, .bool_and,
      .bool_or, .div, .equal_equal, .greater_or_equal, .greater_than,
      .less_or_equal, .less_than, .merge_error_sets, .mod, .mul, .mul_wrap,
      .mul_sat, .sub, .sub_wrap, .sub_sat, .@"orelse" => {
        const nodes = self.collectBinopExprs(n);
        // a significantly high number is fine
        var last_prec: u8 = 0xff;
        var possible_splits: usize = 0;
        var k: usize = 1;
        while (k < nodes.len) : (k += 2) {
          const prec = tagPrec(self.tree.nodeTag(nodes[k]));
          if (prec < last_prec) {
            last_prec = prec;
            possible_splits += 1;
          }
        }
        assert(nodes.len % 2 == 1);
        var ds = std.ArrayList(*Doc).empty;
        var sb = self.db.seqb();
        var tmp = self.db.seqb();
        last_prec = 0xff;
        var splits: usize = 0;
        var i: usize = 1;
        util.listAppend(try self.t(nodes[i-1]), &ds, self.al);
        // FIXME: this is flaky, need to revisit
        while (i < nodes.len) : (i += 2) {
          const op = self._token(self.tree.nodeMainToken(nodes[i]));
          const id = d.genGroupID();
          if (ds.items.len >= 2) {
            util.listAppendSlice(*Doc, &tmp.docs, ds.items, self.al);
            ds.clearRetainingCapacity();
            const op_prec = tagPrec(self.tree.nodeTag(nodes[i]));
            if (op_prec <= last_prec) {
              // only split when we're at a low precedence operator
              tmp.softline()._();
              last_prec = op_prec;
              splits += 1;
            } else if (splits == possible_splits) {
              // indent-split if we're splitting unconditionally and if
              // we've exhausted possible splits
              tmp.indent(self.db.seqb().softline().finish())._();
            } else {
              // add space only when we split
              tmp.ifsplit(id, self.db.space(), self.db.seq(&.{}))._();
            }
            const split_doc = self.db.seqb().text(op).space().finishSeq();
            const flat_doc = self.db.seqb().space().text(op).space().finishSeq();
            const op_doc = self.db.seqb().ifsplit(id, split_doc, flat_doc).finish();
            tmp.extends(op_doc).append(try self.t(nodes[i+1]));
            util.listAppend(self.db.groupi(id, tmp.finish()), &ds, self.al);
          } else {
            tmp.space().text(op).space()._();
            tmp.append(try self.t(nodes[i+1]));
            util.listAppend(self.db.groupi(id, tmp.finish()), &ds, self.al);
          }
          tmp.reset();
        }
        assert(ds.items.len > 0 and tmp.isEmpty());
        util.listAppendSlice(*Doc, &tmp.docs, ds.items, self.al);
        sb.indent(tmp.finish())._();
        return self.db.group(sb.finish());
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
        const cnt = try self.t(_n.ast.elem_count);
        const ty = try self.t(_n.ast.elem_type);
        var sb = self.db.seqb().text("[").appends(cnt);
        if (_n.ast.sentinel.unwrap()) |s| {
          sb.text(":").append(try self.t(s));
        }
        return self.db.group(sb.text("]").appends(ty).finish());
      },
      .ptr_type_aligned => {
        const _n = self.tree.ptrTypeAligned(n);
        var sb = self.db.seqb();
        switch (_n.size) {
          .one => sb.text("*")._(),
          .c => sb.text("[*c]")._(),
          .many => sb.text("[*]")._(),
          .slice => sb.text("[]")._(),
        }
        // TODO: other pointer token components
        if (_n.const_token != null) {
          sb.text("const").space()._();
        }
        return self.db.group(sb.appends(try self.t(_n.ast.child_type)).finish());
      },
      .ptr_type_sentinel => {
        const _n = self.tree.ptrTypeSentinel(n);
        var sb = self.db.seqb();
        switch (_n.size) {
          .one => sb.text("*")._(),
          .c => sb.text("[*c:")._(),
          .many => sb.text("[*:")._(),
          .slice => sb.text("[:")._(),
        }
        const s = _n.ast.sentinel.unwrap().?;
        sb.appends(try self.t(s)).text("]")._();
        // TODO: other pointer token components
        if (_n.const_token != null) {
          sb.text("const").space()._();
        }
        return self.db.group(sb.appends(try self.t(_n.ast.child_type)).finish());
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
