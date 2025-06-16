@preconcurrency import CoreGraphics

public struct DrawRoutine: Sendable {
  public var boundingRect: CGRect
  public var gradients: [String: Gradient]
  public var subroutines: [String: DrawRoutine]
  public var steps: [DrawStep]

  public init(
    boundingRect: CGRect,
    gradients: [String: Gradient],
    subroutines: [String: DrawRoutine],
    steps: [DrawStep]
  ) {
    self.boundingRect = boundingRect
    self.gradients = gradients
    self.subroutines = subroutines
    self.steps = steps
  }
}

public struct PathRoutine: Sendable {
  public var id: String
  public var content: [PathSegment]

  public init(id: String, content: [PathSegment]) {
    self.id = id
    self.content = content
  }
}

public struct Routines: Sendable {
  public var drawRoutine: DrawRoutine
  public var pathRoutines: [PathRoutine]

  public init(drawRoutine: DrawRoutine, pathRoutines: [PathRoutine] = []) {
    self.drawRoutine = drawRoutine
    self.pathRoutines = pathRoutines
  }
}
