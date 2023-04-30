//
//  Lib.swift
//  
//
//  Created by Markus Kasperczyk on 13.02.22.
//

import Foundation


public protocol EagerParseStrategy where Input.SubSequence == Input {
    associatedtype Input : Collection
    associatedtype Value
    func parse(_ input: Input) -> Value?
}

public struct MaxParser<Strategy : EagerParseStrategy> : Parser {
    
    @usableFromInline
    let strategy : Strategy
    
    public init(strategy: Strategy) {
        self.strategy = strategy
    }
    
    @inlinable
    public func apply(_ input: Strategy.Input, onSuccess: (Strategy.Value, Strategy.Input) -> Void) {
        
        guard input.count > 0 else {
            return
        }
        
        var value : Strategy.Value?
        var length = 0
        
        for matchLength in 1...input.count {
            guard let recognized = strategy.parse(input.prefix(matchLength)) else {
                break
            }
            value = recognized
            length = matchLength
        }
        
        if let vals = value.map({[($0, input.dropFirst(length))]}) {
            for (val, tail) in vals {
                onSuccess(val, tail)
            }
        }
        
    }
    
}


public protocol DefaultParsable {
    associatedtype DefaultStrategy : EagerParseStrategy
    static var defaultParsingStrategy : DefaultStrategy {get}
}

public extension MaxParser where Strategy.Value : DefaultParsable {
    
    init() where Strategy == Strategy.Value.DefaultStrategy {
        self = MaxParser(strategy: Strategy.Value.defaultParsingStrategy)
    }
    
}

public struct DefaultIntParseStrategy : EagerParseStrategy {
    public init(){}
    @inlinable
    public func parse(_ input: Substring) -> Int? {
        Int(input)
    }
}

public struct DefaultFloatParseStrategy : EagerParseStrategy {
    public init() {}
    @inlinable
    public func parse(_ input: Substring) -> Float? {
        Float(input)
    }
}

public struct DefaultDoubleParseStrategy : EagerParseStrategy {
    public init() {}
    @inlinable
    public func parse(_ input: Substring) -> Double? {
        Double(input)
    }
}

extension Int : DefaultParsable {
    public static let defaultParsingStrategy = DefaultIntParseStrategy()
}

extension Float : DefaultParsable {
    public static let defaultParsingStrategy = DefaultFloatParseStrategy()
}

extension Double : DefaultParsable {
    public static let defaultParsingStrategy = DefaultDoubleParseStrategy()
}

public typealias DefaultMaxParser<Value : DefaultParsable> = MaxParser<Value.DefaultStrategy>
public typealias UFloatParser = DefaultMaxParser<Float>
public typealias UIntParser = DefaultMaxParser<Int>
public typealias UDoubleParser = DefaultMaxParser<Double>


public struct SingleWordParser<T> : Parser {
    
    let word : Substring
    let value : T
    
    public init(mapping word: String, to value: T) {
        self.word = word.dropFirst(0)
        self.value = value
    }
    
    public func apply(_ input: Substring, onSuccess: (T, Substring) -> Void) {
        if word == input.prefix(word.count) {
            onSuccess(value, input.dropFirst(word.count))
        }
    }
    
}


extension SingleWordParser: ExpressibleByUnicodeScalarLiteral where T == Void {
    public typealias UnicodeScalarLiteralType = StringLiteralType
}

extension SingleWordParser: ExpressibleByExtendedGraphemeClusterLiteral where T == Void {
    public typealias ExtendedGraphemeClusterLiteralType = StringLiteralType
}

extension SingleWordParser : ExpressibleByStringLiteral where T == Void {
    
    public init(stringLiteral value: String) {
        self = SingleWordParser(mapping: value, to: ())
    }
    
}


public struct WordParser<T> : Parser, ExpressibleByDictionaryLiteral {
    
    let dict : [Substring : T]
    
    public init(matching dict: [Substring : T]) {self.dict = dict}
    
    public init(dictionaryLiteral elements: (String, T)...) {
        self.dict = .init(uniqueKeysWithValues: elements.map{($0.dropFirst(0), $1)})
    }
    
    public func apply(_ input: Substring, onSuccess: (T, Substring) -> Void) {
        
        for (key, value) in dict {
            if key == input.prefix(key.count) {
                return onSuccess(value, input.dropFirst(key.count))
            }
        }
    }
    
}


extension WordParser : ExpressibleByArrayLiteral where T == Void {
    
    public init(arrayLiteral elements: String...) {
        self = WordParser(matching: .init(elements.lazy.map{($0.dropFirst(0), ())}, uniquingKeysWith: {_, _ in }))
    }
    
}


public typealias SucceededParser<Input> = ReturnParser<Void, Input>


public extension ReturnParser where Value == Void {
    
    init() {
        self = ReturnParser(())
    }
    
}


public struct StringParser : Parser {
    
    let droppingUnwanted : Bool
    let charSet : (Character) -> Bool
    
    public init(droppingUnwanted: Bool = true,
                allowedCharacters: @escaping (Character) -> Bool) {
        self.droppingUnwanted = droppingUnwanted
        self.charSet = allowedCharacters
    }
    
    public func apply(_ input: Substring, onSuccess: (Substring, Substring) -> Void) {
        let result = input.prefix(while: charSet)
        guard !result.isEmpty else {
            return
        }
        let tailWithWhitespace = input.dropFirst(result.count)
        onSuccess(result, droppingUnwanted ? tailWithWhitespace.drop(while: {!charSet($0)}) : tailWithWhitespace)
    }
    
}


public struct SplitParser<Strategy : EagerParseStrategy> : Parser where Strategy.Input == Substring {
    
    @usableFromInline
    let strategy : Strategy
    @usableFromInline
    let splitCharacter : Character
    
    public init(strategy: Strategy,
                splitCharacter: Character) {
        self.strategy = strategy
        self.splitCharacter = splitCharacter
    }
    
    @inlinable
    public func apply(_ input: Substring, onSuccess: ([Strategy.Value], Substring) -> Void) {
       
        var result = [Strategy.Value]()
        var input = input
        
        while true {
            let val = input.prefix{$0 != splitCharacter}
            let max = MaxParser(strategy: strategy).apply(val)
            guard let (value, tail) = max.possibleInterpretations.min(by: {$0.tail < $1.tail}) else {break}
            result.append(value)
            input = input.dropFirst(tail.isEmpty ? val.count + 1 : val.count - tail.count)
        }
        
        if result.count > 0 {
            onSuccess(result, input)
        }
        
    }
    
}
