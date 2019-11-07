@inlinable
public func zip<A1, A2, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  with f: @escaping (A1, A2) -> R
) -> Parser<D, R> {
  p1.flatMap { a in p2.map { b in f(a, b) } }
}

@inlinable
public func zip<A1, A2, A3, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  with f: @escaping (A1, A2, A3) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, with: identity))
  { f($0, $1.0, $1.1) }
}

@inlinable
public func zip<A1, A2, A3, A4, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  with f: @escaping (A1, A2, A3, A4) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, with: identity))
  { f($0, $1.0, $1.1, $1.2) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  with f: @escaping (A1, A2, A3, A4, A5) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  with f: @escaping (A1, A2, A3, A4, A5, A6) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  _ p33: Parser<D, A33>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30, $1.31) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  _ p33: Parser<D, A33>,
  _ p34: Parser<D, A34>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30, $1.31, $1.32) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  _ p33: Parser<D, A33>,
  _ p34: Parser<D, A34>,
  _ p35: Parser<D, A35>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30, $1.31, $1.32, $1.33) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  _ p33: Parser<D, A33>,
  _ p34: Parser<D, A34>,
  _ p35: Parser<D, A35>,
  _ p36: Parser<D, A36>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30, $1.31, $1.32, $1.33, $1.34) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  _ p33: Parser<D, A33>,
  _ p34: Parser<D, A34>,
  _ p35: Parser<D, A35>,
  _ p36: Parser<D, A36>,
  _ p37: Parser<D, A37>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, p37, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30, $1.31, $1.32, $1.33, $1.34, $1.35) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  _ p33: Parser<D, A33>,
  _ p34: Parser<D, A34>,
  _ p35: Parser<D, A35>,
  _ p36: Parser<D, A36>,
  _ p37: Parser<D, A37>,
  _ p38: Parser<D, A38>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, p37, p38, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30, $1.31, $1.32, $1.33, $1.34, $1.35, $1.36) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  _ p33: Parser<D, A33>,
  _ p34: Parser<D, A34>,
  _ p35: Parser<D, A35>,
  _ p36: Parser<D, A36>,
  _ p37: Parser<D, A37>,
  _ p38: Parser<D, A38>,
  _ p39: Parser<D, A39>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, p37, p38, p39, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30, $1.31, $1.32, $1.33, $1.34, $1.35, $1.36, $1.37) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39, A40, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  _ p33: Parser<D, A33>,
  _ p34: Parser<D, A34>,
  _ p35: Parser<D, A35>,
  _ p36: Parser<D, A36>,
  _ p37: Parser<D, A37>,
  _ p38: Parser<D, A38>,
  _ p39: Parser<D, A39>,
  _ p40: Parser<D, A40>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39, A40) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, p37, p38, p39, p40, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30, $1.31, $1.32, $1.33, $1.34, $1.35, $1.36, $1.37, $1.38) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39, A40, A41, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  _ p33: Parser<D, A33>,
  _ p34: Parser<D, A34>,
  _ p35: Parser<D, A35>,
  _ p36: Parser<D, A36>,
  _ p37: Parser<D, A37>,
  _ p38: Parser<D, A38>,
  _ p39: Parser<D, A39>,
  _ p40: Parser<D, A40>,
  _ p41: Parser<D, A41>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39, A40, A41) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, p37, p38, p39, p40, p41, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30, $1.31, $1.32, $1.33, $1.34, $1.35, $1.36, $1.37, $1.38, $1.39) }
}

@inlinable
public func zip<A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39, A40, A41, A42, D, R>(
  _ p1: Parser<D, A1>,
  _ p2: Parser<D, A2>,
  _ p3: Parser<D, A3>,
  _ p4: Parser<D, A4>,
  _ p5: Parser<D, A5>,
  _ p6: Parser<D, A6>,
  _ p7: Parser<D, A7>,
  _ p8: Parser<D, A8>,
  _ p9: Parser<D, A9>,
  _ p10: Parser<D, A10>,
  _ p11: Parser<D, A11>,
  _ p12: Parser<D, A12>,
  _ p13: Parser<D, A13>,
  _ p14: Parser<D, A14>,
  _ p15: Parser<D, A15>,
  _ p16: Parser<D, A16>,
  _ p17: Parser<D, A17>,
  _ p18: Parser<D, A18>,
  _ p19: Parser<D, A19>,
  _ p20: Parser<D, A20>,
  _ p21: Parser<D, A21>,
  _ p22: Parser<D, A22>,
  _ p23: Parser<D, A23>,
  _ p24: Parser<D, A24>,
  _ p25: Parser<D, A25>,
  _ p26: Parser<D, A26>,
  _ p27: Parser<D, A27>,
  _ p28: Parser<D, A28>,
  _ p29: Parser<D, A29>,
  _ p30: Parser<D, A30>,
  _ p31: Parser<D, A31>,
  _ p32: Parser<D, A32>,
  _ p33: Parser<D, A33>,
  _ p34: Parser<D, A34>,
  _ p35: Parser<D, A35>,
  _ p36: Parser<D, A36>,
  _ p37: Parser<D, A37>,
  _ p38: Parser<D, A38>,
  _ p39: Parser<D, A39>,
  _ p40: Parser<D, A40>,
  _ p41: Parser<D, A41>,
  _ p42: Parser<D, A42>,
  with f: @escaping (A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, A16, A17, A18, A19, A20, A21, A22, A23, A24, A25, A26, A27, A28, A29, A30, A31, A32, A33, A34, A35, A36, A37, A38, A39, A40, A41, A42) -> R
) -> Parser<D, R> {
  zip(p1, zip(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, p37, p38, p39, p40, p41, p42, with: identity))
  { f($0, $1.0, $1.1, $1.2, $1.3, $1.4, $1.5, $1.6, $1.7, $1.8, $1.9, $1.10, $1.11, $1.12, $1.13, $1.14, $1.15, $1.16, $1.17, $1.18, $1.19, $1.20, $1.21, $1.22, $1.23, $1.24, $1.25, $1.26, $1.27, $1.28, $1.29, $1.30, $1.31, $1.32, $1.33, $1.34, $1.35, $1.36, $1.37, $1.38, $1.39, $1.40) }
}
