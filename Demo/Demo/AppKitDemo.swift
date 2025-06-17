#if canImport(AppKit)
import AppKit
import CGGenRTSupport
import SwiftUI

// AppKit demo showing cggen API examples
class AppKitDemoViewController: NSViewController, NSTableViewDataSource,
  NSTableViewDelegate {
  private let tableView = NSTableView()
  private let scrollView = NSScrollView()

  struct Example {
    let category: String
    let code: String
    let createView: () -> NSView
  }

  #if swift(>=6.1)
  private let examples: [Example] = [
    // NSImage Creation
    Example(
      category: "NSImage Creation",
      code: "NSImage.draw(\\.star)",
      createView: {
        let imageView = NSImageView()
        imageView.image = NSImage.draw(\.star)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
      }
    ),
    Example(
      category: "NSImage Creation",
      code: "NSImage(drawing: .heart)",
      createView: {
        let imageView = NSImageView()
        imageView.image = NSImage(drawing: .heart)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
      }
    ),

    // Sizing
    Example(
      category: "Sizing",
      code: "NSImage.draw(\\.gear, scale: 2.0)",
      createView: {
        let imageView = NSImageView()
        imageView.image = NSImage.draw(\.gear, scale: 2.0)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        return imageView
      }
    ),
    Example(
      category: "Sizing",
      code: ".draw(\\.mountain, size: CGSize(40, 30), contentMode: .aspectFit)",
      createView: {
        let imageView = NSImageView()
        imageView.image = NSImage.draw(
          \.mountain,
          size: CGSize(width: 40, height: 30),
          contentMode: .aspectFit
        )
        imageView.imageScaling = .scaleNone
        return imageView
      }
    ),

    // Image Views
    Example(
      category: "NSImageView",
      code: "imageView.image = NSImage(drawing: .rocket)",
      createView: {
        let imageView = NSImageView()
        imageView.image = NSImage(drawing: .rocket)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        imageView.layer?.borderColor = NSColor.separatorColor.cgColor
        imageView.layer?.borderWidth = 0.5
        return imageView
      }
    ),
    Example(
      category: "NSImageView",
      code: "imageView.imageScaling = .scaleNone",
      createView: {
        let imageView = NSImageView()
        imageView.image = NSImage(drawing: .star)
        imageView.imageScaling = .scaleNone
        imageView.wantsLayer = true
        imageView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
        imageView.layer?.borderColor = NSColor.separatorColor.cgColor
        imageView.layer?.borderWidth = 0.5
        return imageView
      }
    ),

    // Interactive
    Example(
      category: "Interactive",
      code: "NSButton(image: NSImage.draw(\\.gear))",
      createView: {
        let button = NSButton(
          image: NSImage.draw(\.gear),
          target: nil,
          action: nil
        )
        button.bezelStyle = .rounded
        return button
      }
    ),
    Example(
      category: "Interactive",
      code: "button.image = NSImage.draw(\\.heart)",
      createView: {
        let button = NSButton(
          title: "Like",
          image: NSImage.draw(\.heart),
          target: nil,
          action: nil
        )
        button.imagePosition = .imageLeading
        button.bezelStyle = .rounded
        return button
      }
    ),
  ]
  #else
  private let examples: [Example] = []
  #endif

  override func loadView() {
    view = NSView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupTableView()
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    scrollView.frame = view.bounds
  }

  private func setupTableView() {
    view.wantsLayer = true

    // Setup scroll view
    scrollView.hasVerticalScroller = true
    scrollView.borderType = .noBorder
    scrollView.documentView = tableView
    view.addSubview(scrollView)

    // Setup table view
    tableView.style = .inset
    tableView.rowHeight = 60
    tableView.gridStyleMask = []
    tableView.intercellSpacing = NSSize(width: 0, height: 1)

    // Create columns
    let iconColumn =
      NSTableColumn(identifier: NSUserInterfaceItemIdentifier("icon"))
    iconColumn.title = "Result"
    iconColumn.width = 80
    tableView.addTableColumn(iconColumn)

    let codeColumn =
      NSTableColumn(identifier: NSUserInterfaceItemIdentifier("code"))
    codeColumn.title = "Code"
    codeColumn.width = 400
    tableView.addTableColumn(codeColumn)

    tableView.dataSource = self
    tableView.delegate = self

    // Group by category
    tableView.floatsGroupRows = true
  }

  // MARK: - NSTableViewDataSource

  func numberOfRows(in _: NSTableView) -> Int {
    // Count categories + examples
    let categories = Set(examples.map(\.category))
    return categories.count + examples.count
  }

  func tableView(
    _: NSTableView,
    objectValueFor _: NSTableColumn?,
    row _: Int
  ) -> Any? {
    nil
  }

  func tableView(_: NSTableView, isGroupRow row: Int) -> Bool {
    var currentRow = 0
    var lastCategory = ""

    for example in examples {
      if example.category != lastCategory {
        if currentRow == row {
          return true
        }
        lastCategory = example.category
        currentRow += 1
      }
      if currentRow == row {
        return false
      }
      currentRow += 1
    }

    return false
  }

  // MARK: - NSTableViewDelegate

  func tableView(
    _: NSTableView,
    viewFor tableColumn: NSTableColumn?,
    row: Int
  ) -> NSView? {
    var currentRow = 0
    var lastCategory = ""
    var categoryRows: [String: Int] = [:]

    for example in examples {
      if example.category != lastCategory {
        categoryRows[example.category] = currentRow
        lastCategory = example.category
        currentRow += 1
      }
      if currentRow == row {
        // This is a regular row
        if tableColumn?.identifier.rawValue == "icon" {
          let containerView = NSView()
          let exampleView = example.createView()
          exampleView.translatesAutoresizingMaskIntoConstraints = false
          containerView.addSubview(exampleView)

          NSLayoutConstraint.activate([
            exampleView.centerXAnchor
              .constraint(equalTo: containerView.centerXAnchor),
            exampleView.centerYAnchor
              .constraint(equalTo: containerView.centerYAnchor),
            exampleView.widthAnchor.constraint(lessThanOrEqualToConstant: 50),
            exampleView.heightAnchor.constraint(lessThanOrEqualToConstant: 50),
          ])

          return containerView
        } else {
          let textField = NSTextField(labelWithString: example.code)
          textField.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
          textField.lineBreakMode = .byTruncatingTail
          return textField
        }
      }
      currentRow += 1
    }

    // Group row
    if let category = categoryRows.first(where: { $0.value == row })?.key {
      let textField = NSTextField(labelWithString: category)
      textField.font = .systemFont(ofSize: 13, weight: .semibold)
      textField.textColor = .secondaryLabelColor
      return textField
    }

    return nil
  }

  func tableView(
    _ tableView: NSTableView,
    rowViewForRow row: Int
  ) -> NSTableRowView? {
    if self.tableView(tableView, isGroupRow: row) {
      let rowView = NSTableRowView()
      rowView.isGroupRowStyle = true
      return rowView
    }
    return nil
  }
}

// SwiftUI wrapper
struct AppKitDemo: NSViewControllerRepresentable {
  func makeNSViewController(context _: Context) -> AppKitDemoViewController {
    AppKitDemoViewController()
  }

  func updateNSViewController(
    _: AppKitDemoViewController,
    context _: Context
  ) {}
}

#Preview {
  AppKitDemo()
}

#endif
