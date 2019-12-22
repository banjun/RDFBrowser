import Foundation

typealias Verb = String
typealias RDFGraph = Graph<Subject, Verb>

struct Graph<Node: Equatable, Label: Equatable> {
    var nodes: [Node]
    var edges: [Edge] {
        didSet {
            edges.forEach {
                if !nodes.contains($0.source) {
                    nodes.append($0.source)
                }
                if !nodes.contains($0.destination) {
                    nodes.append($0.destination)
                }
            }
        }
    }
    struct Edge: Equatable {
        var source: Node
        var label: Label
        var destination: Node
    }
}

extension String: DisplayNameConvertible {
    var displayName: String { self }
}
