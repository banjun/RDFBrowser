import Cocoa
import NorthLayout
import Ikemen

final class SubjectCell: NSTableCellView, NibLessLoadable {
    var subject: Subject? {
        didSet {
            nameField.stringValue = subject?.displayName ?? ""
            commentField.stringValue = subject?.comment ?? ""
        }
    }

    private let nameField = AutolayoutLabel() ※ {
        $0.font = .boldSystemFont(ofSize: 14)
        $0.textColor = .labelColor
        $0.isBezeled = false
        $0.drawsBackground = false
    }
    private let commentField = AutolayoutLabel() ※ {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .secondaryLabelColor
        $0.isBezeled = false
        $0.drawsBackground = false
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        let autolayout = northLayoutFormat([:], [
            "name": nameField,
            "comment": commentField])
        autolayout("H:|-[name]-|")
        autolayout("H:|-[comment]-|")
        autolayout("V:|-[name][comment]-|")
    }
    required init?(coder: NSCoder) {fatalError()}
}
