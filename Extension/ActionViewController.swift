//
//  ActionViewController.swift
//  Extension
//
//  Created by Serhii Prysiazhnyi on 16.11.2024.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    @IBOutlet var script: UITextView!
    
    var pageTitle = ""
    var pageURL = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = inputItem.attachments?.first {
                itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [weak self] (dict, error) in
                    // do stuff!
                    guard let itemDictionary = dict as? NSDictionary else { return }
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    print(javaScriptValues)
                    
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""

                    DispatchQueue.main.async {
                        self?.title = self?.pageTitle
                    }
                }
            }
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        DispatchQueue.main.async {
            self.selectAlert()
        }

        
    }

    @IBAction func done() {
        let item = NSExtensionItem()
        let argument: NSDictionary = ["customJavaScript": script.text]
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
        item.attachments = [customJavaScript]

        extensionContext?.completeRequest(returningItems: [item])
    }

    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        script.scrollIndicatorInsets = script.contentInset

        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange)
    }

//    func selectAlert() {
//        
//        let alert = UIAlertController(title: "Choose default script", message: "Select from the list", preferredStyle: .actionSheet)
//        
//        // Добавляем действия для разных типов карт
//        alert.addAction(UIAlertAction(title: "alert(document.title);", style: .default, handler: { _ in
//            self.done()
//        }))
//        
////        alert.addAction(UIAlertAction(title: "Satellite", style: .default, handler: { _ in
////            self.mapView.mapType = .satellite
////        }))
////        
////        alert.addAction(UIAlertAction(title: "Hybrid", style: .default, handler: { _ in
////            self.mapView.mapType = .hybrid
////        }))
//        
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//        
//        // Показываем UIAlertController
//        present(alert, animated: true, completion: nil)
//    }
    
    func selectAlert() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "JavaScript-код", message: "Выбири из дефольного списка", preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "alert(document.title);", style: .default, handler: { _ in
                self.script.text = "alert(document.title);"
                self.done()
            }))
            alert.addAction(UIAlertAction(title: "alert(document.URL);", style: .default, handler: { _ in
                self.script.text = "alert(document.URL);"
                self.done()
            }))
            alert.addAction(UIAlertAction(title: "alert(document.domain);", style: .default, handler: { _ in
                self.script.text = "alert(document.domain);"
                self.done()
            }))
        alert.addAction(UIAlertAction(title: "alert(document.body.innerHTML);", style: .default, handler: { _ in
            self.script.text = "alert(document.body.innerHTML);"
            self.done()
        }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
                  //  для IPAD
//            if let popoverController = alert.popoverPresentationController {
//                popoverController.sourceView = self.view
//                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
//                popoverController.permittedArrowDirections = []
//            }
            
            self.present(alert, animated: true, completion: nil)
        }
    }
}
