import Foundation
import Testing

import CGGenCore
import SVGParse

// Not-wf cases from the W3C XML Conformance Test Suite, downloaded from
// w3.org and cached. The XML parser in SVGParse supports only the XML
// subset SVG uses, so only cases within that subset run: valid UTF-8, no
// encoding declaration other than UTF-8, no DOCTYPE, no CDATA. The release
// is immutable, so the curated case count is pinned.
@Suite(.enabled(if: extendedTestsEnabled))
struct XMLConformanceTests {
  @Test func rejectsNotWellFormed() async throws {
    let cases = try await notWellFormedCases()
    #expect(cases.count == 82)
    for testCase in cases {
      #expect(
        (try? XML.parse(from: testCase.data).get()) == nil,
        "\(testCase.id) parsed but is not well-formed"
      )
    }
  }
}

// Same switch as `extendedTestsEnabled` in SVGTests.swift; the nightly
// extended CI job sets it.
private let extendedTestsEnabled = ProcessInfo.processInfo
  .environment["CGGEN_EXTENDED_TESTS"] == "1"

private let suiteURL =
  URL(string: "https://www.w3.org/XML/Test/xmlts20020606.zip")!

private let catalogs = [
  "xmltest/xmltest.xml",
  "sun/sun-valid.xml", "sun/sun-invalid.xml",
  "sun/sun-not-wf.xml", "sun/sun-error.xml",
  "ibm/ibm_oasis_valid.xml", "ibm/ibm_oasis_invalid.xml",
  "ibm/ibm_oasis_not-wf.xml",
  "oasis/oasis.xml",
  "japanese/japanese.xml",
]

private struct ConformanceTestError: Error, CustomStringConvertible {
  var description: String
}

private func notWellFormedCases(
) async throws -> [(id: String, data: Data)] {
  let root = try await cachedSuiteRoot()
  var cases: [(id: String, data: Data)] = []
  for catalog in catalogs {
    let catalogURL = root.appendingPathComponent(catalog)
    let text = try String(
      decoding: Data(contentsOf: catalogURL), as: UTF8.self
    )
    for test in testElements(in: text) where test["TYPE"] == "not-wf" {
      guard let uri = test["URI"], let id = test["ID"] else {
        throw ConformanceTestError(description: "malformed catalog \(catalog)")
      }
      let data = try Data(
        contentsOf: catalogURL.deletingLastPathComponent()
          .appendingPathComponent(uri)
      )
      if isWithinSupportedSubset(data) {
        cases.append((id, data))
      }
    }
  }
  return cases
}

// <TEST TYPE="not-wf" ID="..." URI="..." ...> attributes
private func testElements(in catalog: String) -> [[String: String]] {
  catalog.matches(of: /<TEST\b([^>]*?)>/.dotMatchesNewlines()).map { match in
    var attributes: [String: String] = [:]
    for attribute in match.output.1.matches(of: /([\w:]+)\s*=\s*"([^"]*)"/) {
      attributes[String(attribute.output.1)] = String(attribute.output.2)
    }
    return attributes
  }
}

private func isWithinSupportedSubset(_ data: Data) -> Bool {
  guard !data.contains(sequence: "<!DOCTYPE"),
        !data.contains(sequence: "<![CDATA["),
        let text = String(data: data, encoding: .utf8)
  else { return false }
  guard let encoding = text.firstMatch(
    of: /encoding\s*=\s*["']([^"']+)["']/
  ) else { return true }
  return encoding.output.1.lowercased() == "utf-8"
}

extension Data {
  fileprivate func contains(sequence: String) -> Bool {
    range(of: Data(sequence.utf8)) != nil
  }
}

private func cachedSuiteRoot() async throws -> URL {
  let cache = URL.cachesDirectory
    .appendingPathComponent("cggen-xml-conformance")
  let root = cache.appendingPathComponent("XML-Test-Suite/xmlconf")
  if FileManager.default.fileExists(atPath: root.path) {
    return root
  }
  try FileManager.default.createDirectory(
    at: cache, withIntermediateDirectories: true
  )
  let (downloaded, response) = try await URLSession.shared.download(
    from: suiteURL
  )
  guard (response as? HTTPURLResponse)?.statusCode == 200 else {
    throw ConformanceTestError(
      description: "failed to download \(suiteURL)"
    )
  }
  let zip = cache.appendingPathComponent("xmlts.zip")
  try? FileManager.default.removeItem(at: zip)
  try FileManager.default.moveItem(at: downloaded, to: zip)
  let unzip = Process()
  unzip.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
  unzip.arguments = ["-q", "-o", zip.path, "-d", cache.path]
  try unzip.run()
  unzip.waitUntilExit()
  guard unzip.terminationStatus == 0,
        FileManager.default.fileExists(atPath: root.path) else {
    throw ConformanceTestError(description: "failed to unpack \(zip.path)")
  }
  return root
}
