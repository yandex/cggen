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
    case let .`import`(importStatement):
      return [importStatement.render()]
    case let .moduleImport(module):
      return ["@import \(module);"]
    case let .compilerDirective(directive):
      return [directive]
    case let .cdecl(decl):
      return decl.render()
    }
  }
}


extension ObjcTerm.CDecl: Renderable {
  typealias RenderType = [String]
  func render() -> [String] {
    let intersectingLines = specifiers.render() + [declarators.render()]
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
    case .functionSpecifier(_):
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
    }
  }
}

extension ObjcTerm.CDecl.Declarator.Pointer: Renderable {
  typealias RenderType = String
  func render() -> String {
    switch self {
    case .last(_):
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
    case .enum(_):
      return []
    case let .simple(typeName):
      return [typeName]
    case let .structOrUnion(type, attrs, id, declList):
      let structDecl = ([type.rawValue] + attrs + [id])
        .compactMap(identity).joined(separator: " ")
      guard declList.count > 0 else {
        return [structDecl]
      }
      let structMembers = declList.render(indent: 2).map { "\($0);" }
      return ["\(structDecl) {"] + structMembers + [ "}" ]
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
