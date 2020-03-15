import UIKit
import Ikemen
import NorthLayout

final class SubjectOverviewView: UIView {
    var subject: SubjectSampleResult? {
        didSet {
            update()
        }
    }

    private let labelLabel = UILabel() ※ {
        $0.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .headline), size: 24)
        $0.textColor = .label
        $0.numberOfLines = 0
    }
    private let typeLabel = UILabel() ※ {
        $0.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .subheadline), size: 20)
        $0.textColor = .label
        $0.numberOfLines = 0
    }
    private lazy var linkButton: UIButton = .init() ※ {
        $0.setTitle("Web", for: .normal)
        $0.addTarget(self, action: #selector(gotoSubjectLink(_:)), for: .touchUpInside)
        $0.setTitleColor(.link, for: .normal)
        $0.backgroundColor = .tertiarySystemBackground
        $0.contentEdgeInsets.left = 8
        $0.contentEdgeInsets.right = 8
    }

    init() {
        super.init(frame: .zero)
        let autolayout = northLayoutFormat(["p": 8], ["label": labelLabel, "type": typeLabel, "link": linkButton])
        autolayout("H:||[label]-(>=p)-[type(>=32,<=128)]||")
        autolayout("H:||[label]-(>=p)-[link]||")
        autolayout("V:||[label]-(>=0)-||")
        autolayout("V:||[type]-(>=p)-[link]||")

        labelLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        linkButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        backgroundColor = .secondarySystemBackground
    }
    required init?(coder: NSCoder) {fatalError()}

    private func update() {
        labelLabel.text = subject.flatMap {$0.label ?? $0.name ?? $0.subject}
        typeLabel.text = subject?.typeLabel ?? subject?.type
    }

    @IBAction func gotoSubjectLink(_ sender: Any?) {
        guard let url = (subject.flatMap {URL(string: $0.subject)}) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
