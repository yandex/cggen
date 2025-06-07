#if canImport(UIKit)
import CGGenRuntimeSupport
import SwiftUI
import UIKit

// UIKit View Controller demonstrating cggen API usage
class UIKitDemoViewController: UIViewController {
  private let scrollView = UIScrollView()
  private let stackView = UIStackView()

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    addDemoSections()
  }

  private func setupViews() {
    view.backgroundColor = .systemBackground

    // Setup scroll view
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(scrollView)

    // Setup stack view
    stackView.axis = .vertical
    stackView.alignment = .leading
    stackView.spacing = 30
    stackView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(stackView)

    // Constraints
    NSLayoutConstraint.activate([
      scrollView.topAnchor
        .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      stackView.topAnchor.constraint(
        equalTo: scrollView.topAnchor,
        constant: 20
      ),
      stackView.leadingAnchor.constraint(
        equalTo: scrollView.leadingAnchor,
        constant: 20
      ),
      stackView.trailingAnchor.constraint(
        equalTo: scrollView.trailingAnchor,
        constant: -20
      ),
      stackView.bottomAnchor.constraint(
        equalTo: scrollView.bottomAnchor,
        constant: -20
      ),
      stackView.widthAnchor.constraint(
        equalTo: scrollView.widthAnchor,
        constant: -40
      ),
    ])
  }

  private func addDemoSections() {
    // Section 1: Basic UIImage creation with KeyPath syntax
    addSection(title: "UIImage Creation - KeyPath Syntax (Preferred)") {
      let codeLabel = createCodeLabel("""
      // Using KeyPath syntax - most concise
      let icon = UIImage.draw(\\.star)
      let largeIcon = UIImage.draw(\\.star, scale: 3.0)
      """)

      let imageView1 = UIImageView(image: UIImage.draw(\.star))
      let imageView2 = UIImageView(image: UIImage.draw(\.star, scale: 3.0))

      let imagesStack = UIStackView(arrangedSubviews: [imageView1, imageView2])
      imagesStack.axis = .horizontal
      imagesStack.spacing = 20

      return UIStackView(arrangedSubviews: [codeLabel, imagesStack])
    }

    // Section 2: Direct initialization
    addSection(title: "Direct UIImage Initialization") {
      let codeLabel = createCodeLabel("""
      // Direct initialization
      let heart = UIImage(drawing: .heart)
      let rocket = UIImage(drawing: .rocket, scale: 2.0)
      """)

      let imageView1 = UIImageView(image: UIImage(drawing: .heart))
      let imageView2 = UIImageView(image: UIImage(drawing: .rocket, scale: 2.0))

      let imagesStack = UIStackView(arrangedSubviews: [imageView1, imageView2])
      imagesStack.axis = .horizontal
      imagesStack.spacing = 20

      return UIStackView(arrangedSubviews: [codeLabel, imagesStack])
    }

    // Section 3: Content modes
    addSection(title: "Content Modes with Target Size") {
      let codeLabel = createCodeLabel("""
      // Generate images with specific size and content mode
      let thumbnail = UIImage.draw(
        \\.mountain,
        size: CGSize(width: 100, height: 60),
        contentMode: .aspectFit
      )
      """)

      let fitImage = UIImage.draw(
        \.mountain,
        size: CGSize(width: 100, height: 60),
        contentMode: .aspectFit
      )

      let fillImage = UIImage.draw(
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

      let imagesStack = UIStackView(arrangedSubviews: [fitView, fillView])
      imagesStack.axis = .horizontal
      imagesStack.spacing = 20
      imagesStack.distribution = .fillEqually

      return UIStackView(arrangedSubviews: [codeLabel, imagesStack])
    }

    // Section 4: In UIButton
    addSection(title: "Using in UIButton") {
      let codeLabel = createCodeLabel("""
      // Set button image
      button.setImage(UIImage.draw(\\.gear), for: .normal)
      """)

      let button1 = UIButton(type: .system)
      button1.setImage(UIImage.draw(\.gear), for: .normal)
      button1.setTitle(" Settings", for: .normal)

      let button2 = UIButton(type: .system)
      button2.setImage(UIImage.draw(\.heart), for: .normal)
      button2.tintColor = .systemRed

      let buttonsStack = UIStackView(arrangedSubviews: [button1, button2])
      buttonsStack.axis = .horizontal
      buttonsStack.spacing = 20

      return UIStackView(arrangedSubviews: [codeLabel, buttonsStack])
    }

    // Section 5: UIImageView with different content modes
    addSection(title: "UIImageView Content Modes") {
      let codeLabel = createCodeLabel("""
      imageView.image = UIImage(drawing: .rocket)
      imageView.contentMode = .scaleAspectFit
      """)

      let imageView1 = UIImageView(image: UIImage(drawing: .rocket))
      imageView1.contentMode = .scaleAspectFit
      imageView1.backgroundColor = .systemGray6
      imageView1.layer.borderColor = UIColor.systemGray4.cgColor
      imageView1.layer.borderWidth = 1
      imageView1.widthAnchor.constraint(equalToConstant: 80).isActive = true
      imageView1.heightAnchor.constraint(equalToConstant: 80).isActive = true

      let imageView2 = UIImageView(image: UIImage(drawing: .rocket))
      imageView2.contentMode = .center
      imageView2.backgroundColor = .systemGray6
      imageView2.layer.borderColor = UIColor.systemGray4.cgColor
      imageView2.layer.borderWidth = 1
      imageView2.widthAnchor.constraint(equalToConstant: 80).isActive = true
      imageView2.heightAnchor.constraint(equalToConstant: 80).isActive = true

      let labeledView1 = createLabeledView(
        view: imageView1,
        label: ".scaleAspectFit"
      )
      let labeledView2 = createLabeledView(view: imageView2, label: ".center")

      let imagesStack = UIStackView(arrangedSubviews: [
        labeledView1,
        labeledView2,
      ])
      imagesStack.axis = .horizontal
      imagesStack.spacing = 20

      return UIStackView(arrangedSubviews: [codeLabel, imagesStack])
    }
  }

  // Helper methods
  private func addSection(title: String, content: () -> UIView) {
    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .headline)

    let contentView = content()
    let contentStack = contentView as? UIStackView ?? {
      let stack = UIStackView(arrangedSubviews: [contentView])
      stack.axis = .vertical
      stack.spacing = 10
      stack.alignment = .leading
      return stack
    }()

    let sectionStack = UIStackView(arrangedSubviews: [titleLabel, contentStack])
    sectionStack.axis = .vertical
    sectionStack.spacing = 10
    sectionStack.alignment = .fill

    let container = UIView()
    container.backgroundColor = .systemGray6
    container.layer.cornerRadius = 8
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

  private func createCodeLabel(_ code: String) -> UILabel {
    let label = UILabel()
    label.text = code
    label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    label.textColor = .label
    label.numberOfLines = 0
    label.backgroundColor = .systemBackground
    label.layer.cornerRadius = 4
    label.layer.borderColor = UIColor.systemGray4.cgColor
    label.layer.borderWidth = 1

    // Add padding
    let paddedLabel = UIView()
    paddedLabel.addSubview(label)
    label.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: paddedLabel.topAnchor, constant: 8),
      label.leadingAnchor.constraint(
        equalTo: paddedLabel.leadingAnchor,
        constant: 8
      ),
      label.trailingAnchor.constraint(
        equalTo: paddedLabel.trailingAnchor,
        constant: -8
      ),
      label.bottomAnchor.constraint(
        equalTo: paddedLabel.bottomAnchor,
        constant: -8
      ),
    ])

    return label
  }

  private func createImageViewWithBorder(
    image: UIImage?,
    label: String
  ) -> UIView {
    let imageView = UIImageView(image: image)
    imageView.contentMode = .scaleAspectFit
    imageView.backgroundColor = .systemBackground
    imageView.layer.borderColor = UIColor.systemGray4.cgColor
    imageView.layer.borderWidth = 1
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.widthAnchor.constraint(equalToConstant: 100).isActive = true
    imageView.heightAnchor.constraint(equalToConstant: 60).isActive = true

    return createLabeledView(view: imageView, label: label)
  }

  private func createLabeledView(view: UIView, label: String) -> UIView {
    let labelView = UILabel()
    labelView.text = label
    labelView.font = .preferredFont(forTextStyle: .caption1)
    labelView.textColor = .secondaryLabel
    labelView.textAlignment = .center

    let stack = UIStackView(arrangedSubviews: [view, labelView])
    stack.axis = .vertical
    stack.spacing = 4
    stack.alignment = .center

    return stack
  }
}

// SwiftUI wrapper
struct UIKitDemo: UIViewControllerRepresentable {
  func makeUIViewController(context _: Context) -> UIKitDemoViewController {
    UIKitDemoViewController()
  }

  func updateUIViewController(_: UIKitDemoViewController, context _: Context) {}
}

#Preview {
  UIKitDemo()
}

#endif
