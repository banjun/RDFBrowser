import UIKit
import Ikemen

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow() ※ {
            let imasparqlEndpoint = URL(string: "https://sparql.crssnky.xyz/spql/imas/query")!
            let prismdbEndpoint = URL(string: "https://prismdb.takanakahiko.me/sparql")!
            let localhostEndpoint = URL(string: "http://localhost:3000/sparql")!

            let endpoint = prismdbEndpoint

            let sc = UISplitViewController()
            sc.viewControllers = [QueryAndResultsViewController(endpoint: endpoint), UINavigationController()]
            $0.rootViewController = sc
            $0.makeKeyAndVisible()
        }
        return true
    }
}

