import Cocoa
func notifyUpdateAvailable() {}
@main
struct Tests {
    static func main() {
        let release = URL(string: "https://github.com/Allan-yuwu/BLEUnlock/releases/tag/v99.0.0")!
        let asset = URL(string: "https://github.com/Allan-yuwu/BLEUnlock/releases/download/v99.0.0/BLEUnlock-v99.0.0.dmg")!
        precondition(isForkReleaseURL(release))
        precondition(isForkReleaseURL(asset, asset: true))
        for value in ["https://github.com/bifrost-proxy/BLEUnlock/releases/tag/v99.0.0", "https://github.com/Allan-yuwu/BLEUnlock-fake/releases/tag/v99.0.0", "http://github.com/Allan-yuwu/BLEUnlock/releases/tag/v99.0.0", "https://github.com.evil.example/Allan-yuwu/BLEUnlock/releases/tag/v99.0.0"] {
            precondition(!isForkReleaseURL(URL(string: value)!))
        }
        let prefs = UserDefaults.standard
        prefs.set(true, forKey: "autoCheckUpdates")
        savePendingUpdate(version: "99.0.0", downloadURL: asset, releaseURL: release)
        precondition(pendingUpdate()?.downloadURL == asset)
        prefs.set("https://github.com/bifrost-proxy/BLEUnlock/releases/tag/v99.0.0", forKey: "pendingUpdateReleaseURL")
        precondition(pendingUpdate() == nil)
        precondition(prefs.object(forKey: "pendingUpdateVersion") == nil)
        savePendingUpdate(version: "99.0.0", downloadURL: URL(string: "https://github.com/bifrost-proxy/BLEUnlock/releases/download/v99.0.0/a.dmg"), releaseURL: release)
        precondition(pendingUpdate() == nil)
        clearPendingUpdate()
        print("PASS: fork update route validation and old-upstream pending-cache invalidation")
    }
}
