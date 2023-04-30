import XCTest
@testable import Parser

final class ParserTests: XCTestCase {
    
    
    func testExpr() throws {
        
        let grammar = Expr()
        
        let result = grammar.apply("(14+7)*2").removingDuplicates().removingIncompleteInterpretations()
        
        XCTAssert(result.isSuccess && result.possibleInterpretations.first!.value == 42, "\(result)")
        XCTAssert(grammar.apply(")").isFailure)
        
    }
    
    func testStringParser() {
        
        let grammar = StringParser(allowedCharacters: {!$0.isWhitespace})
        
        let result1 = grammar.apply("Bla bla \n bla")
        
        guard let (Bla, rest) = result1.possibleInterpretations.first else {
            return XCTFail()
        }
        
        XCTAssert(Bla == "Bla", String(Bla))
        
        let result2 = grammar.apply(rest)
        
        guard let (bla, lastBla) = result2.possibleInterpretations.first else {
            return XCTFail()
        }
        
        XCTAssert(bla == "bla", String(bla))
        
        let result3 = grammar.apply(lastBla)
        
        XCTAssert(result3.isUnique)
        
        guard let (bla2, empty) = result3.possibleInterpretations.first else {
            return XCTFail()
        }
        
        XCTAssert(bla2 == bla, String(bla2))
        XCTAssert(empty.isEmpty, String(empty))
        
        
        
    }
    
    func testAddr() {
        
        
        let grammar = PostAnschrift()
        
        XCTAssert(grammar.apply("Bla bla").isFailure)
        
        let txt =
"""
Herr Max Mustermann\t
StrasseOhneLeerzeichen 42
12345 KeineLeerzeichenStadt\t\n
"""
        
        let result = grammar.apply(txt)
        
        XCTAssert(result.isSuccess)
        
    }
    
    func testSplitParser() {
        
        let grammar = SplitParser(strategy: DefaultIntParseStrategy(),
                                  splitCharacter: ",")
        
        let str = "1234,6543,365a,a,,42,,"
        
        let result = grammar.apply(str)
        
        guard let (ints, tail) = result.possibleInterpretations.first else {
            return XCTFail()
        }
        
        XCTAssert(ints == [1234, 6543, 365], "\(ints)")
        XCTAssert(tail == "a,a,,42,,", String(tail))
        
    }
    
    func testWhitespace() {
        
        let grammar = StringParser(allowedCharacters: \.isWhitespace)
        
        let result = grammar.apply("  ")
        
        guard result.isSuccess else {
            return XCTFail("\(result.possibleInterpretations)")
        }
        
    }
    
    func testSingleMember() {
        
        let testStr =
    """
    "foo" : "bar"
    """
        
        let grammar = JSONSingleMemberStrategy()
        
        let result = grammar.apply(testStr)
        
        guard result.isSuccess else {
            return XCTFail("\(result.possibleInterpretations)")
        }
        
        guard let (json1, _) = result.possibleInterpretations.first else {
            return XCTFail()
        }
        
        XCTAssertEqual(json1.0, "foo")
        XCTAssertEqual(json1.1, .string("bar"))
        
    }
 
    func testJSON() {
        
        let testStr =
    """
    {"foo" : "bar"}
    """
        
        let grammar = JSONParser()
        
        let result = grammar.apply(testStr)
        
        guard result.isSuccess else {
            return XCTFail("\(result.possibleInterpretations)")
        }
        
        guard let (json1, _) = result.possibleInterpretations.first else {
            return XCTFail()
        }
        
        let json2 = try! JSONDecoder().decode(JSON.self, from: Data(testStr.utf8))
        
        XCTAssert(json1 == json2, "\(json1)")
        
    }
    
}


/*
 
 expr -> term + expr | term
 term -> factor * term | factor
 factor -> (expr) | Int
 
 */


struct Expr : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, Int, Substring> {
        
        ZipParser {
            Term()
            "+" as SingleWordParser
            Expr()
        }.map{term, _, expr in term + expr} | Term()
        
    }
    
}

struct Term : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, Int, Substring> {
        ZipParser {
            Factor()
            "*" as SingleWordParser
            Term()
        }.map{factor, _, term in factor * term} | Factor()
    }
    
}


struct Factor : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, Int, Substring> {
        ZipParser {
            "(" as SingleWordParser
            Expr()
            ")" as SingleWordParser
        }.map{_, expr, _ in expr} | UIntParser()
    }
    
}


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

typealias StringUntilWhitespaceParser = StringParser

extension StringParser {
    
    init() {
        self = .init(allowedCharacters: {$0 == "\n" || !$0.isWhitespace})
    }
    
}

struct PostAnschrift : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, ParsedAddress, Substring> {
        ZipParser {
            PersonenTeil()
            Strasse()
            Stadt()
        }.map(ParsedAddress.init)
    }
    
}


struct PersonenTeil : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, ParsedPerson, Substring> {
        ZipParser {
            TitelTeil()
            NamensTeil()
            "\n" as SingleWordParser
        }.map{maybeTitle, person, _ in
            ParsedPerson(title: maybeTitle, firstName: person.firstName, lastName: person.lastName)
        }
    }
    
}

struct TitelTeil : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, String?, Substring> {
        StringUntilWhitespaceParser().map{String($0) as String?}.orSuccess(nil)
    }
    
}

struct NamensTeil : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, ParsedPerson, Substring> {
        ZipParser {
            StringUntilWhitespaceParser()
            StringUntilWhitespaceParser()
        }.map{first, last in ParsedPerson(title: nil, firstName: String(first), lastName: String(last))}
    }
    
}

