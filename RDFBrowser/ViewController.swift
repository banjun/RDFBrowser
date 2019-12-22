import Cocoa
import SwiftSparql
import NorthLayout
import Ikemen

final class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    private lazy var typesTableView: NSTableView = NSTableView(frame: .zero) ※ { tv in
        tv.delegate = self
        tv.usesAutomaticRowHeights = true
        tv.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "types")))
        tv.headerView = nil
        tv.target = self
        tv.doubleAction = #selector(didDoubleClickType)
    }
    private lazy var subjectsTableView: NSTableView = NSTableView(frame: .zero) ※ { tv in
        tv.delegate = self
        tv.usesAutomaticRowHeights = true
        tv.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "subjects")))
        tv.headerView = nil
        tv.doubleAction = #selector(didDoubleClickSubject)
    }
    private lazy var verbObjectPairTableView: NSTableView = NSTableView(frame: .zero) ※ { tv in
        tv.delegate = self
        tv.usesAutomaticRowHeights = true
        tv.addTableColumn(NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: "pairs")))
        tv.headerView = nil
        tv.target = self
        tv.doubleAction = #selector(didDoubleClickVerbObjectPair)
    }

    private var types: [RDFTypeSchema] = [] {
        didSet {
            selectedType = nil
            typesTableView.reloadData()
        }
    }
    private var selectedType: RDFTypeSchema? {
        didSet {
            if oldValue != selectedType {
                fetchRootSubjects()
            }
        }
    }
    private var selectedSubjectViewModel: SubjectViewModel? {
        didSet {
            if let selectedSubjectViewModel = selectedSubjectViewModel {
                print(selectedSubjectViewModel)
            } else {
                print("unselected subject")
            }
            if oldValue !== selectedSubjectViewModel {
                fetchChildrenOfRootSubject()
            }
        }
    }
    private var rootSubjectViewModels: [SubjectViewModel] = [] {
        didSet {
            selectedSubjectViewModel = nil
            subjectsTableView.reloadData()
        }
    }

    private let nodesView = NodesView()

    private let endpoint: URL

    init(endpoint: URL) {
        self.endpoint = endpoint
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {fatalError()}

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let autolayout = view.northLayoutFormat([:], [
            "types": NSScrollView() ※ {
                $0.documentView = typesTableView
                $0.hasVerticalScroller = true
            },
            "subjects": NSScrollView() ※ {
                $0.documentView = subjectsTableView
                $0.hasVerticalScroller = true
            },
            "pairs": NSScrollView() ※ {
                $0.documentView = verbObjectPairTableView
                $0.hasVerticalScroller = true
            },
            "nodes": nodesView])
        autolayout("H:|[types(200)]-[subjects(200)]-[pairs(>=200)]-[nodes]|")
        autolayout("V:|[types(>=200)]|")
        autolayout("V:|[subjects]|")
        autolayout("V:|[pairs]|")
        autolayout("V:|[nodes]|")

        typesTableView.dataSource = self
        subjectsTableView.dataSource = self
        verbObjectPairTableView.dataSource = self
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.initialFirstResponder = typesTableView
    }

    override func viewDidAppear() {
        super.viewDidAppear()

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
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView {
        case typesTableView: return types.count
        case subjectsTableView: return rootSubjectViewModels.count
        case verbObjectPairTableView: return selectedSubjectViewModel?.children.count ?? 0
        default: return 0
        }
    }
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn else { return nil }
        switch tableView {
        case typesTableView:
            return tableView.makeView(type: SubjectCell.self, identifier: tableColumn.identifier, owner: self) ※ {
                let type = types[row]
                $0.subject = Subject(iri: IRIRef(value: type.type), label: type.label, name: nil, comment: type.comment)
            }
        case subjectsTableView:
            return tableView.makeView(type: SubjectCell.self, identifier: tableColumn.identifier, owner: self) ※ {
                $0.subject = rootSubjectViewModels[row].subject
            }
        case verbObjectPairTableView:
            return tableView.makeView(type: VerbObjectPairCell.self, identifier: tableColumn.identifier, owner: self) ※ {
                let pair = selectedSubjectViewModel!.children[row]
                $0.pair = (verb: pair.verb.subject, object: pair.object.subject)
            }
        default: return nil
        }
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if 0 <= typesTableView.selectedRow && typesTableView.selectedRow < types.count {
            selectedType = types[typesTableView.selectedRow]
        } else {
            selectedType = nil
        }

        if 0 <= subjectsTableView.selectedRow && subjectsTableView.selectedRow < rootSubjectViewModels.count {
            selectedSubjectViewModel = rootSubjectViewModels[subjectsTableView.selectedRow]
        } else {
            selectedSubjectViewModel = nil
        }
    }

    private func fetchRootSubjects() {
        guard let type = selectedType else { return }

//        let countQuery = SelectQuery(
//            capture: .expressions([(Var("count"), .init(.count(distinct: false, expression: nil)))]),
//            where: WhereClause(patterns:
//                SwiftSparql.subject(Var("subject")).rdfType(is: IRIRef(value: type.type))
//                .triples))

        let sampleQuery = SelectQuery(
            where: WhereClause(patterns:
                subject(Var("subject")).rdfType(is: IRIRef(value: type.type))
                    .optional {$0.rdfsLabel(is: Var("label"))}
                    .optional {$0.schemaName(is: Var("name"))}
                    .triples),
            order: [.by(.RAND)],
            limit: 20)

//        Request(endpoint: endpoint, select: countQuery).fetch()
//            .zip(
        Request(endpoint: endpoint, select: sampleQuery).fetch()
//        )
//            .onSuccess { (count: [Count], samples: [SubjectSampleResult]) in
            .onSuccess { (samples: [SubjectSampleResult]) in
                self.rootSubjectViewModels = samples.map {SubjectViewModel(subject: Subject(iri: IRIRef(value: $0.subject), label: $0.label, name: $0.name, comment: nil))}
        }
        .onFailure {NSLog("%@", "error = \(String(describing: $0))")}
    }

    private func fetchChildrenOfRootSubject() {
        guard let subjectViewModel = selectedSubjectViewModel else { return }
        subjectViewModel.fetchChildrenSamples(endpoint: endpoint).onSuccess {
            print(subjectViewModel.debugDescription)
            self.verbObjectPairTableView.reloadData()
        }
    }

    @objc private func didDoubleClickType() {
        guard 0 <= typesTableView.clickedRow, typesTableView.clickedRow < types.count else { return }
        guard let url = URL(string: types[typesTableView.clickedRow].type) else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func didDoubleClickSubject() {
        guard 0 <= subjectsTableView.clickedRow, subjectsTableView.clickedRow < rootSubjectViewModels.count else { return }
        guard let url = URL(string: rootSubjectViewModels[subjectsTableView.clickedRow].subject.iri.value) else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func didDoubleClickVerbObjectPair() {
        guard let selectedSubjectViewModel = selectedSubjectViewModel,
            0 <= verbObjectPairTableView.clickedRow, verbObjectPairTableView.clickedRow < selectedSubjectViewModel.children.count else { return }
        guard let url = URL(string: selectedSubjectViewModel.children[verbObjectPairTableView.clickedRow].object.subject.iri.value) else { return }
        NSWorkspace.shared.open(url)
    }
}

struct Count: Codable {
    var count: Int
}

final class NodesView: NSView {
    var summary: (count: Int, samples: Int)? {
        didSet { update() }
    }
    var samples: [Subject] = [] {
        didSet {
            update()
        }
    }

    private let summaryLabel = NSTextField(labelWithString: "") ※ {
        $0.font = .boldSystemFont(ofSize: 14)
        $0.textColor = .labelColor
    }

    init() {
        super.init(frame: .zero)

        let autolayout = northLayoutFormat([:], [
            "summary": summaryLabel,
            "nodes": NSView()
        ])
        autolayout("H:|[summary]|")
        autolayout("H:|[nodes]|")
        autolayout("V:|[summary][nodes]|")
    }
    required init?(coder: NSCoder) {fatalError()}

    private func update() {
        summaryLabel.stringValue = "\(summary.map {String($0.samples)} ?? "--") samples out of \(summary.map {String($0.count)} ?? "--") subjects for \(samples.first?.displayName ?? "--")"
    }
}
