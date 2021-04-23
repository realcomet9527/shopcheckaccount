const std = @import("std");
const logger = @import("logger.zig");

usingnamespace @import("strings.zig");
usingnamespace @import("ast/base.zig");

const ImportRecord = @import("import_record.zig").ImportRecord;

// There are three types.
// 1. Expr (expression)
// 2. Stmt (statement)
// 3. Binding
// Q: "What's the difference between an expression and a statement?"
// A:  > Expression: Something which evaluates to a value. Example: 1+2/x
//     > Statement: A line of code which does something. Example: GOTO 100
//     > https://stackoverflow.com/questions/19132/expression-versus-statement/19224#19224

// Expr, Binding, and Stmt each wrap a Data:
// Data is where the actual data where the node lives.
// There are four possible versions of this structure:
// [ ] 1.  *Expr, *Stmt, *Binding
// [ ] 1a. *Expr, *Stmt, *Binding something something dynamic dispatch
// [ ] 2.  *Data
// [x] 3.  Data.(*) (The union value in Data is a pointer)
// I chose #3 mostly for code simplification -- sometimes, the data is modified in-place.
// But also it uses the least memory.
// Since Data is a union, the size in bytes of Data is the max of all types
// So with #1 or #2, if S.Function consumes 768 bits, that means Data must be >= 768 bits
// Which means "true" in code now takes up over 768 bits, probably more than what v8 spends
// Instead, this approach means Data is the size of a pointer.
// It's not really clear which approach is best without benchmarking it.
// The downside with this approach is potentially worse memory locality, since the data for the node is somewhere else.
// But it could also be better memory locality due to smaller in-memory size (more likely to hit the cache)
// only benchmarks will provide an answer!
// But we must have pointers somewhere in here because can't have types that contain themselves
pub const BindingNodeIndex = Binding;
pub const StmtNodeIndex = Stmt;
pub const ExprNodeIndex = Expr;

pub const ExprNodeList = []Expr;
pub const StmtNodeList = []Stmt;
pub const BindingNodeList = []Binding;

// TODO: figure out if we actually need this
// -- original comment --
// Files are parsed in parallel for speed. We want to allow each parser to
// generate symbol IDs that won't conflict with each other. We also want to be
// able to quickly merge symbol tables from all files into one giant symbol
// table.
//
// We can accomplish both goals by giving each symbol ID two parts: a source
// index that is unique to the parser goroutine, and an inner index that
// increments as the parser generates new symbol IDs. Then a symbol map can
// be an array of arrays indexed first by source index, then by inner index.
// The maps can be merged quickly by creating a single outer array containing
// all inner arrays from all parsed files.
pub const Ref = packed struct {
    source_index: Ref.Int = std.math.maxInt(Ref.Int),
    inner_index: Ref.Int,

    // 2 bits of padding for whatever is the parent
    pub const Int = u31;
    const None = Ref{ .inner_index = std.math.maxInt(Ref.Int) };
    pub fn isNull(self: *const Ref) bool {
        return self.source_index == std.math.maxInt(Ref.Int) and self.inner_index == std.math.maxInt(Ref.Int);
    }

    pub fn isSourceNull(self: *const Ref) bool {
        return self.source_index == std.math.maxInt(Ref.Int);
    }
};

pub const ImportItemStatus = packed enum {
    none,

    // The linker doesn't report import/export mismatch errors
    generated,
    // The printer will replace this import with "undefined"

    missing,
};

pub const LocRef = struct { loc: logger.Loc, ref: ?Ref };

pub const Flags = struct {

    // Instead of 4 bytes for booleans, we can store it in 4 bits
    // It will still round up to 1 byte. But that's 3 bytes less!
    pub const Property = packed struct {
        is_computed: bool = false,
        is_method: bool = false,
        is_static: bool = false,
        was_shorthand: bool = false,
        is_spread: bool = false,

        const None = Flags.Property{};
    };

    pub const Function = packed struct {
        is_async: bool = false,
        is_generator: bool = false,
        has_rest_arg: bool = false,
        has_if_scope: bool = false,

        // This is true if the function is a method
        is_unique_formal_parameters: bool = false,

        // Only applicable to function statements.
        is_export: bool = false,

        const None = Flags.Function{};
    };
};

pub const Binding = struct {
    loc: logger.Loc,
    data: B,

    pub const Tag = packed enum {
        b_identifier,
        b_array,
        b_property,
        b_object,
        b_missing,
    };

    pub fn init(t: anytype, loc: logger.Loc) Binding {
        switch (@TypeOf(t)) {
            *B.Identifier => {
                return Binding{ .loc = loc, .data = B{ .b_identifier = t } };
            },
            *B.Array => {
                return Binding{ .loc = loc, .data = B{ .b_array = t } };
            },
            *B.Property => {
                return Binding{ .loc = loc, .data = B{ .b_property = t } };
            },
            *B.Object => {
                return Binding{ .loc = loc, .data = B{ .b_object = t } };
            },
            *B.Missing => {
                return Binding{ .loc = loc, .data = B{ .b_missing = t } };
            },
            else => {
                @compileError("Invalid type passed to Binding.init");
            },
        }
    }

    pub fn alloc(allocator: *std.mem.Allocator, t: anytype, loc: logger.Loc) Binding {
        switch (@TypeOf(t)) {
            B.Identifier => {
                var data = allocator.create(B.Identifier) catch unreachable;
                data.* = t;
                return Binding{ .loc = loc, .data = B{ .b_identifier = data } };
            },
            B.Array => {
                var data = allocator.create(B.Array) catch unreachable;
                data.* = t;
                return Binding{ .loc = loc, .data = B{ .b_array = data } };
            },
            B.Property => {
                var data = allocator.create(B.Property) catch unreachable;
                data.* = t;
                return Binding{ .loc = loc, .data = B{ .b_property = data } };
            },
            B.Object => {
                var data = allocator.create(B.Object) catch unreachable;
                data.* = t;
                return Binding{ .loc = loc, .data = B{ .b_object = data } };
            },
            B.Missing => {
                var data = allocator.create(B.Missing) catch unreachable;
                data.* = t;
                return Binding{ .loc = loc, .data = B{ .b_missing = data } };
            },
            else => {
                @compileError("Invalid type passed to Binding.alloc");
            },
        }
    }
};

pub const B = union(Binding.Tag) {
    b_identifier: *B.Identifier,
    b_array: *B.Array,
    b_property: *B.Property,
    b_object: *B.Object,
    b_missing: *B.Missing,

    pub const Identifier = struct {
        ref: Ref,
    };

    pub const Property = struct {
        flags: Flags.Property = Flags.Property.None,
        key: ExprNodeIndex,
        value: BindingNodeIndex,
        default_value: ?ExprNodeIndex = null,
    };

    pub const Object = struct { properties: []Property, is_single_line: bool = false };

    pub const Array = struct {
        items: []ArrayBinding,
        has_spread: bool = false,
        is_single_line: bool = false,
    };

    pub const Missing = struct {};
};

pub const ClauseItem = struct {
    alias: string,
    alias_loc: logger.Loc,
    name: LocRef,

    // This is the original name of the symbol stored in "Name". It's needed for
    // "SExportClause" statements such as this:
    //
    //   export {foo as bar} from 'path'
    //
    // In this case both "foo" and "bar" are aliases because it's a re-export.
    // We need to preserve both aliases in case the symbol is renamed. In this
    // example, "foo" is "OriginalName" and "bar" is "Alias".
    original_name: string,
};

pub const G = struct {
    pub const Decl = struct {
        binding: BindingNodeIndex,
        value: ?ExprNodeIndex = null,
    };

    pub const NamespaceAlias = struct {
        namespace_ref: Ref,
        alias: string,
    };

    pub const Class = struct {
        class_keyword: logger.Range = logger.Range.None,
        ts_decorators: ExprNodeList = &([_]Expr{}),
        class_name: ?LocRef = null,
        extends: ?ExprNodeIndex = null,
        body_loc: logger.Loc = logger.Loc.Empty,
        properties: []Property = &([_]Property{}),
    };

    // invalid shadowing if left as Comment
    pub const Comment = struct { loc: logger.Loc, text: string };

    pub const Property = struct {
        ts_decorators: ExprNodeList = &([_]Expr{}),
        // Key is optional for spread
        key: ?ExprNodeIndex = null,

        // This is omitted for class fields
        value: ?ExprNodeIndex = null,

        // This is used when parsing a pattern that uses default values:
        //
        //   [a = 1] = [];
        //   ({a = 1} = {});
        //
        // It's also used for class fields:
        //
        //   class Foo { a = 1 }
        //
        initializer: ?ExprNodeIndex = null,
        kind: Kind = Kind.normal,
        flags: Flags.Property = Flags.Property.None,

        pub const Kind = packed enum {
            normal,
            get,
            set,
            spread,
        };
    };

    pub const FnBody = struct {
        loc: logger.Loc,
        stmts: StmtNodeList,
    };

    pub const Fn = struct {
        name: ?LocRef,
        open_parens_loc: logger.Loc,
        args: []Arg = &([_]Arg{}),
        body: ?FnBody = null,
        arguments_ref: ?Ref = null,

        flags: Flags.Function = Flags.Function.None,
    };

    pub const Arg = struct {
        ts_decorators: ?ExprNodeList = null,
        binding: BindingNodeIndex,
        default: ?ExprNodeIndex = null,

        // "constructor(public x: boolean) {}"
        is_typescript_ctor_field: bool = false,
    };
};

