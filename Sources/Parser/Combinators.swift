//
//  Combinators.swift
//  
//
//  Created by Markus Kasperczyk on 21.10.23.
//

public struct OrParser<P1 : Parser, P2 : Parser> : Parser where
P1.Tape == P2.Tape, P1.Output == P2.Output {
    
    public let p1 : P1
    public let p2 : P2
    
    public func parse(_ input: P1.Tape) -> [(output: P1.Output, tail: P1.Tape)] {
        p1.parse(input) + p2.parse(input)
    }
}

public struct OrShortCircuitParser<P1 : Parser, P2 : Parser> : Parser where
P1.Tape == P2.Tape, P1.Output == P2.Output {
    
    public let p1 : P1
    public let p2 : P2
    
    public func parse(_ input: P1.Tape) -> [(output: P1.Output, tail: P1.Tape)] {
        let results = p1.parse(input)
        return results.isEmpty ? p2.parse(input) : results
    }
}

public struct MapParser<Wrapped: Parser, Output> : Parser {
    public let wrapped : Wrapped
    public let trafo : (Wrapped.Output) -> Output
    public func parse(_ input: Wrapped.Tape) -> [(output: Output, tail: Wrapped.Tape)] {
        wrapped.parse(input).map{(trafo($0), $1)}
    }
}

public struct CompactMapParser<Wrapped: Parser, Output> : Parser {
    public let wrapped : Wrapped
    public let trafo : (Wrapped.Output) -> Output?
    public func parse(_ input: Wrapped.Tape) -> [(output: Output, tail: Wrapped.Tape)] {
        wrapped.parse(input).compactMap{res, tail in trafo(res).map{($0, tail)}}
    }
}

public struct FlatMapParser<Wrapped: Parser, Next: Parser> : Parser where Wrapped.Tape == Next.Tape {
    public let wrapped : Wrapped
    public let trafo : (Wrapped.Output) -> Next
    public func parse(_ input: Wrapped.Tape) -> [(output: Next.Output, tail: Wrapped.Tape)] {
        wrapped.parse(input).flatMap {trafo($0).parse($1)}
    }
}

public struct Success<Tape, Output> : Parser {
    public let value : Output
    public init(_ value: Output) {
        self.value = value
    }
    public func parse(_ input: Tape) -> [(output: Output, tail: Tape)] {
        [(value, input)]
    }
}

public extension Parser {
    
    static func |<Other : Parser>(lhs: Self, rhs: Other) -> some Parser<Tape, Output> where Other.Tape == Tape, Other.Output == Output {
        OrParser(p1: lhs, p2: rhs)
    }
    
    static func ||<Other : Parser>(lhs: Self, rhs: Other) -> some Parser<Tape, Output> where Other.Tape == Tape, Other.Output == Output {
        OrShortCircuitParser(p1: lhs, p2: rhs)
    }
    
    func map<T>(_ trafo: @escaping (Output) -> T) -> MapParser<Self, T> {
        MapParser(wrapped: self, trafo: trafo)
    }
    
    func compactMap<T>(_ trafo: @escaping (Output) -> T?) -> CompactMapParser<Self, T> {
        CompactMapParser(wrapped: self, trafo: trafo)
    }
    
    func flatMap<Next : Parser>(_ trafo: @escaping (Output) -> Next) -> FlatMapParser<Self, Next> {
        FlatMapParser(wrapped: self, trafo: trafo)
    }
    
    func mapVoid() -> some Parser<Tape, Void> {
        map{_ in }
    }
    
    func orSuccess(_ value: Output) -> some Parser<Tape, Output> {
        self || Success(value)
    }
    
    func orSuccess() -> some Parser<Tape, Void> {
        mapVoid() || Success(())
    }
}
