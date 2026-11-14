//
//  AppGroup.swift
//  Shield iOS
//
//  The app group the Safari extension leaves its reports in for the app. Both iOS targets
//  compile this file, so they settle on the same group. It's group.io.github.livid.Shield, as in
//  their entitlements, unless a sideloading tool re-signed Shield: AltStore and the like grant a
//  renamed group (listed in the provisioning profile they embed), and a wildcard profile grants
//  none at all.
//

import Foundation

/// The app group to share reports through, or nil when this copy of Shield has none. Then the
/// extension's reports never reach the app.
let sharedSuiteName: String? = {
    let named = "group.io.github.livid.Shield"
    // A renamed group usually keeps the original name in it, so try those first.
    let provisioned = provisionedAppGroups().sorted { $0.contains(named) && !$1.contains(named) }
    // On iOS this is nil for any group the process isn't entitled to.
    return ([named] + provisioned).first {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: $0) != nil
    }
}()

/// The app groups in this bundle's embedded.mobileprovision: a signed plist that Xcode and
/// sideloading tools put in the app and in each extension. Empty if there's no profile.
private func provisionedAppGroups() -> [String] {
    guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
          let data = try? Data(contentsOf: url),
          let start = data.range(of: Data("<?xml".utf8)),
          let end = data.range(of: Data("</plist>".utf8), in: start.upperBound..<data.endIndex),
          let profile = try? PropertyListSerialization.propertyList(
              from: data.subdata(in: start.lowerBound..<end.upperBound), format: nil) as? [String: Any],
          let entitlements = profile["Entitlements"] as? [String: Any]
    else { return [] }
    return entitlements["com.apple.security.application-groups"] as? [String] ?? []
}