pub const Symbol = struct {
    // This is the name that came from the parser. Printed names may be renamed
    // during minification or to avoid name collisions. Do not use the original
    // name during printing.
    original_name: string,

    // This is used for symbols that represent items in the import clause of an
    // ES6 import statement. These should always be referenced by EImportIdentifier
    // instead of an EIdentifier. When this is present, the expression should
    // be printed as a property access off the namespace instead of as a bare
    // identifier.
    //
    // For correctness, this must be stored on the symbol instead of indirectly
    // associated with the Ref for the symbol somehow. In ES6 "flat bundling"
    // mode, re-exported symbols are collapsed using MergeSymbols() and renamed
    // symbols from other files that end up at this symbol must be able to tell
    // if it has a namespace alias.
    namespace_alias: ?G.NamespaceAlias = null,

    // Used by the parser for single pass parsing. Symbols that have been merged
    // form a linked-list where the last link is the symbol to use. This link is
    // an invalid ref if it's the last link. If this isn't invalid, you need to
    // FollowSymbols to get the real one.
    link: ?Ref = null,

    // An estimate of the number of uses of this symbol. This is used to detect
    // whether a symbol is used or not. For example, TypeScript imports that are
    // unused must be removed because they are probably type-only imports. This
    // is an estimate and may not be completely accurate due to oversights in the
    // code. But it should always be non-zero when the symbol is used.
    use_count_estimate: u32 = 0,

    // This is for generating cross-chunk imports and exports for code splitting.
    chunk_index: ?u32 = null,

    // This is used for minification. Symbols that are declared in sibling scopes
    // can share a name. A good heuristic (from Google Closure Compiler) is to
    // assign names to symbols from sibling scopes in declaration order. That way
    // local variable names are reused in each global function like this, which
    // improves gzip compression:
    //
    //   function x(a, b) { ... }
    //   function y(a, b, c) { ... }
    //
    // The parser fills this in for symbols inside nested scopes. There are three
    // slot namespaces: regular symbols, label symbols, and private symbols.
    nested_scope_slot: ?u32 = null,

    kind: Kind = Kind.other,

    // Certain symbols must not be renamed or minified. For example, the
    // "arguments" variable is declared by the runtime for every function.
    // Renaming can also break any identifier used inside a "with" statement.
    must_not_be_renamed: bool = false,

    // We automatically generate import items for property accesses off of
    // namespace imports. This lets us remove the expensive namespace imports
    // while bundling in many cases, replacing them with a cheap import item
    // instead:
    //
    //   import * as ns from 'path'
    //   ns.foo()
    //
    // That can often be replaced by this, which avoids needing the namespace:
    //
    //   import {foo} from 'path'
    //   foo()
    //
    // However, if the import is actually missing then we don't want to report a
    // compile-time error like we do for real import items. This status lets us
    // avoid this. We also need to be able to replace such import items with
    // undefined, which this status is also used for.
    import_item_status: ImportItemStatus = ImportItemStatus.none,

    // Sometimes we lower private symbols even if they are supported. For example,
    // consider the following TypeScript code:
    //
    //   class Foo {
    //     #foo = 123
    //     bar = this.#foo
    //   }
    //
    // If "useDefineForClassFields: false" is set in "tsconfig.json", then "bar"
    // must use assignment semantics instead of define semantics. We can compile
    // that to this code:
    //
    //   class Foo {
    //     constructor() {
    //       this.#foo = 123;
    //       this.bar = this.#foo;
    //     }
    //     #foo;
    //   }
    //
    // However, we can't do the same for static fields:
    //
    //   class Foo {
    //     static #foo = 123
    //     static bar = this.#foo
    //   }
    //
    // Compiling these static fields to something like this would be invalid:
    //
    //   class Foo {
    //     static #foo;
    //   }
    //   Foo.#foo = 123;
    //   Foo.bar = Foo.#foo;
    //
    // Thus "#foo" must be lowered even though it's supported. Another case is
    // when we're converting top-level class declarations to class expressions
    // to avoid the TDZ and the class shadowing symbol is referenced within the
    // class body:
    //
    //   class Foo {
    //     static #foo = Foo
    //   }
    //
    // This cannot be converted into something like this:
    //
    //   var Foo = class {
    //     static #foo;
    //   };
    //   Foo.#foo = Foo;
    //
    private_symbol_must_be_lowered: bool = false,

    pub const Kind = enum {

        // An unbound symbol is one that isn't declared in the file it's referenced
        // in. For example, using "window" without declaring it will be unbound.
        unbound,

        // This has special merging behavior. You're allowed to re-declare these
        // symbols more than once in the same scope. These symbols are also hoisted
        // out of the scope they are declared in to the closest containing function
        // or module scope. These are the symbols with this kind:
        //
        // - Function arguments
        // - Function statements
        // - Variables declared using "var"
        //
        hoisted,
        hoisted_function,

        // There's a weird special case where catch variables declared using a simple
        // identifier (i.e. not a binding pattern) block hoisted variables instead of
        // becoming an error:
        //
        //   var e = 0;
        //   try { throw 1 } catch (e) {
        //     print(e) // 1
        //     var e = 2
        //     print(e) // 2
        //   }
        //   print(e) // 0 (since the hoisting stops at the catch block boundary)
        //
        // However, other forms are still a syntax error:
        //
        //   try {} catch (e) { let e }
        //   try {} catch ({e}) { var e }
        //
        // This symbol is for handling this weird special case.
        catch_identifier,

        // Generator and async functions are not hoisted, but still have special
        // properties such as being able to overwrite previous functions with the
        // same name
        generator_or_async_function,

        // This is the special "arguments" variable inside functions
        arguments,

        // Classes can merge with TypeScript namespaces.
        class,

        // A class-private identifier (i.e. "#foo").
        private_field,
        private_method,
        private_get,
        private_set,
        private_get_set_pair,
        private_static_field,
        private_static_method,
        private_static_get,
        private_static_set,
        private_static_get_set_pair,

        // Labels are in their own namespace
        label,

        // TypeScript enums can merge with TypeScript namespaces and other TypeScript
        // enums.
        ts_enum,

        // TypeScript namespaces can merge with classes, functions, TypeScript enums,
        // and other TypeScript namespaces.
        ts_namespace,

        // In TypeScript, imports are allowed to silently collide with symbols within
        // the module. Presumably this is because the imports may be type-only.
        import,

        // Assigning to a "const" symbol will throw a TypeError at runtime
        cconst,

        // This annotates all other symbols that don't have special behavior.
        other,
    };

    pub const Use = struct {
        count_estimate: u32 = 0,
    };

    pub const Map = struct {
        // This could be represented as a "map[Ref]Symbol" but a two-level array was
        // more efficient in profiles. This appears to be because it doesn't involve
        // a hash. This representation also makes it trivial to quickly merge symbol
        // maps from multiple files together. Each file only generates symbols in a
        // single inner array, so you can join the maps together by just make a
        // single outer array containing all of the inner arrays. See the comment on
        // "Ref" for more detail.
        symbols_for_source: [][]Symbol = undefined,

        pub fn get(self: *Map, ref: Ref) ?Symbol {
            self.symbols_for_source[ref.source_index][ref.inner_index];
        }

        pub fn init(sourceCount: usize, allocator: *std.mem.Allocator) !Map {
            var symbols_for_source: [][]Symbol = try allocator.alloc([]Symbol, sourceCount);
            return Map{ .symbols_for_source = symbols_for_source };
        }
    };

    pub fn isKindPrivate(kind: Symbol.Kind) bool {
        return kind >= Symbol.Kind.private_field and kind <= Symbol.Kind.private_static_get_set_pair;
    }

    pub fn isKindHoisted(kind: Symbol.Kind) bool {
        return kind == Symbol.Kind.hoisted or kind == Symbol.Kind.hoisted_function;
    }

    pub fn isHoisted(self: *Symbol) bool {
        return Symbol.isKindHoisted(self.kind);
    }

    pub fn isKindHoistedOrFunction(kind: Symbol.Kind) bool {
        return isKindHoisted(kind) or kind == Symbol.Kind.generator_or_async_function;
    }

    pub fn isKindFunction(kind: Symbol.Kind) bool {
        return kind == Symbol.Kind.hoisted_function or kind == Symbol.Kind.generator_or_async_function;
    }
};

pub const OptionalChain = packed enum(u2) {

// "a?.b"
start,

// "a?.b.c" => ".c" is OptionalChainContinue
// "(a?.b).c" => ".c" is OptionalChain null
ccontinue };

