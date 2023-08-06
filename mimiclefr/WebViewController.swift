//
//  ViewController.swift
//  mimicle
//
//  Created by Hyung-Min Noh on 2021/11/22.
//

import UIKit
import WebKit
import Moya
import Firebase
import FacebookCore
import AVFoundation

class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {

    @IBOutlet weak var webView: WKWebView!
    var downloadHelper:WKDownloadHelper!
    
    private let provider = MoyaProvider<MimicleApi>()
    //public var pushToken = ""
    var popoverController: UIPopoverPresentationController?
    
    //푸시 랜딩 받기
    @objc func didRecieveLandingNotification(_ notification: Notification) {
        let landingUrl = UserDefaults.standard.string(forKey: "landing")
        if(landingUrl != nil && landingUrl != ""){
            self.loadWebPage(landingUrl!)
            UserDefaults.standard.setValue("", forKey: "landing")
        }
    }
    
    //다이나믹링크 랜딩 받기
    @objc func didRecieveDeeplinkLandingNotification(_ notification: Notification) {
        webView?.evaluateJavaScript("callBackground()") { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else if let result = result {
                print(result)
            }
        }
    }
    
    //앱 포그라운드 시점 웹호출
    @objc func didRecieveToForegroundNotification(_ notification: Notification) {
        webView?.evaluateJavaScript("callApp()") { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else if let result = result {
                print(result)
            }
        }
    }
    
