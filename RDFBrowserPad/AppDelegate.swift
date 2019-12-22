import UIKit
import Ikemen

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        window = UIWindow() ※ {
//            $0.rootViewController = ViewController(endpoint: URL(string: "https://sparql.crssnky.xyz/spql/imas/query")!)
            $0.rootViewController = ViewController(endpoint: URL(string: "https://prismdb.takanakahiko.me/sparql")!)
            $0.makeKeyAndVisible()
        }
        return true
    }
}

