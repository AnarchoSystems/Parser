//
//  Lib.swift
//
//
//  Created by Markus Kasperczyk on 21.10.23.
//

public struct Exactly : ExpressibleByStringLiteral, Parser {
    public let searched : String
    public init(_ searched: String) {
        self.searched = searched
    }
    public init(stringLiteral value: String) {
        self.searched = value
    }
    public func parse(_ input: Substring) -> [(output: String, tail: Substring)] {
        if input.prefix(searched.count) == searched {
            [(searched, input.dropFirst(searched.count))]
        }
        else {
            []
        }
    }
}

public struct Repeat<Pattern: Parser, Separator: Parser> : ParserWrapper where Pattern.Tape == Separator.Tape {
   
    public typealias Output = [Pattern.Output]
    
    public let pattern : Pattern
    public let separator : Separator
    
    public init(pattern: Pattern, separator: Separator) {
        self.pattern = pattern
        self.separator = separator
    }
    
    @ParserBuilder
    public var body : some Parser<Pattern.Tape, (Pattern.Output, [Pattern.Output])> {
        pattern
        many.map(\.1)*
    }
    
    public func transform(_ bodyResult: (Pattern.Output, [Pattern.Output])) -> [Pattern.Output] {
        [bodyResult.0] + bodyResult.1
    }
    
    @ParserBuilder
    public var many : some Parser<Pattern.Tape, (Separator.Output, Pattern.Output)> {
        separator
        pattern
    }
    
}

public struct Match<Tape : Collection, Output> : Parser where Tape.SubSequence == Tape {
    
    public let match : (Tape.Element) -> Bool
    public let convert : (Tape.SubSequence) -> Output
    
    public init(_ match: @escaping (Tape.Element) -> Bool, convert: @escaping (Tape.SubSequence) -> Output) {
        self.match = match
        self.convert = convert
    }
    
    public init(_ match: @escaping (Tape.Element) -> Bool) where Output == Tape.SubSequence {
        self.match = match
        self.convert = {$0}
    }
    
    public func parse(_ input: Tape) -> [(output: Output, tail: Tape)] {
        let results = input.prefix(while: match)
        return [(convert(results), input.dropFirst(results.count))]
    }
    
}

public typealias MatchString<T> = Match<Substring, T>

extension Regex : Parser {
    
    public func parse(_ input: Substring) -> [(output: Output, tail: Substring)] {
        guard let match = try? prefixMatch(in: input) else {
            return []
        }
        let result : [(output: Output, tail: Substring)] = [(match.output, input[match.range.upperBound...])]
        return result
    }
    
}
