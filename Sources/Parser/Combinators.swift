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

postfix operator *
postfix operator +
postfix operator -?

public struct Multiple<Pattern : Parser> : Parser {
    
    public let pattern : Pattern
    
    public init(pattern: Pattern) {
        self.pattern = pattern
    }
    
    public func parse(_ input: Pattern.Tape) -> [(output: [Pattern.Output], tail: Pattern.Tape)] {
        var results = pattern.parse(input).map{([$0], $1, false)}
        if results.isEmpty {
            return [([], input)]
        }
        var newResults : [([Pattern.Output], Pattern.Tape, Bool)] = []
        while results.contains(where: {!$2}) {
            for idx in results.indices {
                if results[idx].2 {
                    newResults.append(results[idx])
                    continue
                }
                var done = true
                for (newResult, newTail) in pattern.parse(results[idx].1) {
                    if done {
                        results[idx].0.append(newResult)
                    }
                    else {
                        results[idx].0[results[idx].0.count - 1] = newResult
                    }
                    results[idx].1 = newTail
                    newResults.append(results[idx])
                    done = false
                }
                if done {
                    newResults.append(results[idx])
                    newResults[newResults.count - 1].2 = true
                }
            }
            results = newResults
            newResults = []
        }
        return results.map{(output: $0.0, tail: $0.1)}
    }
    
}

public struct AtLeastOne<Pattern: Parser> : ParserWrapper {
    
    public typealias Output = [Pattern.Output]
    
    public let pattern : Pattern
    
    public init(pattern: Pattern) {
        self.pattern = pattern
    }
    
    @ParserBuilder
    public var body: some Parser<Pattern.Tape, (Pattern.Output, [Pattern.Output])> {
        pattern
        pattern*
    }
    
    public func transform(_ bodyResult: (Pattern.Output, [Pattern.Output])) -> [Pattern.Output] {
        [bodyResult.0] + bodyResult.1
    }
    
}

public struct Maybe<Pattern: Parser> : ParserWrapper {
    
    public let pattern : Pattern
    
    public init(pattern: Pattern) {
        self.pattern = pattern
    }
    
    public var body: some Parser<Pattern.Tape, Pattern.Output?> {
        pattern.map{$0 as Pattern.Output?}.orSuccess(nil)
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
    
    static postfix func *(arg: Self) -> some Parser<Tape, [Output]> {
        Multiple(pattern: arg)
    }
    
    static postfix func +(arg: Self) -> some Parser<Tape, [Output]> {
        AtLeastOne(pattern: arg)
    }
    
    static postfix func -?(arg: Self) -> some Parser<Tape, Output?> {
        Maybe(pattern: arg)
    }
    
}
