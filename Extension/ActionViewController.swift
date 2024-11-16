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
    //var nameScript = ""

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
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Скрипты", style: .plain, target: self, action: #selector(showScriptList))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(transitionAction))
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        loadScriptsList()
        
        DispatchQueue.main.async {
           self.selectAlert()  //-- алерт с дефолтными скриптами
        }
    }

    @objc func transitionAction() {
        if !script.text.isEmpty {
            let savedScripts = loadScriptsList() // Получаем список сохранённых скриптов
            
            // Проверяем, есть ли скрипт с таким же содержимым в списке сохранённых
            if let scripts = savedScripts {
                if scripts.values.contains(script.text) {
                    // Если скрипт уже сохранён, просто завершаем
                    done()
                    print("Скрипт уже сохранён")
                } else {
                    // Если скрипт не найден в сохранённых, вызываем alert для сохранения
                    alertBeforSaveScript(script: script.text)
                }
            } else {
                // Если список сохранённых скриптов пуст, тоже вызываем alert для сохранения
                alertBeforSaveScript(script: script.text)
            }
        } else {
            // Завершаем, если текст пустой
            done()
            print("Пусто")
        }
    }

    
    @IBAction func done() {
        
            guard let host = URL(string: pageURL)?.host else { return }

            // Передача данных хост-приложению
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
        
    func alertBeforSaveScript(script: String) {
        let ac = UIAlertController(title: "Задать название скрипта", message: nil, preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: "Сохранить", style: .default) { [weak self, weak ac] _ in
            guard let nameScript = ac?.textFields?[0].text, !nameScript.isEmpty else { return }
            self?.saveScript(name: nameScript, script: script)
            print("name -- \(nameScript), script -- \(script)")
            
            // Завершить работу расширения только после сохранения
            self?.done()
        }
        
        ac.addTextField { textField in
            textField.placeholder = "Введите название скрипта"
        }
        
        ac.addAction(submitAction)
        ac.addAction(UIAlertAction(title: "Отмена", style: .cancel)) // Не завершаем расширение на отмене
        
        present(ac, animated: true)
    }


    
    func saveScript(name: String, script: String) {
        let defaults = UserDefaults.standard
        var scripts = defaults.dictionary(forKey: "SavedScripts") as? [String: String] ?? [:]
        scripts[name] = script
        defaults.set(scripts, forKey: "SavedScripts")
        print("Скрипт \(name) сохранён.")
    }
    
    func loadScriptsList() -> [String: String]? {
        let defaults = UserDefaults.standard
        if let savedScripts = defaults.dictionary(forKey: "SavedScripts") as? [String: String], !savedScripts.isEmpty {
            print("Загружены скрипты: \(savedScripts)")  // Печать для отладки
            return savedScripts
        } else {
            print("Скрипты не найдены.")
            return nil
        }
    }

    @objc func showScriptList() {
        if let scripts = loadScriptsList() {
            let alert = UIAlertController(title: "Выберите скрипт", message: nil, preferredStyle: .actionSheet)

            for (name, _) in scripts {
                alert.addAction(UIAlertAction(title: name, style: .default, handler: { _ in
                    self.script.text = scripts[name]
                }))
            }
            
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
            self.present(alert, animated: true)
        }
    }
}
