import Base

enum ObjcTerm {
  struct TypeName: ExpressibleByStringLiteral, CustomStringConvertible {
    let name: StaticString

    init(stringLiteral value: StaticString) { name = value }
    var description: String { return name.description }

    static let int: TypeName = "int"
    static let void: TypeName = "void"
  }

  typealias NotImplemented = Never
  enum Import {
    case angleBrackets(path: String)
    case doubleQuotes(path: String)
  }

  indirect enum Expr {
    enum BinOp: String {
      case less = "<"
    }

    enum PostfixOp: String {
      case incr = "++"
    }

    enum UnaryOp: String {
      case address = "&"
    }

    case cast(to: TypeName, Expr)
    case member(String, Expr)
    case call(Expr, args: [Expr])
    case `subscript`(Expr, idx: Expr)
    case bin(lhs: Expr, op: BinOp, rhs: Expr)
    case postfix(e: Expr, op: PostfixOp)
    case unary(op: UnaryOp, e: Expr)

    case const(raw: String)
    case identifier(String)
    case list(type: TypeName, [Expr])
  }

  enum Statement {
    enum BlockItem {
      case decl(CDecl)
      case stmnt(Statement)
    }

    indirect case `for`(init: CDecl, cond: Expr, incr: Expr, body: Statement)
    case expr(Expr)
    case block([BlockItem])
  }

  struct CDecl {
    enum Specifier {
      enum StorageClass: String {
        case typedef
        case `static`
        case extern
      }

      enum TypeSpecifier {
        enum StructOrUnion: String {
          case `struct`
          case union
        }

        struct StructDeclaration {
          var spec: [TypeSpecifier]
          var decl: [Declarator]
        }

        case simple(TypeName)
        case structOrUnion(StructOrUnion, attributes: [String], identifier: String?, declList: [StructDeclaration])
        case `enum`(NotImplemented)
      }

      case storage(StorageClass)
      case type(TypeSpecifier)
      case attribute(String)
      case functionSpecifier(NotImplemented)
    }

    struct Declarator {
      enum Direct {
        case identifier(String)
        indirect case braced(Declarator)
        indirect case array(Direct)
        indirect case parametrList(Declarator, [Specifier])
      }

      enum Pointer {
        case last(typeQual: NotImplemented?)
        indirect case more(typeQual: NotImplemented?, pointer: Pointer)
      }

      var pointer: Pointer?
      var direct: Direct
      var attributes: [String]

      init(pointer: Pointer?, direct: Direct, attrs: [String]) {
        self.pointer = pointer
        self.direct = direct
        attributes = attrs
      }

      init(identifier: String) {
        pointer = nil
        direct = .identifier(identifier)
        attributes = []
      }
    }

    enum Initializer {
      case list([Expr])
      case expr(Expr)
    }

    enum InitDeclarator {
      case decl(Declarator)
      case declinit(Declarator, Initializer)
    }

    var specifiers: [Specifier]
    var declarators: [InitDeclarator]
  }

  indirect case composite([ObjcTerm])
  case `import`(Import)
  case newLine
  case comment(String)
  case moduleImport(module: String)
  case compilerDirective(String)
  case cdecl(CDecl)
  case stmnt(Statement)
}

extension ObjcTerm.CDecl.Declarator {
  static func namedInSwift(_ name: String, decl: ObjcTerm.CDecl.Declarator) -> ObjcTerm.CDecl.Declarator {
    return modified(decl) {
      $0.attributes.append("CF_SWIFT_NAME(\(name))")
    }
  }

  static func identifier(_ id: String) -> ObjcTerm.CDecl.Declarator {
    return .init(identifier: id)
  }

  static func braced(_ decl: ObjcTerm.CDecl.Declarator) -> ObjcTerm.CDecl.Declarator {
    return .init(pointer: nil, direct: .braced(decl), attrs: [])
  }

  static func parametrList(_ decl: ObjcTerm.CDecl.Declarator, params: [ObjcTerm.CDecl.Specifier]) -> ObjcTerm.CDecl.Declarator {
    return .init(pointer: nil, direct: .parametrList(decl, params), attrs: [])
  }

  static func pointed(_ decl: ObjcTerm.CDecl.Declarator) -> ObjcTerm.CDecl.Declarator {
    return modified(decl) {
      switch $0.pointer {
      case nil:
        $0.pointer = .last(typeQual: nil)
      case let .some(pointer):
        $0.pointer = .more(typeQual: nil, pointer: pointer)
      }
    }
  }
}

extension ObjcTerm.CDecl.Declarator {
  static func functionPointer(
    name _: String,
    _ params: ObjcTerm.CDecl.Specifier...
  ) -> ObjcTerm.CDecl.Declarator {
    return .parametrList(
      .braced(.pointed(.identifier("drawingHandler"))),
      params: params
    )
  }
}

extension ObjcTerm {
  // MARK: imports

  struct SystemModule: ExpressibleByStringLiteral {
    var value: StaticString
    var name: String { return value.description }
    init(stringLiteral value: StaticString) {
      self.value = value
    }

    static let foundation: SystemModule = "Foundation"
    static let coreGraphics: SystemModule = "CoreGraphics"
    static let coreFoundation: SystemModule = "CoreFoundation"
  }

  static func `import`(_ systemModule: SystemModule, asModule: Bool) -> ObjcTerm {
    let name = systemModule.name
    return asModule ?
      .moduleImport(module: name) :
      .import(.doubleQuotes(path: "\(name)/\(name).h"))
  }

  static func `import`(
    _ systemModules: SystemModule...,
    asModule: Bool
  ) -> ObjcTerm {
    return .init(systemModules.map { .import($0, asModule: asModule) })
  }

  // MARK: Composite

  init<T: Sequence>(
    _ lexems: T
  ) where T.Element == ObjcTerm {
    self = .composite(.init(lexems))
  }

  init(_ lexems: ObjcTerm...) {
    self = .composite(lexems)
  }

  // MARK: Audited regions

  static func inAuditedRegion(
    _ lexems: ObjcTerm,
    startRegion: String,
    endRegion: String
  ) -> ObjcTerm {
    return .init(
      .compilerDirective(startRegion),
      .newLine,
      lexems,
      .newLine,
      .compilerDirective(endRegion)
    )
  }

  static func inCFNonnullRegion(_ lexems: ObjcTerm...) -> ObjcTerm {
    return inAuditedRegion(
      .init(lexems),
      startRegion: "CF_ASSUME_NONNULL_BEGIN",
      endRegion: "CF_ASSUME_NONNULL_END"
    )
  }

  // MARK: Swift bridging

  // typedef struct CF_BRIDGED_TYPE(id) objcName *objcNameRef CF_SWIFT_NAME(namespace);
  static func swiftNamespace(_ namespace: String, cPref: String) -> ObjcTerm {
    return .cdecl(.init(specifiers: [
      .storage(.typedef),
      .type(.structOrUnion(
        .struct,
        attributes: ["CF_BRIDGED_TYPE(id)"],
        identifier: "\(cPref)\(namespace)", declList: []
      )),
    ], declarators: [
        .decl(.namedInSwift(
          namespace,
          decl: .pointed(.identifier("\(cPref)\(namespace)Ref"))
        )),
    ]))
  }
}
