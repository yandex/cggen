#if canImport(UIKit)
import CGGenBytecode
import SwiftUI
import UIKit

// Example model for table view
struct UIKitExample {
  var code: String
  var createView: () -> UIView
}

// UIKit View Controller demonstrating cggen API usage
class UIKitDemoViewController: UIViewController {
  private let tableView = UITableView(frame: .zero, style: .grouped)
  private var examples: [(category: String, items: [UIKitExample])] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    setupExamples()
    setupViews()
  }

  private func setupExamples() {
    #if swift(>=6.1)
    examples = [
      (
        category: "UIImage Creation",
        items: [
          UIKitExample(
            code: "UIImage.draw(\\.star)",
            createView: {
              let imageView = UIImageView(image: UIImage.draw(\.star))
              imageView.contentMode = .scaleAspectFit
              imageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
              return imageView
            }
          ),
          UIKitExample(
            code: "UIImage(drawing: .heart)",
            createView: {
              let imageView = UIImageView(image: UIImage(drawing: .heart))
              imageView.contentMode = .scaleAspectFit
              imageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
              return imageView
            }
          ),
          UIKitExample(
            code: "UIImage.draw(\\.rocket, scale: 3.0)",
            createView: {
              let imageView = UIImageView(image: UIImage.draw(
                \.rocket,
                scale: 3.0
              ))
              imageView.contentMode = .scaleAspectFit
              imageView.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
              return imageView
            }
          ),
        ]
      ),
      (
        category: "Sizing",
        items: [
          UIKitExample(
            code: "UIImage.draw(\\.mountain,\n  size: CGSize(width: 60, height: 40),\n  contentMode: .aspectFit)",
            createView: {
              let imageView = UIImageView(
                image: UIImage.draw(
                  \.mountain,
                  size: CGSize(width: 60, height: 40),
                  contentMode: .aspectFit
                )
              )
              imageView.contentMode = .scaleAspectFit
              imageView.backgroundColor = .systemGray6
              imageView.layer.borderColor = UIColor.systemGray4.cgColor
              imageView.layer.borderWidth = 1
              imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 40)
              return imageView
            }
          ),
          UIKitExample(
            code: "UIImage.draw(\\.mountain,\n  size: CGSize(width: 60, height: 40),\n  contentMode: .aspectFill)",
            createView: {
              let imageView = UIImageView(
                image: UIImage.draw(
                  \.mountain,
                  size: CGSize(width: 60, height: 40),
                  contentMode: .aspectFill
                )
              )
              imageView.contentMode = .scaleAspectFit
              imageView.backgroundColor = .systemGray6
              imageView.layer.borderColor = UIColor.systemGray4.cgColor
              imageView.layer.borderWidth = 1
              imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 40)
              return imageView
            }
          ),
        ]
      ),
      (
        category: "UIButton Integration",
        items: [
          UIKitExample(
            code: "button.setImage(UIImage.draw(\\.gear), for: .normal)",
            createView: {
              let button = UIButton(type: .system)
              button.setImage(UIImage.draw(\.gear), for: .normal)
              button.setTitle(" Settings", for: .normal)
              button.frame = CGRect(x: 0, y: 0, width: 100, height: 44)
              return button
            }
          ),
          UIKitExample(
            code: "// Tinted button\nbutton.setImage(UIImage.draw(\\.heart), for: .normal)\nbutton.tintColor = .systemRed",
            createView: {
              let button = UIButton(type: .system)
              button.setImage(UIImage.draw(\.heart), for: .normal)
              button.tintColor = .systemRed
              button.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
              return button
            }
          ),
        ]
      ),
      (
        category: "UIImageView Content Modes",
        items: [
          UIKitExample(
            code: "imageView.image = UIImage(drawing: .rocket)\nimageView.contentMode = .scaleAspectFit",
            createView: {
              let imageView = UIImageView(image: UIImage(drawing: .rocket))
              imageView.contentMode = .scaleAspectFit
              imageView.backgroundColor = .systemGray6
              imageView.layer.borderColor = UIColor.systemGray4.cgColor
              imageView.layer.borderWidth = 1
              imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
              return imageView
            }
          ),
          UIKitExample(
            code: "imageView.image = UIImage(drawing: .star)\nimageView.contentMode = .center",
            createView: {
              let imageView = UIImageView(image: UIImage(drawing: .star))
              imageView.contentMode = .center
              imageView.backgroundColor = .systemGray6
              imageView.layer.borderColor = UIColor.systemGray4.cgColor
              imageView.layer.borderWidth = 1
              imageView.frame = CGRect(x: 0, y: 0, width: 60, height: 60)
              return imageView
            }
          ),
        ]
      ),
    ]
    #else
    examples = []
    #endif
  }

  private func setupViews() {
    view.backgroundColor = .systemBackground

    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(
      UIKitExampleCell.self,
      forCellReuseIdentifier: "ExampleCell"
    )
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 100

    view.addSubview(tableView)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.frame = view.bounds
  }
}

// MARK: - UITableView DataSource & Delegate

extension UIKitDemoViewController: UITableViewDataSource, UITableViewDelegate {
  func numberOfSections(in _: UITableView) -> Int {
    examples.count
  }

  func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
    examples[section].items.count
  }

  func tableView(
    _: UITableView,
    titleForHeaderInSection section: Int
  ) -> String? {
    examples[section].category
  }

  func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "ExampleCell",
      for: indexPath
    ) as! UIKitExampleCell
    let example = examples[indexPath.section].items[indexPath.row]
    cell.configure(with: example)
    return cell
  }
}

// Custom cell for displaying examples
class UIKitExampleCell: UITableViewCell {
  private let codeLabel = UILabel()
  private let containerView = UIView()
  private var exampleView: UIView?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupCell()
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupCell() {
    selectionStyle = .none

    codeLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
    codeLabel.textColor = .label
    codeLabel.numberOfLines = 0

    contentView.addSubview(codeLabel)
    contentView.addSubview(containerView)
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    let padding: CGFloat = 16
    let spacing: CGFloat = 8

    // Layout code label
    let labelSize = codeLabel.sizeThatFits(CGSize(
      width: contentView.bounds.width - padding * 2,
      height: .greatestFiniteMagnitude
    ))
    codeLabel.frame = CGRect(
      x: padding,
      y: 12,
      width: contentView.bounds.width - padding * 2,
      height: labelSize.height
    )

    // Layout container view
    let containerY = codeLabel.frame.maxY + spacing
    if let exampleView {
      containerView.frame = CGRect(
        x: padding,
        y: containerY,
        width: exampleView.frame.width,
        height: exampleView.frame.height
      )
      exampleView.frame = containerView.bounds
    } else {
      containerView.frame = CGRect(
        x: padding,
        y: containerY,
        width: 100,
        height: 44
      )
    }
  }

  override func sizeThatFits(_ size: CGSize) -> CGSize {
    let padding: CGFloat = 16
    let spacing: CGFloat = 8

    let labelSize = codeLabel.sizeThatFits(CGSize(
      width: size.width - padding * 2,
      height: .greatestFiniteMagnitude
    ))
    let exampleHeight = exampleView?.frame.height ?? 44

    let totalHeight = 12 + labelSize.height + spacing + exampleHeight + 12
    return CGSize(width: size.width, height: totalHeight)
  }

  func configure(with example: UIKitExample) {
    codeLabel.text = example.code

    // Remove old views
    exampleView?.removeFromSuperview()

    // Add new view
    let view = example.createView()
    containerView.addSubview(view)
    exampleView = view

    setNeedsLayout()
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
