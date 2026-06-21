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
  io: std.Io,
  db: DocBuilder,
  /// cache the last token we checked for comments. This helps to speed
  /// up checking whether a token has trailing comments or not.
  tkn_cache: TokenCache = .{.tkn = 0, .has_trailing_comment = false},
  /// whether to translate an empty block `{}` as decoupled, i.e. on separate lines
  decouple_empty_block_braces: u16 = 0,
  fmt_disabled_pos: ?usize = null,
  /// other metadata trackers
  _in_call_args: u16 = 0,
  _comments: u32 = 0,

  const Self = @This();
  const TokenCache = struct {tkn: Ast.TokenIndex, has_trailing_comment: bool};

  pub fn init(al: Allocator, io: std.Io) !Self {
    return .{
      .al = al,
      .tree = undefined,
      .io = io,
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
    return self.tree.tokenTag(tkn) == .l_brace;
  }

  fn hasTerminator(self: *Self, n: Node.Index, terms: []const std.zig.Token.Tag) ?Ast.TokenIndex {
    const tkn = self.tree.lastToken(n) + 1;
    const tag = self.tree.tokenTag(tkn);
    for (terms) |term| {
      if (tag == term) {
        return tkn;
      }
    }
    return null;
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

  inline fn updateLinesToDecllines(sb: *SeqBuilder) void {
    for (sb.docs.items) |doc| {
      if (doc.is(.line)) {
        doc.line.ty = .decl;
      }
    }
  }

  inline fn updateLinesToDecllines2(self: *Self, sb: *SeqBuilder) void {
    for (sb.docs.items) |*doc| {
      if (doc.*.is(.line)) {
        doc.*.line.ty = .decl;
      } else if (doc.*.is(.ifsplit)) {
        if (doc.*.ifsplit.split.is(.line)) {
          doc.* = doc.*.ifsplit.split;
        } else {
          doc.* = self.db.empty();
        }
      }
    }
  }

  /// check if we can format a container's members inline
  fn canFormatMembersInline(self: *Self, lbrace: Ast.TokenIndex, rbrace: Ast.TokenIndex) bool {
    const start = self.tree.tokenStart(lbrace);
    const end = self.tree.tokenStart(rbrace);
    if (std.mem.find(u8, self.tree.source[start..end], "//") != null) {
      return false;
    }
    var tkn = lbrace;
    while (tkn != rbrace) : (tkn += 1) {
      switch (self.tree.tokenTag(tkn)) {
        .keyword_fn, .keyword_pub,
        .keyword_inline, .keyword_noinline,
        .keyword_union, .keyword_struct,
        .keyword_extern, .keyword_test => return false,
        else => {},
      }
    }
    return self.tknHasNoTC(rbrace);
  }

  /// check if comments count changed since we last kept count
  inline fn commentsChanged(self: *Self, last_count: usize) bool {
    return last_count != self._comments;
  }

  /// check whether this token has a trailing comment
  fn tknHasTC(self: *Self, tkn: Ast.TokenIndex) bool {
    const tag = self.tree.tokenTag(tkn);
    if (tag == .multiline_string_literal_line or (tag != .eof and self.tree.tokenTag(tkn + 1) == .multiline_string_literal_line)) {
      return true;
    }
    if (tkn != 0 and self.tkn_cache.tkn == tkn) {
      return self.tkn_cache.has_trailing_comment;
    }
    const start = self.tree.tokenStart(tkn) + self._token(tkn).len;
    const end = self.tree.tokenStart(tkn + 1);
    return std.mem.find(u8, self.tree.source[start .. end], "//") != null;
  }

  /// check whether this token has no trailing comment
  inline fn tknHasNoTC(self: *Self, tkn: Ast.TokenIndex) bool {
    return !self.tknHasTC(tkn);
  }

  inline fn isKwdTkn(self: *Self, tkn: Ast.TokenIndex, skip_comptime: bool) bool {
    var tag = self.tree.tokenTag(tkn);
    if (skip_comptime and tag == .keyword_comptime) tag = self.tree.tokenTag(tkn + 1);
    return std.mem.startsWith(u8, @tagName(tag), "keyword");
  }

  fn getRBrackTkn(self: *Self, lbrack: Ast.TokenIndex) Ast.TokenIndex {
    var rbrack = lbrack;
    if (self.tree.tokenTag(rbrack) == .l_paren) {
      rbrack += 1;
    }
    var lbracks = @as(usize, 0);
    while (true) {
      const tag = self.tree.tokenTag(rbrack);
      if (tag == .r_paren) {
        if (lbracks == 0) {
          return rbrack;
        }
        lbracks -= 1;
      } else if (tag == .l_paren) {
        lbracks += 1;
      }
      rbrack += 1;
    }
    assert(self.tree.tokenTag(rbrack) == .r_paren);
    return rbrack;
  }
  
  /// simple abstraction over call chains
  const Chain = union(enum) {
    ident: Ast.TokenIndex,
    idents: []Ast.TokenIndex,
    call: struct {
      expr: union(enum) {
        tkn: Ast.TokenIndex,
        tkns: []Ast.TokenIndex,
        chain: *Chain,
        node: Node.Index,
      },
      params: []const Node.Index
    },
    expr: Node.Index,
    const TokenIndexList = std.ArrayList(Ast.TokenIndex);

    pub fn getLBrackTkn(self: *const Chain, ts: *Translate) Ast.TokenIndex {
      switch (self.*) {
        .ident => |tkn| return tkn + 1,
        .idents => |tkns| return tkns[tkns.len - 1] + 1,
        .call => |call| {
          if (call.params.len > 0) {
            return ts.tree.firstToken(call.params[0]) - 1;
          } 
          switch (call.expr) {
            .tkn => |tkn| return tkn + 1,
            .tkns => |tkns| return tkns[tkns.len - 1] + 1,
            .chain => |chn| return chn.getLBrackTkn(ts),
            .node => |n| return ts.tree.lastToken(n) + 1,
          }
        },
        .expr => |expr| return ts.tree.lastToken(expr) + 1,
      }
    }

    pub fn getLastTkn(self: *const Chain, ts: *Translate) Ast.TokenIndex {
      switch (self.*) {
        .ident => |tkn| return tkn,
        .idents => |tkns| return tkns[tkns.len - 1],
        .call => |call| {
          if (call.params.len > 0) {
            return ts.tree.lastToken(call.params[call.params.len - 1]) + 1; // rbrack
          }
          // call has no params
          switch (call.expr) {
            .tkn => |tkn| return tkn + 2, // lbrack, rbrack
            .tkns => |tkns| return tkns[tkns.len - 1] + 2, // lbrack, rbrack
            .chain => |chn| return chn.getLastTkn(ts),
            .node => |n| return ts.tree.lastToken(n) + 2, // lbrack, rbrack
          }
        },
        .expr => |expr| return ts.tree.lastToken(expr),
      }
    }

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

  fn chainExprtoChainCall(self: *Self, expr: Chain, call: Ast.full.Call, list: *ChainList) void {
    switch (expr) {
      .idents => |lhs| {
        const c = Chain{.call = .{.expr = .{.tkns = lhs}, .params = call.ast.params}};
        util.listAppend(c, list, self.al);
      }, 
      .ident => |idx| {
        const c = Chain{.call = .{.expr = .{.tkn = idx}, .params = call.ast.params}};
        util.listAppend(c, list, self.al);
      },
      else => {
        const e = util.box(expr, self.al);
        const c = Chain{.call = .{.expr = .{.chain = e}, .params = call.ast.params}};
        util.listAppend(c, list, self.al);
      }
    }
  }

  fn _collectChainsStep(
    self: *Self,
    n: Node.Index,
    list: *ChainList,
    merge_field_access_tkns: bool,
  ) void {
    switch (self.tree.nodeTag(n)) {
      .identifier => {
        const ident = Chain{.ident = self.tree.nodeMainToken(n)};
        util.listAppend(ident, list, self.al);
      },
      .call, .call_comma, .call_one, .call_one_comma => {
        const call = self.getCallInfo(n);
        self._collectChainsStep(call.ast.fn_expr, list, merge_field_access_tkns);
        const last = list.pop().?;
        self.chainExprtoChainCall(last, call, list);
      },
      .error_value => {
        const lhs = self.tree.nodeMainToken(n);
        if (merge_field_access_tkns) {
          var tmp = [_]Ast.TokenIndex{lhs, lhs + 2};
          const slice = util.allocSlice(Ast.TokenIndex, 2, self.al);
          @memcpy(slice.ptr, &tmp);
          util.listAppend(Chain{.idents = slice}, list, self.al);
        } else {
          // if `merge_field_access_tkns` is false, then gather the ident
          // tokens, for example: foo.bar -> foo, bar
          var tkns = [_]Chain{Chain{.ident = lhs}, Chain{.ident = lhs + 2}};
          util.listAppendSlice(Chain, list, tkns[0..], self.al);
        }
      },
      .field_access, .unwrap_optional => {
        const lhs, const _rhs = self.tree.nodeData(n).node_and_token;
        self._collectChainsStep(lhs, list, merge_field_access_tkns);
        const last = list.getLast();
        switch (last) {
          .ident => |idx| {
            if (merge_field_access_tkns) {
              _ = list.pop().?;
              var tmp = [_]Ast.TokenIndex{idx, _rhs};
              const slice = util.allocSlice(Ast.TokenIndex, 2, self.al);
              @memcpy(slice.ptr, &tmp);
              util.listAppend(Chain{.idents = slice}, list, self.al);
            } else {
              // if `merge_field_access_tkns` is false, then gather the ident
              // tokens, for example: foo.bar -> foo, bar
              util.listAppend(Chain{.ident = _rhs}, list, self.al);
            }
          },
          .idents => |tkns| {
            assert(merge_field_access_tkns);
            var new_tkns = util.allocSlice(Ast.TokenIndex, tkns.len + 1, self.al);
            @memcpy(new_tkns[0..tkns.len], tkns.ptr);
            new_tkns[new_tkns.len - 1] = _rhs;
            list.items[list.items.len - 1].idents = new_tkns;
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

  fn collectChains(self: *Self, n: Node.Index, is_chain_call: bool) ?[]Chain {
    var list = ChainList.empty;
    switch (self.tree.nodeTag(n)) {
      .field_access, .error_value, .unwrap_optional => {
        self._collectChainsStep(n, &list, is_chain_call);
      },
      else => return null,
    }
    return if (list.items.len > 0) list.items else null;
  }

  fn flattenChains(
    self: *Self,
    expr: Node.Index,
    call: ?Ast.full.Call,
    is_chain_call: bool,
  ) ?[]Chain {
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
    if (self.collectChains(expr, is_chain_call)) |segments| {
      const last = segments[segments.len - 1];
      if (call) |call_| {
        util.listAppendSlice(Chain, &list, segments[0..segments.len - 1], self.al);
        self.chainExprtoChainCall(last, call_, &list);
      } else {
        util.listAppendSlice(Chain, &list, segments, self.al);
      }
    }
    return if (list.items.len > 0) list.items else null;
  }

  fn tChain(self: *Self, chain: Chain) *Doc {
    switch (chain) {
      .ident => |idx| {
        return self.ttkn(idx);
      },
      .idents => |tkns| {
        var sb = self.db.seqb();
        for (tkns, 0..) |tkn, i| {
          if (i > 0) {
            const prev_tkn = tkns[i - 1];
            const dot = prev_tkn + 1;
            assert(self.tree.tokenTag(dot) == .period);
            sb.decllineIf(self.tknHasTC(prev_tkn))._();
            sb.append(self.ttknWithSTL(dot));
          }
          sb.append(self.ttkn(tkn));
        }
        return sb.finishSeq();
      },
      .expr => |_n| {
        return self.t(_n);
      },
      .call => |c| {
        var sb = self.db.seqb();
        var lbrack: Ast.TokenIndex = undefined;
        switch (c.expr) {
          .tkn => |tkn| {
            sb.append(self.ttkn(tkn));
            lbrack = tkn + 1;
          },
          .tkns => |tkns| {
            for (tkns, 0..) |tkn, i| {
              if (i > 0) {
                const prev_tkn = tkns[i - 1];
                const dot = prev_tkn + 1;
                assert(self.tree.tokenTag(dot) == .period);
                sb.decllineIf(self.tknHasTC(prev_tkn))._();
                sb.append(self.ttknWithSTL(dot));
              }
              sb.append(self.ttkn(tkn));
              lbrack = tkn + 1;
            }
          },
          .chain => |chn| {
            sb.append(self.tChain(chn.*));
            lbrack = chn.getLBrackTkn(self);
          },
          .node => |nd| {
            sb.append(self.t(nd));
            lbrack = self.tree.lastToken(nd) + 1;
          },
        }
        assert(self.tree.tokenTag(lbrack) == .l_paren);
        const id = d.genGroupID();
        const rbrack = self.getRBrackTkn(lbrack);
        sb.decllineIf(self.tknHasTC(lbrack - 1))._();
        self.tCall(sb, id, lbrack, rbrack, c.params, null, null, true);
        return self.db.groupi(id, sb.finish());
      },
    }
  }

  fn tCallChain(self: *Self, call: Ast.full.Call) ?*Doc {
    if (self.flattenChains(call.ast.fn_expr, call, true)) |chains| {
      var sbs: std.ArrayList(*Doc) = .empty;
      for (chains) |chain| {
        const doc = self.tChain(chain);
        util.listAppend(doc, &sbs, self.al);
      }
      const id = d.genGroupID();
      var flat = self.db.seqb();
      var last_tkn: ?Ast.TokenIndex = null;
      for (sbs.items, 0..) |doc, i| {
        if (i > 0) {
          var tkn = chains[i - 1].getLastTkn(self) + 1;
          while (self.tree.tokenTag(tkn) != .period) tkn += 1;
          assert(self.tree.tokenTag(tkn) == .period);
          flat.decllineIf(self.tknHasTC(tkn - 1)).append(self.ttkn(tkn));
          last_tkn = tkn;
        }
        if (last_tkn) |tkn| flat.decllineIf(self.tknHasTC(tkn))._();
        flat.append(doc);
      }
      var split = self.db.seqb();
      split.append(sbs.items[0]);
      var rest = self.db.seqb();
      for (sbs.items[1..], 0..) |doc, i| {
        var tkn = chains[i].getLastTkn(self) + 1;
        while (self.tree.tokenTag(tkn) != .period) tkn += 1;
        assert(self.tree.tokenTag(tkn) == .period);
        rest.softlineOrDeclline(self.tknHasNoTC(tkn - 1));
        rest.append(self.ttknWithSTL(tkn));
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

  fn tAccessChain(self: *Self, n: Node.Index) *Doc {
    const chains = self.flattenChains(n, null, false).?;
    var sbs: std.ArrayList(*Doc) = .empty;
    for (chains) |chain| {
      const doc = self.tChain(chain);
      util.listAppend(doc, &sbs, self.al);
    }
    const id = d.genGroupID();
    var flat = self.db.seqb();
    var last_tkn: ?Ast.TokenIndex = null;
    for (sbs.items, 0..) |doc, i| {
      if (i > 0) {
        var tkn = chains[i - 1].getLastTkn(self) + 1;
        if (self.tree.tokenTag(tkn) != .period) tkn += 1;
        assert(self.tree.tokenTag(tkn) == .period);
        flat.decllineIf(self.tknHasTC(tkn - 1)).append(self.ttkn(tkn));
        last_tkn = tkn;
      }
      if (last_tkn) |tkn| flat.decllineIf(self.tknHasTC(tkn))._();
      flat.append(doc);
    }
    var split = self.db.seqb();
    split.append(sbs.items[0]);
    var rest = self.db.seqb();
    for (sbs.items[1..], 0..) |doc, i| {
      var tkn = chains[i].getLastTkn(self) + 1;
      if (self.tree.tokenTag(tkn) != .period) tkn += 1;
      assert(self.tree.tokenTag(tkn) == .period);
      rest.softlineOrDeclline(self.tknHasNoTC(tkn - 1));
      rest.append(self.ttknWithSTL(tkn));
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

  fn tBinaryExpr(self: *Self, n: Node.Index, tag: Node.Tag) *Doc {
    var list: BinaryList = .empty;
    const all_same_precs = self._collectBinaryExprStep(n, tag,  &list);
    const nodes = list.items;
    const first = nodes[0];
    assert(first.op == null);
    var sb = self.db.seqb();
    sb.append(self.t(first.node));
    var rest = self.db.seqb();
    var tmp = self.db.seqb();
    const group = all_same_precs or nodes.len > 12;
    if (nodes.len > 1) {
      var last: ?*Doc = null;
      for (nodes[1..]) |bin| {
        const tkn = self.tree.nodeMainToken(bin.op.?);
        const op = self.ttkn(tkn);
        const doc = self.t(bin.node);
        if (last) |lhs| {
          tmp.append(lhs);
          tmp.decllineOrNormline(self.tknHasTC(tkn - 1));
          tmp.append(op);
          tmp.decllineOrSpace(self.tknHasTC(tkn));
          tmp.append(doc);
          last = self.db.group(tmp.finish());
          tmp.reset();
        } else if (group) {
          tmp.decllineOrNormline(self.tknHasTC(tkn - 1));
          tmp.append(op);
          tmp.decllineOrSpace(self.tknHasTC(tkn));
          tmp.append(doc);
          last = self.db.group(tmp.finish());
          tmp.reset();
        } else {
          rest.decllineOrNormline(self.tknHasTC(tkn - 1));
          rest.append(op);
          rest.decllineOrSpace(self.tknHasTC(tkn));
          rest.append(doc);
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

  fn tOrelseCatch(self: *Self, n: Node.Index) *Doc {
    const lhs, const rhs = self.tree.nodeData(n).node_and_node;
    const lhs_d = self.t(lhs);
    const tkn = self.tree.nodeMainToken(n);
    var sb = self.db.seqb().appends(lhs_d);
    var tmp = self.db.seqb();
    const rhs_isnt_block = !self.isBlock(self.tree.nodeMainToken(rhs));
    if (rhs_isnt_block) {
      tmp.decllineOrNormline(self.tknHasTC(self.tree.lastToken(lhs)));
    } else {
      tmp.decllineOrSpace(self.tknHasTC(self.tree.lastToken(lhs)));
    }
    tmp.appends(self.ttknWithSTL(tkn)).spaceIf(self.tknHasNoTC(tkn))._();
    tmp = self.db.seqb().group(tmp.finish());
    if (self.tree.tokenTag(tkn + 1) == .pipe) {
      const l_pipe = self.ttknWithSTL(tkn + 1); // |
      const ident = self.ttknWithSTL(tkn + 2); // IDENT
      const r_pipe = self.ttknWithSTL(tkn + 3); // |
      tmp.appends(l_pipe).appends(ident).append(r_pipe);
      tmp.spaceIf(self.tknHasNoTC(tkn + 3))._();
      tmp = self.db.seqb().group(tmp.finish());
    }
    if (rhs_isnt_block) {
      const rhs_d = self.t(rhs);
      tmp.append(rhs_d);
      sb.indent(tmp.finish())._();
    } else {
      // NOTE: we specialize the formatting for `rhs` when it's a block
      const lbrace = self.tree.nodeMainToken(rhs);
      const rbrace = self.tree.lastToken(rhs);
      if (self.tree.tokenTag(lbrace - 1) == .colon and self.tree.tokenTag(lbrace - 2) == .identifier) {
        tmp.appends(self.ttknWithTL(lbrace - 2)).append(self.ttknWithSTL(lbrace - 1));
        tmp.spaceIf(self.tknHasNoTC(lbrace - 1))._();
      }
      var buf: [2]Node.Index = undefined;
      const stmts = switch (self.tree.nodeTag(rhs)) {
        .block_two, .block_two_semicolon => blk: {
          const first, const second = self.tree.nodeData(rhs).opt_node_and_opt_node;
          break :blk unwrapTwo(&buf, first, second);
        },
        .block, .block_semicolon => blk: {
          const rng = self.tree.nodeData(rhs).extra_range;
          break :blk self.tree.extraDataSlice(rng, Node.Index);
        },
        else => unreachable,
      };
      const has_stmts = stmts.len > 0;
      const b = self.tBlock(lbrace, rbrace, tmp, stmts, .{.ignore_rbrace = has_stmts, .group = false});
      if (has_stmts) {
        sb.indent(b.seq.docs).hardline().append(self.tRbrace(rbrace, true));
      } else {
        sb.indent(b.seq.docs)._();
      }
    }
    return self.db.group(sb.finish());
  }

  fn tCall(
    self: *Self,
    sb: *SeqBuilder,
    id: u32,
    lbrack: Ast.TokenIndex,
    rbrack: Ast.TokenIndex,
    params: []const Node.Index,
    fn_tkn: ?Ast.TokenIndex,
    attr_doc: ?*Doc,
    can_add_trailing_comma: bool,
  ) void {
    assert(self.tree.tokenTag(lbrack) == .l_paren);
    assert(self.tree.tokenTag(rbrack) == .r_paren);
    const lb = self._ttkn(lbrack, .{.add_only_trailing_comment = true});
    const top_comments = self.getNextLineComments(lbrack, params.len != 0 or attr_doc != null);
    const lb_has_trailing = self.tknHasTC(lbrack);
    sb.append(lb);
    const result =
      if (attr_doc) |doc| blk: {
        var tmp = self.db.seqb();
        if (top_comments) |c_doc| {
          tmp.declline().append(c_doc);
        } else if (lb_has_trailing) {
          tmp.declline()._();
        } else {
          tmp.softline()._();
        }
        tmp.append(doc);
        const has_comment = top_comments != null or lb_has_trailing;
        break :blk CallResult{.sb = tmp, .has_comment = has_comment, .softline = true};
      }
      else if (fn_tkn) |ftkn| self.tFnParams(id, ftkn, params, lb_has_trailing, top_comments)
      else self.tCallArgs(id, params, lb_has_trailing, top_comments, can_add_trailing_comma);
    var sb_args = result.sb;
    const should_softline = result.softline;
    const args_has_comment = result.has_comment;
    if (should_softline or args_has_comment) {
      sb.indent(sb_args.finish())._();
    } else {
      sb.extend(sb_args.finish());
    }
    // NOTE: `args_has_comment` subsumes `lb_has_trailing`
    // TODO: should rbrack's comment trailing line be configurable?
    const r_doc = self.ttkn(rbrack);
    if (args_has_comment) {
      // force a break since left bracket is already broken,
      sb.declline().append(r_doc);
    } else {
      sb.softlineIf(should_softline).append(r_doc);
    }
  }

  fn tAttribute(self: *Self, n: Node.Index, name: ?[]const u8) *Doc {
    var sb = self.db.seqb();
    const tkn = self.tree.firstToken(n) - 2;
    if (name) |id| {
      assert(std.mem.eql(u8, id, self._token(tkn)));
      sb.append(self.ttknWithSTL(tkn));
    }
    const lbrack = tkn + 1;
    const rbrack = self.tree.lastToken(n) + 1;
    const id = d.genGroupID();
    self.tCall(sb, id, lbrack, rbrack, &.{n}, null, null, false);
    return self.db.groupi(id, sb.finish());
  }

  const CallResult = struct{sb: *SeqBuilder, has_comment: bool, softline: bool};

  fn tCallArgs(
    self: *Self,
    id: u32,
    params: []const Node.Index,
    lb_has_trailing: bool,
    top_comments: ?*Doc,
    can_add_trailing_comma: bool,
  ) CallResult {
    var sb_args = self.db.seqb();
    const should_softline = params.len > 0;
    const comments = self._comments;
    var softline_pos: ?usize = null;
    var arg_has_comment = top_comments != null or params.len > 0 and lb_has_trailing;
    if (top_comments) |doc| {
      sb_args.declline().append(doc);
    } else if (lb_has_trailing) {
      sb_args.declline()._();
    } else {
      softline_pos = sb_args.len();
      sb_args.softline()._();
    }
    if (should_softline) {
      self._in_call_args += 1;
      for (params, 0..) |_n, i| {
        if (i > 0) {
          const tkn = self.tree.firstToken(_n) - 1;
          assert(self.tree.tokenTag(tkn) == .comma);
          sb_args.decllineIf(self.tknHasTC(tkn - 1))._();
          sb_args.append(self.ttkn(tkn));
          if (arg_has_comment) {
            sb_args.declline()._();
          } else if (self.tknHasTC(tkn)) {
            sb_args.declline()._();
            arg_has_comment = true;
          } else {
            sb_args.normline()._();
          }
        }
        sb_args.append(self.t(_n));
        arg_has_comment = arg_has_comment or self.commentsChanged(comments);
      }
      self._in_call_args -= 1;
      const tkn = self.tree.lastToken(params[params.len - 1]) + 1;
      if (self.tree.tokenTag(tkn) == .comma) {
        if (arg_has_comment or self.tknHasTC(tkn)) {
          sb_args.decllineIf(self.tknHasTC(tkn - 1)).append(self.ttkn(tkn));
          arg_has_comment = true;
        } else if (can_add_trailing_comma) {
          sb_args.ifsplit(id, self.db.text(","), self.db.empty())._();
        } 
      } else if (can_add_trailing_comma) {
        if (!arg_has_comment) {
          // add trailing comma for complex args or if we break
          sb_args.ifsplit(id, self.db.text(","), self.db.softline())._();
        } else if (self.tknHasNoTC(tkn - 1)) {
          sb_args.text(",")._();
        }
      }
    }
    arg_has_comment = arg_has_comment or self.commentsChanged(comments);
    if (arg_has_comment) {
      updateLinesToDecllines(sb_args);
    }
    if (!should_softline and !arg_has_comment) {
      if (softline_pos) |pos| {
        sb_args.docs.items[pos] = self.db.empty();
      }
    }
    return .{.sb = sb_args, .has_comment = arg_has_comment, .softline = should_softline};
  }

  // NOTE: Keep this in sync with tCallArgs()
  fn tFnParams(
    self: *Self,
    id: u32,
    fn_tkn: Ast.TokenIndex,
    params: []const Node.Index,
    lb_has_trailing: bool,
    top_comments: ?*Doc,
  ) CallResult {
    var tkn = fn_tkn + 1;
    if (self.tree.tokenTag(tkn) == .identifier) tkn += 1;
    assert(self.tree.tokenTag(tkn) == .l_paren);
    tkn += 1;
    var sb_prms = self.db.seqb();
    const comments = self._comments;
    var softline_pos: ?usize = null;
    // NOTE: params like `...` and `anytype` are not stored in params, however,
    //   we'd have encountered `anytype` or `...` before hitting a comma (,) 
    var prm_has_comment = top_comments != null or params.len > 0 and lb_has_trailing;
    if (top_comments) |doc| {
      sb_prms.declline().append(doc);
    } else if (lb_has_trailing) {
      sb_prms.declline()._();
    } else {
      softline_pos = sb_prms.len();
      sb_prms.softline()._();
    }
    self._in_call_args += 1;
    var tmp = self.db.seqb();
    var i = @as(usize, 0);
    var prms = @as(usize, 0);
    while (true) : (tkn += 1) {
      switch (self.tree.tokenTag(tkn)) {
        .doc_comment => {
          tmp.appends(self.ttkn(tkn)).declline()._();
          prm_has_comment = true;
        },
        .keyword_noalias, .keyword_comptime => {
          tmp.appends(self.ttknWithSTL(tkn)).spaceIf(self.tknHasNoTC(tkn))._();
        },
        .keyword_anytype => {
          tmp.append(self.ttkn(tkn));
          if (!prm_has_comment) {
            prm_has_comment = self.tknHasTC(tkn);
          }
        },
        .identifier => {
          const prev = self.tree.tokenTag(tkn - 1);
          if (
            prev == .l_paren or
            prev == .comma or
            prev == .keyword_comptime or
            prev == .keyword_noalias
          ) {
            tmp.append(self.ttknWithSTL(tkn));
          } else if (i < params.len) {
            const p = params[i];
            tmp.append(self.t(p));
            tkn = self.tree.lastToken(p);
            i += 1;
          }
        },
        .colon => {
          tmp.appends(self.ttknWithSTL(tkn)).spaceIf(self.tknHasNoTC(tkn))._();
          prms += 1;
        },
        .comma => {
          if (self.tree.tokenTag(tkn + 1) != .r_paren) {
            tmp.decllineIf(self.tknHasTC(tkn - 1))._();
            tmp.append(self.ttkn(tkn));
            sb_prms.group(tmp.finish())._();
            if (prm_has_comment) {
              sb_prms.declline()._();
            } else if (self.tknHasTC(tkn)) {
              sb_prms.declline()._();
              prm_has_comment = true;
            } else {
              sb_prms.normline()._();
            }
          } else {
            if (prm_has_comment or self.tknHasTC(tkn)) {
              tmp.decllineIf(self.tknHasTC(tkn - 1)).append(self.ttkn(tkn));
              prm_has_comment = true;
            }
            sb_prms.group(tmp.finish())._();
          }
          tmp.reset();
        },
        .ellipsis3 => {
          tmp.append(self.ttkn(tkn));
          prm_has_comment = prm_has_comment or self.tknHasTC(tkn);
          prms += 1;
        },
        .r_paren => {
          if (tmp.isNotEmpty()) {
            sb_prms.group(tmp.finish())._();
          } else if (!tmp.done) {
            _ = tmp.finish();
          }
          break;
        },
        else => {
          if (i < params.len) {
            const p = params[i];
            tmp.append(self.t(p));
            tkn = self.tree.lastToken(p);
            i += 1;
          }
        }
      }
    }
    self._in_call_args -= 1;
    const should_softline = prms != 0;
    assert(self.tree.tokenTag(tkn) != .comma);
    if (!prm_has_comment and should_softline) {
      // add trailing comma for complex args or if we break
      sb_prms.ifsplit(id, self.db.text(","), self.db.softline())._();
    }
    prm_has_comment = prm_has_comment or self.commentsChanged(comments);
    if (prm_has_comment) {
      updateLinesToDecllines(sb_prms);
    }
    // if no comments and we're certain we shouldn't softline, erase any saved softline
    if (!should_softline and !prm_has_comment) {
      if (softline_pos) |pos| {
        sb_prms.docs.items[pos] = self.db.empty();
      }
    }
    return .{.sb = sb_prms, .has_comment = prm_has_comment, .softline = should_softline};
  }

  fn tVarDeclProto(self: *Self, vd: Ast.full.VarDecl) *SeqBuilder {
    var sb = self.db.seqb();
    var tmp = self.db.seqb();
    if (vd.visib_token) |idx| {
      sb.appends(self.ttknWithSTL(idx)).spaceIf(self.tknHasNoTC(idx))._();
    }
    if (vd.extern_export_token) |idx| {
      sb.appends(self.ttknWithSTL(idx)).spaceIf(self.tknHasNoTC(idx))._();
      if (vd.lib_name) |_idx| {
        sb.appends(self.ttknWithSTL(_idx)).spaceIf(self.tknHasNoTC(_idx))._();
      }
    }
    if (vd.threadlocal_token) |idx| {
      sb.appends(self.ttknWithSTL(idx)).spaceIf(self.tknHasNoTC(idx))._();
    }
    if (vd.comptime_token) |idx| {
      sb.appends(self.ttknWithSTL(idx)).spaceIf(self.tknHasNoTC(idx))._();
    }
    const comments = self._comments;
    sb.append(self.ttknWithSTL(vd.ast.mut_token));
    sb.spaceIf(self.tknHasNoTC(vd.ast.mut_token))._();
    sb.append(self.ttkn(vd.ast.mut_token + 1));
    if (vd.ast.type_node.unwrap()) |_n| {
      const tkn = self.tree.firstToken(_n) - 1;
      assert(self.tree.tokenTag(tkn) == .colon);
      sb.appends(self.ttknWithSTL(tkn)).spaceIf(self.tknHasNoTC(tkn))._();
      sb.append(self.t(_n));
    }
    if (vd.ast.align_node.unwrap()) |_n| {
      tmp.normline().append(self.tAttribute(_n, "align"));
    }
    if (vd.ast.addrspace_node.unwrap()) |_n| {
      tmp.normline().append(self.tAttribute(_n, "addrspace"));
    }
    if (vd.ast.section_node.unwrap()) |_n| {
      tmp.normline().append(self.tAttribute(_n, "linksection"));
    }
    if (self.commentsChanged(comments)) {
      updateLinesToDecllines(tmp);
    }
    sb.append(self.db.indent(tmp.finish()));
    return sb;
  }

  fn tVarDecl(self: *Self, vd: Ast.full.VarDecl) *Doc {
    var sb = self.tVarDeclProto(vd);
    if (vd.ast.init_node.unwrap()) |_n| {
      const tkn = self.tree.firstToken(_n) - 1;
      assert(self.tree.tokenTag(tkn) == .equal);
      sb.decllineOrSpace(self.tknHasTC(tkn - 1));
      sb.append(self.ttknWithSTL(tkn));
      sb.spaceIf(self.tknHasNoTC(tkn))._();
      sb.append(self.t(_n));
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
  ) *Doc {
    // KEYWORD_fn IDENTIFIER? LPAREN ParamDeclList RPAREN ByteAlign? AddrSpace? LinkSection? CallConv? EXCLAMATIONMARK? TypeExpr
    // `fn (a: b, c: d) addrspace(e) linksection(f) callconv(g) return_type`.
    var sb = self.db.seqb();
    var curr = if (fn_tkn > 0) fn_tkn - 1 else fn_tkn;
    loop: while (true) : (curr -= 1) {
      switch (self.tree.tokenTag(curr)) {
        .keyword_inline, .keyword_export, .keyword_pub, .keyword_noinline,
        .keyword_extern => {
          sb.spaceIf(self.tknHasNoTC(curr))._();
          sb.append(self.ttknWithSTL(curr));
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
    assert(self.tree.tokenTag(fn_tkn) == .keyword_fn);
    sb.appends(self.ttknWithSTL(fn_tkn)).spaceIf(self.tknHasNoTC(fn_tkn))._();
    curr = fn_tkn + 1;
    if (self.tree.tokenTag(curr) == .identifier) {
      sb.append(self.ttknWithSTL(curr));
    }
    const id = d.genGroupID();
    var lbrack = curr;
    while (self.tree.tokenTag(lbrack) != .l_paren) lbrack += 1;
    const rbrack = self.getRBrackTkn(lbrack);
    self.tCall(sb, id, lbrack, rbrack, params, fn_tkn, null, true);
    const comments = self._comments;
    var tmp = self.db.seqb();
    if (byte_align) |_n| {
      tmp.normline().append(self.tAttribute(_n, "align"));
    }
    if (addr_space) |_n| {
      tmp.normline().append(self.tAttribute(_n, "addrspace"));
    }
    if (call_conv) |_n| {
      tmp.normline().append(self.tAttribute(_n, "callconv"));
    }
    if (link_section) |_n| {
      tmp.normline().append(self.tAttribute(_n, "linksection"));
    }
    if (ret_ty) |_n| {
      const rbrack_has_tc = self.tknHasTC(rbrack);
      if (tmp.isNotEmpty() or params.len > 0) {
        tmp.decllineOrNormline(rbrack_has_tc);
        if (self.commentsChanged(comments)) {
          updateLinesToDecllines(tmp);
        }
        sb.group(tmp.finish())._();
        const tkn = self.tree.nodeMainToken(_n) - 1;
        if (self.tree.tokenTag(tkn) == .bang) {
          sb.append(self.ttknWithSTL(tkn));
        }
        sb.append(self.t(_n));
      } else {
        sb.decllineOrSpace(rbrack_has_tc);
        _ = tmp.finish();
        const tkn = self.tree.nodeMainToken(_n) - 1;
        if (self.tree.tokenTag(tkn) == .bang) {
          sb.append(self.ttknWithSTL(tkn));
        }
        sb.append(self.t(_n));
      }
    } else {
      updateLinesToDecllines(tmp);
      sb.group(tmp.finish())._();
    }
    return self.db.groupi(id, sb.finish());
  }

  fn tBlockMembers(self: *Self, sb: *SeqBuilder, members: []const Node.Index, add_last_line: bool) void {
    for (members, 1..) |_n, i| {
      self._tDocComment(sb, self.tree.firstToken(_n));
      sb.append(self.t(_n));
      var term_tkn: Ast.TokenIndex = undefined;
      if (self.hasTerminator(_n, &.{.semicolon, .comma})) |tkn| {
        sb.decllineIf(self.tknHasTC(tkn - 1))._();
        term_tkn = tkn;
        if (i != members.len or add_last_line) {
          sb.append(self.ttknWithTL(tkn));
        } else {
          sb.append(self.ttkn(tkn));
        }
      } else {
        term_tkn = self.tree.lastToken(_n);
      }
      if (i == members.len and !add_last_line) break;
      const len = sb.len();
      self.tline(sb, term_tkn);
      if (len == sb.len() and self.tknHasNoTC(term_tkn)) {
        sb.declline()._();
      }
    }
  }

  fn tRbrace(self: *Self, rbrace: Ast.TokenIndex, add_rbrace_trailing_line: bool) *Doc {
    // when `}` has a comment, we add a trailing line to the comment, only if
    // the next token is a keyword (i.e. the start of a new decl).
    if (add_rbrace_trailing_line) {
      const next_tag = self.tree.tokenTag(rbrace + 1);
      const next_is_kwd = next_tag != .keyword_else and (next_tag == .eof or std.mem.startsWith(u8, @tagName(next_tag), "keyword"));
      if (next_is_kwd) {
        return self.ttknWithTL(rbrace);
      }
    }
    return self.ttkn(rbrace);
  }

  const BlockFmtConfig = struct {
    /// group the generated doc
    group: bool = false,
    /// combine '{' and '}' into '{}' if members are empty
    combine_braces_if_empty: bool = true,
    /// add a sep/decl line after '{'
    add_top_separator_line: bool = true,
    /// add trailing line after '}'
    add_rbrace_trailing_line: bool = true,
    /// only translate the lbrace '{' and its associated comments 
    lbrace_only: bool = false,
    /// translate the block but do not add '}' and its associated comments 
    ignore_rbrace: bool = false,
  };

  /// translate a block of statements
  /// NOTE: tBlock consumes the builder `sb`.
  fn tBlock(
    self: *Self,
    lbrace: Ast.TokenIndex,
    rbrace: Ast.TokenIndex,
    sb: *SeqBuilder,
    stmts: []const Node.Index,
    cfg: BlockFmtConfig,
  ) *Doc {
    assert(self.tree.tokenTag(lbrace) == .l_brace);
    assert(self.tree.tokenTag(rbrace) == .r_brace);
    const lb = self._ttkn(lbrace, .{.add_only_trailing_comment = true, .add_trailing_line_for_comment = false});
    sb.append(lb);
    const top_comments = self.getNextLineComments(lbrace, stmts.len != 0);
    var tmp = self.db.seqb();
    if (top_comments) |doc| {
      tmp.decllineIf(cfg.add_top_separator_line).append(doc);
    } else if (stmts.len != 0) {
      tmp.decllineIf(cfg.add_top_separator_line)._();
    }
    if (cfg.lbrace_only) {
      sb.indent(tmp.finish())._();
      return lb;
    }
    self.tBlockMembers(tmp, stmts, false);
    const rb = self.tRbrace(rbrace, cfg.add_rbrace_trailing_line);
    if (!cfg.ignore_rbrace and cfg.combine_braces_if_empty and self.decouple_empty_block_braces == 0 and tmp.isEmpty() and self.tknHasNoTC(lbrace)) {
      _ = tmp.finish();
      return sb.appends(rb).finishSeq();
    }
    if (!cfg.ignore_rbrace) {
      sb.indent(tmp.finish()).hardline().append(rb);
    } else {
      sb.extends(tmp.finish())._();
    }
    return if (cfg.group) self.db.group(sb.finish()) else sb.finishSeq();
  }

  fn tContainerDeclInline(self: *Self, id: u32, sb: *SeqBuilder, members: []const Node.Index) void {
    for (members, 0..) |n, i| {
      if (i > 0) {
        sb.text(",").normline()._();
      }
      sb.append(self.t(n));
    }
    sb.ifsplit(id, self.db.text(","), self.db.empty())._();
  }

  fn tContainerDecl(
    self: *Self,
    mlayout: ?Ast.TokenIndex,
    container: Ast.TokenIndex,
    enum_token: ?Ast.TokenIndex,
    container_arg: ?Node.Index,
    members: []const Node.Index,
  ) *Doc {
    // `struct {}`, `union {}`, `opaque {}`, `enum {}`.
    const comments = self._comments;
    var sb = self.db.seqb();
    if (mlayout) |tkn| {
      sb.appends(self.ttknWithSTL(tkn)).spaceIf(self.tknHasNoTC(tkn))._();
    } else {
      const layout = container - 1;
      switch (self.tree.tokenTag(layout)) {
        .keyword_packed, .keyword_extern => {
          sb.appends(self.ttknWithSTL(layout)).spaceIf(self.tknHasNoTC(layout))._();
        },
        else => {}
      }
    }
    sb.append(self.ttkn(container));
    var lbrace = container;
    if (enum_token) |tkn| {
      sb.decllineIf(self.tknHasTC(container))._();
      const lbrack = tkn - 1;
      assert(self.tree.tokenTag(lbrack) == .l_paren);
      if (container_arg) |arg| {
        const rbrack = self.tree.lastToken(arg) + 1;
        assert(self.tree.tokenTag(rbrack) == .r_paren);
        const attr_doc = self.tAttribute(arg, self._token(tkn));
        self.tCall(sb, d.genGroupID(), lbrack, rbrack, &.{}, null, attr_doc, false);
        sb = self.db.seqb().group(sb.finish());
        lbrace = rbrack + 1;
      } else {
        sb.append(self.ttknWithSTL(lbrack));
        sb.append(self.ttknWithSTL(tkn));
        const rbrack = tkn + 1;
        assert(self.tree.tokenTag(rbrack) == .r_paren);
        sb.append(self.ttkn(rbrack));
        lbrace = rbrack + 1;
      }
    } else if (container_arg) |arg| {
      sb.decllineIf(self.tknHasTC(container))._();
      sb.append(self.tAttribute(arg, null));
      lbrace = self.tree.lastToken(arg) + 2;
    } else {
      lbrace += 1;
    }
    while (self.tree.tokenTag(lbrace) != .l_brace) lbrace += 1;
    var rbrace: Ast.TokenIndex = undefined;
    if (members.len != 0) {
      rbrace = self.tree.lastToken(members[members.len - 1]); 
      while (self.tree.tokenTag(rbrace) != .r_brace) rbrace += 1;
    } else {
      rbrace = lbrace + 1;
    }
    assert(self.tree.tokenTag(lbrace) == .l_brace);
    assert(self.tree.tokenTag(rbrace) == .r_brace);
    sb.spaceIf(self.tknHasNoTC(lbrace - 1))._();
    const id = d.genGroupID();
    const lb = self._ttkn(lbrace, .{.add_only_trailing_comment = true});
    sb.decllineIf(self.tknHasTC(lbrace - 1))._();
    sb.append(lb);
    const top_comments = self.getNextLineComments(lbrace, members.len != 0);
    var tmp = self.db.seqb();
    if (top_comments) |doc| {
      tmp.declline().append(doc);
    } else if (self.tknHasTC(lbrace)) {
      tmp.declline()._();
    } else {
      tmp.normline()._();
    }
    if (members.len == 0) {
      _ = tmp.finish(); // flush unneeded normline
      sb.decllineIf(self.tknHasTC(lbrace)).append(self.ttkn(rbrace));
      return self.db.groupi(id, sb.finish());
    } else if (comments == self._comments and self.canFormatMembersInline(lbrace, rbrace)) {
      self.tContainerDeclInline(id, tmp, members);
      sb.indent(tmp.finish()).normline().append(self.ttkn(rbrace));
      return self.db.groupi(id, sb.finish());
    }
    var term_tkn: Ast.TokenIndex = lbrace;
    for (members, 1..) |_n, i| {
      self._tDocComment(tmp, self.tree.firstToken(_n));
      tmp.append(self.t(_n));
      if (self.hasTerminator(_n, &.{.semicolon})) |tkn| {
        sb.decllineIf(self.tknHasTC(tkn - 1))._();
        if (i != members.len) {
          tmp.append(self.ttknWithTL(tkn));
          term_tkn = tkn;
        } else {
          tmp.append(self.ttkn(tkn));
          break;
        }
      } else {
        const tkn = self.tree.lastToken(_n) + 1;
        const tt = self.tree.tokenTag(tkn);
        if (tt == .comma) {
          tmp.decllineIf(self.tknHasTC(tkn - 1))._();
          if (i != members.len) {
            tmp.append(self._ttkn(tkn, .{.add_trailing_line_for_comment = true, .add_only_lines_if_no_comment = true}));
            if (self.tknHasNoTC(tkn)) tmp.ifsplit(id, self.db.empty(), self.db.space())._();
          } else {
            tmp.append(self.ttkn(tkn));
          }
          term_tkn = tkn;
        } else {
          term_tkn = tkn - 1;
        }
      }
      if (i != members.len and self.tknHasNoTC(term_tkn)) {
        const len = tmp.len();
        self.tline(tmp, term_tkn);
        if (len == tmp.len()) {
          tmp.declline()._();
        }
      }
    }
    const tag = self.tree.tokenTag(term_tkn);
    const add_trailing_comma = tag != .comma and tag != .semicolon and tag != .r_brace and self.tknHasNoTC(term_tkn);
    if (add_trailing_comma) tmp.text(",")._();
    self.updateLinesToDecllines2(tmp);
    sb.indent(tmp.finish()).declline().append(self.ttkn(rbrace));
    return self.db.groupi(id, sb.finish());
  }

  fn tErrorSetDeclInline(self: *Self, id: u32, sb: *SeqBuilder, members: []const Ast.TokenIndex) void {
    for (members, 0..) |n, i| {
      if (i > 0) {
        sb.text(",").normline()._();
      }
      sb.append(self.ttkn(n));
    }
    sb.ifsplit(id, self.db.text(","), self.db.empty())._();
  }

  fn tErrorSetDecl(
    self: *Self,
    container: Ast.TokenIndex,
    members: []const Ast.TokenIndex,
    lbrace: Ast.TokenIndex,
    rbrace: Ast.TokenIndex,
  ) *Doc {
    // `error {}`
    const comments = self._comments;
    var sb = self.db.seqb();
    sb.append(self.ttkn(container));
    assert(self.tree.tokenTag(lbrace) == .l_brace);
    assert(self.tree.tokenTag(rbrace) == .r_brace);
    sb.spaceIf(self.tknHasNoTC(lbrace - 1))._();
    const id = d.genGroupID();
    const lb = self._ttkn(lbrace, .{.add_only_trailing_comment = true});
    sb.decllineIf(self.tknHasTC(lbrace - 1))._();
    sb.append(lb);
    const top_comments = self.getNextLineComments(lbrace, members.len != 0);
    var tmp = self.db.seqb();
    if (top_comments) |doc| {
      tmp.declline().append(doc);
    } else if (self.tknHasTC(lbrace)) {
      tmp.declline()._();
    } else {
      tmp.normline()._();
    }
    if (members.len == 0) {
      _ = tmp.finish(); // flush unneeded normline
      sb.decllineIf(self.tknHasTC(lbrace)).append(self.ttkn(rbrace));
      return self.db.groupi(id, sb.finish());
    } else if (comments == self._comments and self.canFormatMembersInline(lbrace, rbrace)) {
      self.tErrorSetDeclInline(id, tmp, members);
      sb.indent(tmp.finish()).normline().append(self.ttkn(rbrace));
      return self.db.groupi(id, sb.finish());
    }
    var term_tkn: Ast.TokenIndex = lbrace;
    for (members, 1..) |_n, i| {
      tmp.append(self.ttkn(_n));
      const tkn = _n + 1;
      const tt = self.tree.tokenTag(tkn);
      if (tt == .comma) {
        tmp.decllineIf(self.tknHasTC(tkn - 1))._();
        if (i != members.len) {
          tmp.append(self._ttkn(tkn, .{.add_trailing_line_for_comment = true, .add_only_lines_if_no_comment = true}));
          if (self.tknHasNoTC(tkn)) tmp.ifsplit(id, self.db.empty(), self.db.space())._();
        } else {
          tmp.append(self.ttkn(tkn));
        }
        term_tkn = tkn;
      } else {
        term_tkn = tkn - 1;
      }
      if (i != members.len and self.tknHasNoTC(term_tkn)) {
        const len = tmp.len();
        self.tline(tmp, term_tkn);
        if (len == tmp.len()) {
          tmp.declline()._();
        }
      }
    }
    const tag = self.tree.tokenTag(term_tkn);
    const add_trailing_comma = tag != .comma and tag != .semicolon and tag != .r_brace and self.tknHasNoTC(term_tkn);
    if (add_trailing_comma) tmp.text(",")._();
    self.updateLinesToDecllines2(tmp);
    sb.indent(tmp.finish()).declline().append(self.ttkn(rbrace));
    return self.db.groupi(id, sb.finish());
  }

  fn tOpenContainerDecl(
    self: *Self,
    members: []const Node.Index,
  ) *Doc {
    // `struct {}`, `union {}`, `opaque {}`, `enum {}`.
    var sb = self.db.seqb();
    self._tcomment(sb, 0, self.tree.tokenStart(0), .{.add_trailing_line_for_comment = true});
    self.tBlockMembers(sb, members, true);
    // if we're still in no-fmt mode, write the source from where it was last disabled
    if (self.fmt_disabled_pos) |pos| {
      assert(self.db.disable_writes);
      self.db.disable_writes = false;
      sb.text(self.tree.source[pos..])._();
      self.fmt_disabled_pos = null;
      if (self.tree.source[self.tree.source.len - 1] != '\n') {
        sb.declline()._();
      }
    }
    return sb.finishSeq();
  }

  fn tContainerField(self: *Self, cf: Ast.full.ContainerField) *Doc {
    var sb = self.db.seqb();
    if (cf.comptime_token) |idx| {
      sb.appends(self.ttknWithSTL(idx)).spaceIf(self.tknHasNoTC(idx))._();
    }
    if (!cf.ast.tuple_like) {
      sb.append(self.ttkn(cf.ast.main_token));
      if (cf.ast.type_expr.unwrap()) |_n| {
        const tkn = self.tree.firstToken(_n) - 1;
        assert(self.tree.tokenTag(tkn) == .colon);
        sb.decllineIf(self.tknHasTC(tkn - 1))._();
        sb.appends(self.ttknWithSTL(tkn)).spaceIf(self.tknHasNoTC(tkn)).append(self.t(_n));
      }
    } else if (cf.ast.type_expr.unwrap()) |_n| {
      sb.append(self.t(_n));
    }

    if (cf.ast.align_expr.unwrap()) |_n| {
      const tkn = self.tree.firstToken(_n) - 1;
      sb.spaceIf(self.tknHasNoTC(tkn)).append(self.tAttribute(_n, "align"));
    }
    if (cf.ast.value_expr.unwrap()) |_n| {
      const tkn = self.tree.firstToken(_n) - 1;
      assert(self.tree.tokenTag(tkn) == .equal);
      sb.decllineIf(self.tknHasTC(tkn - 1))._();
      sb.spaceIf(self.tknHasNoTC(tkn - 1)).append(self.ttknWithSTL(tkn));
      sb.spaceIf(self.tknHasNoTC(tkn)).append(self.t(_n));
    }
    return self.db.group(sb.finish());
  }

  fn tWhile(self: *Self, wl: Ast.full.While) *Doc {
    var sb = self.db.seqb();
    var flat_b = self.db.seqb();
    if (wl.label_token) |tkn| {
      flat_b.appends(self.ttknWithSTL(tkn)).append(self.ttknWithSTL(tkn + 1));
      flat_b.spaceIf(self.tknHasNoTC(tkn + 1))._();
    }
    if (wl.inline_token) |tkn| {
      flat_b.appends(self.ttknWithSTL(tkn)).spaceIf(self.tknHasNoTC(tkn))._();
    }
    var tmp = self.db.seqb();
    tmp.append(self.ttknWithSTL(wl.ast.while_token));
    tmp.spaceIf(self.tknHasNoTC(wl.ast.while_token))._();
    const id = d.genGroupID();
    const lbrack = wl.ast.while_token + 1;
    const rbrack = self.tree.lastToken(wl.ast.cond_expr) + 1;
    self.tCall(tmp, id, lbrack, rbrack, &.{wl.ast.cond_expr}, null, null, false);
    flat_b.group(tmp.finish())._();
    var last_tkn = rbrack;
    var wl_top_has_tc = self.tknHasTC(rbrack);
    if (wl.payload_token) |tkn| {
      flat_b.decllineOrSpace(self.tknHasTC(rbrack));
      flat_b.append(self.ttknWithSTL(tkn - 1)); // |
      flat_b.append(self.ttknWithSTL(tkn)); // IDENT or *
      if (self.tree.tokenTag(tkn) == .asterisk) {
        flat_b.append(self.ttknWithSTL(tkn + 1)); // IDENT
        last_tkn = tkn + 2;
        flat_b.append(self.ttkn(last_tkn)); // |
      } else {
        last_tkn = tkn + 1;
        flat_b.append(self.ttkn(last_tkn)); // |
      }
      wl_top_has_tc = wl_top_has_tc or self.tknHasTC(last_tkn);
    }
    const id1 = d.genGroupID();
    if (wl.ast.cont_expr.unwrap()) |cnt| {
      tmp = self.db.seqb();
      const lbrack_ = self.tree.firstToken(cnt) - 1;
      const rbrack_ = self.tree.lastToken(cnt) + 1; 
      tmp.append(self.ttknWithSTL(lbrack_ - 1)); // ':'
      tmp.spaceIf(self.tknHasNoTC(lbrack_ - 1))._();
      self.tCall(tmp, id, lbrack_, rbrack_, &.{cnt}, null, null, false);
      const cont_d = tmp.finish();
      var split = flat_b.copy();
      if (self.tknHasNoTC(lbrack_ - 2)) { // before ':'
        flat_b.append(self.db.group(self.db.seqb().space().extends(cont_d).finish()));
        split.softline().group(cont_d)._();
      } else {
        flat_b.declline().group(cont_d)._();
        split.declline().group(cont_d)._();
      }
      const db = self.db.seqb().ifsplit(id1, split.finishSeq(), flat_b.finishSeq());
      sb.groupi(id1, db.finish())._();
      last_tkn = rbrack_;
      wl_top_has_tc = wl_top_has_tc or self.tknHasTC(last_tkn);
    } else {
      sb.groupi(id1, flat_b.finish())._();
    }
    var then_is_block = false;
    if (wl.ast.else_expr.unwrap()) |els| {
      const is_empty_block = self.isEmptyBlock(wl.ast.then_expr);
      if (is_empty_block) { self.decouple_empty_block_braces += 1; }
      defer if (is_empty_block) { self.decouple_empty_block_braces -= 1; };
      const then_expr = self.t(wl.ast.then_expr);
      const m_tkn = self.tree.nodeMainToken(wl.ast.then_expr);
      const last_has_tc = self.tknHasTC(last_tkn);
      const before_if_tkn_is_else_tkn = self.tree.tokenTag(wl.ast.while_token - 1) == .keyword_else;
      const after_else_tkn_is_if_tkn = self.tree.tokenTag(wl.else_token + 1) == .keyword_if;
      // we break irrespective of comments when we're in an else-if expression
      const in_elif_expr = before_if_tkn_is_else_tkn or after_else_tkn_is_if_tkn;
      if (self.isBlock(m_tkn)) {
        then_is_block = true;
        sb.decllineOrSpace(last_has_tc);
        sb.append(then_expr);
      } else {
        var flat = self.db.seqb();
        var split = self.db.seqb();
        var flat_doc: *Doc = undefined;
        // special handling for block assignments:
        var is_block_assignment = false;
        if (self.tree.nodeTag(wl.ast.then_expr) == .assign) {
          _, const rhs = self.tree.nodeData(wl.ast.then_expr).node_and_node;
          is_block_assignment = (self.isBlock(self.tree.nodeMainToken(rhs)));
        }
        if (wl_top_has_tc or last_has_tc or in_elif_expr or is_block_assignment) {
          flat.declline().append(then_expr);
          split.declline().append(then_expr);
          flat_doc = self.db.indent(flat.finish());
        } else {
          flat.space().append(then_expr);
          split.softline().append(then_expr);
          flat_doc = flat.finishSeq();
        }
        sb.ifsplit(id, self.db.indent(split.finish()), flat_doc)._();
      }
      last_tkn = self.tree.lastToken(wl.ast.then_expr);
      const else_tkn = last_tkn + 1;
      assert(else_tkn == wl.else_token);
      const is_empty_block2 = self.isEmptyBlock(els);
      if (is_empty_block2) { self.decouple_empty_block_braces += 1; }
      defer if (is_empty_block2) { self.decouple_empty_block_braces -= 1; };
      const else_expr = self.t(els);
      const tkn = self.tree.nodeMainToken(els);
      if (then_is_block or self.isBlock(tkn) or in_elif_expr) {
        const else_doc = self.ttkn(else_tkn);
        const else_tkn_has_no_tc = self.tknHasNoTC(else_tkn);
        last_tkn = else_tkn;
        if (then_is_block) {
          sb.spaceOrDeclline(self.tknHasNoTC(else_tkn - 1));
          sb.append(else_doc);
          if (wl.error_token) |err_tkn| {
            sb.spaceOrDeclline(else_tkn_has_no_tc);
            sb.append(self.ttknWithSTL(err_tkn - 1)); // |
            sb.append(self.ttknWithSTL(err_tkn)); // IDENT
            last_tkn = err_tkn + 1; // |
            sb.append(self.ttkn(last_tkn));
            sb.spaceOrDeclline(self.tknHasNoTC(last_tkn));
          } else {
            assert(last_tkn == else_tkn);
            sb.spaceOrDeclline(else_tkn_has_no_tc);
          }
          sb.append(else_expr);
        } else {
          const in_elif_expr_end = before_if_tkn_is_else_tkn and !after_else_tkn_is_if_tkn;
          var els_sb = self.db.seqb();
          els_sb.declline().append(else_doc);
          if (in_elif_expr_end) {
            els_sb.spaceIf(wl.error_token != null and else_tkn_has_no_tc)._();
          } else {
            els_sb.spaceOrDeclline(else_tkn_has_no_tc);
          }
          if (wl.error_token) |err_tkn| {
            els_sb.append(self.ttknWithSTL(err_tkn - 1)); // |
            els_sb.append(self.ttknWithSTL(err_tkn)); // IDENT
            last_tkn = err_tkn + 1; // |
            els_sb.append(self.ttkn(last_tkn));
            if (!in_elif_expr_end) {
              els_sb.spaceOrDeclline(self.tknHasNoTC(last_tkn));
            } 
          }
          if (in_elif_expr_end) {
            els_sb.indent(self.db.seqb().declline().appends(else_expr).finish())._();
          } else {
            els_sb.append(else_expr);
          }
          sb.group(els_sb.finish())._();
        }
      } else {
        var flat = self.db.seqb();
        var split = self.db.seqb();
        var rest = self.db.seqb();
        const else_doc = self.ttkn(else_tkn);
        const else_tkn_has_tc = self.tknHasTC(else_tkn);
        const else_tkn_has_no_tc = !else_tkn_has_tc;
        var indent_flat = false;
        if (wl_top_has_tc or self.tknHasTC(else_tkn - 1)) {
          flat.declline().append(else_doc);
          split.declline().append(else_doc);
          indent_flat = true;
          if (wl.error_token != null) {
            flat.spaceIf(!else_tkn_has_tc)._();
            split.spaceIf(!else_tkn_has_tc)._();
          }
        } else {
          flat.space().appends(else_doc).spaceIf(else_tkn_has_no_tc)._();
          split.softline().append(else_doc);
          if (wl.error_token != null) {
            split.spaceIf(!else_tkn_has_tc)._();
          }
        }
        last_tkn = else_tkn;
        if (wl.error_token) |err_tkn| {
          flat.decllineIf(else_tkn_has_tc)._();
          split.decllineIf(else_tkn_has_tc)._();
          const l_pipe_doc = self.ttknWithSTL(err_tkn - 1); // |
          const err_doc = self.ttknWithSTL(err_tkn); // IDENT
          last_tkn = err_tkn + 1;
          const r_pipe_doc = self.ttkn(last_tkn); // |
          flat.appends(l_pipe_doc).appends(err_doc).append(r_pipe_doc);
          split.appends(l_pipe_doc).appends(err_doc).append(r_pipe_doc);
          if (indent_flat) {
            flat.indent(self.db.seqb().declline().appends(else_expr).finish())._();
          } else {
            flat.spaceOrDeclline(self.tknHasNoTC(last_tkn));
            flat.append(else_expr);
          }
        } else {
          if (indent_flat) {
            flat.indent(self.db.seqb().declline().appends(else_expr).finish())._();
          } else {
            flat.decllineIf(else_tkn_has_tc)._();
            flat.append(else_expr);
          }
        }
        rest.decllineOrSoftline(self.tknHasTC(last_tkn));
        rest.append(else_expr);
        split.indent(rest.finish())._();
        sb.ifsplit(id, split.finishSeq(), flat.finishSeq())._();
      }
    } else {
      const is_if = self.tree.tokenTag(wl.ast.while_token) == .keyword_if; 
      const is_empty_block = is_if and self.isEmptyBlock(wl.ast.then_expr);
      if (is_empty_block) { self.decouple_empty_block_braces += 1; }
      defer if (is_empty_block) { self.decouple_empty_block_braces -= 1; };
      const tkn = self.tree.nodeMainToken(wl.ast.then_expr);
      const then_expr = self.t(wl.ast.then_expr);
      if (self.isBlock(tkn)) {
        const tkn_ = self.tree.firstToken(wl.ast.then_expr);
        sb.spaceOrDeclline(self.tknHasNoTC(tkn_ - 1));
        sb.append(then_expr);
      } else {
        var flat = self.db.seqb();
        var split = self.db.seqb();
        var flat_doc: *Doc = undefined;
        if (wl_top_has_tc or self.tknHasTC(self.tree.firstToken(wl.ast.then_expr) - 1)) {
          flat.declline().append(then_expr);
          split.declline().append(then_expr);
          flat_doc = self.db.indent(flat.finish());
        } else {
          flat.space().append(then_expr);
          split.softline().append(then_expr);
          flat_doc = flat.finishSeq();
        }
        sb.ifsplit(id, self.db.indent(split.finish()), flat_doc)._();
      }
    }
    return self.db.groupi(id, sb.finish());
  }

  fn tFor(self: *Self, fl: Ast.full.For) *Doc {
    var sb = self.db.seqb();
    var tmp = self.db.seqb();
    if (fl.label_token) |tkn| {
      tmp.appends(self.ttknWithSTL(tkn)).append(self.ttknWithSTL(tkn + 1));
      tmp.spaceIf(self.tknHasNoTC(tkn + 1))._();
    }
    if (fl.inline_token) |tkn| {
      tmp.appends(self.ttknWithSTL(tkn)).spaceIf(self.tknHasNoTC(tkn))._();
    }
    tmp.append(self.ttknWithSTL(fl.ast.for_token));
    tmp.spaceIf(self.tknHasNoTC(fl.ast.for_token))._();
    const lbrack = fl.ast.for_token + 1;
    const rbrack = self.tree.lastToken(fl.ast.inputs[fl.ast.inputs.len - 1]) + 1; 
    const id = d.genGroupID();
    self.tCall(tmp, id, lbrack, rbrack, fl.ast.inputs, null, null, false);
    sb.group(tmp.finish())._();
    var fl_top_has_tc = false;
    var last_tkn: Ast.TokenIndex = undefined;
    {
      tmp = self.db.seqb();
      fl_top_has_tc = self.tknHasTC(rbrack);
      tmp.decllineOrSpace(fl_top_has_tc);
      tmp.append(self.ttknWithSTL(rbrack + 1)); // |
      tmp.append(self.ttknWithSTL(fl.payload_token));
      var idx = fl.payload_token + 1;
      while (self.tree.tokenTag(idx) != .pipe) {
        tmp.append(self.ttknWithSTL(idx));
        if (self.tree.tokenTag(idx) == .comma) {
          tmp.spaceIf(self.tknHasNoTC(idx))._();
        }
        idx += 1;
      }
      tmp.append(self.ttkn(idx));
      sb.group(tmp.finish())._();
      last_tkn = idx;
      fl_top_has_tc = fl_top_has_tc or self.tknHasTC(last_tkn);
    }
    var then_is_block = false;
    if (fl.ast.else_expr.unwrap()) |els| {
      const is_empty_block = self.isEmptyBlock(fl.ast.then_expr);
      if (is_empty_block) { self.decouple_empty_block_braces += 1; }
      defer if (is_empty_block) { self.decouple_empty_block_braces -= 1; };
      const then_expr = self.t(fl.ast.then_expr);
      const m_tkn = self.tree.nodeMainToken(fl.ast.then_expr);
      const last_has_tc = self.tknHasTC(last_tkn);
      assert(self.tree.tokenTag(last_tkn) == .pipe);
      if (self.isBlock(m_tkn)) {
        then_is_block = true;
        sb.decllineOrSpace(last_has_tc);
        sb.append(then_expr);
      } else {
        var flat = self.db.seqb();
        var split = self.db.seqb();
        var flat_doc: *Doc = undefined;
        if (fl_top_has_tc or last_has_tc) {
          flat.declline().append(then_expr);
          split.declline().append(then_expr);
          flat_doc = self.db.indent(flat.finish());
        } else {
          flat.space().append(then_expr);
          split.softline().append(then_expr);
          flat_doc = flat.finishSeq();
        }
        sb.ifsplit(id, self.db.indent(split.finish()), flat_doc)._();
      }
      last_tkn = self.tree.lastToken(fl.ast.then_expr);
      const else_tkn = last_tkn + 1;
      assert(self.tree.tokenTag(else_tkn) == .keyword_else);
      const is_empty_block2 = self.isEmptyBlock(els);
      if (is_empty_block2) { self.decouple_empty_block_braces += 1; }
      defer if (is_empty_block2) { self.decouple_empty_block_braces -= 1; };
      const else_expr = self.t(els);
      const tkn = self.tree.nodeMainToken(els);
      if (then_is_block or self.isBlock(tkn)) {
        const else_doc = self.ttkn(else_tkn);
        const else_tkn_has_no_tc = self.tknHasNoTC(else_tkn);
        last_tkn = else_tkn;
        if (then_is_block) {
          sb.decllineOrSpace(self.tknHasTC(else_tkn - 1));
          sb.append(else_doc);
          sb.spaceOrDeclline(else_tkn_has_no_tc);
          sb.append(else_expr);
        } else {
          var els_sb = self.db.seqb();
          els_sb.declline().append(else_doc);
          els_sb.spaceOrDeclline(else_tkn_has_no_tc);
          els_sb.append(else_expr);
          sb.group(els_sb.finish())._();
        }
      } else {
        var flat = self.db.seqb();
        var split = self.db.seqb();
        var rest = self.db.seqb();
        const else_doc = self.ttkn(else_tkn);
        const else_tkn_has_no_tc = self.tknHasNoTC(else_tkn);
        if (fl_top_has_tc or self.tknHasTC(else_tkn - 1)) {
          flat.declline().append(else_doc);
          split.declline().append(else_doc);
          flat.indent(self.db.seqb().declline().appends(else_expr).finish())._();
        } else {
          flat.space().append(else_doc);
          flat.spaceOrDeclline(else_tkn_has_no_tc);
          flat.append(else_expr);
          split.softline().append(else_doc);
        }
        rest.softlineOrDeclline(else_tkn_has_no_tc);
        rest.append(else_expr);
        split.indent(rest.finish())._();
        sb.ifsplit(id, split.finishSeq(), flat.finishSeq())._();
      }
    } else {
      const tkn = self.tree.nodeMainToken(fl.ast.then_expr);
      const then_expr = self.t(fl.ast.then_expr);
      if (self.isBlock(tkn)) {
        const tkn_ = self.tree.firstToken(fl.ast.then_expr);
        sb.spaceOrDeclline(self.tknHasNoTC(tkn_ - 1));
        sb.append(then_expr);
      } else {
        var flat = self.db.seqb();
        var split = self.db.seqb();
        var flat_doc: *Doc = undefined;
        if (!fl_top_has_tc and self.tknHasNoTC(self.tree.firstToken(fl.ast.then_expr) - 1)) {
          flat.space().append(then_expr);
          split.softline().append(then_expr);
          flat_doc = flat.finishSeq();
        } else {
          flat.declline().append(then_expr);
          split.declline().append(then_expr);
          flat_doc = self.db.indent(flat.finish());
        }
        sb.ifsplit(id, self.db.indent(split.finish()), flat_doc)._();
      }
    }
    return self.db.groupi(id, sb.finish());
  }

  fn tSwitch(self: *Self, sw: Ast.full.Switch) *Doc {
    var sb = self.db.seqb();
    var tmp = self.db.seqb();
    if (sw.label_token) |tkn| {
      tmp.appends(self.ttknWithSTL(tkn)).append(self.ttknWithSTL(tkn + 1));
      tmp.spaceIf(self.tknHasNoTC(tkn + 1))._();
    }
    tmp.append(self.ttknWithSTL(sw.ast.switch_token));
    tmp.spaceIf(self.tknHasNoTC(sw.ast.switch_token))._();
    const id = d.genGroupID();
    const lbrack = sw.ast.switch_token + 1;
    const rbrack = self.tree.lastToken(sw.ast.condition) + 1;
    self.tCall(tmp, id, lbrack, rbrack, &.{sw.ast.condition}, null, null, false);
    sb.group(tmp.finish())._();
    sb.decllineOrSpace(self.tknHasTC(rbrack));
    const lbrace = rbrack + 1;
    const rbrace = blk: {
      const tkn = blk2: {
        if (sw.ast.cases.len > 0) {
          break :blk2 self.tree.lastToken(sw.ast.cases[sw.ast.cases.len - 1]) + 1;
        }
        break :blk2 lbrace + 1;
      };
      break :blk if (self.tree.tokenTag(tkn) == .comma) tkn + 1 else tkn;
    };
    _ = self.tBlock(lbrace, rbrace, sb, sw.ast.cases, .{.lbrace_only = true});
    var cases = self.db.seqb();
    var last_tkn = lbrace;
    for (sw.ast.cases, 0..) |cs, i| {
      if (i > 0) {
        const tkn = self.tree.firstToken(cs) - 1;
        assert(self.tree.tokenTag(tkn) == .comma);
        cases.decllineIf(self.tknHasTC(tkn - 1))._();
        cases.appends(self.ttkn(tkn)).declline()._();
      }
      cases.append(self.t(cs));
      last_tkn = self.tree.lastToken(cs);
    }
    if (self.tree.tokenTag(last_tkn + 1) == .comma) {
      last_tkn += 1;
      if (self.tknHasTC(last_tkn)) {
        cases.append(self.ttkn(last_tkn));
      }
    }
    if (sw.ast.cases.len > 0) {
      if (self.tknHasNoTC(last_tkn)) {
        cases.text(",")._();
      }
      sb.indent(cases.finish()).declline()._();
    } else {
      _ = cases.finish();
      sb.decllineIf(self.tknHasTC(last_tkn))._();
    }
    sb.append(self.tRbrace(rbrace, true));
    return self.db.group(sb.finish());
  }

  fn tSwitchCase(self: *Self, sc: Ast.full.SwitchCase) *Doc {
    var sb = self.db.seqb();
    if (sc.inline_token) |tkn| {
      sb.appends(self.ttknWithSTL(tkn)).spaceIf(self.tknHasNoTC(tkn))._();
    }
    var tmp = self.db.seqb();
    if (sc.ast.values.len > 0) {
      for (sc.ast.values, 0..) |v, i| {
        if (i > 0) {
          const tkn = self.tree.firstToken(sc.ast.values[i]) - 1;
          assert(self.tree.tokenTag(tkn) == .comma);
          tmp.decllineIf(self.tknHasTC(tkn - 1))._();
          tmp.append(self.ttknWithSTL(tkn));
          if (self.tknHasNoTC(tkn)) {
            tmp.normline()._();
          }
        }
        tmp.append(self.t(v));
      }
    } else {
      // `else` case
      tmp.append(self.ttkn(sc.ast.arrow_token - 1));
    }
    tmp.decllineOrSpace(self.tknHasTC(sc.ast.arrow_token - 1));
    tmp.append(self.ttknWithSTL(sc.ast.arrow_token));
    if (sc.inline_token != null and sc.ast.values.len > 0) {
      sb.indent(tmp.finish())._();
    } else {
      sb.group(tmp.finish())._();
    }
    var last_tkn = sc.ast.arrow_token;
    if (sc.payload_token) |tkn| {
      sb.spaceIf(self.tknHasNoTC(sc.ast.arrow_token))._();
      sb.append(self.ttknWithSTL(tkn - 1)); // |
      sb.append(self.ttknWithSTL(tkn));
      var idx = tkn + 1;
      while (self.tree.tokenTag(idx) != .pipe) {
        sb.append(self.ttknWithSTL(idx));
        if (self.tree.tokenTag(idx) == .comma) {
          sb.spaceIf(self.tknHasNoTC(idx))._();
        }
        idx += 1;
      }
      sb.append(self.ttknWithSTL(idx)); // |
      last_tkn = idx;
    }
    sb.spaceIf(self.tknHasNoTC(last_tkn))._();
    if (sc.inline_token != null) {
      sb.indentOne(self.t(sc.ast.target_expr))._();
    } else {
      sb.append(self.t(sc.ast.target_expr));
    }
    return self.db.group(sb.finish());
  }

  const NodeOrToken = union(enum) {
    node: Node.Index,
    token: Ast.TokenIndex,
    tokens: struct{Ast.TokenIndex, Ast.TokenIndex},
  };

  fn tArrayType(
    self: *Self,
    lbrack: Ast.TokenIndex,
    elem: ?NodeOrToken,
    sentinel: ?Node.Index,
    elem_type: ?NodeOrToken,
  ) struct{*Doc, Ast.TokenIndex} {
    assert(self.tree.tokenTag(lbrack) == .l_bracket);
    const comments = self._comments;
    const lb = self._ttkn(lbrack, .{.add_only_trailing_comment = true});
    const top_comments = self.getNextLineComments(lbrack, true);
    var sb = self.db.seqb();
    sb.append(lb);
    var elems = self.db.seqb();
    if (top_comments) |c_doc| {
      elems.declline().append(c_doc);
    }
    var last_tkn = lbrack;
    if (elem) |elem_| {
      last_tkn = switch (elem_) {
        .node => |nd| self.tree.lastToken(nd),
        .token => |tkn| tkn,
        .tokens => |tkns| tkns.@"1",
      };
      if (top_comments == null) {
        elems.decllineOrSoftline(self.tknHasTC(last_tkn));
      }
      switch (elem_) {
        .node => |nd| {
          elems.append(self.t(nd));
        },
        .token => |tkn| {
          elems.append(self.ttkn(tkn));
        },
        .tokens => |tkns| {
          elems.append(self.ttknWithSTL(tkns.@"0"));
          elems.append(self.ttkn(tkns.@"1"));
        }
      }
    }
    if (sentinel) |s| {
      const cln = self.tree.firstToken(s) - 1;
      assert(self.tree.tokenTag(cln) == .colon);
      if (self.tknHasTC(cln - 1)) {
        elems.declline()._();
      } else if (elems.isEmpty()) {
        elems.softline()._();
      }
      elems.append(self.ttkn(cln));
      elems.decllineIf(self.tknHasTC(cln))._();
      elems.append(self.t(s));
      last_tkn = self.tree.lastToken(s);
    }
    const has_comments = self.commentsChanged(comments) or self.tknHasTC(last_tkn);
    if (has_comments) {
      updateLinesToDecllines(elems);
    }
    sb.indent(elems.finish())._();
    if (elems.isNotEmpty() or has_comments) {
      sb.decllineOrSoftline(has_comments);
    }
    last_tkn += 1;
    assert(self.tree.tokenTag(last_tkn) == .r_bracket);
    sb.append(self.ttkn(last_tkn));
    if (elem_type) |et| {
      const ty = switch (et) {
        .node => |nd| self.t(nd),
        .token => |tkn| self.ttkn(tkn),
        .tokens => unreachable,
      };
      sb.decllineIf(self.tknHasTC(last_tkn)).append(ty);
    }
    return .{self.db.group(sb.finish()), last_tkn};
  }

  fn tPtrType(self: *Self, ty: Ast.full.PtrType) *Doc {
    var sb = self.db.seqb();
    const tkn = ty.ast.main_token;
    var last_tkn: Ast.TokenIndex = tkn;
    switch (ty.size) {
      .c => {
        const doc, const _tkn = self.tArrayType(tkn, .{.tokens = .{tkn + 1, tkn + 2}}, null, null);
        sb.append(doc);
        last_tkn = _tkn;
      },
      .one => {
        // NOTE: adapted from (std) Render.zig:
        // Since ** tokens exist and the same token is shared by two
        // nested pointer types, we check to see if we are the parent
        // in such a relationship. If so, skip rendering anything for
        // this pointer type and rely on the child to render our asterisk
        // as well when it renders the ** token.
        if (self.tree.tokenTag(tkn) == .asterisk_asterisk and tkn == self.tree.nodeMainToken(ty.ast.child_type)) {
          _ = sb.finish();
          return self.t(ty.ast.child_type);
        }
        sb.append(self.ttkn(tkn));
        last_tkn = tkn;
      },
      .many => {
        const doc, const _tkn = self.tArrayType(tkn, .{.token = tkn + 1}, ty.ast.sentinel.unwrap(), null);
        sb.append(doc);
        last_tkn = _tkn;
      },
      .slice => {
        const doc, const _tkn = self.tArrayType(tkn, null, ty.ast.sentinel.unwrap(), null);
        sb.append(doc);
        last_tkn = _tkn;
      }
    }
    var allow: ?*Doc = null;
    var alig: ?*Doc = null;
    var addr: ?*Doc = null;
    var cnst: ?*Doc = null;
    var vol: ?*Doc = null;
  
    var allow_has_no_cmt = false;
    var align_has_no_cmt = false;
    var addr_has_no_cmt = false;
    var const_has_cmt = false;
    var vol_has_cmt = false;

    if (ty.allowzero_token) |i| {
      allow = self.ttkn(i);
      allow_has_no_cmt = self.tknHasNoTC(i);
    }
    if (ty.ast.align_node.unwrap()) |nd| {
      if (ty.ast.bit_range_start.unwrap()) |brs| {
        var tmp = self.db.seqb();
        var args = self.db.seqb(); 
        const bre = ty.ast.bit_range_end.unwrap().?;
        const f_doc = self.t(nd);
        const s_doc = self.t(brs);
        const e_doc = self.t(bre);
        const colon_1 = self.tree.firstToken(brs) - 1;
        const colon_2 = self.tree.firstToken(bre) - 1;
        const colon_1_doc = self.ttknWithSTL(colon_1);
        const colon_2_doc = self.ttknWithSTL(colon_2);

        const id = d.genGroupID();
        const tkn_ = self.tree.firstToken(nd) - 2;
        const lbrack = tkn_ + 1;
        const rbrack = self.tree.lastToken(bre) + 1;

        var split_d = self.db.seqb();
        var flat_d = self.db.seqb();
        var rest_d = self.db.seqb();
        split_d.append(f_doc);
        flat_d.append(f_doc);
        if (self.tknHasTC(colon_1 - 1)) {
          rest_d.declline()._();
          flat_d.declline()._();
        } else {
          rest_d.softline()._();
        }
        rest_d.appends(colon_1_doc).append(s_doc);
        rest_d.decllineOrSoftline(self.tknHasTC(colon_2 - 1));
        rest_d.appends(colon_2_doc).append(e_doc);
        flat_d.appends(colon_1_doc).append(s_doc);
        flat_d.decllineIf(self.tknHasTC(colon_2 - 1)).appends(colon_2_doc).append(e_doc);
        split_d.indent(rest_d.finish())._();
        args.ifsplit(id, split_d.finishSeq(), flat_d.finishSeq())._();
        
        tmp.append(self.ttknWithSTL(lbrack - 1));
        self.tCall(tmp, id, lbrack, rbrack, &.{}, null, args.finishSeq(), false);
        align_has_no_cmt = self.tknHasNoTC(rbrack);
        alig = self.db.groupi(id, tmp.finish());
      } else {
        alig = self.tAttribute(nd, "align");
        align_has_no_cmt = self.tknHasNoTC(self.tree.lastToken(nd) + 1);
      }
    }
    if (ty.ast.addrspace_node.unwrap()) |nd| {
      addr = self.tAttribute(nd, "addrspace");
      addr_has_no_cmt = self.tknHasNoTC(self.tree.lastToken(nd) + 1);
    }
    if (ty.const_token) |i| {
      cnst = self.ttkn(i);
      const_has_cmt = self.tknHasTC(i);
    }
    if (ty.volatile_token) |i| {
      vol = self.ttkn(i);
      vol_has_cmt = self.tknHasTC(i);
    }
    var split = self.db.seqb();
    var flat = self.db.seqb();
    var rest = self.db.seqb();
    if (allow) |_n| {
      if (self.tknHasTC(last_tkn)) {
        split.declline()._();
        flat.declline()._();
      }
      last_tkn = ty.allowzero_token.?;
      split.append(_n);
      flat.appends(_n).spaceIf(allow_has_no_cmt)._();
    }
    if (alig) |_n| {
      const prev_has_tc = self.tknHasTC(last_tkn);
      last_tkn = self.tree.lastToken(ty.ast.align_node.unwrap().?) + 1;
      if (split.isNotEmpty()) {
        rest.decllineOrNormline(prev_has_tc);
        rest.append(_n);
      } else {
        split.decllineIf(prev_has_tc).append(_n);
      }
      flat.decllineIf(prev_has_tc).appends(_n).spaceIf(align_has_no_cmt)._();
    }
    if (addr) |_n| {
      const prev_has_tc = self.tknHasTC(last_tkn);
      last_tkn = self.tree.lastToken(ty.ast.addrspace_node.unwrap().?) + 1;
      if (split.isNotEmpty()) {
        rest.decllineOrNormline(prev_has_tc);
        rest.append(_n);
      } else {
        split.decllineIf(prev_has_tc).append(_n);
      }
      flat.decllineIf(prev_has_tc).appends(_n).spaceIf(addr_has_no_cmt)._();
    }
    var skip_vol = false;
    var skip_child = false;
    const c = self.t(ty.ast.child_type);
    if (cnst) |_n| {
      skip_vol = vol != null;
      skip_child = true;
      const prev_has_tc = self.tknHasTC(last_tkn);
      last_tkn = ty.const_token.?;
      if (vol) |_n2| {
        const b = self.db.seqb().appends(_n);
        b.decllineOrSpace(const_has_cmt);
        b.appends(_n2).decllineOrNormline(vol_has_cmt);
        b.append(c);
        const g = self.db.group(b.finish());
        if (split.isNotEmpty()) {
          rest.decllineOrNormline(prev_has_tc);
          rest.append(g);
        } else {
          split.decllineIf(prev_has_tc).append(g);
        }
      } else {
        var tmp = self.db.seqb().appends(_n);
        tmp.decllineOrSpace(const_has_cmt);
        tmp.append(c);
        const g = self.db.group(tmp.finish());
        if (split.isNotEmpty()) {
          rest.decllineOrNormline(prev_has_tc);
          rest.append(g);
        } else {
          split.decllineIf(prev_has_tc).append(g);
        }
      }
      flat.decllineIf(prev_has_tc).appends(_n).spaceIf(!const_has_cmt)._();
    }
    if (vol) |_n| {
      const prev_has_tc = self.tknHasTC(last_tkn);
      last_tkn = ty.volatile_token.?;
      if (!skip_vol) {
        if (split.isNotEmpty()) {
          rest.decllineOrNormline(prev_has_tc);
          rest.append(_n);
        } else {
          split.decllineIf(prev_has_tc).append(_n);
        }
      }
      flat.decllineIf(prev_has_tc).appends(_n).spaceIf(!vol_has_cmt)._();
    }
    const prev_has_tc = self.tknHasTC(self.tree.firstToken(ty.ast.child_type) - 1);
    if (!skip_child) {
      if (split.isNotEmpty()) {
        rest.decllineOrNormline(prev_has_tc);
        rest.append(c);
      } else {
        split.decllineIf(prev_has_tc).append(c);
      }
    }
    flat.decllineIf(prev_has_tc).append(c);
    split.indent(rest.finish())._();
    const id = d.genGroupID();
    sb.ifsplit(id, split.finishSeq(), flat.finishSeq())._();
    return self.db.groupi(id, sb.finish());
  }

  fn tStructOrArrayInit(
    self: *Self,
    n: Node.Index,
    texpr: ?Node.Index,
    fields: []const Node.Index,
    is_struct: bool,
  ) *Doc {
    var sb = self.db.seqb();
    var lbrace: Ast.TokenIndex = undefined;
    if (texpr) |te| {
      sb.append(self.t(te));
      lbrace = self.tree.lastToken(te) + 1;
    } else {
      // main token is '{'
      lbrace = self.tree.nodeMainToken(n);
      sb.append(self.ttkn(lbrace - 1));
    }
    const comments = self._comments;
    var args = self.db.seqb();
    const lb = self._ttkn(lbrace, .{.add_only_trailing_comment = true, .add_trailing_line_for_comment = false});
    const comments2 = self._comments;
    const top_comments = self.getNextLineComments(lbrace, fields.len != 0);
    sb.decllineIf(self.tknHasTC(lbrace - 1)).append(lb);
    const lb_has_tc = self.tknHasTC(lbrace);
    if (top_comments) |doc| {
      args.declline().append(doc);
    } else if (fields.len != 0) {
      args.decllineOrSoftline(lb_has_tc);
    }
    var rbrace: Ast.TokenIndex = undefined;
    for (fields, 1..) |val, i| {
      var tmp = self.db.seqb();
      if (is_struct) {
        const idx = self.tree.firstToken(val) - 2;
        tmp.append(self.ttknWithSTL(idx - 1)); // .
        tmp.append(self.ttknWithSTL(idx));
        tmp.spaceIf(self.tknHasNoTC(idx))._();
        tmp.append(self.ttknWithSTL(idx + 1)); // =
        tmp.spaceIf(self.tknHasNoTC(idx + 1))._();
      }
      tmp.append(self.t(val));
      const tkn = self.tree.lastToken(val) + 1;
      var do_group = true;
      if (self.tree.tokenTag(tkn) == .comma) {
        if (self.tknHasTC(tkn) or i < fields.len) {
          tmp.decllineIf(self.tknHasTC(tkn - 1))._();
          tmp.append(self.ttkn(tkn));
          args.group(tmp.finish())._();
          if (self.tknHasNoTC(tkn)) {
            args.normline()._();
          } else if (i < fields.len) {
            args.declline()._();
          }
          do_group = false;
        }
      }
      if (do_group) {
        args.group(tmp.finish())._();
      }
      rbrace = tkn;
    }
    if (fields.len == 0) {
      const rb = self.ttkn(lbrace + 1);
      if (top_comments != null or lb_has_tc) {
        sb.extends(args.finish()).declline()._();
      } else {
        _ = args.finish();
      }
      sb.append(rb);
      return self.db.group(sb.finish());
    } else if (self.tree.tokenTag(rbrace) != .r_brace) {
      rbrace += 1;
    }
    assert(self.tree.tokenTag(rbrace) == .r_brace);
    const id = d.genGroupID();
    if (self.tknHasNoTC(rbrace - 1)) {
      if (self.tknHasTC(lbrace) or comments2 != self._comments) {
        args.text(",")._();
      } else {
        args.ifsplit(id, self.db.text(","), self.db.empty())._();
      }
    }
    if (self.commentsChanged(comments)) {
      updateLinesToDecllines(args);
      sb.indent(args.finish()).declline()._();
    } else {
      sb.indent(args.finish()).softline()._();
    }
    sb.append(self.ttkn(rbrace));
    return self.db.groupi(id, sb.finish());
  }

  fn tSlice(self: *Self, s: Ast.full.Slice) *Doc {
    // foo[x..y:t]
    const comments = self._comments;
    var sb = self.db.seqb();
    sb.append(self.t(s.ast.sliced));
    sb.decllineIf(self.tknHasTC(s.ast.lbracket - 1))._();
    const lb = self._ttkn(s.ast.lbracket, .{.add_only_trailing_comment = true});
    const top_comments = self.getNextLineComments(s.ast.lbracket, true);
    sb.append(lb);
    var tmp = self.db.seqb();
    if (top_comments) |c_doc| {
      tmp.declline().append(c_doc);
    } else {
      tmp.decllineOrSoftline(self.tknHasTC(s.ast.lbracket));
    }
    tmp.append(self.t(s.ast.start));
    var tkn = self.tree.lastToken(s.ast.start) + 1; // ..
    tmp.decllineIf(self.tknHasTC(tkn - 1)).append(self.ttkn(tkn));
    if (s.ast.end.unwrap()) |end| {
      tmp.decllineIf(self.tknHasTC(tkn))._();
      tmp.append(self.t(end));
      tkn = self.tree.lastToken(end);
    }
    if (s.ast.sentinel.unwrap()) |sentinel| {
      const cln = self.tree.firstToken(sentinel) - 1;
      assert(self.tree.tokenTag(cln) == .colon);
      tmp.decllineOrSoftline(self.tknHasTC(cln - 1));
      tmp.append(self.ttkn(cln));
      tmp.decllineIf(self.tknHasTC(cln))._();
      tmp.append(self.t(sentinel));
      tkn = self.tree.lastToken(sentinel);
    }
    const has_comments = self.commentsChanged(comments) or self.tknHasTC(tkn);
    if (has_comments) {
      updateLinesToDecllines(tmp);
    }
    sb.indent(tmp.finish())._();
    sb.decllineOrSoftline(has_comments);
    tkn += 1;
    assert(self.tree.tokenTag(tkn) == .r_bracket);
    sb.append(self.ttkn(tkn));
    return self.db.group(sb.finish());
  }

  const TokenFmtConfig = struct {
    add_trailing_line_for_comment: bool = false,
    add_only_lines_if_no_comment: bool = false,
    add_only_trailing_comment: bool = false,
    add_only_next_line_comments: bool = false,
  };

  fn _tline(self: *Self, sb: *SeqBuilder, start: usize, end: usize, next_is_eof: bool) void {
    // only add newlines if we don't already have comments. comments always handle
    // their own newlines
    if (std.mem.find(u8, self.tree.source[start .. end], "//") != null) {
      return;
    }
    if (std.mem.findScalar(u8, self.tree.source[start..end], '\n') != null) {
      const newlines = @min(2, std.mem.countScalar(u8, self.tree.source[start..end], '\n'));
      for (0..newlines) |_| {
        sb.declline()._();
      }
    } else if (next_is_eof) {
      sb.declline()._();
    }
  }

  fn tline(self: *Self, sb: *SeqBuilder, tkn: Ast.TokenIndex) void {
    const start = self.tree.tokenStart(tkn) + self._token(tkn).len;
    const end = self.tree.tokenStart(tkn + 1);
    self._tline(sb, start, end, self.tree.tokenTag(tkn + 1) == .eof);
  }

  fn _tcomment(
    self: *Self,
    sb: *SeqBuilder,
    start: usize,
    end: usize,
    cfg: TokenFmtConfig,
  ) void {
    // NOTE: _tcomment() doesn't handle doc_comment as those are separate
    // nodes not stored in the tree's token seq
    var idx = start;
    // handle trailing comments
    var add_only_next_line_comments = cfg.add_only_next_line_comments;
    var is_same_line = true;
    var comments = @as(u32, 0);
    defer self._comments += comments;
    // NOTE: adapted from (std) Render.zig
    while (std.mem.find(u8, self.tree.source[idx .. end], "//")) |offset| {
      const comment_start = idx + offset;
      // If there is no newline, the comment ends with EOF
      const newline_idx = std.mem.findScalar(u8, self.tree.source[comment_start..end], '\n');
      const newline = if (newline_idx) |i| comment_start + i else null;
      const raw_comment = self.tree.source[comment_start .. newline orelse self.tree.source.len];
      const trimmed_comment = std.mem.trimEnd(u8, raw_comment, &std.ascii.whitespace);
      var fmt_comment: ?[]const u8 = null;
      if (idx != 0) {
        if (std.mem.containsAtLeast(u8, self.tree.source[idx..comment_start], 2, "\n")) {
          if (cfg.add_only_trailing_comment) return;
          sb.declline().declline()._();
          is_same_line = false;
        } else if (std.mem.findScalar(u8, self.tree.source[idx..comment_start], '\n') != null) {
          if (cfg.add_only_trailing_comment) return;
          sb.declline()._();
          is_same_line = false;
        } else if (idx == start) {
          if (!add_only_next_line_comments) {
            sb.space()._();
          }
        }
        if (add_only_next_line_comments) {
          add_only_next_line_comments = false;
          if (is_same_line) {
            idx = (newline orelse end - 1) + 1;
            continue;
          }
        }
      }
      idx = (newline orelse end - 1) + 1;
      const comment_content = std.mem.trimStart(u8, trimmed_comment["//".len..], &std.ascii.whitespace);
      if (self.fmt_disabled_pos != null and std.mem.eql(u8, comment_content, "mint fmt: on")) {
        // formatting was disabled but we're now at the point where it's re-enabled
        // first, enable writing to a seqbuilder
        self.db.disable_writes = false;
        const raw = self.tree.source[self.fmt_disabled_pos.?..comment_start];
        sb.text(raw)._();
        self.fmt_disabled_pos = null;
        fmt_comment = "// mint fmt: on";
      } else if (self.fmt_disabled_pos == null and std.mem.eql(u8, comment_content, "mint fmt: off")) {
        // disable formatting
        self.fmt_disabled_pos = idx;
        fmt_comment = "// mint fmt: off";
      }
      // it is still our responsibility to separate multiline
      // comments even if add_trailing_line_for_comment is unset
      if (comments > 0 and !cfg.add_trailing_line_for_comment) {
        sb.declline()._();
      }
      if (fmt_comment) |cmt| {
        sb.text(cmt)._();
        fmt_comment = null;
      } else {
        sb.text(trimmed_comment)._();
      }
      comments += 1;
      if (cfg.add_trailing_line_for_comment) {
        sb.declline()._();
      }
      if (self.fmt_disabled_pos != null) {
        // we're in no fmt mode, so disable writing to a seqbuilder
        self.db.disable_writes = true;
      }
      if (cfg.add_only_trailing_comment) return;
    }
    if (idx != start) {
      if (cfg.add_only_next_line_comments and !cfg.add_trailing_line_for_comment) {
        // trim off the last line
        const len = sb.len();
        if (len > 0 and sb.docs.items[len - 1].is(.line)) {
          sb.docs.items = sb.docs.items[0..len - 1];
        }
      } else if (cfg.add_trailing_line_for_comment and end != self.tree.source.len) {
        const newlines = @min(@as(usize, 1), std.mem.countScalar(u8, self.tree.source[idx..end], '\n'));
        for (0..newlines) |_| {
          sb.declline()._();
        }
      }
    } else if (cfg.add_only_lines_if_no_comment) {
      self._tline(sb, start, end, false);
    }
  }

  fn _tContainerComment(self: *Self, sb: *SeqBuilder, start: Ast.TokenIndex) void {
    // NOTE: adapted from (std) Render.zig
    var tkn = start;
    while (self.tree.tokenTag(tkn) == .container_doc_comment) : (tkn += 1) {
      sb.append(self.ttknWithSTL(tkn));
    }
  }

  fn _tDocComment(self: *Self, sb: *SeqBuilder, end: Ast.TokenIndex) void {
    // NOTE: adapted from (std) Render.zig
    // search backwards for the first doc comment.
    if (end == 0) return;
    var tkn = end - 1;
    while (self.tree.tokenTag(tkn) == .doc_comment) {
      if (tkn == 0) break;
      tkn -= 1;
    } else {
      tkn += 1;
    }
    const first = tkn;
    if (first == end) return;
    if (first != 0) {
      const prev_tkn_tag = self.tree.tokenTag(first - 1);
      assert(prev_tkn_tag != .l_paren);
      // TODO: if (prev_tkn_tag != .l_brace) { }
    }
    while (self.tree.tokenTag(tkn) == .doc_comment) : (tkn += 1) {
      // NOTE: _ttkn(..) handles comment increment for `doc_comment`
      sb.append(self.ttkn(tkn));
      sb.declline()._();
    }
  }

  fn getNextLineComments(self: *Self, tkn: Ast.TokenIndex, add_line_at_comment_end: bool) ?*Doc {
    const start = self.tree.tokenStart(tkn) + self._token(tkn).len;
    const end = self.tree.tokenStart(tkn + 1);
    var sb = self.db.seqb();
    const cfg: TokenFmtConfig = .{.add_only_next_line_comments = true, .add_trailing_line_for_comment = add_line_at_comment_end};
    self._tcomment(sb, start, end, cfg);
    for (sb.docs.items, 0..) |doc, i| {
      if (doc.is(.line)) {
        sb.docs.items[i] = self.db.empty();
      } else {
        break;
      }
    }
    const docs = sb.finish();
    return if (docs.len != 0) self.db.group(docs) else null;
  }

  fn _ttkn(self: *Self, tkn: Ast.TokenIndex, cfg: TokenFmtConfig) *Doc {
    var sb = self.db.seqb();
    const lxm = self._token(tkn);
    if (self.fmt_disabled_pos == null) {
      if (self.tree.tokenTag(tkn) != .doc_comment) {
        sb.text(lxm)._();
      } else {
        const trimmed_comment = std.mem.trimEnd(u8, lxm, &std.ascii.whitespace);
        sb.text(trimmed_comment)._();
        self._comments += 1;
      }
    } else {
      sb.append(self.db.empty());
    }
    const start = self.tree.tokenStart(tkn) + lxm.len;
    const end = self.tree.tokenStart(tkn + 1);
    self.tkn_cache = .{.tkn = tkn, .has_trailing_comment = false};
    self._tcomment(sb, start, end, cfg);
    if (sb.len() > 1) {
      self.tkn_cache.has_trailing_comment = true;
      return self.db.group(sb.finish());
    }
    return sb.finish()[0];
  }

  fn tcomment(self: *Self, sb: *SeqBuilder, start: usize, end: usize) void {
    self._tcomment(sb, start, end, .{});
  }

  fn ttkn(self: *Self, tkn: Ast.TokenIndex) *Doc {
    return self._ttkn(tkn, .{});
  }

  /// token with comment having a trailing line as seen in the source
  fn ttknWithTL(self: *Self, tkn: Ast.TokenIndex) *Doc {
    return self._ttkn(tkn, .{.add_trailing_line_for_comment = true});
  }

  /// token with comment having a stripped trailing line 
  fn ttknWithSTL(self: *Self, tkn: Ast.TokenIndex) *Doc {
    const doc = self._ttkn(tkn, .{});
    if (self.tknHasTC(tkn)) {
      return self.db.seqb().appends(doc).declline().finishSeq();
    }
    return doc;
  }

  fn t(self: *Self, n: Node.Index) *Doc {
    const tag = self.tree.nodeTag(n);
    assert(tag != self.tree.nodeTag(Node.Index.root));
    switch (tag) {
      .identifier, .number_literal, .anyframe_literal,
      .string_literal, .char_literal, .unreachable_literal => {
        return self.ttkn(self.tree.nodeMainToken(n));
      },
      .anyframe_type => {
        // anyframe->return_type
        _, const node = self.tree.nodeData(n).token_and_node;
        const tkn = self.tree.nodeMainToken(n);
        var sb = self.db.seqb();
        sb.append(self.ttknWithSTL(tkn)); // anyframe
        sb.append(self.ttknWithSTL(tkn + 1)); // ->
        sb.append(self.t(node)); // rhs
        return self.db.group(sb.finish());
      },
      .multiline_string_literal => {
         var start, const end = self.tree.nodeData(n).token_and_token;
         var sb = self.db.seqb();
         const prev_tkn = start - 1;
         // we treat multiline strings as comments so the prev token must
         // certainly have a trailing comment
         assert(self.tknHasTC(prev_tkn));
         var tkns = @as(u32, 0);
         while (start != end) : (start += 1) {
           if (tkns > 0) sb.declline()._();
           sb.append(self.ttkn(start));
           tkns += 1;
         }
         sb.decllineIf(tkns > 0).appends(self.ttkn(end))._();
         // increment since we treat multiline string literals like comments
         self._comments += 1;
         return self.db.group(sb.finish());
       },
       .error_set_decl => {
         const lbrace, const rbrace = self.tree.nodeData(n).token_and_token;
         var members = std.ArrayList(Ast.TokenIndex).empty;
         var start = lbrace + 1;
         while (start != rbrace) : (start += 1) {
           if (self.tree.tokenTag(start) != .comma) {
             util.listAppend(start, &members, self.al);
           }
         }
         return self.tErrorSetDecl(self.tree.nodeMainToken(n), members.items, lbrace, rbrace);
       },
      .negation_wrap, .negation, .bool_not, .bit_not => {
        const expr = self.tree.nodeData(n).node;
        var sb = self.db.seqb();
        sb.appends(self.ttknWithSTL(self.tree.nodeMainToken(n))).append(self.t(expr));
        return self.db.group(sb.finish());
      },
      .simple_var_decl, .global_var_decl, .local_var_decl, .aligned_var_decl => {
        return self.tVarDecl(self.tree.fullVarDecl(n).?);
      },
      .enum_literal => {
        const tk = self.tree.nodeMainToken(n);
        var sb = self.db.seqb();
        sb.append(self.ttknWithSTL(tk - 1));
        return sb.appends(self.ttkn(tk)).finishSeq();
      },
      .call_one, .call_one_comma, .call, .call_comma => {
        const call = self.getCallInfo(n);
        if (self.tCallChain(call)) |doc| return doc;
        const id = d.genGroupID();
        var sb = self.db.seqb();
        const expr = self.t(call.ast.fn_expr);
        const tkn = self.tree.lastToken(call.ast.fn_expr) + 1;
        const lbrack = tkn;
        var rbrack: Ast.TokenIndex = undefined;
        if (call.ast.params.len > 0) {
          rbrack = self.tree.lastToken(call.ast.params[call.ast.params.len - 1]) + 1;
        } else {
          rbrack = tkn + 1;
        }
        if (self.tree.tokenTag(rbrack) != .r_paren) rbrack += 1;
        sb.append(expr);
        sb.decllineIf(self.tknHasTC(self.tree.lastToken(call.ast.fn_expr)))._();
        self.tCall(sb, id, lbrack, rbrack, call.ast.params, null, null, true);
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
        var sb = self.db.seqb();
        sb.append(self.t(proto));
        sb.spaceOrDeclline(self.tknHasNoTC(self.tree.lastToken(proto)));
        sb.append(self.t(body));
        return self.db.group(sb.finish());
      },
      .block_two, .block_two_semicolon => {
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        var sb = self.db.seqb();
        const lbrace = self.tree.nodeMainToken(n);
        const rbrace = self.tree.lastToken(n);
        if (self.tree.tokenTag(lbrace - 1) == .colon and self.tree.tokenTag(lbrace - 2) == .identifier) {
          sb.appends(self.ttknWithTL(lbrace - 2)).append(self.ttknWithSTL(lbrace - 1));
          sb.spaceIf(self.tknHasNoTC(lbrace - 1))._();
        }
        var buf: [2]Node.Index = undefined;
        const body = unwrapTwo(&buf, first, second);
        return self.tBlock(lbrace, rbrace, sb, body, .{});
      },
      .block, .block_semicolon => {
        const rng = self.tree.nodeData(n).extra_range;
        const stmts = self.tree.extraDataSlice(rng, Node.Index);
        var sb = self.db.seqb();
        const lbrace = self.tree.nodeMainToken(n);
        const rbrace = self.tree.lastToken(n);
        if (self.tree.tokenTag(lbrace - 1) == .colon and self.tree.tokenTag(lbrace - 2) == .identifier) {
          sb.appends(self.ttknWithTL(lbrace - 2)).append(self.ttknWithSTL(lbrace - 1));
          sb.spaceIf(self.tknHasNoTC(lbrace - 1))._();
        }
        return self.tBlock(lbrace, rbrace, sb, stmts, .{});
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
        return self.tContainerDecl(null, main_tkn, enum_tkn, null, members);
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
        const wl: Ast.full.While = .{
          .inline_token = null,
          .label_token = null,
          .payload_token = ifn.payload_token,
          .else_token = ifn.else_token,
          .error_token = ifn.error_token,
          .ast = .{
            .cond_expr = ifn.ast.cond_expr,
            .cont_expr = .none,
            .else_expr = ifn.ast.else_expr,
            .then_expr = ifn.ast.then_expr,
            .while_token = ifn.ast.if_token,
          }
        };
        return self.tWhile(wl);
      },
      .@"if" => {
        const ifn = self.tree.ifFull(n);
        const wl: Ast.full.While = .{
          .inline_token = null,
          .label_token = null,
          .payload_token = ifn.payload_token,
          .else_token = ifn.else_token,
          .error_token = ifn.error_token,
          .ast = .{
            .cond_expr = ifn.ast.cond_expr,
            .cont_expr = .none,
            .else_expr = ifn.ast.else_expr,
            .then_expr = ifn.ast.then_expr,
            .while_token = ifn.ast.if_token,
          }
        };
        return self.tWhile(wl);
      },
      .for_simple => {
        return self.tFor(self.tree.forSimple(n));
      },
      .@"for" => {
        return self.tFor(self.tree.forFull(n));
      },
      .while_cont => {
        return self.tWhile(self.tree.whileCont(n));
      },
      .while_simple => {
        return self.tWhile(self.tree.whileSimple(n));
      },
      .@"while" => {
        return self.tWhile(self.tree.whileFull(n));
      },
      .@"switch", .switch_comma => {
        return self.tSwitch(self.tree.switchFull(n));
      },
      .switch_case_one, .switch_case_inline_one => {
        return self.tSwitchCase(self.tree.switchCaseOne(n));
      },
      .switch_case, .switch_case_inline => {
        return self.tSwitchCase(self.tree.switchCase(n));
      },
      .switch_range => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        var sb = self.db.seqb();
        sb.append(self.t(lhs));
        const tkn = self.tree.nodeMainToken(n);
        sb.decllineIf(self.tknHasTC(tkn - 1)).append(self.ttkn(tkn));
        sb.decllineIf(self.tknHasTC(tkn)).append(self.t(rhs));
        return self.db.group(sb.finish());
      },
      .for_range => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_opt_node;
        var sb = self.db.seqb();
        sb.append(self.t(lhs));
        const tkn = self.tree.nodeMainToken(n);
        sb.decllineIf(self.tknHasTC(tkn - 1)).append(self.ttkn(tkn));
        if (rhs.unwrap()) |_n| {
          sb.decllineIf(self.tknHasTC(tkn))._();
          sb.append(self.t(_n));
        }
        return self.db.group(sb.finish());
      },
      .builtin_call_two, .builtin_call_two_comma => {
        const id = d.genGroupID();
        var sb = self.db.seqb();
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        const tkn = self.tree.nodeMainToken(n);
        var buf: [2]Node.Index = undefined;
        const args = unwrapTwo(&buf, first, second);
        const lbrack = tkn + 1;
        var rbrack: Ast.TokenIndex = undefined;
        if (args.len > 0) {
          rbrack = self.tree.lastToken(args[args.len - 1]) + 1;
        } else {
          rbrack = lbrack + 1;
        }
        if (self.tree.tokenTag(rbrack) != .r_paren) rbrack += 1;
        sb.append(self.ttknWithSTL(tkn));
        self.tCall(sb, id, lbrack, rbrack, args, null, null, true);
        return self.db.groupi(id, sb.finish());
      },
      .builtin_call, .builtin_call_comma => {
        const id = d.genGroupID();
        var sb = self.db.seqb();
        const rng = self.tree.nodeData(n).extra_range;
        const prms = self.tree.extraDataSlice(rng, Node.Index);
        const tkn = self.tree.nodeMainToken(n);
        const lbrack = tkn + 1;
        var rbrack: Ast.TokenIndex = undefined;
        if (prms.len > 0) {
          rbrack = self.tree.lastToken(prms[prms.len - 1]) + 1;
        } else {
          rbrack = lbrack + 1;
        }
        if (self.tree.tokenTag(rbrack) != .r_paren) rbrack += 1;
        sb.append(self.ttknWithSTL(tkn));
        self.tCall(sb, id, lbrack, rbrack, prms, null, null, true);
        return self.db.groupi(id, sb.finish());
      },
      .error_union => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        var sb = self.db.seqb();
        sb.append(self.t(lhs));
        const tkn = self.tree.lastToken(lhs);
        sb.decllineIf(self.tknHasTC(tkn)).append(self.ttknWithSTL(tkn + 1));
        sb.append(self.t(rhs));
        return self.db.group(sb.finish());
      },
      .struct_init, .struct_init_comma => {
        const decl = self.tree.structInit(n);
        return self.tStructOrArrayInit(n, decl.ast.type_expr.unwrap(), decl.ast.fields, true);
      },
      .struct_init_one, .struct_init_one_comma => {
        const first, const second = self.tree.nodeData(n).node_and_opt_node;
        const fields = if (second.unwrap()) |_n| &.{_n} else &.{};
        return self.tStructOrArrayInit(n, first, fields, true);
      },
      .struct_init_dot, .struct_init_dot_comma => {
        const decl = self.tree.structInitDot(n);
        return self.tStructOrArrayInit(n, null, decl.ast.fields, true);
      },
      .struct_init_dot_two, .struct_init_dot_two_comma => {
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        var buf: [2]Node.Index = undefined;
        const args = unwrapTwo(&buf, first, second);
        return self.tStructOrArrayInit(n, null, args, true);
      },
      .array_init, .array_init_comma => {
        const decl = self.tree.arrayInit(n);
        return self.tStructOrArrayInit(n, decl.ast.type_expr.unwrap(), decl.ast.elements, false);
      },
      .array_init_one, .array_init_one_comma => {
        const first, const second = self.tree.nodeData(n).node_and_node;
        return self.tStructOrArrayInit(n, first, &.{second}, false);
      },
      .array_init_dot, .array_init_dot_comma => {
        const decl = self.tree.arrayInitDot(n);
        return self.tStructOrArrayInit(n, decl.ast.type_expr.unwrap(), decl.ast.elements, false);
      },
      .array_init_dot_two, .array_init_dot_two_comma => {
        const first, const second = self.tree.nodeData(n).opt_node_and_opt_node;
        var buf: [2]Node.Index = undefined;
        const args = unwrapTwo(&buf, first, second);
        return self.tStructOrArrayInit(n, null,  args, false);
      },
      .@"return" => {
        const tkn = self.tree.nodeMainToken(n);
        var sb = self.db.seqb().appends(self.ttkn(tkn));
        const expr = self.tree.nodeData(n).opt_node;
        if (expr.unwrap()) |_n| {
          sb.spaceOrDeclline(self.tknHasNoTC(tkn));
          sb.append(self.t(_n));
        }
        return self.db.group(sb.finish());
      },
      .@"break", .@"continue" => {
        // `break :label expr`, `break expr`, `break :label`, `break`.
        // `continue :label expr`, `continue expr`, `continue :label`, `continue`.
        const mtkn = self.tree.nodeMainToken(n);
        var sb = self.db.seqb().appends(self.ttkn(mtkn));
        const tkn, const node = self.tree.nodeData(n).opt_token_and_opt_node;
        var last_tkn = mtkn;
        if (tkn.unwrap()) |idx| {
          sb.spaceOrDeclline(self.tknHasNoTC(mtkn));
          sb.append(self.ttknWithSTL(mtkn + 1)); // :
          sb.appends(self.ttkn(idx))._();
          last_tkn = idx;
        }
        if (node.unwrap()) |_n| {
          sb.spaceOrDeclline(self.tknHasNoTC(last_tkn));
          sb.append(self.t(_n));
        }
        return self.db.group(sb.finish());
      },
      .assign_destructure => {
        const ad = self.tree.assignDestructure(n);
        var sb = self.db.seqb();
        var last_tkn: Ast.TokenIndex = undefined;
        for (ad.ast.variables, 0..) |vr, i| {
          if (i > 0) {
            const tkn = self.tree.firstToken(vr) - 1;
            sb.decllineIf(self.tknHasTC(tkn - 1))._();
            sb.append(self.ttkn(tkn));
            sb.spaceOrDeclline(self.tknHasNoTC(tkn));
          }
          sb.append(self.t(vr));
          last_tkn = self.tree.lastToken(vr);
        }
        sb.spaceOrDeclline(self.tknHasNoTC(last_tkn));
        sb.append(self.ttknWithSTL(ad.ast.equal_token));
        sb.spaceIf(self.tknHasNoTC(ad.ast.equal_token))._();
        sb.append(self.t(ad.ast.value_expr));
        return self.db.group(sb.finish());
      },
      .assign, .assign_add, .assign_mul, .assign_div,
      .assign_mod, .assign_sub, .assign_shl, .assign_shr,
      .assign_shl_sat, .assign_bit_and, .assign_bit_xor, 
      .assign_bit_or, .assign_mul_wrap, .assign_add_wrap, 
      .assign_sub_wrap, .assign_add_sat, .assign_sub_sat,
      .assign_mul_sat => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        var sb = self.db.seqb();
        sb.append(self.t(lhs));
        var last_tkn = self.tree.lastToken(lhs);
        sb.spaceOrDeclline(self.tknHasNoTC(last_tkn));
        last_tkn += 1;
        sb.append(self.ttknWithSTL(last_tkn));
        sb.spaceIf(self.tknHasNoTC(last_tkn))._();
        sb.append(self.t(rhs));
        return self.db.group(sb.finish());
      },
      .field_access, .unwrap_optional, .error_value => {
        // lhs.a lhs.? error.expr
        return self.tAccessChain(n);
      },
      .deref => {
        // expr.*
        const expr = self.tree.nodeData(n).node;
        var sb = self.db.seqb();
        sb.append(self.t(expr));
        sb.decllineIf(self.tknHasTC(self.tree.lastToken(expr)))._();
        sb.append(self.ttkn(self.tree.nodeMainToken(n))); // .* token
        return self.db.group(sb.finish());
      },
      // ops
      .add, .add_wrap, .add_sat, .array_cat, .array_mult, .bang_equal,
      .bit_and, .bit_or, .shl, .shl_sat, .shr, .bit_xor, .bool_and,
      .bool_or, .div, .greater_or_equal, .greater_than, .equal_equal, 
      .less_or_equal, .less_than, .merge_error_sets, .mod, .mul, .mul_wrap,
      .mul_sat, .sub, .sub_wrap, .sub_sat => {
        return self.tBinaryExpr(n, tag);
      },
      .@"try", .@"defer", .@"comptime", .@"suspend", .@"resume", .@"nosuspend" => {
        const tkn = self.tree.nodeMainToken(n);
        const _n = self.tree.nodeData(n).node;
        var sb = self.db.seqb();
        sb.append(self.ttknWithSTL(tkn));
        sb.spaceIf(self.tknHasNoTC(tkn))._();
        sb.append(self.t(_n));
        return self.db.group(sb.finish());
      },
      .@"errdefer" => {
        const tkn = self.tree.nodeMainToken(n);
        const m_tkn, const _n = self.tree.nodeData(n).opt_token_and_node;
        var sb = self.db.seqb();
        sb.append(self.ttknWithSTL(tkn));
        sb.spaceIf(self.tknHasNoTC(tkn))._();
        if (m_tkn.unwrap()) |pl| {
          sb.append(self.ttknWithSTL(pl - 1));
          sb.append(self.ttknWithSTL(pl));
          sb.append(self.ttknWithSTL(pl + 1));
          sb.spaceIf(self.tknHasNoTC(pl + 1))._();
        }
        sb.append(self.t(_n));
        return self.db.group(sb.finish());
      },
      .test_decl => {
        const tkn = self.tree.nodeMainToken(n);
        const mb_tkn, const _n = self.tree.nodeData(n).opt_token_and_node;
        var sb = self.db.seqb();
        sb.append(self.ttknWithSTL(tkn));
        sb.spaceIf(self.tknHasNoTC(tkn))._();
        if (mb_tkn.unwrap()) |pl| {
          sb.append(self.ttknWithSTL(pl));
          sb.spaceIf(self.tknHasNoTC(pl))._();
        }
        sb.append(self.t(_n));
        return self.db.group(sb.finish());
      },
      .@"catch", .@"orelse" => {
        return self.tOrelseCatch(n);
      },
      .address_of, .optional_type => {
        // & | ?expr
        const tkn = self.tree.nodeMainToken(n);
        var sb = self.db.seqb().appends(self.ttknWithSTL(tkn));
        sb.append(self.t(self.tree.nodeData(n).node));
        return self.db.group(sb.finish());
      },
      .array_access => {
        const lhs, const rhs = self.tree.nodeData(n).node_and_node;
        var sb = self.db.seqb();
        sb.append(self.t(lhs));
        const tkn = self.tree.lastToken(lhs);
        sb.decllineIf(self.tknHasTC(tkn))._();
        const lbrack = tkn + 1;
        const rest, _  = self.tArrayType(lbrack, .{.node = rhs}, null, null);
        sb.append(rest);
        return self.db.group(sb.finish());
      },
      .grouped_expression => {
        // `(expr)`
        const expr, _ = self.tree.nodeData(n).node_and_token;
        const lbrack = self.tree.nodeMainToken(n);
        const rbrack = self.tree.lastToken(expr) + 1;
        assert(self.tree.tokenTag(lbrack) == .l_paren);
        assert(self.tree.tokenTag(rbrack) == .r_paren);
        var sb = self.db.seqb();
        const comments = self._comments;
        const lb = self._ttkn(lbrack, .{.add_only_trailing_comment = true});
        const top_comments = self.getNextLineComments(lbrack, true);
        sb.append(lb);
        var tmp = self.db.seqb();
        if (top_comments) |c_doc| {
          tmp.declline().append(c_doc);
        }
        tmp.append(self.t(expr));
        if (self.commentsChanged(comments)) {
          sb.indent(tmp.finish())._();
        } else {
          sb.extend(tmp.finish());
        }
        sb.decllineIf(self.tknHasTC(self.tree.lastToken(expr)))._();
        sb.append(self.ttkn(rbrack));
        return self.db.group(sb.finish());
      },
      .slice => {
        return self.tSlice(self.tree.slice(n));
      },
      .slice_sentinel => {
        return self.tSlice(self.tree.sliceSentinel(n));
      },
      .slice_open => {
        return self.tSlice(self.tree.sliceOpen(n));
      },
      //: Type Nodes
      .array_type_sentinel, .array_type => {
        const _n = (
          if (tag == .array_type) self.tree.arrayType(n)
          else self.tree.arrayTypeSentinel(n)
        );
        const lbrack = self.tree.nodeMainToken(n);
        var sb = self.db.seqb();
        const doc, _ = self.tArrayType(lbrack, .{.node = _n.ast.elem_count}, _n.ast.sentinel.unwrap(), .{.node = _n.ast.elem_type});
        sb.append(doc);
        return self.db.group(sb.finish());
      },
      .ptr_type_aligned => {
        return self.tPtrType(self.tree.ptrTypeAligned(n));
      },
      .ptr_type_sentinel => {
        return self.tPtrType(self.tree.ptrTypeSentinel(n));
      },
      .ptr_type_bit_range => {
        return self.tPtrType(self.tree.ptrTypeBitRange(n));
      },
      .ptr_type => {
        return self.tPtrType(self.tree.ptrType(n));
      },
      else => {
        log.debug("found unhandled node: {}", .{tag});
        unreachable;
      }
    }
  }

  fn writeErrors(self: *Self, filename: []const u8) !void {
    var buf: [2048]u8 = undefined;
    var writer = std.Io.File.stdout().writer(self.io, &buf);
    for (self.tree.errors) |err| {
      // render line/column location
      const offset = self.tree.errorOffset(err);
      const loc = self.tree.tokenLocation(offset, err.token);
      // FIXME: for some reason, loc is actually off by 1 for line and column
      try writer.interface.print("{s}:{}:{}: error: ", .{filename, loc.line + 1, loc.column + 1});
      try self.tree.renderError(err, &writer.interface);
      // render source line
      const indent = 2;
      try writer.interface.writeByte('\n');
      _ = try writer.interface.splatByte(' ', indent);
      try writer.interface.print("{s}\n", .{self.tree.source[loc.line_start..loc.line_end]});
      // render squiggle
      _ = try writer.interface.splatByte(' ', loc.column + indent);
      try writer.interface.writeAll("^\n");
      defer writer.flush() catch {};
    }
  }

  pub fn translate(self: *Self, filename: []const u8, src: [:0]const u8, mode: Ast.Mode) !*Doc {
    self.tree = try Ast.parse(self.al, src, mode);
    if (self.tree.errors.len > 0) {
      try self.writeErrors(filename);
      return error.ParseError;
    }
    const doc = self.tOpenContainerDecl(self.tree.rootDecls());
    // verify that all builders are successfully consumed
    self.db.verify();
    self.db.resetBuilders();
    return doc;
  }
};
