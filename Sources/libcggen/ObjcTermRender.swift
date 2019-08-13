import Base

protocol Renderable {
  associatedtype RenderType
  func render() -> RenderType
}

extension Renderable where RenderType == [String] {
  func renderText() -> String {
    return render().joined(separator: "\n")
  }

  func render(indent: Int) -> RenderType {
    return render().map { String(repeating: " ", count: indent) + $0 }
  }
}

extension Collection where Element: Renderable {
  func render() -> [Element.RenderType] {
    return map { $0.render() }
  }
}

extension Array: Renderable where Element: Renderable {}

extension ObjcTerm: Renderable {
  typealias RenderType = [String]
  func render() -> [String] {
    switch self {
    case let .composite(sequence):
      return sequence.flatMap { $0.render() }
    case .newLine:
      return [""]
    case let .comment(comment):
      return ["// \(comment)"]
    case let .import(importStatement):
      return [importStatement.render()]
    case let .moduleImport(module):
      return ["@import \(module);"]
    case let .compilerDirective(directive):
      return [directive]
    case let .cdecl(decl):
      return decl.render()
    case let .stmnt(s):
      return s.render()
    }
  }
}

extension ObjcTerm.Statement: Renderable {
  func render() -> [String] {
    switch self {
    case let .expr(e):
      return [e.render() + ";"]
    case let .block(list):
      return ["{"] + list.flatMap { $0.render(indent: 2) } + ["}"]
    case let .for(init: initDecl, cond: cond, incr: incr, body: body):
      return ["for ("].appendFirstToLast(initDecl.render(), separator: "")
        .appendFirstToLast(["\(cond.render()); \(incr.render()))"], separator: " ")
        .appendFirstToLast(body.render(), separator: " ")
    }
  }
}

extension ObjcTerm.Statement.BlockItem: Renderable {
  func render() -> [String] {
    switch self {
    case let .decl(d):
      return d.render()
    case let .stmnt(s):
      return s.render()
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
      return [storageClass.rawValue]
    case .functionSpecifier:
      return []
    case let .attribute(attr):
      return [attr]
    case let .type(specifier):
      return specifier.render()
    }
  }
}

extension ObjcTerm.CDecl.Declarator: Renderable {
  func render() -> String {
    return ([(pointer?.render() ?? "") + direct.render()] + attributes)
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
      return [decl.render()]
    case let .declinit(decl, initializer):
      return [decl.render()].appendFirstToLast(initializer.render(), separator: " = ")
    }
  }
}

extension ObjcTerm.CDecl.Declarator.Direct {
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

extension ObjcTerm.CDecl.Declarator.Pointer: Renderable {
  typealias RenderType = String
  func render() -> String {
    switch self {
    case .last:
      return "*"
    case let .more(typeQual: _, pointer: next):
      return "*" + next.render()
    }
  }
}

extension ObjcTerm.CDecl.Specifier.TypeSpecifier: Renderable {
  typealias RenderType = [String]
  func render() -> [String] {
    switch self {
    case .enum:
      return []
    case let .simple(typeName):
      return [typeName.description]
    case let .structOrUnion(type, attrs, id, declList):
      let structDecl = ([type.rawValue] + attrs + [id])
        .compactMap(identity).joined(separator: " ")
      guard declList.count > 0 else {
        return [structDecl]
      }
      let structMembers = declList.render(indent: 2).map { "\($0);" }
      return ["\(structDecl) {"] + structMembers + ["}"]
    }
  }
}

extension ObjcTerm.CDecl.Specifier.TypeSpecifier.StructDeclaration: Renderable {
  func render() -> String {
    return (spec.render() + [decl.render()])
      .flatMap { $0 }
      .joined(separator: " ")
  }
}

extension ObjcTerm.Import: Renderable {
  func render() -> String {
    switch self {
    case let .angleBrackets(path: path):
      return "#import <\(path)>"
    case let .doubleQuotes(path: path):
      return "#import \"\(path)\""
    }
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
    case let .list(type: type, list):
      let initializers = list.map { $0.render() }.joined(separator: ", ")
      return "(\(type)){ \(initializers) }"
    case let .member(field, expr):
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
    }
  }
}
