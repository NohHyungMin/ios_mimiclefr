//
//  SceneDelegate.swift
//  mimicle
//
//  Created by Hyung-Min Noh on 2021/11/22.
//

import UIKit
import FacebookCore
import FirebaseDynamicLinks
import nanopb

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    //다이나믹 링크 수신
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if let incomingURL = userActivity.webpageURL {
            DynamicLinks.dynamicLinks().handleUniversalLink(incomingURL) { dynamicLinks, error in
                // Dynamic Link 처리
                if dynamicLinks == dynamicLinks {
                    self.parsingDynamicLink(dynamicLink: dynamicLinks!)
                }
                // Optional(<FIRDynamicLink: 0x2808c94f0, url [https://exdeeplinkjake.page.link/navigation&ibi=com.jake.sample.ExDeeplink], match type: unique, minimumAppVersion: N/A, match message: (null)>)
            }
        }
    }
    
    func parsingDynamicLink(dynamicLink: DynamicLink) {
        guard let url = dynamicLink.url else { return }
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            return
        }
        for queryItem in queryItems {
            if queryItem.name == "linkurl" {
                if queryItem.value != nil {
                    //UserDefaults.standard.setValue(queryItem.value, forKey: "deeplinkLanding")
                    print("value: ", queryItem.value!)
                    // 다이나믹링크 랜딩url 전송
                    NotificationCenter.default.post(
                        name: NSNotification.Name(rawValue: "deeplinkLanding"), // 알림을 식별하는 태그
                        object: nil, // 발송자가 옵저버에게 보내려고 하는 객체
                        userInfo: ["deeplink" : "\(queryItem.value!)"]
                    )
                }
            }
        }
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let userActivity = connectionOptions.userActivities.first {
            self.scene(scene, continue: userActivity)
        }
    }
    
    //페이스북 공유, 로그인 필요 메소드
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }

        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: "webCallToForeground"), // 알림을 식별하는 태그
            object: nil, // 발송자가 옵저버에게 보내려고 하는 객체
            userInfo: nil
        )
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        NotificationCenter.default.post(
            name: NSNotification.Name(rawValue: "webCallToBackground"), // 알림을 식별하는 태그
            object: nil, // 발송자가 옵저버에게 보내려고 하는 객체
            userInfo: nil
        )
    }
}

