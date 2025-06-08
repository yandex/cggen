#if canImport(AppKit)
import AppKit
import CGGenRuntimeSupport
import SwiftUI

// Flipped view for proper coordinate system
class FlippedView: NSView {
  override var isFlipped: Bool { true }
}

// AppKit View Controller demonstrating cggen API usage
class AppKitDemoViewController: NSViewController {
  private let scrollView = NSScrollView()
  private let contentView = FlippedView()
  private var contentHeight: CGFloat = 0

  override func loadView() {
    view = NSView()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    addDemoSections()
  }

  override func viewDidLayout() {
    super.viewDidLayout()
    scrollView.frame = view.bounds
    contentView.frame = CGRect(
      x: 0,
      y: 0,
      width: view.bounds.width,
      height: contentHeight
    )
  }

  private func setupViews() {
    view.wantsLayer = true

    // Setup scroll view
    scrollView.hasVerticalScroller = true
    scrollView.borderType = .noBorder
    view.addSubview(scrollView)

    // Setup content view
    scrollView.documentView = contentView
  }

  private func addDemoSections() {
    var yOffset: CGFloat = 20

    // Section 1: Basic NSImage creation with KeyPath syntax
    yOffset = addSection(
      title: "NSImage Creation - KeyPath Syntax",
      description: "Most concise syntax using KeyPath",
      yOffset: yOffset
    ) { containerView in
      let imageView1 = NSImageView()
      imageView1.image = NSImage.draw(\.star)
      imageView1.imageScaling = .scaleProportionallyUpOrDown
      imageView1.frame = CGRect(x: 16, y: 40, width: 16, height: 16)
      containerView.addSubview(imageView1)

      let imageView2 = NSImageView()
      imageView2.image = NSImage.draw(\.star, scale: 3.0)
      imageView2.imageScaling = .scaleProportionallyUpOrDown
      imageView2.frame = CGRect(x: 40, y: 40, width: 16, height: 16)
      containerView.addSubview(imageView2)

      return 65
    }

    // Section 2: Direct initialization
    yOffset = addSection(
      title: "Direct NSImage Initialization",
      description: "Create images with Drawing instances",
      yOffset: yOffset
    ) { containerView in
      let imageView1 = NSImageView()
      imageView1.image = NSImage(drawing: .heart)
      imageView1.imageScaling = .scaleProportionallyUpOrDown
      imageView1.frame = CGRect(x: 16, y: 40, width: 16, height: 16)
      containerView.addSubview(imageView1)

      let imageView2 = NSImageView()
      imageView2.image = NSImage(drawing: .rocket, scale: 2.0)
      imageView2.imageScaling = .scaleProportionallyUpOrDown
      imageView2.frame = CGRect(x: 40, y: 40, width: 24, height: 24)
      containerView.addSubview(imageView2)

      return 70
    }

    // Section 3: Content modes
    yOffset = addSection(
      title: "Content Modes with Target Size",
      description: "Generate images with specific size and content mode",
      yOffset: yOffset
    ) { containerView in
      let fitImage = NSImage.draw(
        \.mountain,
        size: CGSize(width: 40, height: 30),
        contentMode: .aspectFit
      )

      let fillImage = NSImage.draw(
        \.mountain,
        size: CGSize(width: 40, height: 30),
        contentMode: .aspectFill
      )

      let fitView = createImageView(
        image: fitImage,
        frame: CGRect(x: 16, y: 40, width: 40, height: 30)
      )
      containerView.addSubview(fitView)

      let fitLabel = createLabel(
        text: "Aspect Fit",
        frame: CGRect(x: 16, y: 74, width: 40, height: 16)
      )
      containerView.addSubview(fitLabel)

      let fillView = createImageView(
        image: fillImage,
        frame: CGRect(x: 66, y: 40, width: 40, height: 30)
      )
      containerView.addSubview(fillView)

      let fillLabel = createLabel(
        text: "Aspect Fill",
        frame: CGRect(x: 66, y: 74, width: 40, height: 16)
      )
      containerView.addSubview(fillLabel)

      return 90
    }

    // Section 4: In NSButton
    yOffset = addSection(
      title: "Using in NSButton",
      description: "Set button images easily",
      yOffset: yOffset
    ) { containerView in
      let button1 = NSButton(
        title: "Settings",
        image: NSImage.draw(\.gear),
        target: nil,
        action: nil
      )
      button1.imagePosition = .imageLeading
      button1.bezelStyle = .rounded
      button1.frame = CGRect(x: 16, y: 40, width: 70, height: 22)
      containerView.addSubview(button1)

      let button2 = NSButton(
        image: NSImage.draw(\.heart),
        target: nil,
        action: nil
      )
      button2.bezelStyle = .texturedRounded
      button2.isBordered = true
      button2.frame = CGRect(x: 92, y: 40, width: 30, height: 22)
      containerView.addSubview(button2)

      return 65
    }

    // Section 5: NSImageView with different scaling modes
    yOffset = addSection(
      title: "NSImageView Scaling Modes",
      description: "Standard AppKit scaling mode support",
      yOffset: yOffset
    ) { containerView in
      let imageView1 = createImageView(
        image: NSImage(drawing: .rocket),
        frame: CGRect(x: 16, y: 40, width: 40, height: 40),
        scaling: .scaleProportionallyUpOrDown
      )
      containerView.addSubview(imageView1)

      let label1 = createLabel(
        text: ".scaleProportionallyUpOrDown",
        frame: CGRect(x: 16, y: 84, width: 40, height: 32)
      )
      label1.maximumNumberOfLines = 2
      containerView.addSubview(label1)

      let imageView2 = createImageView(
        image: NSImage(drawing: .rocket),
        frame: CGRect(x: 66, y: 40, width: 40, height: 40),
        scaling: .scaleNone
      )
      containerView.addSubview(imageView2)

      let label2 = createLabel(
        text: ".scaleNone",
        frame: CGRect(x: 66, y: 84, width: 40, height: 16)
      )
      containerView.addSubview(label2)

      return 120
    }

    // Section 6: Drawing in custom NSView
    yOffset = addSection(
      title: "Custom NSView Drawing",
      description: "Draw directly in NSView subclass",
      yOffset: yOffset
    ) { containerView in
      let customView = CustomDrawingView(drawing: .star)
      customView.frame = CGRect(x: 16, y: 40, width: 40, height: 40)
      containerView.addSubview(customView)

      return 90
    }

    contentHeight = yOffset
  }

