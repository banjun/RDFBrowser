import UIKit
import SwiftSparql
import Ikemen

final class QueryAndResultsViewController: UITableViewController, UISearchTextFieldDelegate {
    private let endpoint: URL
    private lazy var searchHeaderView: UIView = .init() ※ {
        let autolayout = $0.northLayoutFormat([:], ["field": searchField])
        autolayout("H:||[field]||")
        autolayout("V:||[field]||")
    }
    private let searchField = UISearchTextField() ※ {
        $0.returnKeyType = .search
    }

    private var queryResults: [QueryResult] = [] {
        didSet {
            tableView.reloadData()
        }
    }

    init(endpoint: URL) {
        self.endpoint = endpoint
        super.init(style: .plain)
    }
    required init?(coder: NSCoder) {fatalError()}

    override func viewDidLoad() {
        super.viewDidLoad()

        searchField.delegate = self
        tableView.register(QueryResultCell.self, forCellReuseIdentifier: "Cell")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if searchField.text?.isEmpty ?? true {
            searchField.text = "らぁら"
            search(text: "らぁら")
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if tableView.tableHeaderView?.frame.height != searchHeaderView.frame.height {
            searchHeaderView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            searchHeaderView.sizeToFit()
            searchHeaderView.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: max(searchHeaderView.frame.height, 44))
            tableView.tableHeaderView = searchHeaderView
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return queryResults.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! QueryResultCell
        let r = queryResults[indexPath.row]
        cell.subjectLabel.text = r.label ?? r.name ?? r.subject
        cell.typeLabel.text = r.typeLabel
        cell.matchedTextLabel.text = r.matchedText
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let r = queryResults[indexPath.row]
        showDetailViewController(UINavigationController(rootViewController: SubjectGraphViewController(endpoint: endpoint, subject: r)) ※ {$0.interactivePopGestureRecognizer?.delegate = nil}, sender: nil)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        NSLog("%@", "query search text: \(searchField.text ?? "")")
        search(text: searchField.text ?? "")
        return true
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        searchField.resignFirstResponder()
    }

    struct QueryResult: Codable {
        var subject: String
        var type: String
        var typeLabel: String?
        var label: String?
        var name: String?
        var matchedText: String
    }

    func search(text: String) {
        let subject = SwiftSparql.subject(Var("subject"))
        let type = Var("type")
        let typeLabel = Var("typeLabel")
        let label = Var("label")
        let name = Var("name")
        let matchedText = Var("matchedText")

        let query = SelectQuery(
            option: .distinct,
            where: WhereClause(patterns:
                subject.rdfType(is: type)
                    .optional {$0.rdfsLabel(is: label)}
                    .optional {$0.schemaName(is: name)}
                    .alternative({[
                        $0.rdfsLabel,
                        $0.schemaName,
                        $0.rdfTypeIsPrismCharacter().erasingSubjectType {$0.prismName},
                        $0.rdfTypeIsPrismCharacter().erasingSubjectType {$0.prismName_kana},
                        $0.rdfTypeIsPrismCharacter().erasingSubjectType {$0.prismFavorite_food},
                        $0.rdfTypeIsPrismEpisode().erasingSubjectType {$0.prismサブタイトル},
                        ]}, is: matchedText)
                    .triples
                    + SwiftSparql.subject(type).rdfsLabel(is: typeLabel).triples
                    + [.filter(.CONTAINS(v: matchedText, sub: text, caseInsensitive: true))]),
            limit: 100)
        NSLog("%@", "query: \(Serializer.serialize(query))")
        Request(endpoint: endpoint, select: query).fetch()
            .onSuccess {self.queryResults = $0}
            .onFailure {
                NSLog("%@", "failure: \(String(describing: $0))")
                let ac = UIAlertController(title: "Error", message: String(describing: $0), preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(ac, animated: true)
        }
    }
}

import NorthLayout

final class QueryResultCell: UITableViewCell {
    let subjectLabel = UILabel() ※ {
        $0.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .title1), size: 20)
        $0.textColor = .label
        $0.numberOfLines = 0
    }
    let typeLabel = UILabel() ※ {
        $0.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .title2), size: 16)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }
    let matchedTextLabel = UILabel() ※ {
        $0.font = UIFont(descriptor: .preferredFontDescriptor(withTextStyle: .body), size: 16)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        let autolayout = contentView.northLayoutFormat([:], ["subject": subjectLabel, "type": typeLabel, "matched": matchedTextLabel])
        autolayout("H:||[subject]-(>=0)-[type]||")
        autolayout("H:||[matched]||")
        autolayout("V:||[subject]-[matched]||")
        autolayout("V:||[type]-(>=0)-[matched]||")

        typeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    required init?(coder: NSCoder) {fatalError()}
}

extension TripleBuilder where State: TripleBuilderStateRDFTypeBoundType {
    func erasingSubjectType(_ block: @escaping (TripleBuilder<State>) -> (Var) -> TripleBuilder<State>) -> ((Var) -> TripleBuilder<TripleBuilderStateIncompleteSubject>) {
        return {v in .init(subject: self.subject, triples: block(self)(v).triples)}
    }
}

extension BuiltInCall {
    static func CONTAINS(v: Var, sub: String, caseInsensitive: Bool) -> BuiltInCall {
        return .CONTAINS(Expression(.LCASE(Expression(.STR(v: v)))), Expression(.LCASE(Expression(stringLiteral: sub))))
    }
}
