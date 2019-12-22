import Cocoa
import NorthLayout
import Ikemen

final class VerbObjectPairCell: NSTableCellView, NibLessLoadable {
    private let view =  VerbObjectPairView()
    var pair: (verb: Subject, object: Subject)? {
        set {view.pair = newValue}
        get {view.pair}
    }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let autolayout = northLayoutFormat([:], ["v": view])
        autolayout("H:|[v]|")
        autolayout("V:|[v]|")
    }
    required init?(coder: NSCoder) {fatalError()}
}

final class VerbObjectPairView: NSView {
    var pair: (verb: Subject, object: Subject)? {
        didSet {
            verbLabel.stringValue = pair?.verb.displayName ?? ""
            objectLabel.stringValue = pair?.object.displayName ?? ""
        }
    }
    private let verbLabel = AutolayoutLabel() ※ {
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .labelColor
        $0.isBezeled = false
        $0.drawsBackground = false
    }
    private let objectLabel = AutolayoutLabel() ※ {
        $0.font = .boldSystemFont(ofSize: 14)
        $0.textColor = .labelColor
        $0.isBezeled = false
        $0.drawsBackground = false
    }

    init() {
        super.init(frame: .zero)

        let autolayout = northLayoutFormat([:], [
            "verb": verbLabel,
            "object": objectLabel])
        autolayout("H:|[verb]-(>=0)-|")
        autolayout("H:|-(>=0)-[object]|")
        autolayout("V:|[verb]-[object]|")
    }
    required init?(coder: NSCoder) {fatalError()}
}
