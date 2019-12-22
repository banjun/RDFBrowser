import Foundation
import SwiftSparql

enum RdfSchema: IRIBaseProvider {
    static var base: IRIRef {return IRIRef(value: "http://www.w3.org/1999/02/22-rdf-syntax-ns#")}
}
enum RDFSSchema: IRIBaseProvider {
    static var base: IRIRef {return IRIRef(value: "http://www.w3.org/2000/01/rdf-schema#")}
}
enum SchemaSchema: IRIBaseProvider {
    static var base: IRIRef {return IRIRef(value: "http://schema.org/")}
}

struct RDFSClass: RDFTypeConvertible {
    static var rdfType: IRIRef {return RDFSSchema.rdfType("Class")}
}
extension TripleBuilder where State: TripleBuilderStateIncompleteSubjectType {
    func rdfTypeIsRDFSClass() -> TripleBuilder<TripleBuilderStateRDFTypeBound<RDFSClass>> {rdfType(is: RDFSClass.self)}

    func rdfType(is iri: IRIRef) -> TripleBuilder<State> {
        .init(base: self, appendingVerb: RdfSchema.verb("type"), value: [.iriRef(iri)])
    }

    func verb(v: Var, is o: Var) -> TripleBuilder<State> {
        .init(base: self, appendingVerb: .simple(v), value: [.var(o)])
    }
}
extension TripleBuilder {
    func rdfsLabel(is v: Var) -> TripleBuilder<State> {
        .init(base: self, appendingVerb: RDFSSchema.verb("label"), value: [.var(v)])
    }
    func rdfsComment(is v: Var) -> TripleBuilder<State> {
        .init(base: self, appendingVerb: RDFSSchema.verb("comment"), value: [.var(v)])
    }
    func schemaName(is v: Var) -> TripleBuilder<State> {
        .init(base: self, appendingVerb: SchemaSchema.verb("name"), value: [.var(v)])
    }
}
extension TripleBuilder where State: TripleBuilderStateRDFTypeBoundType, State.RDFType == RDFSClass {
    func rdfsSubClassOf(is v: Var) -> TripleBuilder<State> {
        .init(base: self, appendingVerb: RDFSSchema.verb("subClassOf"), value: [.var(v)])
    }
}
