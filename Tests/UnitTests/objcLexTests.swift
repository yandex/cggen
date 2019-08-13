@testable import libcggen
import XCTest

final class ObjcLexTests: XCTestCase {
  typealias Declarator = ObjcTerm.CDecl.Declarator
  func testComments() {
    XCTAssertEqual(
      ObjcTerm.composite([.comment("Hello"), .comment("World")]).renderText(),
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
        .import(.doubleQuotes(path: "foo/bar/baz.h")),
      ]).renderText(),
      """
      #import <Foundation/Foundation.h>
      #import "foo/bar/baz.h"
      """
    )
  }

  func testCDecl() {
    XCTAssertEqual(
      ObjcTerm.CDecl(specifiers: [
        .storage(.typedef),
        .type(.structOrUnion(.struct, attributes: ["CF_BRIDGED_TYPE(id)"], identifier: "OldT", declList: [])),
      ], declarators: [
        .decl(.namedInSwift("SwiftT", decl: .pointed(.identifier("NewT")))),
      ]).renderText(),
      """
      typedef struct CF_BRIDGED_TYPE(id) OldT *NewT CF_SWIFT_NAME(SwiftT);
      """
    )
  }

  func testCStruct() {
    XCTAssertEqual(
      ObjcTerm.CDecl(specifiers: [
        .storage(.typedef),
        .type(.structOrUnion(
          .struct, attributes: [], identifier: nil, declList: [
            .init(spec: [.simple(.CGSize)], decl: [.identifier("size")]),
            .init(spec: [.simple(.void)], decl: [.functionPointer(name: "drawingHandler", .type(.simple(.CGContextRef)))]),
          ]
        )),
      ], declarators: [
        .decl(.identifier("Foo")),
      ]).renderText(),
      """
      typedef struct {
        CGSize size;
        void (*drawingHandler)(CGContextRef);
      } Foo;
      """
    )
  }
}
