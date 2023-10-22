//
//  Parser.swift
//
//
//  Created by Markus Kasperczyk on 20.10.23.
//

public protocol Parser<Tape, Output> {
    associatedtype Tape = Substring
    associatedtype Output
    func parse(_ input: Tape) -> [(output: Output, tail: Tape)]
}

public extension Parser {
    func parse<S : Collection>(_ input: S) -> [(output: Output, tail: Tape)] where S.SubSequence == Tape {
        parse(input[...])
    }
}