    //앱 백그라운드 시점 웹호출
    @objc func didRecieveToBackgroundNotification(_ notification: Notification) {
        webView?.evaluateJavaScript("callBackground()") { result, error in
            if let error = error {
                print(error.localizedDescription)
            } else if let result = result {
                print(result)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 옵저버 등록(푸시 받은 뒤 랜딩 이동)
        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveLandingNotification(_:)), name: NSNotification.Name("landing"), object: nil)
        
        // 옵저버 등록(다이나믹 링크를 통해 랜딩 이동)
        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveDeeplinkLandingNotification(_:)), name: NSNotification.Name("deeplinkLanding"), object: nil)
        
        // 앱 포그라운드 시점 웹호출
        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveToForegroundNotification(_:)), name: NSNotification.Name("webCallToForeground"), object: nil)
        
        // 앱 백그라운드 시점 웹호출
        NotificationCenter.default.addObserver(self, selector: #selector(didRecieveToBackgroundNotification(_:)), name: NSNotification.Name("webCallToBackground"), object: nil)
        
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        let guide = view.safeAreaLayoutGuide
        webView.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
        webView.leftAnchor.constraint(equalTo: guide.leftAnchor).isActive = true
        webView.rightAnchor.constraint(equalTo: guide.rightAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: guide.bottomAnchor).isActive = true
        
        //JS에서의 호출 대응
        webView.configuration.userContentController.add(self, name: "saveNoti")
        webView.configuration.userContentController.add(self, name: "setMemno")
        webView.configuration.userContentController.add(self, name: "callSnsSheet")
        webView.configuration.userContentController.add(self, name: "callVibrate")
        
        //앱 버전 검사하기
        // Do any additional setup after loading the view.
        let build = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        provider.request(.getMeta(osType: "ios", versionCode: build)){ (result) in
            switch result {
            case let .success(response):
                let result = try? response.map(AppMetaData.self)
                let url = result?.data.mainurl
                UserDefaults.standard.setValue(url, forKey: "mainUrl")
                
                if(Int((result?.data.vcode)!) ?? 0 > Int(build) ?? 0){
                    if(result?.data.forcedyn.uppercased() == "Y"){
                        self.alert((result?.data.strupdate)!, true)
                    }else{
                        self.alert((result?.data.strupdate)!, false)
                    }
                }
                
                let mainurl = UserDefaults.standard.string(forKey: "mainUrl")
                if(mainurl != nil){
                    //self.loadWebPage("https://app.mimicle.kr/sample/pdf_test.html")
                    self.loadWebPage(mainurl! + "?ostype=ios&vcode=" + build + "&osver=" + UIDevice.current.systemVersion)
                }
            case let .failure(error):
                print(error.localizedDescription)
            }
        }
        
        self.sendPushToken()
    }
    
    func sendPushToken(){
        let build = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        //서버로 푸쉬토큰을 포함 앱정보 전송
        let udid = UIDevice.current.identifierForVendor?.uuidString
        var memno = UserDefaults.standard.string(forKey: "memno")
        if(memno == nil){
            memno = ""
        }
        Messaging.messaging().token { token, error in
          if let error = error {
            print("Error fetching FCM registration token: \(error)")
          } else if let token = token {
            print("FCM registration token: \(token)")
            //self.pushToken = token
            if(udid != nil){
                self.provider.request(.setPushInfo(osType: "ios", versionCode: build, pushkey: token, uuid: udid!, memno: memno!)){ (result) in
                  //switch result {
                  //case let .success(response):
                      //let result = try? response.map(PushInfoData.self)
                      
                      //let memno = result?.memno
                      //UserDefaults.standard.setValue(memno, forKey: "memno")
                      //print("getMeta : \(response)")
                  //case let .failure(error):
                  //    print(error.localizedDescription)
                  //}
              }
            }
          }
        }
    }
    
    // JS -> Native CALL
    @available (iOS 8.0, *)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {

        if(message.name == "callVibrate"){
            
            if(message.body as? String == "1"){
                let notificationGenerator = UINotificationFeedbackGenerator()
                    notificationGenerator.notificationOccurred(.success)
            }else if(message.body as? String == "2"){
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }else if(message.body as? String == "3"){
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }else if(message.name == "saveNoti"){
            print("test 호출 \(message.body)")
        }else if(message.name == "setMemno"){
            UserDefaults.standard.setValue(message.body, forKey: "memno")
            self.sendPushToken()
        }else if(message.name == "callSnsSheet"){
           // let shareText: String = message.body
            let shareObject = [message.body]
            //shareObject.append(shareText)
            let activityViewController = UIActivityViewController(activityItems : shareObject, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.view //activityViewController.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.postToFacebook,UIActivity.ActivityType.postToTwitter,UIActivity.ActivityType.mail]
            self.present(activityViewController, animated: true, completion: nil)
            
            activityViewController.completionWithItemsHandler = { (activityType: UIActivity.ActivityType?, completed: Bool, arrayReturnedItems: [Any]?, error: Error?) in
                if completed {
                    //self.showToast(message: "공유하였습니다")
                }else {
                    //self.showToast(message: "취소되었습니다")
                }
                if let shareError = error {
                    self.showToast(message: "\(shareError.localizedDescription)")
                }
            }
            
            activityViewController.popoverPresentationController?.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            activityViewController.popoverPresentationController?.permittedArrowDirections = []
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if let popoverController = self.popoverController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: size.width*0.5, y: size.height*0.5, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
    }
    
    private func alert(_ strupdate: String, _ isForced : Bool){
        // 메시지창 컨트롤러 인스턴스 생성
        let alert = UIAlertController(title: "", message: strupdate, preferredStyle: UIAlertController.Style.alert)
        
        // 메시지 창 컨트롤러에 들어갈 버튼 액션 객체 생성
        let okAction = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { _ in
            let url = "itms-apps://itunes.apple.com/app/" + "1619856817"
            if let url = URL(string: url), UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        })
        alert.addAction(okAction)
        
        if(!isForced){
            let cancelAction =  UIAlertAction(title: "cancel", style: UIAlertAction.Style.cancel, handler: nil)
            alert.addAction(cancelAction)
        }
        //메시지 창 컨트롤러를 표시
        self.present(alert, animated: false)
    }

    private func loadWebPage(_ url: String) {
        if #available(iOS 15.0, *){
            let mimeTypes = [MimeType(type: "jpeg", fileExtension: "jpg"),
                             MimeType(type: "pdf", fileExtension: "pdf"),
                             MimeType(type: "png", fileExtension: "png"),
                             MimeType(type: "wav", fileExtension: "wav")]
            //helper = WKDownloadHelper(webView: webView, mimeTypes:mimeTypes, delegate: self)
            downloadHelper = WKDownloadHelper(webView: webView, supportedMimeTypes: mimeTypes, delegate: self)
        }
        WKWebsiteDataStore.default().removeData(ofTypes:
                [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache],
                modifiedSince: Date(timeIntervalSince1970: 0)) {
                }
                
        //webView.allowsBackForwardNavigationGestures = true
        
        guard let myUrl = URL(string: url) else {
            return
        }
        let request = URLRequest(url: myUrl)
        webView.load(request)
    }
    
    override func viewDidAppear(_ animated: Bool) {
       super.viewDidAppear(animated)
       
       guard Reachability.networkConnected() else {
           let alert = UIAlertController(title: "NetworkError", message: "Network disconnected.", preferredStyle: .alert)
           let okAction = UIAlertAction(title: "exit", style: .default) { (action) in
               exit(0)
           }
           alert.addAction(okAction)
           self.present(alert, animated: true, completion: nil)
           return
       }
    }
    
    //팝업띄우기
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            completionHandler()
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            completionHandler(true)
        }
        let cancelAction = UIAlertAction(title: "CANCEL", style: .default) { (action) in
            completionHandler(false)
        }
        alert.addAction(okAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: "", message: prompt, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
            if let text = alert.textFields?.first?.text {
                completionHandler(text)
            } else {
                completionHandler(defaultText)
            }
        }
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    //새창띄우기
    var popupWebView: WKWebView?

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let frame = webView.frame
        popupWebView = WKWebView(frame: frame, configuration: configuration)
        popupWebView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        popupWebView?.navigationDelegate = self
        popupWebView?.uiDelegate = self
        view.addSubview(popupWebView!)
        return popupWebView!
    }
    
    func webViewDidClose(_ webView: WKWebView) {
        popupWebView!.removeFromSuperview()
        popupWebView = nil
    }
    
    func showToast(message : String, font: UIFont = UIFont.systemFont(ofSize: 14.0)) {
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.font = font
        toastLabel.textAlignment = .center;
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds = true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
}

extension WebViewController: WKDownloadHelperDelegate {
    func canNavigate(toUrl: URL) -> Bool {
        true
    }
    
    func didFailDownloadingFile(error: Error) {
        print("error while downloading file \(error)")
    }
    
    func didDownloadFile(atUrl: URL) {
        print("did download file!")
        DispatchQueue.main.async {
            let activityVC = UIActivityViewController(activityItems: [atUrl], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            activityVC.popoverPresentationController?.sourceRect = self.view.frame
            activityVC.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
            self.present(activityVC, animated: true, completion: nil)
        }
    }
}
