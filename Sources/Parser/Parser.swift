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

public extension Parser where Tape == Substring {
    func parse(_ input: String) -> [(output: Output, tail: Tape)] {
        parse(input.dropFirst(0))
    }
}