pub const E = struct {
    pub const Array = struct {
        items: ExprNodeList,
        comma_after_spread: ?logger.Loc = null,
        is_single_line: bool = false,
        is_parenthesized: bool = false,
    };

    pub const Unary = struct {
        op: Op.Code,
        value: ExprNodeIndex,
    };

    pub const Binary = struct {
        left: ExprNodeIndex,
        right: ExprNodeIndex,
        op: Op.Code,
    };

    pub const Boolean = struct { value: bool };
    pub const Super = struct {};
    pub const Null = struct {};
    pub const This = struct {};
    pub const Undefined = struct {};
    pub const New = struct {
        target: ExprNodeIndex,
        args: ExprNodeList,

        // True if there is a comment containing "@__PURE__" or "#__PURE__" preceding
        // this call expression. See the comment inside ECall for more details.
        can_be_unwrapped_if_unused: bool = false,
    };
    pub const NewTarget = struct {};
    pub const ImportMeta = struct {};

    pub const Call = struct {
        // Node:
        target: ExprNodeIndex,
        args: ExprNodeList,
        optional_chain: ?OptionalChain = null,
        is_direct_eval: bool = false,

        // True if there is a comment containing "@__PURE__" or "#__PURE__" preceding
        // this call expression. This is an annotation used for tree shaking, and
        // means that the call can be removed if it's unused. It does not mean the
        // call is pure (e.g. it may still return something different if called twice).
        //
        // Note that the arguments are not considered to be part of the call. If the
        // call itself is removed due to this annotation, the arguments must remain
        // if they have side effects.
        can_be_unwrapped_if_unused: bool = false,

        pub fn hasSameFlagsAs(a: *Call, b: *Call) bool {
            return (a.optional_chain == b.optional_chain and
                a.is_direct_eval == b.is_direct_eval and
                a.can_be_unwrapped_if_unused == b.can_be_unwrapped_if_unused);
        }
    };

    pub const Dot = struct {
        // target is Node
        target: ExprNodeIndex,
        name: string,
        name_loc: logger.Loc,
        optional_chain: ?OptionalChain = null,

        // If true, this property access is known to be free of side-effects. That
        // means it can be removed if the resulting value isn't used.
        can_be_removed_if_unused: bool = false,

        // If true, this property access is a function that, when called, can be
        // unwrapped if the resulting value is unused. Unwrapping means discarding
        // the call target but keeping any arguments with side effects.
        call_can_be_unwrapped_if_unused: bool = false,

        pub fn hasSameFlagsAs(a: *Dot, b: *Dot) bool {
            return (a.optional_chain == b.optional_chain and
                a.is_direct_eval == b.is_direct_eval and
                a.can_be_unwrapped_if_unused == b.can_be_unwrapped_if_unused and a.call_can_be_unwrapped_if_unused == b.call_can_be_unwrapped_if_unused);
        }
    };

    pub const Index = struct {
        index: ExprNodeIndex,
        target: ExprNodeIndex,
        optional_chain: ?OptionalChain = null,

        pub fn hasSameFlagsAs(a: *Index, b: *Index) bool {
            return (a.optional_chain == b.optional_chain);
        }
    };

    pub const Arrow = struct {
        args: []G.Arg,
        body: G.FnBody,

        is_async: bool = false,
        has_rest_arg: bool = false,
        prefer_expr: bool = false, // Use shorthand if true and "Body" is a single return statement
    };

    pub const Function = struct { func: G.Fn };

    pub const Identifier = packed struct {
        ref: Ref = Ref.None,

        // If we're inside a "with" statement, this identifier may be a property
        // access. In that case it would be incorrect to remove this identifier since
        // the property access may be a getter or setter with side effects.
        must_keep_due_to_with_stmt: bool = false,

        // If true, this identifier is known to not have a side effect (i.e. to not
        // throw an exception) when referenced. If false, this identifier may or may
        // not have side effects when referenced. This is used to allow the removal
        // of known globals such as "Object" if they aren't used.
        can_be_removed_if_unused: bool = false,

        // If true, this identifier represents a function that, when called, can be
        // unwrapped if the resulting value is unused. Unwrapping means discarding
        // the call target but keeping any arguments with side effects.
        call_can_be_unwrapped_if_unused: bool = false,
    };

    // This is similar to an EIdentifier but it represents a reference to an ES6
    // import item.
    //
    // Depending on how the code is linked, the file containing this EImportIdentifier
    // may or may not be in the same module group as the file it was imported from.
    //
    // If it's the same module group than we can just merge the import item symbol
    // with the corresponding symbol that was imported, effectively renaming them
    // to be the same thing and statically binding them together.
    //
    // But if it's a different module group, then the import must be dynamically
    // evaluated using a property access off the corresponding namespace symbol,
    // which represents the result of a require() call.
    //
    // It's stored as a separate type so it's not easy to confuse with a plain
    // identifier. For example, it'd be bad if code trying to convert "{x: x}" into
    // "{x}" shorthand syntax wasn't aware that the "x" in this case is actually
    // "{x: importedNamespace.x}". This separate type forces code to opt-in to
    // doing this instead of opt-out.
    pub const ImportIdentifier = packed struct {
        ref: Ref,

        // If true, this was originally an identifier expression such as "foo". If
        // false, this could potentially have been a member access expression such
        // as "ns.foo" off of an imported namespace object.
        was_originally_identifier: bool = false,
    };

    // This is similar to EIdentifier but it represents class-private fields and
    // methods. It can be used where computed properties can be used, such as
    // EIndex and Property.
    pub const PrivateIdentifier = struct {
        ref: Ref,
    };

    pub const JSXElement = struct {
        tag: ?ExprNodeIndex = null,
        properties: []G.Property,
        children: ExprNodeList,
    };

    pub const Missing = struct {};

    pub const Number = struct { value: f64 };

    pub const BigInt = struct {
        value: string,
    };

    pub const Object = struct {
        properties: []G.Property,
        comma_after_spread: ?logger.Loc = null,
        is_single_line: bool = false,
        is_parenthesized: bool = false,
    };

    pub const Spread = struct { value: ExprNodeIndex };

    pub const String = struct {
        value: JavascriptString,
        legacy_octal_loc: ?logger.Loc = null,
        prefer_template: bool = false,
    };

    // value is in the Node
    pub const TemplatePart = struct {
        value: ExprNodeIndex,
        tail_loc: logger.Loc,
        tail: JavascriptString,
        tail_raw: string,
    };

    pub const Template = struct {
        tag: ?ExprNodeIndex = null,
        head: JavascriptString,
        head_raw: string, // This is only filled out for tagged template literals
        parts: ?[]TemplatePart = null,
        legacy_octal_loc: logger.Loc = logger.Loc.Empty,
    };

    pub const RegExp = struct {
        value: string,
    };

    pub const Class = G.Class;

    pub const Await = struct { value: ExprNodeIndex };

    pub const Yield = struct {
        value: ?ExprNodeIndex = null,
        is_star: bool = false,
    };

    pub const If = struct {
        test_: ExprNodeIndex,
        yes: ExprNodeIndex,
        no: ExprNodeIndex,
    };

    pub const RequireOrRequireResolve = struct {
        import_record_index: u32,
    };

    pub const Import = struct {
        expr: ExprNodeIndex,
        import_record_index: u32,

        // Comments inside "import()" expressions have special meaning for Webpack.
        // Preserving comments inside these expressions makes it possible to use
        // esbuild as a TypeScript-to-JavaScript frontend for Webpack to improve
        // performance. We intentionally do not interpret these comments in esbuild
        // because esbuild is not Webpack. But we do preserve them since doing so is
        // harmless, easy to maintain, and useful to people. See the Webpack docs for
        // more info: https://webpack.js.org/api/module-methods/#magic-comments.
        leading_interior_comments: []G.Comment,
    };
};

pub const Stmt = struct {
    loc: logger.Loc,
    data: Data,

    pub fn isTypeScript(self: *Stmt) bool {
        return @as(Stmt.Tag, self.data) == .s_type_script;
    }

    pub fn empty() Stmt {
        return Stmt.init(&Stmt.None, logger.Loc.Empty);
    }

    var None = S.Empty{};

    pub fn init(st: anytype, loc: logger.Loc) Stmt {
        if (@typeInfo(@TypeOf(st)) != .Pointer) {
            @compileError("Stmt.init needs a pointer.");
        }

        switch (@TypeOf(st.*)) {
            S.Block => {
                return Stmt{ .loc = loc, .data = Data{ .s_block = st } };
            },
            S.SExpr => {
                return Stmt{ .loc = loc, .data = Data{ .s_expr = st } };
            },
            S.Comment => {
                return Stmt{ .loc = loc, .data = Data{ .s_comment = st } };
            },
            S.Directive => {
                return Stmt{ .loc = loc, .data = Data{ .s_directive = st } };
            },
            S.ExportClause => {
                return Stmt{ .loc = loc, .data = Data{ .s_export_clause = st } };
            },
            S.Empty => {
                return Stmt{ .loc = loc, .data = Data{ .s_empty = st } };
            },
            S.TypeScript => {
                return Stmt{ .loc = loc, .data = Data{ .s_type_script = st } };
            },
            S.Debugger => {
                return Stmt{ .loc = loc, .data = Data{ .s_debugger = st } };
            },
            S.ExportFrom => {
                return Stmt{ .loc = loc, .data = Data{ .s_export_from = st } };
            },
            S.ExportDefault => {
                return Stmt{ .loc = loc, .data = Data{ .s_export_default = st } };
            },
            S.Enum => {
                return Stmt{ .loc = loc, .data = Data{ .s_enum = st } };
            },
            S.Namespace => {
                return Stmt{ .loc = loc, .data = Data{ .s_namespace = st } };
            },
            S.Function => {
                return Stmt{ .loc = loc, .data = Data{ .s_function = st } };
            },
            S.Class => {
                return Stmt{ .loc = loc, .data = Data{ .s_class = st } };
            },
            S.If => {
                return Stmt{ .loc = loc, .data = Data{ .s_if = st } };
            },
            S.For => {
                return Stmt{ .loc = loc, .data = Data{ .s_for = st } };
            },
            S.ForIn => {
                return Stmt{ .loc = loc, .data = Data{ .s_for_in = st } };
            },
            S.ForOf => {
                return Stmt{ .loc = loc, .data = Data{ .s_for_of = st } };
            },
            S.DoWhile => {
                return Stmt{ .loc = loc, .data = Data{ .s_do_while = st } };
            },
            S.While => {
                return Stmt{ .loc = loc, .data = Data{ .s_while = st } };
            },
            S.With => {
                return Stmt{ .loc = loc, .data = Data{ .s_with = st } };
            },
            S.Try => {
                return Stmt{ .loc = loc, .data = Data{ .s_try = st } };
            },
            S.Switch => {
                return Stmt{ .loc = loc, .data = Data{ .s_switch = st } };
            },
            S.Import => {
                return Stmt{ .loc = loc, .data = Data{ .s_import = st } };
            },
            S.Return => {
                return Stmt{ .loc = loc, .data = Data{ .s_return = st } };
            },
            S.Throw => {
                return Stmt{ .loc = loc, .data = Data{ .s_throw = st } };
            },
            S.Local => {
                return Stmt{ .loc = loc, .data = Data{ .s_local = st } };
            },
            S.Break => {
                return Stmt{ .loc = loc, .data = Data{ .s_break = st } };
            },
            S.Continue => {
                return Stmt{ .loc = loc, .data = Data{ .s_continue = st } };
            },
            else => {
                @compileError("Invalid type in Stmt.init");
            },
        }
    }

    pub fn alloc(allocator: *std.mem.Allocator, origData: anytype, loc: logger.Loc) Stmt {
        switch (@TypeOf(origData)) {
            S.Block => {
                var st = allocator.create(S.Block) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_block = st } };
            },
            S.SExpr => {
                var st = allocator.create(S.SExpr) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_expr = st } };
            },
            S.Comment => {
                var st = allocator.create(S.Comment) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_comment = st } };
            },
            S.Directive => {
                var st = allocator.create(S.Directive) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_directive = st } };
            },
            S.ExportClause => {
                var st = allocator.create(S.ExportClause) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_export_clause = st } };
            },
            S.Empty => {
                var st = allocator.create(S.Empty) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_empty = st } };
            },
            S.TypeScript => {
                var st = allocator.create(S.TypeScript) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_type_script = st } };
            },
            S.Debugger => {
                var st = allocator.create(S.Debugger) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_debugger = st } };
            },
            S.ExportFrom => {
                var st = allocator.create(S.ExportFrom) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_export_from = st } };
            },
            S.ExportDefault => {
                var st = allocator.create(S.ExportDefault) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_export_default = st } };
            },
            S.Enum => {
                var st = allocator.create(S.Enum) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_enum = st } };
            },
            S.Namespace => {
                var st = allocator.create(S.Namespace) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_namespace = st } };
            },
            S.Function => {
                var st = allocator.create(S.Function) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_function = st } };
            },
            S.Class => {
                var st = allocator.create(S.Class) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_class = st } };
            },
            S.If => {
                var st = allocator.create(S.If) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_if = st } };
            },
            S.For => {
                var st = allocator.create(S.For) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_for = st } };
            },
            S.ForIn => {
                var st = allocator.create(S.ForIn) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_for_in = st } };
            },
            S.ForOf => {
                var st = allocator.create(S.ForOf) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_for_of = st } };
            },
            S.DoWhile => {
                var st = allocator.create(S.DoWhile) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_do_while = st } };
            },
            S.While => {
                var st = allocator.create(S.While) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_while = st } };
            },
            S.With => {
                var st = allocator.create(S.With) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_with = st } };
            },
            S.Try => {
                var st = allocator.create(S.Try) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_try = st } };
            },
            S.Switch => {
                var st = allocator.create(S.Switch) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_switch = st } };
            },
            S.Import => {
                var st = allocator.create(S.Import) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_import = st } };
            },
            S.Return => {
                var st = allocator.create(S.Return) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_return = st } };
            },
            S.Throw => {
                var st = allocator.create(S.Throw) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_throw = st } };
            },
            S.Local => {
                var st = allocator.create(S.Local) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_local = st } };
            },
            S.Break => {
                var st = allocator.create(S.Break) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_break = st } };
            },
            S.Continue => {
                var st = allocator.create(S.Continue) catch unreachable;
                st.* = origData;
                return Stmt{ .loc = loc, .data = Data{ .s_continue = st } };
            },
            else => {
                @compileError("Invalid type in Stmt.init");
            },
        }
    }

    pub const Tag = packed enum {
        s_block,
        s_comment,
        s_directive,
        s_export_clause,
        s_empty,
        s_type_script,
        s_debugger,
        s_export_from,
        s_export_default,
        s_enum,
        s_namespace,
        s_function,
        s_class,
        s_if,
        s_for,
        s_for_in,
        s_for_of,
        s_do_while,
        s_while,
        s_with,
        s_try,
        s_switch,
        s_import,
        s_return,
        s_throw,
        s_local,
        s_break,
        s_continue,
        s_expr,
    };

    pub const Data = union(Tag) {
        s_block: *S.Block,
        s_expr: *S.SExpr,
        s_comment: *S.Comment,
        s_directive: *S.Directive,
        s_export_clause: *S.ExportClause,
        s_empty: *S.Empty,
        s_type_script: *S.TypeScript,
        s_debugger: *S.Debugger,
        s_export_from: *S.ExportFrom,
        s_export_default: *S.ExportDefault,
        s_enum: *S.Enum,
        s_namespace: *S.Namespace,
        s_function: *S.Function,
        s_class: *S.Class,
        s_if: *S.If,
        s_for: *S.For,
        s_for_in: *S.ForIn,
        s_for_of: *S.ForOf,
        s_do_while: *S.DoWhile,
        s_while: *S.While,
        s_with: *S.With,
        s_try: *S.Try,
        s_switch: *S.Switch,
        s_import: *S.Import,
        s_return: *S.Return,
        s_throw: *S.Throw,
        s_local: *S.Local,
        s_break: *S.Break,
        s_continue: *S.Continue,
    };

    pub fn caresAboutScope(self: *Stmt) bool {
        return switch (self.data) {
            .s_block, .s_empty, .s_debugger, .s_expr, .s_if, .s_for, .s_for_in, .s_for_of, .s_do_while, .s_while, .s_with, .s_try, .s_switch, .s_return, .s_throw, .s_break, .s_continue, .s_directive => {
                return false;
            },

            .s_local => |local| {
                return local.kind != Kind.k_var;
            },
            else => {
                return true;
            },
        };
    }
};

