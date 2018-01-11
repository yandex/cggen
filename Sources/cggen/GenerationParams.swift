// Copyright (c) 2018 Yandex LLC. All rights reserved.
// Author: Alexander Skvortsov <askvortsov@yandex-team.ru>

struct GenerationParams {
  enum Style: String {
    case plain
    case swiftFriendly = "swift-friendly"
  }

  let style: Style
  let importAsModules: Bool
  let prefix: String
  let module: String
}
