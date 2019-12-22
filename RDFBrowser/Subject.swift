import Foundation
import SwiftSparql
import BrightFutures

struct Subject {
    var iri: IRIRef
    var label: String?
    var name: String?
    var comment: String?
    var displayName: String {label ?? name ?? comment ?? iri.value}
}