pub const Expr = struct {
    loc: logger.Loc,
    data: Data,

    pub const EFlags = enum { none, ts_decorator };

    pub fn init(exp: anytype, loc: logger.Loc) Expr {
        switch (@TypeOf(exp)) {
            *E.Array => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_array = exp },
                };
            },
            *E.Unary => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_unary = exp },
                };
            },
            *E.Binary => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_binary = exp },
                };
            },
            *E.This => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_this = exp },
                };
            },
            *E.Boolean => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_boolean = exp },
                };
            },
            *E.Super => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_super = exp },
                };
            },
            *E.Null => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_null = exp },
                };
            },
            *E.Undefined => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_undefined = exp },
                };
            },
            *E.New => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_new = exp },
                };
            },
            *E.NewTarget => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_new_target = exp },
                };
            },
            *E.Function => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_function = exp },
                };
            },
            *E.ImportMeta => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_import_meta = exp },
                };
            },
            *E.Call => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_call = exp },
                };
            },
            *E.Dot => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_dot = exp },
                };
            },
            *E.Index => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_index = exp },
                };
            },
            *E.Arrow => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_arrow = exp },
                };
            },
            *E.Identifier => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_identifier = exp },
                };
            },
            *E.ImportIdentifier => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_import_identifier = exp },
                };
            },
            *E.PrivateIdentifier => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_private_identifier = exp },
                };
            },
            *E.JSXElement => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_jsx_element = exp },
                };
            },
            *E.Missing => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_missing = exp },
                };
            },
            *E.Number => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_number = exp },
                };
            },
            *E.BigInt => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_big_int = exp },
                };
            },
            *E.Object => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_object = exp },
                };
            },
            *E.Spread => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_spread = exp },
                };
            },
            *E.String => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_string = exp },
                };
            },
            *E.TemplatePart => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_template_part = exp },
                };
            },
            *E.Class => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_class = exp },
                };
            },
            *E.Template => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_template = exp },
                };
            },
            *E.RegExp => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_reg_exp = exp },
                };
            },
            *E.Await => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_await = exp },
                };
            },
            *E.Yield => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_yield = exp },
                };
            },
            *E.If => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_if = exp },
                };
            },
            *E.RequireOrRequireResolve => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_require_or_require_resolve = exp },
                };
            },
            *E.Import => {
                return Expr{
                    .loc = loc,
                    .data = Data{ .e_import = exp },
                };
            },
            else => {
                @compileError("Expr.init needs a pointer to E.*");
            },
        }
    }

    pub fn alloc(allocator: *std.mem.Allocator, st: anytype, loc: logger.Loc) Expr {
        switch (@TypeOf(st)) {
            E.Array => {
                var dat = allocator.create(E.Array) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_array = dat } };
            },
            E.Class => {
                var dat = allocator.create(E.Class) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_class = dat } };
            },
            E.Unary => {
                var dat = allocator.create(E.Unary) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_unary = dat } };
            },
            E.Binary => {
                var dat = allocator.create(E.Binary) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_binary = dat } };
            },
            E.This => {
                var dat = allocator.create(E.This) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_this = dat } };
            },
            E.Boolean => {
                var dat = allocator.create(E.Boolean) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_boolean = dat } };
            },
            E.Super => {
                var dat = allocator.create(E.Super) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_super = dat } };
            },
            E.Null => {
                var dat = allocator.create(E.Null) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_null = dat } };
            },
            E.Undefined => {
                var dat = allocator.create(E.Undefined) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_undefined = dat } };
            },
            E.New => {
                var dat = allocator.create(E.New) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_new = dat } };
            },
            E.NewTarget => {
                var dat = allocator.create(E.NewTarget) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_new_target = dat } };
            },
            E.Function => {
                var dat = allocator.create(E.Function) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_function = dat } };
            },
            E.ImportMeta => {
                var dat = allocator.create(E.ImportMeta) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_import_meta = dat } };
            },
            E.Call => {
                var dat = allocator.create(E.Call) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_call = dat } };
            },
            E.Dot => {
                var dat = allocator.create(E.Dot) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_dot = dat } };
            },
            E.Index => {
                var dat = allocator.create(E.Index) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_index = dat } };
            },
            E.Arrow => {
                var dat = allocator.create(E.Arrow) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_arrow = dat } };
            },
            E.Identifier => {
                var dat = allocator.create(E.Identifier) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_identifier = dat } };
            },
            E.ImportIdentifier => {
                var dat = allocator.create(E.ImportIdentifier) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_import_identifier = dat } };
            },
            E.PrivateIdentifier => {
                var dat = allocator.create(E.PrivateIdentifier) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_private_identifier = dat } };
            },
            E.JSXElement => {
                var dat = allocator.create(E.JSXElement) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_jsx_element = dat } };
            },
            E.Missing => {
                var dat = allocator.create(E.Missing) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_missing = dat } };
            },
            E.Number => {
                var dat = allocator.create(E.Number) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_number = dat } };
            },
            E.BigInt => {
                var dat = allocator.create(E.BigInt) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_big_int = dat } };
            },
            E.Object => {
                var dat = allocator.create(E.Object) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_object = dat } };
            },
            E.Spread => {
                var dat = allocator.create(E.Spread) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_spread = dat } };
            },
            E.String => {
                var dat = allocator.create(E.String) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_string = dat } };
            },
            E.TemplatePart => {
                var dat = allocator.create(E.TemplatePart) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_template_part = dat } };
            },
            E.Template => {
                var dat = allocator.create(E.Template) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_template = dat } };
            },
            E.RegExp => {
                var dat = allocator.create(E.RegExp) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_reg_exp = dat } };
            },
            E.Await => {
                var dat = allocator.create(E.Await) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_await = dat } };
            },
            E.Yield => {
                var dat = allocator.create(E.Yield) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_yield = dat } };
            },
            E.If => {
                var dat = allocator.create(E.If) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_if = dat } };
            },
            E.RequireOrRequireResolve => {
                var dat = allocator.create(E.RequireOrRequireResolve) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_require_or_require_resolve = dat } };
            },
            E.Import => {
                var dat = allocator.create(E.Import) catch unreachable;
                dat.* = st;
                return Expr{ .loc = loc, .data = Data{ .e_import = dat } };
            },
            else => {
                @compileError("Invalid type passed to Expr.init");
            },
        }
    }

    pub const Tag = packed enum {
        e_array,
        e_unary,
        e_binary,
        e_boolean,
        e_super,
        e_null,
        e_undefined,
        e_new,
        e_function,
        e_new_target,
        e_import_meta,
        e_call,
        e_dot,
        e_index,
        e_arrow,
        e_identifier,
        e_import_identifier,
        e_private_identifier,
        e_jsx_element,
        e_missing,
        e_number,
        e_big_int,
        e_object,
        e_spread,
        e_string,
        e_template_part,
        e_template,
        e_reg_exp,
        e_await,
        e_yield,
        e_if,
        e_require_or_require_resolve,
        e_import,
        e_this,
        e_class,

        pub fn isArray(self: Tag) bool {
            switch (self) {
                .e_array => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isUnary(self: Tag) bool {
            switch (self) {
                .e_unary => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isBinary(self: Tag) bool {
            switch (self) {
                .e_binary => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isThis(self: Tag) bool {
            switch (self) {
                .e_this => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isClass(self: Tag) bool {
            switch (self) {
                .e_class => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isBoolean(self: Tag) bool {
            switch (self) {
                .e_boolean => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isSuper(self: Tag) bool {
            switch (self) {
                .e_super => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isNull(self: Tag) bool {
            switch (self) {
                .e_null => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isUndefined(self: Tag) bool {
            switch (self) {
                .e_undefined => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isNew(self: Tag) bool {
            switch (self) {
                .e_new => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isNewTarget(self: Tag) bool {
            switch (self) {
                .e_new_target => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isFunction(self: Tag) bool {
            switch (self) {
                .e_function => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isImportMeta(self: Tag) bool {
            switch (self) {
                .e_import_meta => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isCall(self: Tag) bool {
            switch (self) {
                .e_call => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isDot(self: Tag) bool {
            switch (self) {
                .e_dot => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isIndex(self: Tag) bool {
            switch (self) {
                .e_index => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isArrow(self: Tag) bool {
            switch (self) {
                .e_arrow => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isIdentifier(self: Tag) bool {
            switch (self) {
                .e_identifier => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isImportIdentifier(self: Tag) bool {
            switch (self) {
                .e_import_identifier => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isPrivateIdentifier(self: Tag) bool {
            switch (self) {
                .e_private_identifier => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isJsxElement(self: Tag) bool {
            switch (self) {
                .e_jsx_element => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isMissing(self: Tag) bool {
            switch (self) {
                .e_missing => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isNumber(self: Tag) bool {
            switch (self) {
                .e_number => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isBigInt(self: Tag) bool {
            switch (self) {
                .e_big_int => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isObject(self: Tag) bool {
            switch (self) {
                .e_object => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isSpread(self: Tag) bool {
            switch (self) {
                .e_spread => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isString(self: Tag) bool {
            switch (self) {
                .e_string => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isTemplatePart(self: Tag) bool {
            switch (self) {
                .e_template_part => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isTemplate(self: Tag) bool {
            switch (self) {
                .e_template => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isRegExp(self: Tag) bool {
            switch (self) {
                .e_reg_exp => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isAwait(self: Tag) bool {
            switch (self) {
                .e_await => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isYield(self: Tag) bool {
            switch (self) {
                .e_yield => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isIf(self: Tag) bool {
            switch (self) {
                .e_if => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isRequireOrRequireResolve(self: Tag) bool {
            switch (self) {
                .e_require_or_require_resolve => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
        pub fn isImport(self: Tag) bool {
            switch (self) {
                .e_import => {
                    return true;
                },
                else => {
                    return false;
                },
            }
        }
    };

    pub fn assign(a: *Expr, b: *Expr, allocator: *std.mem.Allocator) Expr {
        std.debug.assert(a != b);
        return alloc(allocator, E.Binary{
            .op = .bin_assign,
            .left = a.*,
            .right = b.*,
        }, a.loc);
    }
    pub fn at(expr: *Expr, t: anytype, allocator: *std.mem.allocator) callconv(.Inline) Expr {
        return alloc(allocator, t, loc);
    }

    // Wraps the provided expression in the "!" prefix operator. The expression
    // will potentially be simplified to avoid generating unnecessary extra "!"
    // operators. For example, calling this with "!!x" will return "!x" instead
    // of returning "!!!x".
    pub fn not(expr: Expr, allocator: *std.mem.Allocator) Expr {
        return maybeSimplifyNot(&expr, allocator) orelse expr;
    }

    // The given "expr" argument should be the operand of a "!" prefix operator
    // (i.e. the "x" in "!x"). This returns a simplified expression for the
    // whole operator (i.e. the "!x") if it can be simplified, or false if not.
    // It's separate from "Not()" above to avoid allocation on failure in case
    // that is undesired.
    pub fn maybeSimplifyNot(expr: *Expr, allocator: *std.mem.Allocator) ?Expr {
        switch (expr.data) {
            .e_null, .e_undefined => {
                return expr.at(E.Boolean{ .value = true }, allocator);
            },
            .e_boolean => |b| {
                return expr.at(E.Boolean{ .value = b.value }, allocator);
            },
            .e_number => |n| {
                return expr.at(E.Boolean{ .value = (n.value == 0 or std.math.isNan(n.value)) }, allocator);
            },
            .e_big_int => |b| {
                return expr.at(E.Boolean{ .value = strings.eql(b.value, "0") }, allocator);
            },
            .e_function,
            .e_arrow,
            .e_reg_exp,
            => |b| {
                return expr.at(E.Boolean{ .value = false }, allocator);
            },
            // "!!!a" => "!a"
            .e_unary => |un| {
                if (un.op == Op.Code.un_not and isBooleanValue(un.value)) {
                    return un.value.*;
                }
            },
            .e_binary => |*ex| {
                // TODO: evaluate whether or not it is safe to do this mutation since it's modifying in-place.
                // Make sure that these transformations are all safe for special values.
                // For example, "!(a < b)" is not the same as "a >= b" if a and/or b are
                // NaN (or undefined, or null, or possibly other problem cases too).
                switch (ex.op) {
                    Op.Code.bin_loose_eq => {
                        ex.op = .bin_loose_ne;
                        return expr.*;
                    },
                    Op.Code.bin_op_loose_ne => {
                        ex.op = .bin_loose_eq;
                        return expr.*;
                    },
                    Op.Code.bin_op_strict_eq => {
                        ex.op = .bin_strict_ne;
                        return expr.*;
                    },
                    Op.Code.bin_op_strict_ne => {
                        ex.op = .bin_strict_eq;
                        return expr.*;
                    },
                    Op.Code.bin_op_comma => {
                        ex.right = ex.right.not();
                        return expr.*;
                    },
                    else => {},
                }
            },

            else => {},
        }

        return null;
    }

    pub fn assignStmt(a: *Expr, b: *Expr, allocator: *std.mem.Allocator) Stmt {
        return Stmt.alloc(
            allocator,
            S.SExpr{
                .op = .assign,
                .left = a,
                .right = b,
            },
            loc,
        );
    }

    pub const Data = union(Tag) {
        e_array: *E.Array,
        e_unary: *E.Unary,
        e_binary: *E.Binary,
        e_this: *E.This,
        e_class: *E.Class,
        e_boolean: *E.Boolean,
        e_super: *E.Super,
        e_null: *E.Null,
        e_undefined: *E.Undefined,
        e_new: *E.New,
        e_new_target: *E.NewTarget,
        e_function: *E.Function,
        e_import_meta: *E.ImportMeta,
        e_call: *E.Call,
        e_dot: *E.Dot,
        e_index: *E.Index,
        e_arrow: *E.Arrow,
        e_identifier: *E.Identifier,
        e_import_identifier: *E.ImportIdentifier,
        e_private_identifier: *E.PrivateIdentifier,
        e_jsx_element: *E.JSXElement,
        e_missing: *E.Missing,
        e_number: *E.Number,
        e_big_int: *E.BigInt,
        e_object: *E.Object,
        e_spread: *E.Spread,
        e_string: *E.String,
        e_template_part: *E.TemplatePart,
        e_template: *E.Template,
        e_reg_exp: *E.RegExp,
        e_await: *E.Await,
        e_yield: *E.Yield,
        e_if: *E.If,
        e_require_or_require_resolve: *E.RequireOrRequireResolve,
        e_import: *E.Import,

        pub fn isOptionalChain(self: *Expr) bool {
            return switch (self) {
                Expr.e_dot => |dot| dot.optional_chain != null,
                Expr.e_index => |dot| dot.optional_chain != null,
                Expr.e_call => |dot| dot.optional_chain != null,
                else => false,
            };
        }

        pub fn isBooleanValue(self: *Expr) bool {
            // TODO:
            return false;
            // return switch (self) {
            //     Expr.e_boolean => |dot| true,
            //     Expr.e_if => |dot| dot.optional_chain != OptionalChain.none,
            //     Expr.e_call => |dot| dot.optional_chain != OptionalChain.none,
            //     else => false,
            // };
        }

        pub fn isNumericValue(self: *Expr) bool {
            // TODO:

            return false;
        }

        pub fn isStringValue(self: *Expr) bool {
            // TODO:
            return false;
        }
    };
};

pub const EnumValue = struct {
    loc: logger.Loc,
    ref: Ref,
    name: JavascriptString,
    value: ?ExprNodeIndex,
};

pub const S = struct {
    pub const Block = struct { stmts: StmtNodeList };
    pub const SExpr = struct {
        value: ExprNodeIndex,

        // This is set to true for automatically-generated expressions that should
        // not affect tree shaking. For example, calling a function from the runtime
        // that doesn't have externally-visible side effects.
        does_not_affect_tree_shaking: bool,
    };

    pub const Comment = struct { text: string };

    pub const Directive = struct { value: JavascriptString, legacy_octal_loc: logger.Loc };

    pub const ExportClause = struct { items: []ClauseItem };

    pub const Empty = struct {};

    // This is a stand-in for a TypeScript type declaration
    pub const TypeScript = struct {};

    pub const Debugger = struct {};

    pub const ExportFrom = struct {
        items: []ClauseItem,
        namespace_ref: Ref,
        import_record_index: u32,
        is_single_line: bool,
    };

    pub const ExportDefault = struct { default_name: LocRef, // value may be a SFunction or SClass
    value: StmtOrExpr };

    pub const Enum = struct {
        name: LocRef,
        arg: Ref,
        values: []EnumValue,
        is_export: bool,
    };

    pub const Namespace = struct {
        name: LocRef,
        arg: Ref,
        stmts: StmtNodeList,
        is_export: bool,
    };

    pub const Function = struct {
        func: G.Fn,
    };

    pub const Class = struct { class: G.Class, is_export: bool = false };

    pub const If = struct {
        test_: ExprNodeIndex,
        yes: StmtNodeIndex,
        no: ?StmtNodeIndex,
    };

    pub const For = struct {
    // May be a SConst, SLet, SVar, or SExpr
    init: StmtNodeIndex, test_: ?ExprNodeIndex, update: ?ExprNodeIndex, body: StmtNodeIndex };

    pub const ForIn = struct {
    // May be a SConst, SLet, SVar, or SExpr
    init: StmtNodeIndex, value: ExprNodeIndex, body: StmtNodeIndex };

    pub const ForOf = struct { is_await: bool,
    // May be a SConst, SLet, SVar, or SExpr
    init: StmtNodeIndex, value: ExprNodeIndex, body: StmtNodeIndex };

    pub const DoWhile = struct { body: StmtNodeIndex, test_: ExprNodeIndex };

    pub const While = struct {
        test_: ExprNodeIndex,
        body: StmtNodeIndex,
    };

    pub const With = struct {
        value: ExprNodeIndex,
        body: StmtNodeIndex,
        body_loc: logger.Loc,
    };

    pub const Try = struct {
        body_loc: logger.Loc,
        body: StmtNodeList,

        catch_: ?Catch = null,
        finally: ?Finally = null,
    };

    pub const Switch = struct {
        test_: ExprNodeIndex,
        body_loc: logger.Loc,
        cases: []Case,
    };

    // This object represents all of these types of import statements:
    //
    //    import 'path'
    //    import {item1, item2} from 'path'
    //    import * as ns from 'path'
    //    import defaultItem, {item1, item2} from 'path'
    //    import defaultItem, * as ns from 'path'
    //
    // Many parts are optional and can be combined in different ways. The only
    // restriction is that you cannot have both a clause and a star namespace.
    pub const Import = struct {
    // If this is a star import: This is a Ref for the namespace symbol. The Loc
    // for the symbol is StarLoc.
    //
    // Otherwise: This is an auto-generated Ref for the namespace representing
    // the imported file. In this case StarLoc is nil. The NamespaceRef is used
    // when converting this module to a CommonJS module.
    namespace_ref: Ref, default_name: *LocRef, items: *[]ClauseItem, star_name_loc: *logger.Loc, import_record_index: u32, is_single_line: bool };

    pub const Return = struct { value: ?ExprNodeIndex = null };
    pub const Throw = struct { value: ExprNodeIndex };

    pub const Local = struct {
        kind: Kind = Kind.k_var,
        decls: []G.Decl,
        is_export: bool = false,
        // The TypeScript compiler doesn't generate code for "import foo = bar"
        // statements where the import is never used.
        was_ts_import_equals: bool = false,

        pub const Kind = enum {
            k_var,
            k_let,
            k_const,
        };
    };

    pub const Break = struct {
        label: ?LocRef = null,
    };

    pub const Continue = struct {
        label: ?LocRef = null,
    };
};

pub const Catch = struct {
    loc: logger.Loc,
    binding: ?BindingNodeIndex = null,
    body: StmtNodeList,
};

pub const Finally = struct {
    loc: logger.Loc,
    stmts: StmtNodeList,
};

pub const Case = struct { loc: logger.Loc, value: ?ExprNodeIndex, body: StmtNodeList };

pub const Op = struct {
    // If you add a new token, remember to add it to "OpTable" too
    pub const Code = packed enum(u6) {
        // Prefix
        un_pos,
        un_neg,
        un_cpl,
        un_not,
        un_void,
        un_typeof,
        un_delete,

        // Prefix update
        un_pre_dec,
        un_pre_inc,

        // Postfix update
        un_post_dec,
        un_post_inc,

        // Left-associative
        bin_add,
        bin_sub,
        bin_mul,
        bin_div,
        bin_rem,
        bin_pow,
        bin_lt,
        bin_le,
        bin_gt,
        bin_ge,
        bin_in,
        bin_instanceof,
        bin_shl,
        bin_shr,
        bin_u_shr,
        bin_loose_eq,
        bin_loose_ne,
        bin_strict_eq,
        bin_strict_ne,
        bin_nullish_coalescing,
        bin_logical_or,
        bin_logical_and,
        bin_bitwise_or,
        bin_bitwise_and,
        bin_bitwise_xor,

        // Non-associative
        bin_comma,

        // Right-associative
        bin_assign,
        bin_add_assign,
        bin_sub_assign,
        bin_mul_assign,
        bin_div_assign,
        bin_rem_assign,
        bin_pow_assign,
        bin_shl_assign,
        bin_shr_assign,
        bin_u_shr_assign,
        bin_bitwise_or_assign,
        bin_bitwise_and_assign,
        bin_bitwise_xor_assign,
        bin_nullish_coalescing_assign,
        bin_logical_or_assign,
        bin_logical_and_assign,
    };

    pub const Level = packed enum(u6) {
        lowest,
        comma,
        spread,
        yield,
        assign,
        conditional,
        nullish_coalescing,
        logical_or,
        logical_and,
        bitwise_or,
        bitwise_xor,
        bitwise_and,
        equals,
        compare,
        shift,
        add,
        multiply,
        exponentiation,
        prefix,
        postfix,
        new,
        call,
        member,
        pub fn lt(self: Level, b: Level) callconv(.Inline) bool {
            return @enumToInt(self) < @enumToInt(b);
        }
        pub fn gt(self: Level, b: Level) callconv(.Inline) bool {
            return @enumToInt(self) > @enumToInt(b);
        }
        pub fn gte(self: Level, b: Level) callconv(.Inline) bool {
            return @enumToInt(self) >= @enumToInt(b);
        }
        pub fn lte(self: Level, b: Level) callconv(.Inline) bool {
            return @enumToInt(self) <= @enumToInt(b);
        }
        pub fn eql(self: Level, b: Level) callconv(.Inline) bool {
            return @enumToInt(self) == @enumToInt(b);
        }

        pub fn sub(self: Level, comptime i: anytype) callconv(.Inline) Level {
            return @intToEnum(Level, @enumToInt(self) - i);
        }

        pub fn add(self: Level, comptime i: anytype) callconv(.Inline) Level {
            return @intToEnum(Level, @enumToInt(self) + i);
        }
    };

    text: string,
    level: Level,
    is_keyword: bool = false,

    const Table = []Op{
        // Prefix
        .{ "+", Level.prefix, false },
        .{ "-", Level.prefix, false },
        .{ "~", Level.prefix, false },
        .{ "!", Level.prefix, false },
        .{ "void", Level.prefix, true },
        .{ "typeof", Level.prefix, true },
        .{ "delete", Level.prefix, true },

        // Prefix update
        .{ "--", Level.prefix, false },
        .{ "++", Level.prefix, false },

        // Postfix update
        .{ "--", Level.postfix, false },
        .{ "++", Level.postfix, false },

        // Left-associative
        .{ "+", Level.add, false },
        .{ "-", Level.add, false },
        .{ "*", Level.multiply, false },
        .{ "/", Level.multiply, false },
        .{ "%", Level.multiply, false },
        .{ "**", Level.exponentiation, false }, // Right-associative
        .{ "<", Level.compare, false },
        .{ "<=", Level.compare, false },
        .{ ">", Level.compare, false },
        .{ ">=", Level.compare, false },
        .{ "in", Level.compare, true },
        .{ "instanceof", Level.compare, true },
        .{ "<<", Level.shift, false },
        .{ ">>", Level.shift, false },
        .{ ">>>", Level.shift, false },
        .{ "==", Level.equals, false },
        .{ "!=", Level.equals, false },
        .{ "===", Level.equals, false },
        .{ "!==", Level.equals, false },
        .{ "??", Level.nullish_coalescing, false },
        .{ "||", Level.logical_or, false },
        .{ "&&", Level.logical_and, false },
        .{ "|", Level.bitwise_or, false },
        .{ "&", Level.bitwise_and, false },
        .{ "^", Level.bitwise_xor, false },

        // Non-associative
        .{ ",", LComma, false },

        // Right-associative
        .{ "=", Level.assign, false },
        .{ "+=", Level.assign, false },
        .{ "-=", Level.assign, false },
        .{ "*=", Level.assign, false },
        .{ "/=", Level.assign, false },
        .{ "%=", Level.assign, false },
        .{ "**=", Level.assign, false },
        .{ "<<=", Level.assign, false },
        .{ ">>=", Level.assign, false },
        .{ ">>>=", Level.assign, false },
        .{ "|=", Level.assign, false },
        .{ "&=", Level.assign, false },
        .{ "^=", Level.assign, false },
        .{ "??=", Level.assign, false },
        .{ "||=", Level.assign, false },
        .{ "&&=", Level.assign, false },
    };
};

pub const ArrayBinding = struct {
    binding: BindingNodeIndex,
    default_value: ?ExprNodeIndex,
};

pub const Ast = struct {
    approximate_line_count: i32 = 0,
    has_lazy_export: bool = false,

    // This is a list of CommonJS features. When a file uses CommonJS features,
    // it's not a candidate for "flat bundling" and must be wrapped in its own
    // closure.
    has_top_level_return: bool = false,
    uses_exports_ref: bool = false,
    uses_module_ref: bool = false,
    exports_kind: ExportsKind = ExportsKind.none,

    // This is a list of ES6 features. They are ranges instead of booleans so
    // that they can be used in log messages. Check to see if "Len > 0".
    import_keyword: ?logger.Range = null, // Does not include TypeScript-specific syntax or "import()"
    export_keyword: ?logger.Range = null, // Does not include TypeScript-specific syntax
    top_level_await_keyword: ?logger.Range = null,

    // These are stored at the AST level instead of on individual AST nodes so
    // they can be manipulated efficiently without a full AST traversal
    import_records: ?[]ImportRecord = null,

    hashbang: ?string = null,
    directive: ?string = null,
    url_for_css: ?string = null,
    parts: std.ArrayList(Part),
    symbols: std.ArrayList(Symbol),
    module_scope: ?Scope,
    // char_freq:    *CharFreq,
    exports_ref: ?Ref,
    module_ref: ?Ref,
    wrapper_ref: ?Ref,

    // These are used when bundling. They are filled in during the parser pass
    // since we already have to traverse the AST then anyway and the parser pass
    // is conveniently fully parallelized.
    named_imports: std.AutoHashMap(Ref, NamedImport),
    named_exports: std.StringHashMap(NamedExport),
    top_level_symbol_to_parts: std.AutoHashMap(Ref, []u32),
    export_star_import_records: std.ArrayList(u32),
};

pub const Span = struct {
    text: string,
    range: logger.Range,
};

pub const ExportsKind = enum {
// This file doesn't have any kind of export, so it's impossible to say what
// kind of file this is. An empty file is in this category, for example.
none,

// The exports are stored on "module" and/or "exports". Calling "require()"
// on this module returns "module.exports". All imports to this module are
// allowed but may return undefined.
cjs,

// All export names are known explicitly. Calling "require()" on this module
// generates an exports object (stored in "exports") with getters for the
// export names. Named imports to this module are only allowed if they are
// in the set of export names.
esm,

// Some export names are known explicitly, but others fall back to a dynamic
// run-time object. This is necessary when using the "export * from" syntax
// with either a CommonJS module or an external module (i.e. a module whose
// export names are not known at compile-time).
//
// Calling "require()" on this module generates an exports object (stored in
// "exports") with getters for the export names. All named imports to this
// module are allowed. Direct named imports reference the corresponding export
// directly. Other imports go through property accesses on "exports".
esm_with_dyn };

pub fn isDynamicExport(exp: ExportsKind) bool {
    return kind == .cjs || kind == .esm_with_dyn;
}

pub const DeclaredSymbol = packed struct {
    ref: Ref,
    is_top_level: bool = false,
};

pub const Dependency = packed struct {
    source_index: u32 = 0,
    part_index: u32 = 0,
};

pub const ExprList = std.ArrayList(Expr);
pub const StmtList = std.ArrayList(Stmt);
pub const BindingList = std.ArrayList(Binding);
pub const AstData = struct {
    expr_list: ExprList,
    stmt_list: StmtList,
    binding_list: BindingList,

    pub fn init(allocator: *std.mem.Allocator) AstData {
        return AstData{
            .expr_list = ExprList.init(allocator),
            .stmt_list = StmtList.init(allocator),
            .binding_list = BindingList.init(allocator),
        };
    }

    pub fn deinit(self: *AstData) void {
        self.expr_list.deinit();
        self.stmt_list.deinit();
        self.binding_list.deinit();
    }

    pub fn expr(self: *AstData, index: ExprNodeIndex) Expr {
        return self.expr_list.items[index];
    }

    pub fn stmt(self: *AstData, index: StmtNodeIndex) Stmt {
        return self.stmt_list.items[index];
    }

    pub fn binding(self: *AstData, index: BindingNodeIndex) Binding {
        return self.binding_list.items[index];
    }

    pub fn add_(self: *AstData, t: anytype) !void {
        return switch (@TypeOf(t)) {
            Stmt => {
                try self.stmt_list.append(t);
            },
            Expr => {
                try self.expr_list.append(t);
            },
            Binding => {
                try self.binding_list.append(t);
            },
            else => {
                @compileError("Invalid type passed to AstData.add. Expected Stmt, Expr, or Binding.");
            },
        };
    }

    pub fn add(self: *AstData, t: anytype) !NodeIndex {
        return &t;
        // return switch (@TypeOf(t)) {
        //     Stmt => {
        //         var len = self.stmt_list.items.len;
        //         try self.stmt_list.append(t);
        //         return @intCast(StmtNodeIndex, len);
        //     },
        //     Expr => {
        //         var len = self.expr_list.items.len;
        //         try self.expr_list.append(t);
        //         return @intCast(ExprNodeIndex, len);
        //     },
        //     Binding => {
        //         var len = self.binding_list.items.len;
        //         try self.binding_list.append(t);
        //         return @intCast(BindingNodeIndex, len);
        //     },
        //     else => {
        //         @compileError("Invalid type passed to AstData.add. Expected Stmt, Expr, or Binding.");
        //     },
        // };
    }
};

// Each file is made up of multiple parts, and each part consists of one or
// more top-level statements. Parts are used for tree shaking and code
// splitting analysis. Individual parts of a file can be discarded by tree
// shaking and can be assigned to separate chunks (i.e. output files) by code
// splitting.
pub const Part = struct {
    stmts: []Stmt,
    expr: []Expr,
    bindings: []Binding,
    scopes: []*Scope,

    // Each is an index into the file-level import record list
    import_record_indices: std.ArrayList(u32),

    // All symbols that are declared in this part. Note that a given symbol may
    // have multiple declarations, and so may end up being declared in multiple
    // parts (e.g. multiple "var" declarations with the same name). Also note
    // that this list isn't deduplicated and may contain duplicates.
    declared_symbols: std.ArrayList(DeclaredSymbol),

    // An estimate of the number of uses of all symbols used within this part.
    symbol_uses: std.AutoHashMap(Ref, Symbol.Use),

    // The indices of the other parts in this file that are needed if this part
    // is needed.
    dependencies: std.ArrayList(Dependency),

    // If true, this part can be removed if none of the declared symbols are
    // used. If the file containing this part is imported, then all parts that
    // don't have this flag enabled must be included.
    can_be_removed_if_unused: bool = false,

    // This is used for generated parts that we don't want to be present if they
    // aren't needed. This enables tree shaking for these parts even if global
    // tree shaking isn't enabled.
    force_tree_shaking: bool = false,

    // This is true if this file has been marked as live by the tree shaking
    // algorithm.
    is_live: bool = false,

    pub fn stmtAt(self: *Part, index: StmtNodeIndex) ?Stmt {
        if (std.builtin.mode == std.builtin.Mode.ReleaseFast) {
            return self.stmts[@intCast(usize, index)];
        } else {
            if (self.stmts.len > index) {
                return self.stmts[@intCast(usize, index)];
            }

            return null;
        }
    }

    pub fn exprAt(self: *Part, index: ExprNodeIndex) ?Expr {
        if (std.builtin.mode == std.builtin.Mode.ReleaseFast) {
            return self.expr[@intCast(usize, index)];
        } else {
            if (self.expr.len > index) {
                return self.expr[@intCast(usize, index)];
            }

            return null;
        }
    }
};

pub const StmtOrExpr = union(enum) {
    stmt: StmtNodeIndex,
    expr: ExprNodeIndex,
};

pub const NamedImport = struct {
    // Parts within this file that use this import
    local_parts_with_uses: ?[]u32,

    alias: ?string,
    alias_loc: ?logger.Loc,
    namespace_ref: ?Ref,
    import_record_index: u32,

    // If true, the alias refers to the entire export namespace object of a
    // module. This is no longer represented as an alias called "*" because of
    // the upcoming "Arbitrary module namespace identifier names" feature:
    // https://github.com/tc39/ecma262/pull/2154
    alias_is_star: bool = false,

    // It's useful to flag exported imports because if they are in a TypeScript
    // file, we can't tell if they are a type or a value.
    is_exported: bool = false,
};

pub const NamedExport = struct {
    ref: Ref,
    alias_loc: logger.Loc,
};

pub const StrictModeKind = packed enum(u7) {
    sloppy_mode,
    explicit_strict_mode,
    implicit_strict_mode_import,
    implicit_strict_mode_export,
    implicit_strict_mode_top_level_await,
    implicit_strict_mode_class,
};

pub const Scope = struct {
    kind: Kind = Kind.block,
    parent: ?*Scope,
    children: std.ArrayList(*Scope),
    members: std.StringHashMap(Member),
    generated: std.ArrayList(Ref),

    // This is used to store the ref of the label symbol for ScopeLabel scopes.
    label_ref: ?Ref = null,
    label_stmt_is_loop: bool = false,

    // If a scope contains a direct eval() expression, then none of the symbols
    // inside that scope can be renamed. We conservatively assume that the
    // evaluated code might reference anything that it has access to.
    contains_direct_eval: bool = false,

    // This is to help forbid "arguments" inside class body scopes
    forbid_arguments: bool = false,

    strict_mode: StrictModeKind = StrictModeKind.sloppy_mode,

    pub const Member = struct { ref: Ref, loc: logger.Loc };
    pub const Kind = enum(u8) {
        block,
        with,
        label,
        class_name,
        class_body,

        // The scopes below stop hoisted variables from extending into parent scopes
        entry, // This is a module, TypeScript enum, or TypeScript namespace
        function_args,
        function_body,
    };

    pub fn recursiveSetStrictMode(s: *Scope, kind: StrictModeKind) void {
        if (s.strict_mode == .sloppy_mode) {
            s.strict_mode = kind;
            for (s.children.items) |child| {
                child.recursiveSetStrictMode(kind);
            }
        }
    }

    pub fn kindStopsHoisting(s: *Scope) bool {
        return @enumToInt(s.kind) > @enumToInt(Kind.entry);
    }

    pub fn initPtr(allocator: *std.mem.Allocator) !*Scope {
        var scope = try allocator.create(Scope);
        scope.members = @TypeOf(scope.members).init(allocator);
        return scope;
    }
};

test "Binding.init" {
    var binding = Binding.alloc(
        std.heap.page_allocator,
        B.Identifier{ .ref = Ref{ .source_index = 0, .inner_index = 10 } },
        logger.Loc{ .start = 1 },
    );
    std.testing.expect(binding.loc.start == 1);
    std.testing.expect(@as(Binding.Tag, binding.data) == Binding.Tag.b_identifier);

    std.debug.print("-------Binding:           {d} bits\n", .{@bitSizeOf(Binding)});
    std.debug.print("B.Identifier:             {d} bits\n", .{@bitSizeOf(B.Identifier)});
    std.debug.print("B.Array:                  {d} bits\n", .{@bitSizeOf(B.Array)});
    std.debug.print("B.Property:               {d} bits\n", .{@bitSizeOf(B.Property)});
    std.debug.print("B.Object:                 {d} bits\n", .{@bitSizeOf(B.Object)});
    std.debug.print("B.Missing:                {d} bits\n", .{@bitSizeOf(B.Missing)});
    std.debug.print("-------Binding:           {d} bits\n", .{@bitSizeOf(Binding)});
}

test "Stmt.init" {
    var stmt = Stmt.alloc(
        std.heap.page_allocator,
        S.Continue{},
        logger.Loc{ .start = 1 },
    );
    std.testing.expect(stmt.loc.start == 1);
    std.testing.expect(@as(Stmt.Tag, stmt.data) == Stmt.Tag.s_continue);

    std.debug.print("-----Stmt       {d} bits\n", .{@bitSizeOf(Stmt)});
    std.debug.print("StmtNodeList:   {d} bits\n", .{@bitSizeOf(StmtNodeList)});
    std.debug.print("StmtOrExpr:     {d} bits\n", .{@bitSizeOf(StmtOrExpr)});
    std.debug.print("S.Block         {d} bits\n", .{@bitSizeOf(S.Block)});
    std.debug.print("S.Comment       {d} bits\n", .{@bitSizeOf(S.Comment)});
    std.debug.print("S.Directive     {d} bits\n", .{@bitSizeOf(S.Directive)});
    std.debug.print("S.ExportClause  {d} bits\n", .{@bitSizeOf(S.ExportClause)});
    std.debug.print("S.Empty         {d} bits\n", .{@bitSizeOf(S.Empty)});
    std.debug.print("S.TypeScript    {d} bits\n", .{@bitSizeOf(S.TypeScript)});
    std.debug.print("S.Debugger      {d} bits\n", .{@bitSizeOf(S.Debugger)});
    std.debug.print("S.ExportFrom    {d} bits\n", .{@bitSizeOf(S.ExportFrom)});
    std.debug.print("S.ExportDefault {d} bits\n", .{@bitSizeOf(S.ExportDefault)});
    std.debug.print("S.Enum          {d} bits\n", .{@bitSizeOf(S.Enum)});
    std.debug.print("S.Namespace     {d} bits\n", .{@bitSizeOf(S.Namespace)});
    std.debug.print("S.Function      {d} bits\n", .{@bitSizeOf(S.Function)});
    std.debug.print("S.Class         {d} bits\n", .{@bitSizeOf(S.Class)});
    std.debug.print("S.If            {d} bits\n", .{@bitSizeOf(S.If)});
    std.debug.print("S.For           {d} bits\n", .{@bitSizeOf(S.For)});
    std.debug.print("S.ForIn         {d} bits\n", .{@bitSizeOf(S.ForIn)});
    std.debug.print("S.ForOf         {d} bits\n", .{@bitSizeOf(S.ForOf)});
    std.debug.print("S.DoWhile       {d} bits\n", .{@bitSizeOf(S.DoWhile)});
    std.debug.print("S.While         {d} bits\n", .{@bitSizeOf(S.While)});
    std.debug.print("S.With          {d} bits\n", .{@bitSizeOf(S.With)});
    std.debug.print("S.Try           {d} bits\n", .{@bitSizeOf(S.Try)});
    std.debug.print("S.Switch        {d} bits\n", .{@bitSizeOf(S.Switch)});
    std.debug.print("S.Import        {d} bits\n", .{@bitSizeOf(S.Import)});
    std.debug.print("S.Return        {d} bits\n", .{@bitSizeOf(S.Return)});
    std.debug.print("S.Throw         {d} bits\n", .{@bitSizeOf(S.Throw)});
    std.debug.print("S.Local         {d} bits\n", .{@bitSizeOf(S.Local)});
    std.debug.print("S.Break         {d} bits\n", .{@bitSizeOf(S.Break)});
    std.debug.print("S.Continue      {d} bits\n", .{@bitSizeOf(S.Continue)});
    std.debug.print("-----Stmt       {d} bits\n", .{@bitSizeOf(Stmt)});
}

test "Expr.init" {
    var allocator = std.heap.page_allocator;
    const ident = Expr.alloc(allocator, E.Identifier{}, logger.Loc{ .start = 100 });
    var list = [_]Expr{ident};
    var expr = Expr.alloc(
        allocator,
        E.Array{ .items = list[0..] },
        logger.Loc{ .start = 1 },
    );
    std.testing.expect(expr.loc.start == 1);
    std.testing.expect(@as(Expr.Tag, expr.data) == Expr.Tag.e_array);
    std.testing.expect(expr.data.e_array.items[0].loc.start == 100);

    std.debug.print("--Ref                      {d} bits\n", .{@bitSizeOf(Ref)});
    std.debug.print("--LocRef                   {d} bits\n", .{@bitSizeOf(LocRef)});
    std.debug.print("--logger.Loc               {d} bits\n", .{@bitSizeOf(logger.Loc)});
    std.debug.print("--logger.Range             {d} bits\n", .{@bitSizeOf(logger.Range)});
    std.debug.print("----------Expr:            {d} bits\n", .{@bitSizeOf(Expr)});
    std.debug.print("ExprNodeList:              {d} bits\n", .{@bitSizeOf(ExprNodeList)});
    std.debug.print("E.Array:                   {d} bits\n", .{@bitSizeOf(E.Array)});

    std.debug.print("E.Unary:                   {d} bits\n", .{@bitSizeOf(E.Unary)});
    std.debug.print("E.Binary:                  {d} bits\n", .{@bitSizeOf(E.Binary)});
    std.debug.print("E.Boolean:                 {d} bits\n", .{@bitSizeOf(E.Boolean)});
    std.debug.print("E.Super:                   {d} bits\n", .{@bitSizeOf(E.Super)});
    std.debug.print("E.Null:                    {d} bits\n", .{@bitSizeOf(E.Null)});
    std.debug.print("E.Undefined:               {d} bits\n", .{@bitSizeOf(E.Undefined)});
    std.debug.print("E.New:                     {d} bits\n", .{@bitSizeOf(E.New)});
    std.debug.print("E.NewTarget:               {d} bits\n", .{@bitSizeOf(E.NewTarget)});
    std.debug.print("E.Function:                {d} bits\n", .{@bitSizeOf(E.Function)});
    std.debug.print("E.ImportMeta:              {d} bits\n", .{@bitSizeOf(E.ImportMeta)});
    std.debug.print("E.Call:                    {d} bits\n", .{@bitSizeOf(E.Call)});
    std.debug.print("E.Dot:                     {d} bits\n", .{@bitSizeOf(E.Dot)});
    std.debug.print("E.Index:                   {d} bits\n", .{@bitSizeOf(E.Index)});
    std.debug.print("E.Arrow:                   {d} bits\n", .{@bitSizeOf(E.Arrow)});
    std.debug.print("E.Identifier:              {d} bits\n", .{@bitSizeOf(E.Identifier)});
    std.debug.print("E.ImportIdentifier:        {d} bits\n", .{@bitSizeOf(E.ImportIdentifier)});
    std.debug.print("E.PrivateIdentifier:       {d} bits\n", .{@bitSizeOf(E.PrivateIdentifier)});
    std.debug.print("E.JSXElement:              {d} bits\n", .{@bitSizeOf(E.JSXElement)});
    std.debug.print("E.Missing:                 {d} bits\n", .{@bitSizeOf(E.Missing)});
    std.debug.print("E.Number:                  {d} bits\n", .{@bitSizeOf(E.Number)});
    std.debug.print("E.BigInt:                  {d} bits\n", .{@bitSizeOf(E.BigInt)});
    std.debug.print("E.Object:                  {d} bits\n", .{@bitSizeOf(E.Object)});
    std.debug.print("E.Spread:                  {d} bits\n", .{@bitSizeOf(E.Spread)});
    std.debug.print("E.String:                  {d} bits\n", .{@bitSizeOf(E.String)});
    std.debug.print("E.TemplatePart:            {d} bits\n", .{@bitSizeOf(E.TemplatePart)});
    std.debug.print("E.Template:                {d} bits\n", .{@bitSizeOf(E.Template)});
    std.debug.print("E.RegExp:                  {d} bits\n", .{@bitSizeOf(E.RegExp)});
    std.debug.print("E.Await:                   {d} bits\n", .{@bitSizeOf(E.Await)});
    std.debug.print("E.Yield:                   {d} bits\n", .{@bitSizeOf(E.Yield)});
    std.debug.print("E.If:                      {d} bits\n", .{@bitSizeOf(E.If)});
    std.debug.print("E.RequireOrRequireResolve: {d} bits\n", .{@bitSizeOf(E.RequireOrRequireResolve)});
    std.debug.print("E.Import:                  {d} bits\n", .{@bitSizeOf(E.Import)});
    std.debug.print("----------Expr:            {d} bits\n", .{@bitSizeOf(Expr)});
}

// -- ESBuild bit sizes
// EArray             | 256
// EArrow             | 512
// EAwait             | 192
// EBinary            | 448
// ECall              | 448
// EDot               | 384
// EIdentifier        | 96
// EIf                | 576
// EImport            | 448
// EImportIdentifier  | 96
// EIndex             | 448
// EJSXElement        | 448
// ENew               | 448
// EnumValue          | 384
// EObject            | 256
// EPrivateIdentifier | 64
// ERequire           | 32
// ERequireResolve    | 32
// EString            | 256
// ETemplate          | 640
// EUnary             | 256
// Expr               | 192
// ExprOrStmt         | 128
// EYield             | 128
// Finally            | 256
// Fn                 | 704
// FnBody             | 256
// LocRef             | 96
// NamedExport        | 96
// NamedImport        | 512
// NameMinifier       | 256
// NamespaceAlias     | 192
// opTableEntry       | 256
// Part               | 1088
// Property           | 640
// PropertyBinding    | 512
// Ref                | 64
// SBlock             | 192
// SBreak             | 64
// SClass             | 704
// SComment           | 128
// SContinue          | 64
// Scope              | 704
// ScopeMember        | 96
// SDirective         | 256
// SDoWhile           | 384
// SEnum              | 448
// SExportClause      | 256
// SExportDefault     | 256
// SExportEquals      | 192
// SExportFrom        | 320
// SExportStar        | 192
// SExpr              | 256
// SFor               | 384
// SForIn             | 576
// SForOf             | 640
// SFunction          | 768
// SIf                | 448
// SImport            | 320
// SLabel             | 320
// SLazyExport        | 192
// SLocal             | 256
// SNamespace         | 448
// Span               | 192
// SReturn            | 64
// SSwitch            | 448
// SThrow             | 192
// Stmt               | 192
// STry               | 384
// -- ESBuild bit sizes
