import RegexBuilder
import XCTest
@testable import Parser

struct EquatablePair<T : Equatable, U : Equatable> : Equatable {
    let first : T
    let second : U
}

// MARK: TESTS

final class ParserTests: XCTestCase {
    
    func testExact() {
        XCTAssertEqual(Exactly("Fizz").parse("FizzFizz").map(EquatablePair.init),
                       [EquatablePair(first: "Fizz", second: "Fizz")])
    }
    
    func testRepeat() {
        
        XCTAssertEqual(Repeat(pattern: Exactly("Fizz"), separator: Exactly(",")).parse("Fizz,Fizz,Bla").map(EquatablePair.init),
                       [EquatablePair(first: ["Fizz", "Fizz"], second: ",Bla")])
        
    }
    
    func testRecursion() {
        
        struct Repeat<Pattern: Parser, Separator : Parser> : ParserWrapper where Pattern.Tape == Separator.Tape {
            
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
        
        XCTAssertEqual(Repeat(pattern: Exactly("Fizz"), separator: Exactly(",")).parse("Fizz,Fizz,Fizz,Bla").map(EquatablePair.init),
                       [EquatablePair(first: ["Fizz", "Fizz", "Fizz"], second: ",Bla")])
        
    }
    
    func testMatch() {
        
        XCTAssertEqual(MatchString(\Character.isWhitespace).parse("  Foo  ").map(EquatablePair.init),
                       [EquatablePair(first: "  ", second: "Foo  ")])
        
    }
    
    func testRegex() {
        
        XCTAssertEqual(#/[0-9]*.?[0-9]*/#.parse("12342143.123423abcdef").map(EquatablePair.init),
                       [EquatablePair(first: "12342143.123423", second: "abcdef")])
        
    }
    
    func testMatrix() {
        
        let test =
"""

[1234.5, 654, 13;
54345.25, 444, 123]

"""
        
        let result = MatrixParser().parse(test)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.map(\.output).first!, Matrix(rows: 2, cols: 3, data: [1234.5, 654, 13, 54345.25, 444, 123]))
        
    }
    
    func testAddress() {
        
        
        let grammar = PostAnschrift()
        
        XCTAssertEqual(grammar.parse("Bla bla").count, 0)
        
        let txt =
"""
Herr Max Mustermann\t
StrasseOhneLeerzeichen 42
12345 KeineLeerzeichenStadt\t\n
"""
        
        let result = grammar.parse(txt.dropFirst(0))
        
        XCTAssertEqual(result.count, 1)
        
    }
    
}

// MARK: ADDRESS

/*
 
 from german wikipedia (with minor modifications for simplicity)
 
 <Post-Anschrift>  ::= <Personenteil> <Straße> <Stadt>
 <Personenteil>    ::= <Titelteil> <Namensteil> <EOL>
 <Titelteil>       ::= <Titel> |
 <Namensteil>      ::= <Vornamenteil> <Nachname>
 <Straße>          ::= <Straßenname> <Hausnummer> <EOL>
 <Stadt>           ::= <Postleitzahl> <Stadtname> <EOL>
 
 */

struct ParsedAddress {
    let person : ParsedPerson
    let street : ParsedStreet
    let city : ParsedCity
}

struct ParsedPerson {
    let title : String?
    let firstName : String
    let lastName : String
}

struct ParsedStreet {
    let name : String
    let number : Int
}

struct ParsedCity {
    let name : String
    let zipCode : Int
}

struct StringUntilWhitespace : Parser {
    let allowedChars : (Character) -> Bool = {$0 == "\n" || !$0.isWhitespace}
    func parse(_ input: Substring) -> [(output: Substring, tail: Substring)] {
        let result = input.prefix(while: allowedChars)
        let tail = input.dropFirst(result.count).drop(while: {!allowedChars($0)})
        return [(result, tail)]
    }
}

struct PostAnschrift : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, (ParsedPerson, ParsedStreet, ParsedCity)> {
        PersonenTeil()
        Strasse()
        Stadt()
    }
    
    func transform(_ bodyResult: (ParsedPerson, ParsedStreet, ParsedCity)) -> ParsedAddress {
        let (person, street, city) = bodyResult
        return ParsedAddress(person: person, street: street, city: city)
    }
    
}


struct PersonenTeil : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, (String?, ParsedPerson, String)> {
        TitelTeil()
        NamensTeil()
        Exactly("\n")
    }
    
    func transform(_ bodyResult: (String?, ParsedPerson, String)) -> ParsedPerson {
        let (maybeTitle, person, _) = bodyResult
        return ParsedPerson(title: maybeTitle, firstName: person.firstName, lastName: person.lastName)
    }
    
}

struct TitelTeil : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, String?> {
        StringUntilWhitespace().map{String($0) as String?} | Success(nil)
    }
    
}

struct NamensTeil : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, (Substring, Substring)> {
        StringUntilWhitespace()
        StringUntilWhitespace()
    }
    
    func transform(_ bodyResult: (Substring, Substring)) -> ParsedPerson {
        let (first, last) = bodyResult
        return ParsedPerson(title: nil, firstName: String(first), lastName: String(last))
    }
    
}

struct Strasse : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, (Substring, Int, String)> {
        StringUntilWhitespace()
        Int.defaultParser
        Exactly("\n")
    }
    
    func transform(_ bodyResult: (Substring, Int, String)) -> ParsedStreet {
        let (name, number, _) = bodyResult
        return ParsedStreet(name: String(name), number: number)
    }
    
}


struct Stadt : ParserWrapper {
   
    @ParserBuilder
    var body : some Parser<Substring, (Int, String, Substring, String)> {
        Int.defaultParser
        Exactly(" ")
        StringUntilWhitespace()
        Exactly("\n")
    }
    
    func transform(_ bodyResult: (Int, String, Substring, String)) -> ParsedCity {
        let (zip, _, name, _) = bodyResult
        return ParsedCity(name: String(name), zipCode: zip)
    }
    
}

extension Int {
    static var defaultParser : some Parser<Substring, Int> {
        Regex {
            TryCapture(.localizedInteger(locale: .init(languageCode: .english, languageRegion: .unitedStates)),
                       transform: {Int($0)})
        }.map(\.1)
    }
}

// MARK: MATRIX

// row major
struct Matrix : Equatable {
    let rows : Int
    let cols : Int
    var data : [Float]
}

struct MatrixParser : ParserWrapper {
    
    var body: some Parser<Substring, Matrix> {
        pattern.compactMap{_, _, lines, _, _ in
            guard let first = lines.first else {
                return Matrix(rows: 0, cols: 0, data: [])
            }
            guard lines.allSatisfy({$0.count == first.count}) else {
                return nil
            }
            return Matrix(rows: lines.count, cols: first.count, data: lines.flatMap{$0})
        }
    }
    
    @ParserBuilder
    var pattern : some Parser<Substring, (Substring, String, [[Float]], String, Substring)> {
        MatchString(\.isWhitespace)
        Exactly("[")
        manyLines
        Exactly("]")
        MatchString(\.isWhitespace)
    }
    
    var manyLines : some Parser<Substring, [[Float]]> {
        Repeat(pattern: line, separator: #/[ \t\n\r]*;[ \t\n\r]*/#)
    }
    
    var line : some Parser<Substring, [Float]> {
        Repeat(pattern: number, separator: #/[ \t\n\r]*,[ \t\n\r]*/#)
    }
    
    var number : some Parser<Substring, Float> {
        Regex {
            TryCapture(.localizedDouble(locale: .init(languageCode: .english, languageRegion: .unitedStates)),
                       transform: {Float($0)})
        }.map(\.1)
    }
    
}
