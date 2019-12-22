import Cocoa
import Ikemen

@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        [("im@sparql", "https://sparql.crssnky.xyz/spql/imas/query"),
         ("PrismDB", "https://prismdb.takanakahiko.me/sparql")].forEach {
            let title = $0.0
            let endpoint = URL(string: $0.1)!
            let wc = WindowController(contentViewController: ViewController(endpoint: endpoint)) ※ {
                $0.window?.title = title
                $0.window?.setFrameAutosaveName(title)
                }
            wc.showWindow(nil)
        }
    }
}
