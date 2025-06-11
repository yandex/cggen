import Base

protocol Renderable {
  associatedtype RenderType
  func render() -> RenderType
}

extension Renderable where RenderType == [String] {
  func renderText() -> String {
    render().joined(separator: "\n")
  }

  func render(indent: Int) -> RenderType {
    render().map { String(repeating: " ", count: indent) + $0 }
  }
}

extension Collection where Element: Renderable {
  func render() -> [Element.RenderType] {
    map { $0.render() }
  }
}

extension Array: Renderable where Element: Renderable {}

extension ObjcTerm: Renderable {
  typealias RenderType = [String]
  func render() -> [String] {
    switch self {
    case let .composite(sequence):
      sequence.flatMap { $0.render() }
    case .newLine:
      [""]
    case let .comment(comment):
      ["// \(comment)"]
    case let .preprocessorDirective(preprocessor):
      [preprocessor.render()]
    case let .moduleImport(module):
      ["@import \(module);"]
    case let .compilerDirective(directive):
      [directive]
    case let .cdecl(decl):
      decl.render()
    case let .stmnt(s):
      s.render()
    }
  }
}

extension ObjcTerm.PreprocessorDirective: Renderable {
  func render() -> String {
    switch self {
    case let .define(new, to: old):
      "#define \(new) \(old)"
    case let .if(cond: cond):
      "#if \(cond)"
    case let .ifdef(identifier):
      "#ifdef \(identifier)"
    case let .ifndef(identifier):
      "#ifndef \(identifier)"
    case let .else(cond):
      "#else  // \(cond)"
    case let .endif(cond):
      "#endif  // \(cond)"
    case let .import(type):
      switch type {
      case let .angleBrackets(path: path):
        "#import <\(path)>"
      case let .doubleQuotes(path: path):
        "#import \"\(path)\""
      }
    }
  }
}

extension ObjcTerm.TypeName.DirectAbstractDeclarator: Renderable {
  func render() -> String {
    switch self {
    case let .array(of: type):
      "[" + (type.map { $0.render() } ?? "") + "]"
    }
  }
}

extension ObjcTerm.TypeName.AbstractDeclarator: Renderable {
  func render() -> String {
    switch self {
    case let .direct(direct):
      direct.render()
    case let .pointer(pointer):
      pointer.render()
    case let .pointerTo(pointer, direct):
      pointer.render() + direct.render()
    }
  }
}

extension ObjcTerm.TypeName: Renderable {
  func render() -> [String] {
    let specifiersLines = specifiers.render()
    let decl = declarator?.render() ?? ""
    var lines = specifiersLines.reduce([String]()) {
      $0.appendFirstToLast($1, separator: " ")
    }
    lines.indices.last.map { lines[$0] += decl }

    return lines
  }
}

extension ObjcTerm.Statement: Renderable {
  func render() -> [String] {
    switch self {
    case let .expr(e):
      [e.render() + ";"]
    case let .block(list):
      ["{"] + list.flatMap { $0.render(indent: 2) } + ["}"]
    case let .for(init: initDecl, cond: cond, incr: incr, body: body):
      ["for ("].appendFirstToLast(initDecl.render(), separator: "")
        .appendFirstToLast(
          ["\(cond.render()); \(incr.render()))"],
          separator: " "
        )
        .appendFirstToLast(body.render(), separator: " ")
    case let .multiple(stmnts):
      stmnts.flatMap { $0.render() }
    }
  }
}

extension ObjcTerm.Statement.BlockItem: Renderable {
  func render() -> [String] {
    switch self {
    case let .decl(d):
      d.render()
    case let .stmnt(s):
      s.render()
    }
  }
}

extension ObjcTerm.CDecl: Renderable {
  func render() -> [String] {
    let intersectingLines = specifiers.render() + declarators.render()
    var lines = intersectingLines.reduce([String]()) {
      $0.appendFirstToLast($1, separator: " ")
    }
    lines.indices.last.map { lines[$0] += ";" }
    return lines
  }
}

extension ObjcTerm.CDecl.Specifier: Renderable {
  typealias RenderType = [String]
  func render() -> [String] {
    switch self {
    case let .storage(storageClass):
      [storageClass.rawValue]
    case .functionSpecifier:
      []
    case let .attribute(attr):
      [attr]
    case let .type(specifier):
      specifier.render()
    }
  }
}

extension ObjcTerm.Declarator: Renderable {
  func render() -> String {
    ([(pointer?.render() ?? "") + direct.render()] + attributes)
      .joined(separator: " ")
  }
}

extension ObjcTerm.CDecl.Initializer: Renderable {
  func render() -> [String] {
    switch self {
    case let .list(l):
      let initializers = l.render(indent: 2).map { $0 + "," }
      return ["{"] + initializers + ["}"]
    case let .expr(e):
      return [e.render()]
    }
  }
}

extension ObjcTerm.CDecl.InitDeclarator: Renderable {
  func render() -> [String] {
    switch self {
    case let .decl(decl):
      [decl.render()]
    case let .declinit(decl, initializer):
      [decl.render()]
        .appendFirstToLast(initializer.render(), separator: " = ")
    }
  }
}

extension ObjcTerm.Declarator.Direct {
  func render() -> String {
    switch self {
    case let .braced(decl):
      return "(\(decl.render()))"
    case let .identifier(identifier):
      return identifier
    case let .parametrList(decl, paramList):
      let params = paramList.render().joined().joined(separator: " ")
      return "\(decl.render())(\(params))"
    case let .array(decl):
      return "\(decl.render())[]"
    }
  }
}

extension ObjcTerm.Pointer: Renderable {
  typealias RenderType = String
  func render() -> String {
    switch self {
    case .last:
      "*"
    case let .more(typeQual: _, pointer: next):
      "*" + next.render()
    }
  }
}

extension ObjcTerm.TypeSpecifier: Renderable {
  func render() -> [String] {
    switch self {
    case .enum:
      return []
    case let .simple(typeName):
      return [typeName.description]
    case let .structOrUnion(type, attrs, id, declList):
      let comps: [String?] = [type.rawValue] + attrs + [id]
      let structDecl: String = comps.compactMap(identity).joined(separator: " ")
      guard declList.count > 0 else {
        return [structDecl]
      }
      let structMembers = declList.render(indent: 2).map { "\($0);" }
      return ["\(structDecl) {"] + structMembers + ["}"]
    }
  }
}

extension ObjcTerm.TypeSpecifier.StructDeclaration: Renderable {
  func render() -> String {
    (spec.render() + [decl.render()])
      .flatMap(\.self)
      .joined(separator: " ")
  }
}

extension ObjcTerm.Expr: Renderable {
  func render() -> String {
    switch self {
    case let .cast(to: type, expr):
      return "(\(type))\(expr.render())"
    case let .const(raw: const):
      return const
    case let .identifier(id):
      return id
    case let .list(of: type, list):
      let initializers = list.map { $0.render() }.joined(separator: ", ")
      return "(\(type.render().joined(separator: " "))){ \(initializers) }"
    case let .memberInit(field, expr):
      return ".\(field) = \(expr.render())"
    case let .bin(lhs, op, rhs):
      return [lhs.render(), op.rawValue, rhs.render()].joined(separator: " ")
    case let .postfix(e, op):
      return [e.render(), op.rawValue].joined()
    case let .call(f, args: args):
      return f.render() + "(" + args.render().joined(separator: ", ") + ")"
    case let .subscript(e, idx):
      return e.render() + "[" + idx.render() + "]"
    case let .unary(op, e):
      return op.rawValue + e.render()
    case let .member(value, field):
      return value.render() + "." + field
    }
  }
}
