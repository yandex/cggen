#if canImport(UIKit)
import CGGenRuntimeSupport
import SwiftUI
import UIKit

// UIKit View Controller demonstrating cggen API usage
class UIKitDemoViewController: UIViewController {
  private let scrollView = UIScrollView()
  private var contentHeight: CGFloat = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    addDemoSections()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    scrollView.frame = view.bounds
    scrollView.contentSize = CGSize(
      width: view.bounds.width,
      height: contentHeight + 20
    )
  }

  private func setupViews() {
    view.backgroundColor = .systemBackground
    view.addSubview(scrollView)
  }

  private func addDemoSections() {
    var yOffset: CGFloat = 20

    // Section 1: Basic UIImage creation with KeyPath syntax
    yOffset = addSection(
      title: "UIImage Creation - KeyPath Syntax",
      description: "Most concise syntax using KeyPath",
      yOffset: yOffset
    ) { containerView in
      let imageView1 = UIImageView(image: UIImage.draw(\.star))
      imageView1.frame = CGRect(x: 16, y: 40, width: 16, height: 16)
      imageView1.contentMode = .scaleAspectFit
      containerView.addSubview(imageView1)

      let imageView2 = UIImageView(image: UIImage.draw(\.star, scale: 3.0))
      imageView2.frame = CGRect(x: 40, y: 40, width: 16, height: 16)
      imageView2.contentMode = .scaleAspectFit
      containerView.addSubview(imageView2)

      return 70
    }

    // Section 2: Direct initialization
    yOffset = addSection(
      title: "Direct UIImage Initialization",
      description: "Create images with Drawing instances",
      yOffset: yOffset
    ) { containerView in
      let imageView1 = UIImageView(image: UIImage(drawing: .heart))
      imageView1.frame = CGRect(x: 16, y: 40, width: 16, height: 16)
      imageView1.contentMode = .scaleAspectFit
      containerView.addSubview(imageView1)

      let imageView2 = UIImageView(image: UIImage(drawing: .rocket, scale: 2.0))
      imageView2.frame = CGRect(x: 40, y: 40, width: 24, height: 24)
      imageView2.contentMode = .scaleAspectFit
      containerView.addSubview(imageView2)

      return 80
    }

    // Section 3: Content modes
    yOffset = addSection(
      title: "Content Modes with Target Size",
      description: "Generate images with specific size and content mode",
      yOffset: yOffset
    ) { containerView in
      let fitImage = UIImage.draw(
        \.mountain,
        size: CGSize(width: 40, height: 30),
        contentMode: .aspectFit
      )

      let fillImage = UIImage.draw(
        \.mountain,
        size: CGSize(width: 40, height: 30),
        contentMode: .aspectFill
      )

      let fitView = UIImageView(image: fitImage)
      fitView.frame = CGRect(x: 16, y: 40, width: 40, height: 30)
      fitView.backgroundColor = .systemGray6
      fitView.layer.borderColor = UIColor.systemGray4.cgColor
      fitView.layer.borderWidth = 1
      containerView.addSubview(fitView)

      let fitLabel = UILabel()
      fitLabel.text = "Aspect Fit"
      fitLabel.font = .preferredFont(forTextStyle: .caption2)
      fitLabel.textColor = .secondaryLabel
      fitLabel.frame = CGRect(x: 16, y: 74, width: 40, height: 16)
      fitLabel.textAlignment = .center
      containerView.addSubview(fitLabel)

      let fillView = UIImageView(image: fillImage)
      fillView.frame = CGRect(x: 66, y: 40, width: 40, height: 30)
      fillView.backgroundColor = .systemGray6
      fillView.layer.borderColor = UIColor.systemGray4.cgColor
      fillView.layer.borderWidth = 1
      containerView.addSubview(fillView)

      let fillLabel = UILabel()
      fillLabel.text = "Aspect Fill"
      fillLabel.font = .preferredFont(forTextStyle: .caption2)
      fillLabel.textColor = .secondaryLabel
      fillLabel.frame = CGRect(x: 66, y: 74, width: 40, height: 16)
      fillLabel.textAlignment = .center
      containerView.addSubview(fillLabel)

      return 90
    }

    // Section 4: In UIButton
    yOffset = addSection(
      title: "Using in UIButton",
      description: "Set button images easily",
      yOffset: yOffset
    ) { containerView in
      let button1 = UIButton(type: .system)
      button1.setImage(UIImage.draw(\.gear), for: .normal)
      button1.setTitle(" Settings", for: .normal)
      button1.frame = CGRect(x: 16, y: 40, width: 80, height: 30)
      containerView.addSubview(button1)

      let button2 = UIButton(type: .system)
      button2.setImage(UIImage.draw(\.heart), for: .normal)
      button2.tintColor = .systemRed
      button2.frame = CGRect(x: 106, y: 40, width: 30, height: 30)
      containerView.addSubview(button2)

      return 80
    }

    // Section 5: UIImageView with different content modes
    yOffset = addSection(
      title: "UIImageView Content Modes",
      description: "Standard UIKit content mode support",
      yOffset: yOffset
    ) { containerView in
      let imageView1 = UIImageView(image: UIImage(drawing: .rocket))
      imageView1.contentMode = .scaleAspectFit
      imageView1.backgroundColor = .systemGray6
      imageView1.layer.borderColor = UIColor.systemGray4.cgColor
      imageView1.layer.borderWidth = 1
      imageView1.frame = CGRect(x: 16, y: 40, width: 40, height: 40)
      containerView.addSubview(imageView1)

      let label1 = UILabel()
      label1.text = ".scaleAspectFit"
      label1.font = .preferredFont(forTextStyle: .caption2)
      label1.textColor = .secondaryLabel
      label1.frame = CGRect(x: 16, y: 84, width: 40, height: 32)
      label1.textAlignment = .center
      label1.numberOfLines = 2
      containerView.addSubview(label1)

      let imageView2 = UIImageView(image: UIImage(drawing: .rocket))
      imageView2.contentMode = .center
      imageView2.backgroundColor = .systemGray6
      imageView2.layer.borderColor = UIColor.systemGray4.cgColor
      imageView2.layer.borderWidth = 1
      imageView2.frame = CGRect(x: 66, y: 40, width: 40, height: 40)
      containerView.addSubview(imageView2)

      let label2 = UILabel()
      label2.text = ".center"
      label2.font = .preferredFont(forTextStyle: .caption2)
      label2.textColor = .secondaryLabel
      label2.frame = CGRect(x: 66, y: 84, width: 40, height: 16)
      label2.textAlignment = .center
      containerView.addSubview(label2)

      return 120
    }

    contentHeight = yOffset
  }

  // Helper method for creating sections
  private func addSection(
    title: String,
    description: String,
    yOffset: CGFloat,
    content: (UIView) -> CGFloat
  ) -> CGFloat {
    let containerView = UIView()
    containerView.backgroundColor = .systemGray6
    containerView.layer.cornerRadius = 8

    let titleLabel = UILabel()
    titleLabel.text = title
    titleLabel.font = .preferredFont(forTextStyle: .headline)
    titleLabel.frame = CGRect(
      x: 16,
      y: 12,
      width: view.bounds.width - 64,
      height: 22
    )
    containerView.addSubview(titleLabel)

    let descLabel = UILabel()
    descLabel.text = description
    descLabel.font = .preferredFont(forTextStyle: .caption1)
    descLabel.textColor = .secondaryLabel
    descLabel.frame = CGRect(
      x: 16,
      y: 32,
      width: view.bounds.width - 64,
      height: 16
    )
    containerView.addSubview(descLabel)

    let contentHeight = content(containerView)

    containerView.frame = CGRect(
      x: 20,
      y: yOffset,
      width: view.bounds.width - 40,
      height: contentHeight
    )

    scrollView.addSubview(containerView)

    return yOffset + contentHeight + 15
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