  // Helper method for creating sections
  private func addSection(
    title: String,
    description: String,
    yOffset: CGFloat,
    content: (NSView) -> CGFloat
  ) -> CGFloat {
    let containerView = NSView()
    containerView.wantsLayer = true
    containerView.layer?.backgroundColor = NSColor.controlBackgroundColor
      .cgColor
    containerView.layer?.cornerRadius = 8

    let titleLabel = NSTextField(labelWithString: title)
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.frame = CGRect(
      x: 16,
      y: 0,
      width: view.bounds.width - 64,
      height: 22
    )
    containerView.addSubview(titleLabel)

    let descLabel = NSTextField(labelWithString: description)
    descLabel.font = .preferredFont(forTextStyle: .caption1)
    descLabel.textColor = .secondaryLabelColor
    descLabel.frame = CGRect(
      x: 16,
      y: 20,
      width: view.bounds.width - 64,
      height: 16
    )
    containerView.addSubview(descLabel)

    let contentHeight = content(containerView)

    // Don't flip coordinates - just position from top
    containerView.frame = CGRect(
      x: 20,
      y: yOffset,
      width: view.bounds.width - 40,
      height: contentHeight
    )

    contentView.addSubview(containerView)

    return yOffset + contentHeight + 15
  }

  private func createImageView(
    image: NSImage?,
    frame: CGRect,
    scaling: NSImageScaling = .scaleProportionallyUpOrDown
  ) -> NSImageView {
    let imageView = NSImageView()
    imageView.image = image
    imageView.imageScaling = scaling
    imageView.wantsLayer = true
    imageView.layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
    imageView.layer?.borderColor = NSColor.separatorColor.cgColor
    imageView.layer?.borderWidth = 1
    imageView.frame = frame
    return imageView
  }

  private func createLabel(text: String, frame: CGRect) -> NSTextField {
    let label = NSTextField(labelWithString: text)
    label.font = .preferredFont(forTextStyle: .caption1)
    label.textColor = .secondaryLabelColor
    label.alignment = .center
    label.frame = frame
    return label
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
