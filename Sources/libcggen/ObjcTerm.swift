import Base

enum ObjcTerm {
  typealias NotImplemented = Never
  enum Import {
    case angleBrackets(path: String)
    case doubleQuotes(path: String)
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
        case simple(String)
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
        self.attributes = attrs
      }

      init(identifier: String) {
        pointer = nil
        direct = .identifier(identifier)
        attributes = []
      }
    }
    var specifiers: [Specifier]
    var declarators: [Declarator]
  }
  indirect case composite([ObjcTerm])
  case `import`(Import)
  case newLine
  case comment(String)
  case moduleImport(module: String)
  case compilerDirective(String)
  case cdecl(CDecl)
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

extension ObjcTerm.CDecl.Specifier.TypeSpecifier: ExpressibleByStringLiteral {
  typealias TypeSpecifier = ObjcTerm.CDecl.Specifier.TypeSpecifier
  static let void: TypeSpecifier = "void"
  static let CGContextRef: TypeSpecifier = "CGContextRef"
  static let CGSize: TypeSpecifier = "CGSize"
  init(stringLiteral value: StaticString) {
    self = .simple(value.description)
  }
}

extension ObjcTerm.CDecl.Declarator {
  static func functionPointer(
    name: String,
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

    static let foundation = SystemModule.init(stringLiteral: "Foundation")
    static let coreGraphics = SystemModule.init(stringLiteral: "CoreGraphics")
    static let coreFoundation = SystemModule.init(stringLiteral: "CoreFoundation")
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
      .namedInSwift(
        namespace,
        decl: .pointed(.identifier("\(cPref)\(namespace)Ref"))
      )
    ]))
  }
}
