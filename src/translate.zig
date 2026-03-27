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
  decls: []NodeData,
  tree: Ast,
  db: DocBuilder,
  cfg: FmtConfig,
  _in_call_args: u16 = 0,
  _in_block: u16 = 0,

  const Self = @This();
  const NodeData = struct{tag: Node.Tag, idx: Node.Index};
  const TranslateError = error{Translate};

  pub fn init(src: [:0]const u8, al: Allocator, mode: Ast.Mode, cfg: FmtConfig) !Self {
    const tree = try Ast.parse(al, src, mode);
    const _decls = tree.rootDecls();
    var decls = util.allocSlice(NodeData, _decls.len, al);
    for (_decls, 0..) |idx, i| {
      const tag = tree.nodeTag(idx);
      decls[i] = .{.tag = tag, .idx = idx};
    }
    return .{
      .al = al,
      .tree = tree,
      .decls = decls,
      .cfg = cfg,
      .db = DocBuilder.init(al),
    };
  }

  fn isVarDecl(tag: Node.Tag) bool {
    return switch (tag) {
      .simple_var_decl, .global_var_decl,
      .local_var_decl, .aligned_var_decl => true,
      else => false,
    };
  }

  fn getDeclSep(self: *Self) *Doc {
    var sb = self.db.seqb();
    for (0..self.cfg.decl_line_seps) |_| {
      sb.declline()._();
    }
    return sb.finishSeq();
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

  fn countComponents(self: *Self, n: Node.Index) usize {
    switch (self.tree.nodeTag(n)) {
      .field_access => {
        const _n, _ = self.tree.nodeData(n).node_and_token;
        return 1 + self.countComponents(_n);
      },
      .call_one_comma, .call_one => {
        const _n, const params = self.getCallOneInfo(n);
        var total = @as(usize, 0);
        for (params) |p| {
          total += self.countComponents(p);
        }
        // extra weight for calls
        return 1 + self.countComponents(_n) + total;
      },
      .call_comma, .call => {
        const call = self.tree.callFull(n);
        var total = @as(usize, 0);
        for (call.ast.params) |p| {
          total += self.countComponents(p);
        }
        // extra weight for calls
        return 1 + self.countComponents(call.ast.fn_expr) + total;
      },
      else => return 1,
    }
  }

  fn countArgs(self: *Self, n: Node.Index) usize {
    switch (self.tree.nodeTag(n)) {
      .call_one_comma, .call_one => {
        _, const params = self.getCallOneInfo(n);
        var total = @as(usize, 0);
        for (params) |p| {
          total += self.countComponents(p);
        }
        return total;
      },
      .call_comma, .call => {
        const call = self.tree.callFull(n);
        var total = @as(usize, 0);
        for (call.ast.params) |p| {
          total += self.countComponents(p);
        }
        return total; 
      },
      else => return 0,
    }
  }

  inline fn isCallTag(self: *Self, n: Node.Index) bool {
    return switch (self.tree.nodeTag(n)) {
      .call, .call_one, .call_comma, .call_one_comma => true,
      else => false,
    };
  }

  inline fn isCallCommaTag(self: *Self, n: Node.Index) bool {
    return switch (self.tree.nodeTag(n)) {
      .call_comma, .call_one_comma => true,
      else => false,
    };
  }

  /// simple abstraction over method call chains
  const Chain = union(enum) {
    call: Call,
    ident: Ident,
    expr: Node.Index,
    lbrack,
    rbrack,
    comma,
  
    pub const Call = struct {
      idx: Node.Index,
      params: []const Node.Index,
    };
  
    pub const Ident = struct {
      idx: Ast.TokenIndex,
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
 
    pub inline fn isLbrack(self: Chain) bool {
      return self.is(.lbrack);
    }
 
    pub inline fn isRbrack(self: Chain) bool {
      return self.is(.rbrack);
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

  fn _collectDeepChainsStep(self: *Self, n: Node.Index, list: *ChainList) !void {
    switch (self.tree.nodeTag(n)) {
      .identifier => {
        const ident = Chain{.ident = .{.idx = self.tree.nodeMainToken(n)}};
        util.listAppend(ident, list, self.al);
      },
      .call, .call_comma => {
        const call = self.tree.callFull(n);
        try self._collectDeepChainsStep(call.ast.fn_expr, list);
        util.listAppend(Chain{.lbrack={}}, list, self.al);
        for (call.ast.params, 0..) |p, i| {
          if (i > 0) {
            util.listAppend(Chain{.comma={}}, list, self.al);
          }
          try self._collectDeepChainsStep(p, list);
        }
        util.listAppend(Chain{.rbrack={}}, list, self.al);
      },
      .call_one, .call_one_comma => {
        const fn_expr, const params = self.getCallOneInfo(n);
        try self._collectDeepChainsStep(fn_expr, list);
        util.listAppend(Chain{.lbrack={}}, list, self.al);
        for (params, 0..) |p, i| {
          if (i > 0) {
            util.listAppend(Chain{.comma={}}, list, self.al);
          }
          try self._collectDeepChainsStep(p, list);
        }
        util.listAppend(Chain{.rbrack={}}, list, self.al);
      },
      .field_access => {
        const lhs, const _rhs = self.tree.nodeData(n).node_and_token;
        try self._collectDeepChainsStep(lhs, list);
        const ident = Chain{.ident = .{.idx = _rhs}};
        util.listAppend(ident, list, self.al);
      },
      else => {
        util.listAppend(Chain{.expr = n}, list, self.al);
      },
    }
  } 

  fn collectMethodChains(self: *Self, n: Node.Index) ?[]Chain {
    var list = ChainList.empty;
    switch (self.tree.nodeTag(n)) {
      .field_access => {
        const _n, const rhs = self.tree.nodeData(n).node_and_token;
        self._collectDeepChainsStep(_n, &list) catch return null;
        const ident = Chain{.ident = .{.idx = rhs}};
        util.listAppend(ident, &list, self.al);
      },
      else => return null,
    }
    return if (list.items.len > 0) list.items else null;
  }

  fn flattenCallChain(self: *Self, call: Ast.full.Call) ?[]Chain {
    // foo.bar(..) | <expr>.bar(..)
    // `--> [foo, bar, (..)] | [<expr>, bar, (..)]
    var list = ChainList.empty;
    if (self.collectMethodChains(call.ast.fn_expr)) |segments| {
      util.listAppendSlice(Chain, &list, segments, self.al);
      util.listAppend(Chain{.lbrack={}}, &list, self.al);
      for (call.ast.params, 0..) |p, i| {
        if (self.isCallTag(p)) {
          if (self.collectMethodChains(p)) |_segments| {
            util.listAppendSlice(Chain, &list, _segments, self.al);
            continue;
          }
        }
        if (i > 0) {
          util.listAppend(Chain{.comma={}}, &list, self.al);
        } 
        util.listAppend(Chain{.expr=p}, &list, self.al);
      }
      util.listAppend(Chain{.rbrack={}}, &list, self.al);
    }
    return if (list.items.len > 0) list.items else null;
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

  fn _computeDocComplexity(self: *Self, doc: *Doc) usize {
    var total = @as(usize, 0);
    switch (doc.*) {
      .text => |*_n| {
        total += _n.s.len;
        total += @intFromBool(std.mem.indexOfAny(u8, _n.s, "()") != 0);
      },
      .line => |*_n| {
        switch (_n.ty) {
          .chain => total += 3,
          .soft => total += 2,
          .decl => total += 2,
          .norm => total += 1,
          .hard => total += 0,
        }
      },
      .seq => |*_n| {
        total += self._computeDocsComplexity(_n.docs);
      },
      .indent => |*_n| {
        total += self._computeDocsComplexity(_n.docs);
        total += self.cfg.indent;
      },
      .group => |*_n| {
        total += self._computeDocsComplexity(_n.docs);
      },
      .ifsplit => |*_n| {
        const a = self._computeDocComplexity(_n.split);
        const b = self._computeDocComplexity(_n.split);
        total += @max(a, b);
      },
    }
    return total;
  }

  fn _computeDocsComplexity(self: *Self, docs: []*Doc) usize {
    var total = @as(usize, 0);
    // FIXME: for now, we use a naive width approach
    for (docs) |doc| {
      total += self._computeDocComplexity(doc);
    }
    return total;
  }

  fn isComplexSeq(self: *Self, sb: *SeqBuilder) bool {
    // if we find the doc to be complex, we add softlines
    return self._computeDocsComplexity(sb.docs.items) > self.cfg.width;
  }

  fn flushTkSeq(self: *Self, tk_seq: *StrList, sb: *SeqBuilder) void {
    if (tk_seq.items.len == 0) return;
    var tmp = self.db.seqb();
    for (tk_seq.items, 0..) |txt, j| {
      if (txt[0] == '.') {
        tmp.chainline()._();
        tmp.text(txt)._();
        continue;
      }
      tmp.text(txt)._();
      // only add '.' when we begin the next chain
      if (j < tk_seq.items.len - 1) {
        // since empty chain calls (e.g. foo.bar()) are
        // also stored in tk_seq, we look out for by
        // avoiding adding a '.' in front of `()`
        if (tk_seq.items[j + 1][0] != '(') {
          tmp.text(".")._();
        }
      }
    }
    sb.extend(tmp.finish());
    tk_seq.clearRetainingCapacity();
  }

  fn tCallChain(self: *Self, call: Ast.full.Call) TranslateError!?*Doc {
    if (self.flattenCallChain(call)) |chains| {
      var sb = self.db.seqb();
      const id = d.genGroupID();
      assert(chains[0].isIdent());
      var sb_stack: std.ArrayList(*SeqBuilder) = .empty;
      var tk_seq: StrList = .empty;
      var last = chains[0];
      util.listAppend(self._token(last.ident.idx), &tk_seq, self.al);
      var i = @as(usize, 1);
      while (i < chains.len) : (i += 1) {
        const chain = chains[i];
        switch (chain) {
          .ident => |_n| {
            if (last.isRbrack()) {
              // if last is '(', then we're at the start of a new chain
              // add the chain connector -> '.'
              util.listAppend(@as([]const u8, "."), &tk_seq, self.al);
            }
            util.listAppend(self._token(_n.idx), &tk_seq, self.al);
          },
          .lbrack => {
            if (chains[i+1].isRbrack()) {
              // we can inline chains that have empty calls,
              // so we do that here
              util.listAppend(@as([]const u8, "()"), &tk_seq, self.al);
              self.flushTkSeq(&tk_seq, sb);
              last = chains[i+1];
              i += 1;
              continue;
            }
            self.flushTkSeq(&tk_seq, sb);
            sb.text("(")._();
            util.listAppend(sb, &sb_stack, self.al);
            // reset for args
            sb = self.db.seqb();
          },
          .comma => {
            self.flushTkSeq(&tk_seq, sb);
            sb.text(",")._();
            sb.normline()._();
          },
          .rbrack => {
            self.flushTkSeq(&tk_seq, sb);
            var lhs_sb = sb_stack.pop().?;
            var is_complex = self.isComplexSeq(sb);
            if (!is_complex) {
              // see if we can group the call
              var found = false;
              var idx = lhs_sb.docs.items.len - 1;
              while (idx > 0) : (idx -= 1) {
                const x = lhs_sb.docs.items[idx];
                // the first text after '(' is the function's name
                if (x.is(.text)) {
                  if (!std.mem.eql(u8, x.text.s, "(")) {
                    found = true;
                    break; 
                  }
                }
              }
              if (found) {
                last = chain;
                const fun = lhs_sb.docs.items[idx];
                var tmp = self.db.seqb().appends(fun).extends(lhs_sb.docs.items[idx..]);
                defer _ = tmp.finish();
                is_complex = self.isComplexSeq(tmp);
                if (!is_complex) {
                  lhs_sb.docs.items = lhs_sb.docs.items[0..idx];
                  var args = lhs_sb;
                  // replace normlines with space since args isn't complex
                  for (sb.docs.items, 0..) |doc, k| {
                    if (doc.is(.line)) {
                      if (doc.line.ty == .norm) {
                        sb.docs.items[k] = self.db.text(" ");
                      }
                    }
                  }
                  args.group(
                    self.db.seqb().appends(fun).text("(")
                    .extends(sb.finish()).text(")").finish()
                  )._();
                  sb = args;
                  continue;
                }
              }
            }
            if (!chains[i - 1].isLbrack()) {
              sb.ifsplit(id, self.db.text(","), self.db.text(""))._();
            }
            var args = lhs_sb;
            args.indent(
              self.db.seqb().softlineIf(is_complex)
              .extends(sb.finish()).finish()
            )._();
            args.softlineIf(is_complex).text(")")._();
            sb = args;
          },
          .expr => |_n| {
            sb.append(try self.t(_n));
          },
          .call => unreachable,
        }
        last = chain;
      }
      assert(sb_stack.items.len == 0);
      return self.db.groupi(id, sb.finish());
    }
    return null;
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
      tmp.normline().text("align(")._();
      tmp.append(try self.t(_n));
      tmp.text(")")._();
    }
    if (vd.ast.addrspace_node.unwrap()) |_n| {
      tmp.normline().text("addrspace(")._();
      tmp.append(try self.t(_n));
      tmp.text(")")._();
    }
    if (vd.ast.section_node.unwrap()) |_n| {
      tmp.normline().text("linksection(")._();
      tmp.append(try self.t(_n));
      tmp.text(")")._();
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
        .keyword_inline, .keyword_export, .keyword_pub => {
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
      tmp.normline().text("align(")._();
      tmp.append(try self.t(_n));
      tmp.text(")")._();
    }
    if (addr_space) |_n| {
      tmp.normline().text("addrspace(")._();
      tmp.append(try self.t(_n));
      tmp.text(")")._();
    }
    if (call_conv) |_n| {
      tmp.normline().text("callconv(")._();
      tmp.append(try self.t(_n));
      tmp.text(")")._();
    }
    if (link_section) |_n| {
      tmp.normline().text("linksection(")._();
      tmp.append(try self.t(_n));
      tmp.text(")")._();
    }
    if (ret_ty) |_n| {
      sb.group(tmp.normline().finish())._();
      sb.append(try self.t(_n));
    } else {
      sb.group(tmp.finish())._();
    }
    if (has_extern) {
      sb.text(";").hardline()._();
    }
    return self.db.groupi(id, sb.finish());
  }

  fn t(self: *Self, n: Node.Index) !*Doc {
    const tag = self.tree.nodeTag(n);
    assert(tag != self.tree.nodeTag(Node.Index.root));
    switch (tag) {
      .identifier, .number_literal, .string_literal => {
        return self.db.text(self._token(self.tree.nodeMainToken(n)));
      },
      .simple_var_decl, .global_var_decl, .local_var_decl, .aligned_var_decl => {
        const vd = self.tree.fullVarDecl(n).?;
        var sb = try self.tVarDecl(vd);
        if (self._in_block == 0) {
          sb.text(";").hardline()._();
        }
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
        return self.db.group(sb.hardline().finish());
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
            tmp.append(self.getDeclSep());
          }
          tmp.appends(try self.t(stmt)).text(";")._();
        }
        if (tmp.isEmpty()) {
          _ = tmp.finish();
          return sb.text("}").finishSeq();
        }
        return sb.indent(tmp.finish()).hardline().text("}").finishSeq();
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
    var decls: d.DocList = .empty;
    var last: Node.Tag = self.tree.nodeTag(.root);
    for (self.decls, 0..) |nd, i| {
      if (i > 0) {
        if (!(isVarDecl(last) and isVarDecl(nd.tag))) {
          util.listAppend(self.getDeclSep(), &decls, self.al);
        }
      }
      util.listAppend(try self.t(nd.idx), &decls, self.al);
      last = nd.tag;
    }
    const doc = self.db.seq(decls.items);
    // verify that all builders are successfully consumed
    self.db.verify();
    return doc;
  }
};
