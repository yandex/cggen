// Copyright (c) 2018 Yandex LLC. All rights reserved.
// Author: Alexander Skvortsov <askvortsov@yandex-team.ru>

import PDFParse

struct Image {
  struct Name {
    let snakeCase: String
    let camelCase: String
    init(snakeCase: String) {
      self.snakeCase = snakeCase
      camelCase = snakeCase.snakeToCamelCase()
    }
  }

  let name: Name
  let route: DrawRoute
}
