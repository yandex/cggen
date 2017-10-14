// Copyright (c) 2017 Yandex LLC. All rights reserved.
// Author: Alfred Zien <zienag@yandex-team.ru>

import Foundation

extension String {
  func capitalizedFirst() -> String {
    return prefix(1).uppercased() + dropFirst()
  }
  func snakeToCamelCase() -> String {
    return components(separatedBy: "_").map { $0.capitalizedFirst()}.joined()
  }
}
