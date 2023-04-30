//
//  Parser.swift
//  
//
//  Created by Markus Kasperczyk on 12.02.22.
//

import Foundation


public struct ParseResult<T, Tail> : ExpressibleByArrayLiteral {
    
    public var possibleInterpretations : [(value: T, tail: Tail)]
    
    public init(possibleInterpretations: [(T, Tail)]) {
        self.possibleInterpretations = possibleInterpretations
    }
    
    public init(value: T, tail: Tail) {
        self = ParseResult(possibleInterpretations: [(value, tail)])
    }
    
    public init(arrayLiteral elements: (T, Tail)...) {
        self = ParseResult(possibleInterpretations: elements)
    }
    
    public func map<U>(_ transform: (T) -> U) -> ParseResult<U, Tail> {
        .init(possibleInterpretations: possibleInterpretations.map{(transform($0), $1)})
    }
    
    public func flatMap<U, NewTail>(_ transform: (T, Tail) -> ParseResult<U, NewTail>) -> ParseResult<U, NewTail> {
        .init(possibleInterpretations: possibleInterpretations.flatMap{transform($0, $1).possibleInterpretations})
    }
    
    public static func +(lhs: Self, rhs: Self) -> Self {
        .init(possibleInterpretations: lhs.possibleInterpretations + rhs.possibleInterpretations)
    }
    
    public var isFailure : Bool {
        possibleInterpretations.isEmpty
    }
    
    public var isUnique : Bool {
        possibleInterpretations.count == 1
    }
    
    public func removingDuplicates() -> Self where T : Hashable, Tail : Hashable {
        Self(possibleInterpretations: Set(possibleInterpretations.lazy.map(Pair.init)).map{($0.s, $0.t)})
    }
    
}

public extension ParseResult where Tail : Collection {
    
    var isSuccess : Bool {
        isUnique && !hasIncompletelyParsedValues
    }
    
    func removingIncompleteInterpretations() -> Self {
        Self(possibleInterpretations: possibleInterpretations.filter{$1.isEmpty})
    }
    
    var hasIncompletelyParsedValues : Bool {
        possibleInterpretations.contains(where: {!$1.isEmpty})
    }
    
}

struct Pair<S : Hashable, T : Hashable> : Hashable {
    let s : S
    let t : T
}

public protocol Parser<Input, Value, Tail> {
    
    associatedtype Input
    associatedtype Value
    associatedtype Tail
    
    func apply(_ input: Input, onSuccess: (Value, Tail) -> Void)
    
}

public extension Parser {
    
    func apply(_ input: Input) -> ParseResult<Value, Tail> {
        var result = ParseResult<Value, Tail>()
        apply(input) {value, tail in
            result.possibleInterpretations.append((value, tail))
        }
        return result
    }
}

public struct ReturnParser<Value, Input> : Parser {
    
    let value : Value
    public init(_ value: Value) {
        self.value = value
    }
    
    public func apply(_ input: Input, onSuccess: (Value, Input) -> Void) {
        onSuccess(value, input)
    }
    
}


public struct MapParser<Base : Parser, NewValue> : Parser {
    
    let base : Base
    let trafo : (Base.Value) -> NewValue
    
    public func apply(_ input: Base.Input, onSuccess: (NewValue, Base.Tail) -> Void) {
        base.apply(input) {value, tail in onSuccess(trafo(value), tail)}
    }
    
}


public struct FlatMapParser<Base : Parser, Next : Parser> : Parser where Base.Tail == Next.Input {
    
    let base : Base
    let trafo : (Base.Value) -> Next
    
    public func apply(_ input: Base.Input, onSuccess: (Next.Value, Next.Tail) -> Void) {
        base.apply(input){val, tail in
            trafo(val).apply(tail, onSuccess: onSuccess)
        }
    }
    
}


public struct OrParser<P1 : Parser, P2 : Parser> : Parser where P1.Value == P2.Value, P1.Input == P2.Input, P1.Tail == P2.Tail {
    
    let p1 : P1
    let p2 : P2
    
    public func apply(_ input: P1.Input, onSuccess: (P1.Value, P1.Tail) -> Void) {
        p1.apply(input, onSuccess: onSuccess)
        p2.apply(input, onSuccess: onSuccess)
    }
    
}

public extension Parser {
    
    func map<NewValue>(_ trafo: @escaping (Value) -> NewValue) -> MapParser<Self, NewValue> {
        MapParser(base: self, trafo: trafo)
    }
    
    func flatMap<Next : Parser>(@ParserBuilder _ trafo: @escaping (Value) -> Next) -> FlatMapParser<Self, Next> {
        FlatMapParser(base: self, trafo: trafo)
    }
    
    func then<Next : Parser>(_ trafo: @escaping () -> Next) -> FlatMapParser<Self, Next> {
        flatMap{_ in trafo()}
    }
    
    static func |<Other : Parser>(lhs: Self, rhs: Other) -> OrParser<Self, Other> {
        OrParser(p1: lhs, p2: rhs)
    }
    
    func mapVoid() -> MapParser<Self, Void> {
        map{_ in }
    }
    
    func orSuccess(_ value: Value) -> some Parser<Input, Value, Tail> where Tail == Input {
        self | ReturnParser(value)
    }
    
    func orSuccess() -> some Parser<Input, Void, Tail> where Tail == Input {
        mapVoid() | ReturnParser()
    }
    
}


public protocol ParserWrapper : Parser where Value == Body.Value {
    
    associatedtype Body : Parser
    
    var body : Body {get}
    
}


public extension ParserWrapper {
    
    func apply(_ input: Body.Input, onSuccess: (Body.Value, Body.Tail) -> Void) {
        body.apply(input, onSuccess: onSuccess)
    }
   
    
}


public extension Parser where Input == Substring {
    
    func apply(_ input: String) -> ParseResult<Value, Tail> {
        apply(input.dropFirst(0))
    }
    
}

public struct CallbackParser<P : Parser> : Parser {
    
    let wrapped : P
    let callback : (P.Value, P.Tail) -> Void
    
    public func apply(_ input: P.Input, onSuccess: (P.Value, P.Tail) -> Void) {
        wrapped.apply(input) {val, tail in
            callback(val, tail)
            onSuccess(val, tail)
        }
    }
    
}

public extension Parser {
    
    func debugCallback(_ callback: @escaping (Value, Tail) -> Void) -> CallbackParser<Self> {
        CallbackParser(wrapped: self, callback: callback)
    }
    
    func debugTails(_ callback: @escaping (Tail) -> Void) -> CallbackParser<Self> {
        debugCallback{_, tail in callback(tail)}
    }
    
    func debugValues(_ callback: @escaping (Value) -> Void) -> CallbackParser<Self> {
        debugCallback{value, _ in callback(value)}
    }
    
    func debugPrintStr(_ str: String) -> CallbackParser<Self> {
        debugValues{_ in print(str)}
    }
    
    func debugPrint() -> CallbackParser<Self> {
        debugCallback{print("value: \($0) rest: \($1)")}
    }
    
    func debugPrintValue() -> CallbackParser<Self> {
        debugValues{print($0)}
    }
    
    func debugPrintTail() -> CallbackParser<Self> {
        debugTails{print($0)}
    }

}
