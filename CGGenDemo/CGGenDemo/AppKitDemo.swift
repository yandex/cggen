#if canImport(AppKit)
import AppKit
import CGGenRuntimeSupport
import SwiftUI

// AppKit View Controller demonstrating cggen API usage
class AppKitDemoViewController: NSViewController {
  private let scrollView = NSScrollView()
  private let contentView = NSView()
  private let stackView = NSStackView()

  override func loadView() {
    view = NSView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    addDemoSections()
  }

  private func setupViews() {
    view.wantsLayer = true

    // Setup scroll view
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.hasVerticalScroller = true
    scrollView.borderType = .noBorder
    view.addSubview(scrollView)

    // Setup content view
    contentView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.documentView = contentView

    // Setup stack view
    stackView.orientation = .vertical
    stackView.alignment = .leading
    stackView.spacing = 30
    stackView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stackView)

    // Constraints
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

      stackView.topAnchor.constraint(
        equalTo: contentView.topAnchor,
        constant: 20
      ),
      stackView.leadingAnchor.constraint(
        equalTo: contentView.leadingAnchor,
        constant: 20
      ),
      stackView.trailingAnchor.constraint(
        equalTo: contentView.trailingAnchor,
        constant: -20
      ),
      stackView.bottomAnchor.constraint(
        equalTo: contentView.bottomAnchor,
        constant: -20
      ),
    ])
  }

  private func addDemoSections() {
    // Section 1: Basic NSImage creation with KeyPath syntax
    addSection(title: "NSImage Creation - KeyPath Syntax (Preferred)") {
      let codeLabel = createCodeLabel("""
      // Using KeyPath syntax - most concise
      let icon = NSImage.draw(\\.star)
      let largeIcon = NSImage.draw(\\.star, scale: 3.0)
      """)

      let imageView1 = NSImageView()
      imageView1.image = NSImage.draw(\.star)
      imageView1.imageScaling = .scaleProportionallyUpOrDown

      let imageView2 = NSImageView()
      imageView2.image = NSImage.draw(\.star, scale: 3.0)
      imageView2.imageScaling = .scaleProportionallyUpOrDown

      let imagesStack = NSStackView(views: [imageView1, imageView2])
      imagesStack.orientation = .horizontal
      imagesStack.spacing = 20

      return NSStackView(views: [codeLabel, imagesStack])
    }

    // Section 2: Direct initialization
    addSection(title: "Direct NSImage Initialization") {
      let codeLabel = createCodeLabel("""
      // Direct initialization
      let heart = NSImage(drawing: .heart)
      let rocket = NSImage(drawing: .rocket, scale: 2.0)
      """)

      let imageView1 = NSImageView()
      imageView1.image = NSImage(drawing: .heart)
      let imageView2 = NSImageView()
      imageView2.image = NSImage(drawing: .rocket, scale: 2.0)

      let imagesStack = NSStackView(views: [imageView1, imageView2])
      imagesStack.orientation = .horizontal
      imagesStack.spacing = 20

      return NSStackView(views: [codeLabel, imagesStack])
    }

    // Section 3: Content modes
    addSection(title: "Content Modes with Target Size") {
      let codeLabel = createCodeLabel("""
      // Generate images with specific size and content mode
      let thumbnail = NSImage.draw(
        \\.mountain,
        size: CGSize(width: 100, height: 60),
        contentMode: .aspectFit
      )
      """)

      let fitImage = NSImage.draw(
        \.mountain,
        size: CGSize(width: 100, height: 60),
        contentMode: .aspectFit
      )

      let fillImage = NSImage.draw(
        \.mountain,
        size: CGSize(width: 100, height: 60),
        contentMode: .aspectFill
      )

      let fitView = createImageViewWithBorder(
        image: fitImage,
        label: "Aspect Fit"
      )
      let fillView = createImageViewWithBorder(
        image: fillImage,
        label: "Aspect Fill"
      )

      let imagesStack = NSStackView(views: [fitView, fillView])
      imagesStack.orientation = .horizontal
      imagesStack.spacing = 20
      imagesStack.distribution = .fillEqually

      return NSStackView(views: [codeLabel, imagesStack])
    }

    // Section 4: In NSButton
    addSection(title: "Using in NSButton") {
      let codeLabel = createCodeLabel("""
      // Set button image
      button.image = NSImage.draw(\\.gear)
      """)

      let button1 = NSButton(
        title: "Settings",
        image: NSImage.draw(\.gear),
        target: nil,
        action: nil
      )
      button1.imagePosition = .imageLeading
      button1.bezelStyle = .rounded

      let button2 = NSButton(
        image: NSImage.draw(\.heart),
        target: nil,
        action: nil
      )
      button2.bezelStyle = .texturedRounded
      button2.isBordered = true

      let buttonsStack = NSStackView(views: [button1, button2])
      buttonsStack.orientation = .horizontal
      buttonsStack.spacing = 20

      return NSStackView(views: [codeLabel, buttonsStack])
    }

    // Section 5: NSImageView with different scaling modes
    addSection(title: "NSImageView Scaling Modes") {
      let codeLabel = createCodeLabel("""
      imageView.image = NSImage(drawing: .rocket)
      imageView.imageScaling = .scaleProportionallyUpOrDown
      """)

      let imageView1 = createScaledImageView(
        image: NSImage(drawing: .rocket),
        scaling: .scaleProportionallyUpOrDown,
        label: ".scaleProportionallyUpOrDown"
      )

      let imageView2 = createScaledImageView(
        image: NSImage(drawing: .rocket),
        scaling: .scaleNone,
        label: ".scaleNone"
      )

      let imagesStack = NSStackView(views: [imageView1, imageView2])
      imagesStack.orientation = .horizontal
      imagesStack.spacing = 20

      return NSStackView(views: [codeLabel, imagesStack])
    }

    // Section 6: Drawing in custom NSView
    addSection(title: "Custom NSView Drawing") {
      let codeLabel = createCodeLabel("""
      override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if let context = NSGraphicsContext.current?.cgContext {
          Drawing.star.draw(context)
        }
      }
      """)

      let customView = CustomDrawingView(drawing: .star)
      customView.widthAnchor.constraint(equalToConstant: 100).isActive = true
      customView.heightAnchor.constraint(equalToConstant: 100).isActive = true

      return NSStackView(views: [codeLabel, customView])
    }
  }

  // Helper methods
  private func addSection(title: String, content: () -> NSView) {
    let titleLabel = NSTextField(labelWithString: title)
    titleLabel.font = .preferredFont(forTextStyle: .headline)

    let contentView = content()
    let contentStack = contentView as? NSStackView ?? {
      let stack = NSStackView(views: [contentView])
      stack.orientation = .vertical
      stack.spacing = 10
      stack.alignment = .leading
      return stack
    }()

    let sectionStack = NSStackView(views: [titleLabel, contentStack])
    sectionStack.orientation = .vertical
    sectionStack.spacing = 10
    sectionStack.alignment = .leading

    let container = NSView()
    container.wantsLayer = true
    container.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    container.layer?.cornerRadius = 8
    container.translatesAutoresizingMaskIntoConstraints = false

    container.addSubview(sectionStack)
    sectionStack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      sectionStack.topAnchor.constraint(
        equalTo: container.topAnchor,
        constant: 16
      ),
      sectionStack.leadingAnchor.constraint(
        equalTo: container.leadingAnchor,
        constant: 16
      ),
      sectionStack.trailingAnchor.constraint(
        equalTo: container.trailingAnchor,
        constant: -16
      ),
      sectionStack.bottomAnchor.constraint(
        equalTo: container.bottomAnchor,
        constant: -16
      ),
    ])

    stackView.addArrangedSubview(container)
  }

  private func createCodeLabel(_ code: String) -> NSView {
    let textView = NSTextView()
    textView.string = code
    textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    textView.isEditable = false
    textView.isSelectable = true
    textView.drawsBackground = true
    textView.backgroundColor = .textBackgroundColor
    textView.textColor = .labelColor
    textView.isAutomaticQuoteSubstitutionEnabled = false
    textView.isRichText = false

    let scrollView = NSScrollView()
    scrollView.documentView = textView
    scrollView.hasVerticalScroller = false
    scrollView.hasHorizontalScroller = false
    scrollView.borderType = .lineBorder
    scrollView.translatesAutoresizingMaskIntoConstraints = false

    // Calculate text size and set constraints
    let size = (code as NSString).size(withAttributes: [.font: textView.font!])
    scrollView.heightAnchor.constraint(equalToConstant: size.height + 16)
      .isActive = true

    return scrollView
  }

  private func createImageViewWithBorder(
    image: NSImage?,
    label: String
  ) -> NSView {
    let imageView = NSImageView()
    imageView.image = image
    imageView.imageScaling = .scaleProportionallyUpOrDown
    imageView.wantsLayer = true
    imageView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
    imageView.layer?.borderColor = NSColor.separatorColor.cgColor
    imageView.layer?.borderWidth = 1
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
    imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true

    return createLabeledView(view: imageView, label: label)
  }

  private func createScaledImageView(
    image: NSImage?,
    scaling: NSImageScaling,
    label: String
  ) -> NSView {
    let imageView = NSImageView()
    imageView.image = image
    imageView.imageScaling = scaling
    imageView.wantsLayer = true
    imageView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
    imageView.layer?.borderColor = NSColor.separatorColor.cgColor
    imageView.layer?.borderWidth = 1
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.widthAnchor.constraint(equalToConstant: 80).isActive = true
    imageView.heightAnchor.constraint(equalToConstant: 80).isActive = true

    return createLabeledView(view: imageView, label: label)
  }

  private func createLabeledView(view: NSView, label: String) -> NSView {
    let labelView = NSTextField(labelWithString: label)
    labelView.font = .preferredFont(forTextStyle: .caption1)
    labelView.textColor = .secondaryLabelColor
    labelView.alignment = .center

    let stack = NSStackView(views: [view, labelView])
    stack.orientation = .vertical
    stack.spacing = 4
    stack.alignment = .centerX

    return stack
  }
}

// Custom NSView that draws directly
class CustomDrawingView: NSView {
  let drawing: Drawing

  init(drawing: Drawing) {
    self.drawing = drawing
    super.init(frame: .zero)
    wantsLayer = true
    layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
    layer?.borderColor = NSColor.separatorColor.cgColor
    layer?.borderWidth = 1
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    guard let context = NSGraphicsContext.current?.cgContext else { return }

    // Center the drawing
    let drawingRect = CGRect(
      x: (bounds.width - drawing.size.width) / 2,
      y: (bounds.height - drawing.size.height) / 2,
      width: drawing.size.width,
      height: drawing.size.height
    )

    context.saveGState()
    context.translateBy(x: drawingRect.minX, y: drawingRect.minY)
    drawing.draw(context)
    context.restoreGState()
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
