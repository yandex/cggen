import XCTest
@testable import libcggen

final class ObjcLexTests: XCTestCase {
  typealias Declarator = ObjcTerm.CDecl.Declarator
  func testComments() {
    XCTAssertEqual(
      ObjcTerm.composite([ .comment("Hello"), .comment("World") ]).renderText(),
      """
      // Hello
      // World
      """
    )
  }

  func testImports() {
    XCTAssertEqual(
      ObjcTerm.composite([
        .import(.angleBrackets(path: "Foundation/Foundation.h")),
        .import(.doubleQuotes(path: "foo/bar/baz.h"))
      ]).renderText(),
      """
      #import <Foundation/Foundation.h>
      #import "foo/bar/baz.h"
      """
    )
  }

  func testCDecl() {
    XCTAssertEqual(ObjcTerm.CDecl(specifiers: [
      .storage(.typedef),
      .type(.structOrUnion(.struct, attributes: ["CF_BRIDGED_TYPE(id)"], identifier: "OldT", declList: [])),
    ], declarators: [
      .namedInSwift("SwiftT", decl: .pointed(.identifier("NewT")))
    ]).renderText(),
    """
    typedef struct CF_BRIDGED_TYPE(id) OldT *NewT CF_SWIFT_NAME(SwiftT);
    """)
  }

  func testCStruct() {
    XCTAssertEqual(ObjcTerm.CDecl(specifiers: [
      .storage(.typedef),
      .type(.structOrUnion(
        .struct, attributes: [], identifier: nil, declList: [
          .init(spec: [.CGSize], decl: [.identifier("size")]),
          .init(spec: [.void], decl: [.functionPointer(name: "drawingHandler", .type(.CGContextRef))])
        ]))
    ], declarators: [
      .identifier("Foo"),
    ]).renderText(),
    """
    typedef struct {
      CGSize size;
      void (*drawingHandler)(CGContextRef);
    } Foo;
    """)
  }
}
