import Foundation
import SwiftSparql
import BrightFutures

protocol DisplayNameConvertible {
    var displayName: String { get }
}

struct Subject: Equatable, DisplayNameConvertible {
    var iri: IRIRef
    var type: IRIRef?
    var typeLabel: String?
    var label: String?
    var name: String?
    var comment: String?
    var displayName: String {label ?? name ?? comment ?? iri.value}
}

struct RDFTypeSchema: Codable, Equatable {
    var type: String
    var label: String?
    var comment: String?
    var subClassOf: String?
}

struct SubjectSampleResult: Codable {
    var subject: String
    var type: String?
    var typeLabel: String?
    var label: String?
    var name: String?
}
