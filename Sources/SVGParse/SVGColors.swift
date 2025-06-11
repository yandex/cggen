public enum SVGColorKeyword: String, CaseIterable {
  case aliceblue
  case antiquewhite
  case aqua
  case aquamarine
  case azure
  case beige
  case bisque
  case black
  case blanchedalmond
  case blue
  case blueviolet
  case brown
  case burlywood
  case cadetblue
  case chartreuse
  case chocolate
  case coral
  case cornflowerblue
  case cornsilk
  case crimson
  case cyan
  case darkblue
  case darkcyan
  case darkgoldenrod
  case darkgray
  case darkgreen
  case darkgrey
  case darkkhaki
  case darkmagenta
  case darkolivegreen
  case darkorange
  case darkorchid
  case darkred
  case darksalmon
  case darkseagreen
  case darkslateblue
  case darkslategray
  case darkslategrey
  case darkturquoise
  case darkviolet
  case deeppink
  case deepskyblue
  case dimgray
  case dimgrey
  case dodgerblue
  case firebrick
  case floralwhite
  case forestgreen
  case fuchsia
  case gainsboro
  case ghostwhite
  case gold
  case goldenrod
  case gray
  case grey
  case green
  case greenyellow
  case honeydew
  case hotpink
  case indianred
  case indigo
  case ivory
  case khaki
  case lavender
  case lavenderblush
  case lawngreen
  case lemonchiffon
  case lightblue
  case lightcoral
  case lightcyan
  case lightgoldenrodyellow
  case lightgray
  case lightgreen
  case lightgrey
  case lightpink
  case lightsalmon
  case lightseagreen
  case lightskyblue
  case lightslategray
  case lightslategrey
  case lightsteelblue
  case lightyellow
  case lime
  case limegreen
  case linen
  case magenta
  case maroon
  case mediumaquamarine
  case mediumblue
  case mediumorchid
  case mediumpurple
  case mediumseagreen
  case mediumslateblue
  case mediumspringgreen
  case mediumturquoise
  case mediumvioletred
  case midnightblue
  case mintcream
  case mistyrose
  case moccasin
  case navajowhite
  case navy
  case oldlace
  case olive
  case olivedrab
  case orange
  case orangered
  case orchid
  case palegoldenrod
  case palegreen
  case paleturquoise
  case palevioletred
  case papayawhip
  case peachpuff
  case peru
  case pink
  case plum
  case powderblue
  case purple
  case red
  case rosybrown
  case royalblue
  case saddlebrown
  case salmon
  case sandybrown
  case seagreen
  case seashell
  case sienna
  case silver
  case skyblue
  case slateblue
  case slategray
  case slategrey
  case snow
  case springgreen
  case steelblue
  case tan
  case teal
  case thistle
  case tomato
  case turquoise
  case violet
  case wheat
  case white
  case whitesmoke
  case yellow
  case yellowgreen

  var color: SVG.Color {
    switch self {
    case .aliceblue:
      SVG.Color(red: 240, green: 248, blue: 255)
    case .antiquewhite:
      SVG.Color(red: 250, green: 235, blue: 215)
    case .aqua:
      SVG.Color(red: 0, green: 255, blue: 255)
    case .aquamarine:
      SVG.Color(red: 127, green: 255, blue: 212)
    case .azure:
      SVG.Color(red: 240, green: 255, blue: 255)
    case .beige:
      SVG.Color(red: 245, green: 245, blue: 220)
    case .bisque:
      SVG.Color(red: 255, green: 228, blue: 196)
    case .black:
      SVG.Color(red: 0, green: 0, blue: 0)
    case .blanchedalmond:
      SVG.Color(red: 255, green: 235, blue: 205)
    case .blue:
      SVG.Color(red: 0, green: 0, blue: 255)
    case .blueviolet:
      SVG.Color(red: 138, green: 43, blue: 226)
    case .brown:
      SVG.Color(red: 165, green: 42, blue: 42)
    case .burlywood:
      SVG.Color(red: 222, green: 184, blue: 135)
    case .cadetblue:
      SVG.Color(red: 95, green: 158, blue: 160)
    case .chartreuse:
      SVG.Color(red: 127, green: 255, blue: 0)
    case .chocolate:
      SVG.Color(red: 210, green: 105, blue: 30)
    case .coral:
      SVG.Color(red: 255, green: 127, blue: 80)
    case .cornflowerblue:
      SVG.Color(red: 100, green: 149, blue: 237)
    case .cornsilk:
      SVG.Color(red: 255, green: 248, blue: 220)
    case .crimson:
      SVG.Color(red: 220, green: 20, blue: 60)
    case .cyan:
      SVG.Color(red: 0, green: 255, blue: 255)
    case .darkblue:
      SVG.Color(red: 0, green: 0, blue: 139)
    case .darkcyan:
      SVG.Color(red: 0, green: 139, blue: 139)
    case .darkgoldenrod:
      SVG.Color(red: 184, green: 134, blue: 11)
    case .darkgray:
      SVG.Color(red: 169, green: 169, blue: 169)
    case .darkgreen:
      SVG.Color(red: 0, green: 100, blue: 0)
    case .darkgrey:
      SVG.Color(red: 169, green: 169, blue: 169)
    case .darkkhaki:
      SVG.Color(red: 189, green: 183, blue: 107)
    case .darkmagenta:
      SVG.Color(red: 139, green: 0, blue: 139)
    case .darkolivegreen:
      SVG.Color(red: 85, green: 107, blue: 47)
    case .darkorange:
      SVG.Color(red: 255, green: 140, blue: 0)
    case .darkorchid:
      SVG.Color(red: 153, green: 50, blue: 204)
    case .darkred:
      SVG.Color(red: 139, green: 0, blue: 0)
    case .darksalmon:
      SVG.Color(red: 233, green: 150, blue: 122)
    case .darkseagreen:
      SVG.Color(red: 143, green: 188, blue: 143)
    case .darkslateblue:
      SVG.Color(red: 72, green: 61, blue: 139)
    case .darkslategray:
      SVG.Color(red: 47, green: 79, blue: 79)
    case .darkslategrey:
      SVG.Color(red: 47, green: 79, blue: 79)
    case .darkturquoise:
      SVG.Color(red: 0, green: 206, blue: 209)
    case .darkviolet:
      SVG.Color(red: 148, green: 0, blue: 211)
    case .deeppink:
      SVG.Color(red: 255, green: 20, blue: 147)
    case .deepskyblue:
      SVG.Color(red: 0, green: 191, blue: 255)
    case .dimgray:
      SVG.Color(red: 105, green: 105, blue: 105)
    case .dimgrey:
      SVG.Color(red: 105, green: 105, blue: 105)
    case .dodgerblue:
      SVG.Color(red: 30, green: 144, blue: 255)
    case .firebrick:
      SVG.Color(red: 178, green: 34, blue: 34)
    case .floralwhite:
      SVG.Color(red: 255, green: 250, blue: 240)
    case .forestgreen:
      SVG.Color(red: 34, green: 139, blue: 34)
    case .fuchsia:
      SVG.Color(red: 255, green: 0, blue: 255)
    case .gainsboro:
      SVG.Color(red: 220, green: 220, blue: 220)
    case .ghostwhite:
      SVG.Color(red: 248, green: 248, blue: 255)
    case .gold:
      SVG.Color(red: 255, green: 215, blue: 0)
    case .goldenrod:
      SVG.Color(red: 218, green: 165, blue: 32)
    case .gray:
      SVG.Color(red: 128, green: 128, blue: 128)
    case .grey:
      SVG.Color(red: 128, green: 128, blue: 128)
    case .green:
      SVG.Color(red: 0, green: 128, blue: 0)
    case .greenyellow:
      SVG.Color(red: 173, green: 255, blue: 47)
    case .honeydew:
      SVG.Color(red: 240, green: 255, blue: 240)
    case .hotpink:
      SVG.Color(red: 255, green: 105, blue: 180)
    case .indianred:
      SVG.Color(red: 205, green: 92, blue: 92)
    case .indigo:
      SVG.Color(red: 75, green: 0, blue: 130)
    case .ivory:
      SVG.Color(red: 255, green: 255, blue: 240)
    case .khaki:
      SVG.Color(red: 240, green: 230, blue: 140)
    case .lavender:
      SVG.Color(red: 230, green: 230, blue: 250)
    case .lavenderblush:
      SVG.Color(red: 255, green: 240, blue: 245)
    case .lawngreen:
      SVG.Color(red: 124, green: 252, blue: 0)
    case .lemonchiffon:
      SVG.Color(red: 255, green: 250, blue: 205)
    case .lightblue:
      SVG.Color(red: 173, green: 216, blue: 230)
    case .lightcoral:
      SVG.Color(red: 240, green: 128, blue: 128)
    case .lightcyan:
      SVG.Color(red: 224, green: 255, blue: 255)
    case .lightgoldenrodyellow:
      SVG.Color(red: 250, green: 250, blue: 210)
    case .lightgray:
      SVG.Color(red: 211, green: 211, blue: 211)
    case .lightgreen:
      SVG.Color(red: 144, green: 238, blue: 144)
    case .lightgrey:
      SVG.Color(red: 211, green: 211, blue: 211)
    case .lightpink:
      SVG.Color(red: 255, green: 182, blue: 193)
    case .lightsalmon:
      SVG.Color(red: 255, green: 160, blue: 122)
    case .lightseagreen:
      SVG.Color(red: 32, green: 178, blue: 170)
    case .lightskyblue:
      SVG.Color(red: 135, green: 206, blue: 250)
    case .lightslategray:
      SVG.Color(red: 119, green: 136, blue: 153)
    case .lightslategrey:
      SVG.Color(red: 119, green: 136, blue: 153)
    case .lightsteelblue:
      SVG.Color(red: 176, green: 196, blue: 222)
    case .lightyellow:
      SVG.Color(red: 255, green: 255, blue: 224)
    case .lime:
      SVG.Color(red: 0, green: 255, blue: 0)
    case .limegreen:
      SVG.Color(red: 50, green: 205, blue: 50)
    case .linen:
      SVG.Color(red: 250, green: 240, blue: 230)
    case .magenta:
      SVG.Color(red: 255, green: 0, blue: 255)
    case .maroon:
      SVG.Color(red: 128, green: 0, blue: 0)
    case .mediumaquamarine:
      SVG.Color(red: 102, green: 205, blue: 170)
    case .mediumblue:
      SVG.Color(red: 0, green: 0, blue: 205)
    case .mediumorchid:
      SVG.Color(red: 186, green: 85, blue: 211)
    case .mediumpurple:
      SVG.Color(red: 147, green: 112, blue: 219)
    case .mediumseagreen:
      SVG.Color(red: 60, green: 179, blue: 113)
    case .mediumslateblue:
      SVG.Color(red: 123, green: 104, blue: 238)
    case .mediumspringgreen:
      SVG.Color(red: 0, green: 250, blue: 154)
    case .mediumturquoise:
      SVG.Color(red: 72, green: 209, blue: 204)
    case .mediumvioletred:
      SVG.Color(red: 199, green: 21, blue: 133)
    case .midnightblue:
      SVG.Color(red: 25, green: 25, blue: 112)
    case .mintcream:
      SVG.Color(red: 245, green: 255, blue: 250)
    case .mistyrose:
      SVG.Color(red: 255, green: 228, blue: 225)
    case .moccasin:
      SVG.Color(red: 255, green: 228, blue: 181)
    case .navajowhite:
      SVG.Color(red: 255, green: 222, blue: 173)
    case .navy:
      SVG.Color(red: 0, green: 0, blue: 128)
    case .oldlace:
      SVG.Color(red: 253, green: 245, blue: 230)
    case .olive:
      SVG.Color(red: 128, green: 128, blue: 0)
    case .olivedrab:
      SVG.Color(red: 107, green: 142, blue: 35)
    case .orange:
      SVG.Color(red: 255, green: 165, blue: 0)
    case .orangered:
      SVG.Color(red: 255, green: 69, blue: 0)
    case .orchid:
      SVG.Color(red: 218, green: 112, blue: 214)
    case .palegoldenrod:
      SVG.Color(red: 238, green: 232, blue: 170)
    case .palegreen:
      SVG.Color(red: 152, green: 251, blue: 152)
    case .paleturquoise:
      SVG.Color(red: 175, green: 238, blue: 238)
    case .palevioletred:
      SVG.Color(red: 219, green: 112, blue: 147)
    case .papayawhip:
      SVG.Color(red: 255, green: 239, blue: 213)
    case .peachpuff:
      SVG.Color(red: 255, green: 218, blue: 185)
    case .peru:
      SVG.Color(red: 205, green: 133, blue: 63)
    case .pink:
      SVG.Color(red: 255, green: 192, blue: 203)
    case .plum:
      SVG.Color(red: 221, green: 160, blue: 221)
    case .powderblue:
      SVG.Color(red: 176, green: 224, blue: 230)
    case .purple:
      SVG.Color(red: 128, green: 0, blue: 128)
    case .red:
      SVG.Color(red: 255, green: 0, blue: 0)
    case .rosybrown:
      SVG.Color(red: 188, green: 143, blue: 143)
    case .royalblue:
      SVG.Color(red: 65, green: 105, blue: 225)
    case .saddlebrown:
      SVG.Color(red: 139, green: 69, blue: 19)
    case .salmon:
      SVG.Color(red: 250, green: 128, blue: 114)
    case .sandybrown:
      SVG.Color(red: 244, green: 164, blue: 96)
    case .seagreen:
      SVG.Color(red: 46, green: 139, blue: 87)
    case .seashell:
      SVG.Color(red: 255, green: 245, blue: 237)
    case .sienna:
      SVG.Color(red: 160, green: 82, blue: 45)
    case .silver:
      SVG.Color(red: 192, green: 192, blue: 192)
    case .skyblue:
      SVG.Color(red: 135, green: 206, blue: 235)
    case .slateblue:
      SVG.Color(red: 106, green: 90, blue: 205)
    case .slategray:
      SVG.Color(red: 112, green: 128, blue: 144)
    case .slategrey:
      SVG.Color(red: 112, green: 128, blue: 144)
    case .snow:
      SVG.Color(red: 255, green: 250, blue: 250)
    case .springgreen:
      SVG.Color(red: 0, green: 255, blue: 127)
    case .steelblue:
      SVG.Color(red: 70, green: 130, blue: 180)
    case .tan:
      SVG.Color(red: 210, green: 180, blue: 140)
    case .teal:
      SVG.Color(red: 0, green: 128, blue: 128)
    case .thistle:
      SVG.Color(red: 216, green: 191, blue: 216)
    case .tomato:
      SVG.Color(red: 255, green: 99, blue: 71)
    case .turquoise:
      SVG.Color(red: 64, green: 224, blue: 208)
    case .violet:
      SVG.Color(red: 238, green: 130, blue: 238)
    case .wheat:
      SVG.Color(red: 245, green: 222, blue: 179)
    case .white:
      SVG.Color(red: 255, green: 255, blue: 255)
    case .whitesmoke:
      SVG.Color(red: 245, green: 245, blue: 245)
    case .yellow:
      SVG.Color(red: 255, green: 255, blue: 0)
    case .yellowgreen:
      SVG.Color(red: 154, green: 205, blue: 50)
    }
  }
}
