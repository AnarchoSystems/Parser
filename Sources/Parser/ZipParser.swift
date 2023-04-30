//
//  ZipParser.swift
//  
//
//  Created by Markus Kasperczyk on 13.02.22.
//

import Foundation


@resultBuilder
public struct ParserBuilder {
    
    public static func buildBlock<P>(_ p: P) -> P {
        p
    }
    
    public static func buildBlock<P1, P2>(_ p1: P1, _ p2: P2) -> FlatMapParser<P1, MapParser<P2, (P1.Value, P2.Value)>> {
        p1.flatMap{v1 in p2.map{v2 in (v1, v2)}}
    }
    
    public static func buildBlock<P1, P2, P3>(_ p1: P1, _ p2: P2, _ p3: P3) -> FlatMapParser<P1, FlatMapParser<P2, MapParser<P3, (P1.Value, P2.Value, P3.Value)>>> {
        p1.flatMap{v1 in p2.flatMap{v2 in p3.map{v3 in (v1, v2, v3)}}}
    }
    
    public static func buildBlock<P1, P2, P3, P4>(_ p1: P1, _ p2: P2, _ p3: P3, _ p4: P4) -> FlatMapParser<P1, FlatMapParser<P2, FlatMapParser<P3, MapParser<P4, (P1.Value, P2.Value, P3.Value, P4.Value)>>>> {
        p1.flatMap{v1 in p2.flatMap{v2 in p3.flatMap{v3 in p4.map{v4 in (v1, v2, v3, v4)}}}}
    }
    
    public static func buildBlock<P1, P2, P3, P4, P5>(_ p1: P1, _ p2: P2, _ p3: P3, _ p4: P4, _ p5: P5)
    -> FlatMapParser<P1, FlatMapParser<P2, FlatMapParser<P3, FlatMapParser<P4, MapParser<P5, (P1.Value, P2.Value, P3.Value, P4.Value, P5.Value)>>>>> {
        p1.flatMap{v1 in p2.flatMap{v2 in p3.flatMap{v3 in p4.flatMap{v4 in p5.map{v5 in (v1, v2, v3, v4, v5)}}}}}
    }
    
    public static func buildBlock<P1, P2, P3, P4, P5, P6>(_ p1: P1, _ p2: P2, _ p3: P3, _ p4: P4, _ p5: P5, _ p6: P6)
    -> FlatMapParser<P1, FlatMapParser<P2, FlatMapParser<P3, FlatMapParser<P4, FlatMapParser<P5, MapParser<P6, (P1.Value, P2.Value, P3.Value, P4.Value, P5.Value, P6.Value)>>>>>> {
        p1.flatMap{v1 in p2.flatMap{v2 in p3.flatMap{v3 in p4.flatMap{v4 in p5.flatMap{v5 in p6.map{v6 in (v1, v2, v3, v4, v5, v6)}}}}}}
    }
    
    public static func buildBlock<P1, P2, P3, P4, P5, P6, P7>(_ p1: P1, _ p2: P2, _ p3: P3, _ p4: P4, _ p5: P5, _ p6: P6, _ p7: P7)
    -> FlatMapParser<P1, FlatMapParser<P2, FlatMapParser<P3, FlatMapParser<P4, FlatMapParser<P5, FlatMapParser<P6, MapParser<P7, (P1.Value, P2.Value, P3.Value, P4.Value, P5.Value, P6.Value, P7.Value)>>>>>>> {
        p1.flatMap{v1 in p2.flatMap{v2 in p3.flatMap{v3 in p4.flatMap{v4 in p5.flatMap{v5 in p6.flatMap{v6 in p7.map{v7 in (v1, v2, v3, v4, v5, v6, v7)}}}}}}}
    }
    
    public static func buildBlock<P1, P2, P3, P4, P5, P6, P7, P8>(_ p1: P1, _ p2: P2, _ p3: P3, _ p4: P4, _ p5: P5, _ p6: P6, _ p7: P7, _ p8: P8)
    -> FlatMapParser<P1, FlatMapParser<P2, FlatMapParser<P3, FlatMapParser<P4, FlatMapParser<P5, FlatMapParser<P6, FlatMapParser<P7, MapParser<P8, (P1.Value, P2.Value, P3.Value, P4.Value, P5.Value, P6.Value, P7.Value, P8.Value)>>>>>>>> {
        p1.flatMap{v1 in p2.flatMap{v2 in p3.flatMap{v3 in p4.flatMap{v4 in p5.flatMap{v5 in p6.flatMap{v6 in p7.flatMap{v7 in p8.map{v8 in (v1, v2, v3, v4, v5, v6, v7, v8)}}}}}}}}
    }
    
    public static func buildBlock<P1, P2, P3, P4, P5, P6, P7, P8, P9>(_ p1: P1, _ p2: P2, _ p3: P3, _ p4: P4, _ p5: P5, _ p6: P6, _ p7: P7, _ p8: P8, _ p9: P9)
    -> FlatMapParser<P1, FlatMapParser<P2, FlatMapParser<P3, FlatMapParser<P4, FlatMapParser<P5, FlatMapParser<P6, FlatMapParser<P7, FlatMapParser<P8, MapParser<P9, (P1.Value, P2.Value, P3.Value, P4.Value, P5.Value, P6.Value, P7.Value, P8.Value, P9.Value)>>>>>>>>> {
        p1.flatMap{v1 in p2.flatMap{v2 in p3.flatMap{v3 in p4.flatMap{v4 in p5.flatMap{v5 in p6.flatMap{v6 in p7.flatMap{v7 in p8.flatMap{v8 in p9.map{v9 in (v1, v2, v3, v4, v5, v6, v7, v8, v9)}}}}}}}}}
    }
    
    public static func buildBlock<P1, P2, P3, P4, P5, P6, P7, P8, P9, P10>(_ p1: P1, _ p2: P2, _ p3: P3, _ p4: P4, _ p5: P5, _ p6: P6, _ p7: P7, _ p8: P8, _ p9: P9, _ p10: P10)
    -> FlatMapParser<P1, FlatMapParser<P2, FlatMapParser<P3, FlatMapParser<P4, FlatMapParser<P5, FlatMapParser<P6, FlatMapParser<P7, FlatMapParser<P8, FlatMapParser<P9, MapParser<P10, (P1.Value, P2.Value, P3.Value, P4.Value, P5.Value, P6.Value, P7.Value, P8.Value, P9.Value, P10.Value)>>>>>>>>>> {
        p1.flatMap{v1 in p2.flatMap{v2 in p3.flatMap{v3 in p4.flatMap{v4 in p5.flatMap{v5 in p6.flatMap{v6 in p7.flatMap{v7 in p8.flatMap{v8 in p9.flatMap{v9 in p10.map{v10 in (v1, v2, v3, v4, v5, v6, v7, v8, v9, v10)}}}}}}}}}}
    }
    
}


public struct ZipParser<Wrapped : Parser> : ParserWrapper {
    
    public let body : Wrapped
    
    public init(@ParserBuilder _ content: () -> Wrapped) {
        body = content()
    }
    
}

public struct ParserGroup<Wrapped : Parser> : ParserWrapper {
    
    let wrapped : Wrapped
    
    public init(@ParserBuilder _ content: () -> Wrapped) {
        wrapped = content()
    }
    
    public var body : MapParser<Wrapped, Void> {
        wrapped.mapVoid()
    }
    
}
