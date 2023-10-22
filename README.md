# Parser

This framework allows you to write code like the following:

```swift

struct Repeat<Pattern: Parser, Separator : Parser> : ParserWrapper where
 Pattern.Tape == Separator.Tape {
            
    let pattern : Pattern
    let separator : Separator
            
    var body : some Parser<Pattern.Tape, [Pattern.Output]> {
        recursion.map{[$0] + $2} || pattern.map{[$0]}
    }
            
    @ParserBuilder
    var recursion : some Parser<Pattern.Tape, (Pattern.Output, Separator.Output, [Pattern.Output])> {
        pattern
        separator
        self
    }
            
}          

```

A parser is nothing more than

```swift
public protocol Parser<Tape, Output> {
    associatedtype Tape = Substring
    associatedtype Output
    func parse(_ input: Tape) -> [(output: Output, tail: Tape)]
}
```

But using wrappers, combinators and the parsers from the lib, you can write easy to understand yet expressive parsers.

## Note

This package was inspired by [Numberphile](https://www.youtube.com/watch?v=dDtZLm7HIJs).
