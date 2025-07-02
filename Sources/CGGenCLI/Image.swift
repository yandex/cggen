import CGGenIR

struct Output {
  var image: Image
  var pathRoutines: [PathRoutine]
}

struct Image {
  let name: String
  let route: DrawRoutine
}
