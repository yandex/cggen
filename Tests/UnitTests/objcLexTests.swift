@testable import libcggen
import Testing

@Suite struct ObjcLexTests {
  typealias Declarator = ObjcTerm.Declarator
  @Test func testComments() {
    #expect(
      ObjcTerm.composite([.comment("Hello"), .comment("World")]).renderText() ==
        """
        // Hello
        // World
        """
    )
  }

  @Test func testImports() {
    #expect(
      ObjcTerm.composite([
        .import(.coreFoundation, .foundation),
        .preprocessorDirective(.import(.angleBrackets(path: "System.h"))),
        .preprocessorDirective(.import(.doubleQuotes(path: "foo/bar/baz.h"))),
      ]).renderText() ==
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

  @Test func testCDecl() {
    #expect(
      ObjcTerm.CDecl(specifiers: [
        .storage(.typedef),
        .type(.structOrUnion(
          .struct,
          attributes: ["CF_BRIDGED_TYPE(id)"],
          identifier: "OldT",
          declList: []
        )),
      ], declarators: [
        .decl(.namedInSwift("SwiftT", decl: .pointed(.identifier("NewT")))),
      ]).renderText() ==
        """
        typedef struct CF_BRIDGED_TYPE(id) OldT *NewT CF_SWIFT_NAME(SwiftT);
        """
    )
  }

  @Test func testCStruct() {
    #expect(
      ObjcTerm.CDecl(specifiers: [
        .storage(.typedef),
        .type(.structOrUnion(
          .struct, attributes: [], identifier: nil, declList: [
            .init(spec: [.simple(.CGSize)], decl: [.identifier("size")]),
            .init(
              spec: [.simple(.void)],
              decl: [.functionPointer(
                name: "drawingHandler",
                .type(.simple(.CGContextRef))
              )]
            ),
          ]
        )),
      ], declarators: [
        .decl(.identifier("Foo")),
      ]).renderText() ==
        """
        typedef struct {
          CGSize size;
          void (*drawingHandler)(CGContextRef);
        } Foo;
        """
    )
  }
}
