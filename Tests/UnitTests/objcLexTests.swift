@testable import libcggen

import XCTest

final class ObjcLexTests: XCTestCase {
  typealias Declarator = ObjcTerm.Declarator
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
        .import(.coreFoundation, .foundation),
        .preprocessorDirective(.import(.angleBrackets(path: "System.h"))),
        .preprocessorDirective(.import(.doubleQuotes(path: "foo/bar/baz.h"))),
      ]).renderText(),
      """
      #if __has_feature(modules)
      @import CoreFoundation;
      @import Foundation;
      #else  // __has_feature(modules)
      #import <CoreFoundation/CoreFoundation.h>
      #import <Foundation/Foundation.h>
      #endif  // __has_feature(modules)
      #import <System.h>
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
