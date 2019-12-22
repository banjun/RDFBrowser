import Foundation
import UIKit
import NorthLayout
import Ikemen

final class GraphView: UIView {
    var graph: RDFGraph {
        didSet {
            update()
        }
    }

    private var nodeViews: [NodeView<Subject>] = []
    private var nodesZPositionView = UIView()
    private var edgeViews: [EdgeView<Subject, Verb>] = []
    private var edgesZPositionView = UIView()
    private var edgePaths: [UIBezierPath] = [] {
        didSet {
            edgePathsLayer.path = edgePaths.reduce(into: UIBezierPath()) {$0.append($1)}.cgPath
        }
    }
    private lazy var edgePathsLayer: CAShapeLayer = .init() ※ {
        $0.lineWidth = 4
        $0.strokeColor = UIColor.tertiaryLabel.cgColor
        edgesZPositionView.layer.addSublayer($0)
    }

    private lazy var dynamicAnimator: UIDynamicAnimator = UIDynamicAnimator(referenceView: self) ※ { a in
        a.addBehavior(self.nodeBehavior)
        a.addBehavior(self.boundaryBehavior)
        a.addBehavior(self.collisionBehavior)
    }

    private lazy var displayLink: CADisplayLink = CADisplayLink(target: self, selector: #selector(displayLinkTask)) ※ {
        $0.preferredFramesPerSecond = 5
    }

    private let nodeBehavior = UIDynamicItemBehavior() ※ { b in
        b.density = 1000
        b.elasticity = 0.5
        b.resistance = 0.1
        b.angularResistance = .greatestFiniteMagnitude
        b.allowsRotation = true
    }

    private let boundaryBehavior = UICollisionBehavior(items: []) ※ { b in
        // collision detection on view bounds is always enabled.
        b.collisionMode = .boundaries
    }

    private let collisionBehavior = UICollisionBehavior(items: []) ※ { b in
        // collision detection on some items will be disabled on move.
        // separate view bounds detection to boundaryBehavior.
        b.collisionMode = .everything
    }


    init() {
        self.graph = .init(nodes: [], edges: [])
        super.init(frame: .zero)

        let autolayout = northLayoutFormat([:], [
            "nodes": nodesZPositionView,
            "edges": edgesZPositionView])
        autolayout("H:|[nodes]|")
        autolayout("H:|[edges]|")
        autolayout("V:|[nodes]|")
        autolayout("V:|[edges]|")
        bringSubviewToFront(nodesZPositionView)
        _ = dynamicAnimator
    }
    required init?(coder: NSCoder) {fatalError()}

