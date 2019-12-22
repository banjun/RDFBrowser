import Foundation
import SwiftSparql
import BrightFutures

final class SubjectViewModel: CustomDebugStringConvertible {
    var subject: Subject
    var children: [(verb: SubjectViewModel, object: SubjectViewModel)]

    var debugDescription: String {
        "SubjectViewModel(\(subject.displayName): \(String(describing: (subject, children)))"
    }

    init(subject: Subject, children: [(verb: SubjectViewModel, object: SubjectViewModel)] = []) {
        self.subject = subject
        self.children = children
    }

    func fetchChildrenSamples(endpoint: URL) -> Future<Void, QueryError> {
        let sampleQuery = SelectQuery(
            where: WhereClause(patterns: [.triple(.term(.iri(.ref(subject.iri))), .simple(Var("verb")), [.var(Var("object"))])]
                + SwiftSparql.subject(Var("verb"))
                    .optional {$0.rdfsLabel(is: Var("verbLabel"))}
//                    .optional {$0.schemaName(is: Var("verbName"))}
                    .triples
                + SwiftSparql.subject(Var("object"))
                    .optional {$0.rdfsLabel(is: Var("objectLabel"))}
//                    .optional {$0.schemaName(is: Var("objectName"))}
                    .triples
            ),
            order: [.by(.RAND)],
            limit: 20)

        return Request(endpoint: endpoint, select: sampleQuery).fetch()
            .onSuccess {
                self.children = $0.map {(SubjectViewModel(subject: Subject(verb: $0)),
                                         SubjectViewModel(subject: Subject(object: $0)))}
        }
        .onFailure {NSLog("%@", "error = \(String(describing: $0))")}
        .asVoid()
    }
}

private extension Subject {
    init(verb pair: VerbObjectPairResult) {
        self.init(iri: IRIRef(value: pair.verb), label: pair.verbLabel, name: pair.verbName)
    }
    init(object pair: VerbObjectPairResult) {
        self.init(iri: IRIRef(value: pair.object), label: pair.objectLabel, name: pair.objectName)
    }
}
private struct VerbObjectPairResult: Codable {
    var verb: String
    var verbLabel: String?
    var verbName: String?
    var object: String
    var objectLabel: String?
    var objectName: String?
}
