import UIKit
import NorthLayout
import Ikemen
import SwiftSparql

final class ViewController: UIViewController {
    private let graphView = GraphView()
    private var graph: RDFGraph = .init(nodes: [], edges: []) {
        didSet {
            graphView.graph = graph
        }
    }

    private var types: [RDFTypeSchema] = [] {
        didSet {
            graph.nodes = types.map {Subject(iri: IRIRef(value: $0.type), label: $0.label, name: nil, comment: $0.comment)}

            types.forEach { type in
                let sampleQuery = SelectQuery(
                    where: WhereClause(patterns:
                        subject(Var("subject")).rdfType(is: IRIRef(value: type.type))
//                            .optional {$0.rdfsLabel(is: Var("label"))}
                            .rdfsLabel(is: Var("label"))
                            .optional {$0.schemaName(is: Var("name"))}
                            .triples),
                    order: [.by(.RAND)],
                    limit: 2)

                Request(endpoint: endpoint, select: sampleQuery).fetch()
                    .onSuccess { (samples: [SubjectSampleResult]) in
                        self.graph.edges.append(contentsOf: samples.map {
                            RDFGraph.Edge(
                                source: Subject(iri: IRIRef(value: $0.subject), label: $0.label, name: $0.name, comment: nil),
                                label: "a",
                                destination: Subject(iri: IRIRef(value: type.type), label: type.label, name: nil, comment: type.comment))

                        })

                        samples.forEach { sample in
                            let sampleQuery = SelectQuery(
                                where: WhereClause(patterns: [.triple(.term(.iri(.ref(IRIRef(value: sample.subject)))), .simple(Var("verb")), [.var(Var("object"))])]
                                    + SwiftSparql.subject(Var("verb"))
                                        .optional {$0.rdfsLabel(is: Var("verbLabel"))}
                                        .triples
                                    + SwiftSparql.subject(Var("object"))
                                        .optional {$0.rdfsLabel(is: Var("objectLabel"))}
                                        .triples
                                ),
                                order: [.by(.RAND)],
                                limit: 2)
                            Request(endpoint: self.endpoint, select: sampleQuery).fetch().onSuccess { (samples: [VerbObjectPairResult]) in
                                self.graph.edges.append(contentsOf: samples.map { pair in
                                    RDFGraph.Edge(
                                        source: Subject(iri: IRIRef(value: sample.subject), label: sample.label, name: sample.name, comment: nil),
                                        label: pair.verbLabel ?? pair.verbName ?? pair.verb,
                                        destination: Subject(iri: IRIRef(value: pair.object), label: pair.objectLabel, name: pair.objectName, comment: nil))
                                })
                        }
                        }
                }
                .onFailure {NSLog("%@", "error = \(String(describing: $0))")}
            }
        }
    }

    private let endpoint: URL

    init(endpoint: URL) {
        self.endpoint = endpoint
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {fatalError()}

    override func loadView() {
        view = UIView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let autolayout = northLayoutFormat([:], ["graph": graphView])
        autolayout("H:|[graph]|")
        autolayout("V:|[graph]|")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

//        let nodes = [
//            Subject(iri: IRIRef(value: "IRI-0"), label: nil, name: nil, comment: nil),
//            Subject(iri: IRIRef(value: "IRI-1"), label: nil, name: nil, comment: nil),
//            Subject(iri: IRIRef(value: "IRI-2"), label: nil, name: nil, comment: nil),
//            Subject(iri: IRIRef(value: "IRI-3"), label: nil, name: nil, comment: nil),
//            Subject(iri: IRIRef(value: "IRI-4"), label: nil, name: nil, comment: nil)]
//        let edges = [
//        RDFGraph.Edge(source: nodes[0], label: "verb-0-1", destination: nodes[1]),
//        RDFGraph.Edge(source: nodes[0], label: "verb-0-2", destination: nodes[2])]


        let q = SelectQuery(where: WhereClause(patterns:
            subject(Var("type")).rdfTypeIsRDFSClass()
                .optional {$0.rdfsLabel(is: Var("label"))}
                .optional {$0.rdfsComment(is: Var("comment"))}
                .optional {$0.rdfsSubClassOf(is: Var("subClassOf"))}
                .triples))
        Request(endpoint: endpoint, select: q)
            .fetch()
            .onSuccess {self.types = $0}
            .onFailure {NSLog("%@", "error = \(String(describing: $0))")}

//        graphView.graph = RDFGraph(nodes: nodes, edges: edges)
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
