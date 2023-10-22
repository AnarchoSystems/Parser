//
//  ParserWrapper.swift
//
//
//  Created by Markus Kasperczyk on 21.10.23.
//

public protocol ParserWrapper : Parser where Tape == Wrapped.Tape {
    associatedtype Tape = Wrapped.Tape
    associatedtype Output = Wrapped.Output
    associatedtype Wrapped : Parser
    var body : Wrapped {get}
    func transform(_ bodyResult: Wrapped.Output) -> Output
}

public extension ParserWrapper where Output == Wrapped.Output {
    func transform(_ bodyResult: Wrapped.Output) -> Output {
        bodyResult
    }
}

public extension ParserWrapper {
    func parse(_ input: Tape) -> [(output: Output, tail: Tape)] {
        body.parse(input).map{(transform($0), $1)}
    }
}