    private func update() {
        let removedNodeViews = nodeViews.filter {!graph.nodes.contains($0.node)}
        let removedEdgeViews = edgeViews.filter {!graph.edges.contains($0.edge)}
        removedNodeViews.forEach {$0.removeFromSuperview()}
        removedEdgeViews.forEach {$0.removeFromSuperview()}
        nodeViews.removeAll {removedNodeViews.contains($0)}
        edgeViews.removeAll {removedEdgeViews.contains($0)}

        nodeViews.append(contentsOf: graph.nodes.compactMap { n in
            guard (!nodeViews.contains {$0.node == n}) else { return nil }
            return NodeView(node: n) ※ {
                nodesZPositionView.addSubview($0)
                $0.center = CGPoint(x: nodesZPositionView.bounds.midX + CGFloat(arc4random_uniform(500)) - 250,
                                    y: nodesZPositionView.bounds.midY + CGFloat(arc4random_uniform(100)) - 50)

                nodeBehavior.addItem($0)
                boundaryBehavior.addItem($0)
                collisionBehavior.addItem($0)
            }
        })

        edgeViews.append(contentsOf: graph.edges.compactMap { e in
            guard (!edgeViews.contains {$0.edge == e}) else { return nil }

            let sourceNodeView = (nodeViews.first {$0.node == e.source})!
            let destinationNodeView = (nodeViews.first {$0.node == e.destination})!

            return EdgeView(sourceView: sourceNodeView, edge: e, destinationView: destinationNodeView) ※ {
                edgesZPositionView.addSubview($0)
                $0.center = CGPoint(x: edgesZPositionView.bounds.midX + CGFloat(arc4random_uniform(500)) - 250,
                                    y: edgesZPositionView.bounds.midY + CGFloat(arc4random_uniform(100)) - 50)

                edgesZPositionView.addSubview($0)

                nodeBehavior.addItem($0)
                boundaryBehavior.addItem($0)
                collisionBehavior.addItem($0)

                let length: CGFloat = 128
                dynamicAnimator.addBehavior(UIAttachmentBehavior(item: $0, attachedTo: sourceNodeView) ※ { b in
                    b.frequency = 2
                    b.damping = 1
                    b.frictionTorque = 0
                    b.length = length
                })
                dynamicAnimator.addBehavior(UIAttachmentBehavior(item: $0, attachedTo: destinationNodeView) ※ { b in
                    b.frequency = 2
                    b.damping = 1
                    b.frictionTorque = 0
                    b.length = length
                })
                dynamicAnimator.addBehavior(UIAttachmentBehavior(item: sourceNodeView, attachedTo: destinationNodeView) ※ { b in
                    b.frequency = 2
                    b.damping = 1
                    b.frictionTorque = 0
                    b.length = length * 2
                })

                let lineView = UIView() ※ {$0.backgroundColor = .systemRed}
                _ = edgesZPositionView.northLayoutFormat([:], [
                    "source": sourceNodeView,
                    "destination": destinationNodeView,
                    "line": lineView])
                lineView.leftAnchor.constraint(equalTo: sourceNodeView.centerXAnchor).isActive = true
                lineView.topAnchor.constraint(equalTo: sourceNodeView.centerYAnchor).isActive = true
                lineView.rightAnchor.constraint(equalTo: destinationNodeView.centerXAnchor).isActive = true
                lineView.bottomAnchor.constraint(equalTo: destinationNodeView.centerYAnchor).isActive = true
            }
        })

        displayLink.add(to: .current, forMode: .default)
    }

    private func updateBoundary() {
        let behaviors = [boundaryBehavior, collisionBehavior]
        guard #available(iOS 11, *) else {
            behaviors.forEach {$0.translatesReferenceBoundsIntoBoundary = true}
            return
        }
        behaviors.forEach {$0.setTranslatesReferenceBoundsIntoBoundary(with: safeAreaInsets)}
    }

    @available(iOS 11.0, *)
    public override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        updateBoundary()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        edgePathsLayer.frame = edgesZPositionView.bounds
    }

    @objc private func displayLinkTask() {
        edgePaths = edgeViews.map { ev in
            UIBezierPath() ※ {
                $0.move(to: ev.sourceView.center)
                $0.addLine(to: ev.destinationView.center)
            }
        }
    }
}

final class NodeView<Node: DisplayNameConvertible>: UIView {
    let node: Node
    var behaviors: [UIDynamicBehavior] = []

    init(node: Node) {
        self.node = node
        super.init(frame: .zero)

        backgroundColor = .tertiarySystemBackground
        layer.borderColor = UIColor.secondarySystemGroupedBackground.cgColor
        layer.borderWidth = 2
        layer.cornerRadius = 8

        translatesAutoresizingMaskIntoConstraints = false
        let autolayout = northLayoutFormat([:], [
            "label": UILabel() ※ {
                $0.text = node.displayName
                $0.font = .boldSystemFont(ofSize: 20)
                $0.textColor = .label
                $0.lineBreakMode = .byTruncatingMiddle
            }])
        autolayout("H:|-[label(<=256)]-|")
        autolayout("V:|-[label]-|")
        layoutIfNeeded()
    }
    required init?(coder: NSCoder) {fatalError()}
}

final class EdgeView<Node: Equatable, Label: Equatable & DisplayNameConvertible>: UIView {
    let edge: Graph<Node, Label>.Edge
    let sourceView: UIView
    let destinationView: UIView
    let arrowView = UIView()

    init(sourceView: UIView, edge: Graph<Node, Label>.Edge, destinationView: UIView) {
        self.edge = edge
        self.sourceView = sourceView
        self.destinationView = destinationView
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        let autolayout = northLayoutFormat([:], [
            "label": UILabel() ※ {
                $0.text = edge.label.displayName
                $0.textColor = .label
                $0.lineBreakMode = .byTruncatingMiddle
            },
            "arrow": arrowView])
        autolayout("H:|[label]|")
        autolayout("V:|[label]|")
        layoutIfNeeded()
    }
    required init?(coder: NSCoder) {fatalError()}
}
