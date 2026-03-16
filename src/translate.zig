const std = @import("std");
const fmt = @import("format.zig");
const util = @import("util.zig");

const log = std.log.scoped(.translate);
const assert = std.debug.assert;

const d = fmt.doc;
const Format = fmt.Format;
const Doc = d.Doc;
const SeqBuilder = d.SeqBuilder;
const DocBuilder = d.DocBuilder;
const Allocator = std.mem.Allocator;
const Ast = std.zig.Ast;
const Node = Ast.Node;
const NodeIndexList = std.ArrayList(Node.Index);

pub const Translate = struct {
  al: Allocator,
  decls: []NodeData,
  tree: Ast,
  db: DocBuilder,
  _in_call_args: u32 = 0,

  const Self = @This();
  const NodeData = struct{tag: Node.Tag, idx: Node.Index};
  const TranslateError = error{Translate};

  pub fn init(src: [:0]const u8, al: Allocator, mode: Ast.Mode) !Self {
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
      .db = DocBuilder.init(al),
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

  const ComplexityThreshold = 3;

  /// whether this call node has complex arguments
  inline fn callHasComplexArgs(self: *Self, n: Node.Index) bool {
    return self.countArgs(n) > ComplexityThreshold;
  }

  /// whether this call arg node is complex
  inline fn isComplexCallArg(self: *Self, n: Node.Index) bool {
    return self.countComponents(n) > ComplexityThreshold;
  }

  /// whether this field access node is complex
  inline fn isComplexFieldLHS(self: *Self, n: Node.Index) bool {
    return self.countComponents(n) > ComplexityThreshold;
  }

  /// whether this call node is complex
  inline fn isComplexCall(self: *Self, n: Node.Index) bool {
    if (!self.isCallTag(n)) return false;
    return self.countComponents(n) > ComplexityThreshold;
  }

  /// simple abstraction over method call chains
  const Chain = union(enum) {
    call: Call,
    ident: Ident,
    expr: Node.Index,
  
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

  fn _collectChainsStep(self: *Self, n: Node.Index, list: *ChainList) !void {
    switch (self.tree.nodeTag(n)) {
      .identifier => {
        const ident = Chain{.ident = .{.idx = self.tree.nodeMainToken(n)}};
        util.listAppend(ident, list, self.al);
      },
      .call, .call_comma => {
        const call = self.tree.callFull(n);
        try self._collectChainsStep(call.ast.fn_expr, list);
        const c_call = Chain{.call = .{.idx = n, .params = call.ast.params}};
        util.listAppend(c_call, list, self.al);
      },
      .call_one, .call_one_comma => {
        const fn_expr, const params = self.getCallOneInfo(n);
        try self._collectChainsStep(fn_expr, list);
        const c_call = Chain{.call = .{.idx = n, .params = params}};
        util.listAppend(c_call, list, self.al);
      },
      .field_access => {
        const lhs, const _rhs = self.tree.nodeData(n).node_and_token;
        try self._collectChainsStep(lhs, list);
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
        self._collectChainsStep(_n, &list) catch return null;
        const ident = Chain{.ident = .{.idx = rhs}};
        util.listAppend(ident, &list, self.al);
      },
      else => return null,
    }
    return if (list.items.len > 0) list.items else null;
  }

  fn isComplexParam(self: *Self, param: Node.Index) bool {
    return switch (self.tree.nodeTag(param)) {
      .identifier, .string_literal, .number_literal => false,
      else => true,
    };
  }

  fn shouldSoftline(self: *Self, params: []const Node.Index) bool {
    if (params.len > 0) {
      if (params.len == 1) {
        if (self.countComponents(params[0]) <= ComplexityThreshold) {
          return false;
        }
      }
      for (params) |param| {
        if (self.isComplexParam(param)) {
          return true;
        }
      }
    }
    return false;
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
      sb_args.append(try self.t(_n));
      if (i < params.len - 1) {
        sb_args.text(",")._();
        if (should_softline) {
          sb_args.normline()._();
        } else {
          sb_args.space()._();
        }
      }
    }
    self._in_call_args -= 1;
    if ((params.len > 0 and should_softline) or tag == .call_one_comma) {
      // add trailing comma for complex args or if we break
      sb_args.ifsplit(id, self.db.text(","), self.db.softline())._();
    }
    return sb_args;
  }

  fn t(self: *Self, n: Node.Index) !*Doc {
    const tag = self.tree.nodeTag(n);
    assert(tag != self.tree.nodeTag(Node.Index.root));
    switch (tag) {
      .identifier, .number_literal, .string_literal => {
        return self.db.text(self._token(self.tree.nodeMainToken(n)));
      },
      .simple_var_decl => {
        const vd = self.tree.simpleVarDecl(n);
        var sb = self.db.seqb();
        const mut = self._token(vd.ast.mut_token);
        // TODO: initial components after mut token
        assert(vd.ast.align_node.unwrap() == null);
        const name = self._token(vd.ast.mut_token + 1);
        // TODO: components after mut token
        sb.text(mut).space().text(name)._();
        if (vd.ast.type_node.unwrap()) |_n| {
          sb.text(": ")._();
          sb.append(try self.t(_n));
        }
        if (vd.ast.init_node.unwrap()) |_n| {
          sb.space().text("=").space()._();
          sb.append(try self.t(_n));
        }
        // TODO: check for comments
        return self.db.group(sb.text(";").hardline().finish());
      },
      .call_one, .call_one_comma, .call, .call_comma => {
        const call = self.getCallInfo(n);
        var sb = self.db.seqb();
        const id = d.genGroupID();
        if (self.collectMethodChains(call.ast.fn_expr)) |segments| {
          // foo.bar(..) | <expr>.bar(..)
          // `--> [foo, bar, (..)] | [<expr>, bar, (..)]
          assert(segments[0].isIdent());
          sb.text(self._token(segments[0].ident.idx))._();
          var rest = self.db.seqb();
          for (segments[1..]) |comp| {
            switch (comp) {
              .ident => |ident| {
                if (segments.len > 2) {
                  rest.softline().text(".").text(self._token(ident.idx))._();
                } else {
                  rest.text(".").text(self._token(ident.idx))._();
                }
              },
              .call => |_call| {
                const _id = d.genGroupID();
                var tmp = self.db.seqb();
                tmp.text("(")._();
                const _tag = self.tree.nodeTag(_call.idx);
                const _should_softline = _call.params.len > 0;
                var args = try self.tCallArgs(
                  _id, _tag, _call.params,
                  _should_softline,
                );
                tmp.indent(args.finish())._();
                tmp.softlineIf(_should_softline).text(")")._();
                rest.group(tmp.finish())._();
              },
              .expr => |expr| {
                rest.softline().text(".").append(try self.t(expr));
              },
            }
          }
          const should_softline = self.shouldSoftline(call.ast.params);
          rest.text("(")._();
          var sb_args = try self.tCallArgs(id, tag, call.ast.params, should_softline);
          rest.indent(sb_args.finish())._();
          if (self._in_call_args > 0) {
            rest.softlineIf(should_softline).text(")")._();
            sb.indent(rest.finish())._();
          } else {
            sb.indent(rest.finish())._();
            sb.softlineIf(should_softline).text(")")._();
          }
          return self.db.groupi(id, sb.finish());
        }
        const expr = try self.t(call.ast.fn_expr);
        sb.appends(expr).text("(")._();
        const should_softline = call.ast.params.len > 0;
        var sb_args = try self.tCallArgs(id, tag, call.ast.params, should_softline);
        sb.indent(sb_args.finish())._();
        sb.softlineIf(should_softline).text(")")._();
        return self.db.groupi(id, sb.finish());
      },
      .field_access => {
        // lhs.a
        // TODO:
        unreachable;
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
    for (self.decls) |nd| {
      util.listAppend(try self.t(nd.idx), &decls, self.al);
    }
    const doc = self.db.seq(decls.items);
    // verify that all builders are successfully consumed
    self.db.verify();
    return doc;
  }
};
