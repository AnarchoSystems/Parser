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

public struct Repeat<Pattern: Parser, Separator: Parser> : Parser where Pattern.Tape == Separator.Tape {
    
    public let pattern : Pattern
    public let separator : Separator
    
    public init(pattern: Pattern, separator: Separator) {
        self.pattern = pattern
        self.separator = separator
    }
    
    public func parse(_ input: Pattern.Tape) -> [(output: [Pattern.Output], tail: Pattern.Tape)] {
        
        var temporaryResults = pattern.parse(input).map{([$0], $1, false)}
        var newResults : [([Pattern.Output], Pattern.Tape, Bool)] = []
        
        while temporaryResults.contains(where: {!$2}) {
            for idx in temporaryResults.indices {
                if temporaryResults[idx].2 {
                    newResults.append(temporaryResults[idx])
                    continue
                }
                var isFirstTime = true
                for (_, newTail) in separator.parse(temporaryResults[idx].1) {
                    for (result, newNewTail) in pattern.parse(newTail) {
                        if isFirstTime {
                            temporaryResults[idx].0.append(result)
                            newResults.append((temporaryResults[idx].0, newNewTail, false))
                            isFirstTime = false
                            continue
                        }
                        temporaryResults[idx].0[temporaryResults[idx].0.count - 1] = result
                        newResults.append((temporaryResults[idx].0, newNewTail, false))
                    }
                }
                if isFirstTime {
                    newResults.append(temporaryResults[idx])
                    newResults[newResults.count - 1].2 = true
                }
            }
            temporaryResults = newResults
            newResults = []
        }
        
        return temporaryResults.map{args in (output: args.0, tail: args.1)}
        
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