struct Strasse : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, ParsedStreet, Substring> {
        ZipParser {
            StringUntilWhitespaceParser()
            UIntParser()
            "\n" as SingleWordParser
        }.map{name, number, _ in ParsedStreet(name: String(name), number: number)}
    }
    
}


struct Stadt : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, ParsedCity, Substring> {
        ZipParser {
            UIntParser()
            " " as SingleWordParser
            StringUntilWhitespaceParser()
            "\n" as SingleWordParser
        }.map{zip, _, name, _ in ParsedCity(name: String(name), zipCode: zip)}
    }
    
}

// https://betterprogramming.pub/how-to-encode-and-decode-any-json-safely-in-swift-d5b2b8e2e1e3

indirect enum JSON : Hashable, Decodable {
    
    case string(String)
    case number(Float)
    case boolean(Bool)
    case array([JSON])
    case object([String : JSON])
    case null
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

            if let value = try? container.decode(Float.self) {
              self = .number(value)
              return
            }

            if let value = try? container.decode(Bool.self) {
              self = .boolean(value)
              return
            }

            if let value = try? container.decode(String.self) {
              self = .string(value)
              return
            }

            if let value = try? container.decode([JSON].self) {
              self = .array(value)
              return
            }

            if let value = try? container.decode([String: JSON].self) {
              self = .object(value)
              return
            }

            if
              let container = try? decoder.singleValueContainer(),
              container.decodeNil()
            {
              self = .null
              return
            }

            throw DecodingError.dataCorrupted(
              .init(
                codingPath: container.codingPath,
                debugDescription: "Cannot decode JSON"
              )
            )
    }
    
}


struct JSONParser : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, JSON, Substring> {
        ZipParser {
            StringParser(allowedCharacters: (\.isWhitespace)).orSuccess()
            JSONValueParser()
            StringParser(allowedCharacters: (\.isWhitespace)).orSuccess()
        }.map(\.1)
    }
    
}

struct JSONValueParser : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, JSON, Substring> {
        let first =
        JSONObjectParser().debugPrintStr("OBJECT") | JSONArrayParser().debugPrintStr("ARRAY")
        let second = JSONStringParser().map(JSON.string).debugPrintStr("STRING") | JSONNumberParser().debugPrintStr("NUMBER")
        let third = (["true" : JSON.boolean(true),
                     "false" : .boolean(false),
                      "null" : .null] as WordParser<JSON>)
        (first | second | third.debugPrintStr("LIT"))
    }
    
}

struct JSONObjectParser : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, JSON, Substring> {
        ZipParser {
            "{" as SingleWordParser
            StringParser(allowedCharacters: (\.isWhitespace)).orSuccess()
            "}" as SingleWordParser
        }.map{_, _, _ in JSON.object([:])} |
        ZipParser {
            "{" as SingleWordParser
            JSONMembersParser()
            "}" as SingleWordParser
        }.map {_,
            dict, _ in .object(dict)
        }
    }
    
}

struct JSONArrayParser : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, JSON, Substring> {
        ZipParser {
            ("[" as SingleWordParser)
            StringParser(allowedCharacters: (\.isWhitespace)).orSuccess()
            "]" as SingleWordParser
        }.map{_, _, _ in JSON.array([])} |
        ZipParser {
            "[" as SingleWordParser
            JSONElementsParser().debugPrintStr("ELEMENT")
            "]" as SingleWordParser
        }.map {_, array, _ in .array(array)}
    }
    
}

struct JSONElementsParser : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, [JSON], Substring> {
        SplitParser(strategy: JSONSingleElementStrategy(), splitCharacter: ",")
    }
    
}

struct JSONMembersParser : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, [String : JSON], Substring> {
        ZipParser {
            JSONSingleMemberStrategy()
            ZipParser {
                "," as SingleWordParser
                self
            }.map{$1}.orSuccess([String : JSON]())
        }.map{(val : (String, JSON), dict : [String : JSON]) -> [String : JSON] in
            var copy = dict
            copy[val.0] = val.1
            return copy
        }
    }
    
}

struct JSONSingleElementStrategy : EagerParseStrategy {
    
    func parse(_ input: Substring) -> JSON? {
        
        let grammar = JSONParser()
        let result = grammar.apply(input)
        
        return result.possibleInterpretations.lazy.filter{$1.isEmpty}.min{$0.tail.count < $1.tail.count}?.value
        
    }
    
}

struct JSONSingleMemberStrategy : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, (String, JSON), Substring> {
        
        ZipParser {
            StringParser(allowedCharacters: (\.isWhitespace)).orSuccess()
            JSONStringParser()
            StringParser(allowedCharacters: \.isWhitespace).orSuccess().debugPrint()
            (" : " as SingleWordParser)
            StringParser(allowedCharacters: (\.isWhitespace)).orSuccess()
            JSONParser()
        }.map{_, key, _, _, _, value in (key, value)}
        
    }
    
}

struct JSONStringParser : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, String, Substring> {
        ZipParser {
            "\"" as SingleWordParser
            StringParser(droppingUnwanted: false,
                         allowedCharacters: {!"\"{}[]".contains($0)})
            "\"" as SingleWordParser
        }.map{_, str, _ in String(str)}
    }
    
}

struct JSONNumberParser : ParserWrapper {
    
    @ParserBuilder
    var body : some Parser<Substring, JSON, Substring> {
        ZipParser {
            "-" as SingleWordParser
            UFloatParser()
        }.map{_, num in JSON.number(-num)} | UFloatParser().map(JSON.number)
    }
    
}
