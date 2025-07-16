import Darwin

/// Represents Unix signals as type-safe Int32 wrappers.
public struct Signal: Hashable, Sendable {
  public let value: Int32

  @inlinable
  public init(_ value: Int32) {
    self.value = value
  }

  // Common signals
  public static let interrupt = Signal(SIGINT)
  public static let terminate = Signal(SIGTERM)
  public static let bus = Signal(SIGBUS)
  public static let segmentationFault = Signal(SIGSEGV)
  public static let abort = Signal(SIGABRT)
  public static let illegalInstruction = Signal(SIGILL)
  public static let floatingPointException = Signal(SIGFPE)
  public static let pipe = Signal(SIGPIPE)
  public static let alarm = Signal(SIGALRM)
  public static let hangup = Signal(SIGHUP)
  public static let quit = Signal(SIGQUIT)
  public static let trap = Signal(SIGTRAP)
  public static let kill = Signal(SIGKILL)

  public var name: String {
    switch value {
    case SIGINT: "SIGINT"
    case SIGTERM: "SIGTERM"
    case SIGBUS: "SIGBUS"
    case SIGSEGV: "SIGSEGV"
    case SIGABRT: "SIGABRT"
    case SIGILL: "SIGILL"
    case SIGFPE: "SIGFPE"
    case SIGPIPE: "SIGPIPE"
    case SIGALRM: "SIGALRM"
    case SIGHUP: "SIGHUP"
    case SIGQUIT: "SIGQUIT"
    case SIGTRAP: "SIGTRAP"
    case SIGKILL: "SIGKILL"
    default: "SIG\(value)"
    }
  }

  public func raise() {
    Darwin.raise(value)
  }
}

/// Provides a Swift-friendly API for Unix signal handling with automatic
/// handler chaining.
public enum SignalHandling {
  /// Permanently intercepts the specified signals.
  /// - Parameters:
  ///   - signals: The signals to intercept
  ///   - onSignal: The action to execute when any of the signals is received.
  /// Takes the signal as parameter.
  public static func intercepting(
    _ signals: Signal...,
    onSignal: @escaping (Signal) -> Void
  ) {
    let signals = Array(Set(signals)).sorted { $0.value < $1.value }
    for signal in signals {
      push(for: signal, onSignal)
    }
  }

  /// Temporarily intercepts the specified signals, executes the body, then
  /// restores previous handlers.
  /// - Parameters:
  ///   - signals: The signals to intercept
  ///   - onSignal: The action to execute when any of the signals is received.
  /// Takes the signal as parameter.
  ///   - body: The code to execute while the signals are being intercepted
  /// - Returns: The result of the body closure
  public static func intercepting<T>(
    _ signals: Signal...,
    body: () throws -> T,
    onSignal: @escaping (Signal) -> Void = { _ in }
  ) rethrows -> T {
    try withoutActuallyEscaping(onSignal) { action in
      let signals = Array(Set(signals)).sorted { $0.value < $1.value }
      for signal in signals {
        push(for: signal) { action($0) }
      }
      defer {
        signals.forEach { pop(for: $0) }
      }
      return try body()
    }
  }

  /// Installs a low-level signal handler using the Unix signal() function.
  /// - Parameters:
  ///   - signal: The signal to handle
  ///   - handler: The handler to install, or nil for SIG_DFL
  /// - Returns: The previous handler
  @discardableResult
  public static func signal(
    _ signal: Signal,
    _ handler: (@convention(c) (Int32) -> Void)?
  ) -> (@convention(c) (Int32) -> Void)? {
    Darwin.signal(signal.value, handler ?? SIG_DFL)
  }

  // MARK: - Private

  /// Tracks installed handlers and the original Unix handler for a signal.
  private struct SignalEntry {
    var handlers: [(Signal) -> Void] = []
    var originalHandler: (@convention(c) (Int32) -> Void)?
  }

  private nonisolated(unsafe)
  static var handlerRegistry = [Signal: SignalEntry]()

  private static func push(
    for signal: Signal,
    _ body: @escaping (Signal) -> Void
  ) {
    with(&handlerRegistry[signal, default: SignalEntry()]) {
      if $0.handlers.isEmpty {
        $0.originalHandler = Self.signal(signal) { value in
          let sig = Signal(value)
          let state = Self.handlerRegistry[sig]

          guard let state else { return }
          state.handlers.reversed().forEach { $0(sig) }

          Self.signal(sig, state.originalHandler)
          sig.raise()
        }
      }
      $0.handlers.append(body)
    }
  }

  private static func pop(for signal: Signal) {
    with(&handlerRegistry[signal]) {
      _ = $0?.handlers.popLast()
      if $0?.handlers.isEmpty == true {
        Self.signal(signal, $0?.originalHandler)
        $0 = nil
      }
    }
  }
}
