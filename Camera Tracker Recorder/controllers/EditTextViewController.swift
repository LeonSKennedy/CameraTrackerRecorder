//
//  EditTextViewController.swift
//  Camera Tracker Recorder
//
//  Created by Michael Levesque on 8/5/19.
//  Copyright © 2019 Michael Levesque. All rights reserved.
//

import UIKit

class EditTextViewController: UIViewController, UITextFieldDelegate {
    
    private var projectName: String = ""
    private var sceneValue: String = ""
    private var takeValue: String = ""
    
    @IBOutlet weak var projectText: UITextField!
    @IBOutlet weak var sceneText: UITextField!
    @IBOutlet weak var takeText: UITextField!
    
    override func viewDidLoad() {
        projectText.delegate = self
        sceneText.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateTextFields()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    public func setText(project: String, scene: String, take: String) {
        projectName = project
        sceneValue = scene
        takeValue = take
    }
    
    @IBAction func onEditTextBegin(_ sender: Any) {
        if let textField = sender as? UITextField {
            textField.selectAll(nil)
        }
    }
    
    @IBAction func onProjectEditEnd(_ sender: Any) {
        editEnd(textField: sender as? UITextField, valueRef: &projectName)
    }
    
    @IBAction func onSceneEditEnd(_ sender: Any) {
        editEnd(textField: sender as? UITextField, valueRef: &sceneValue)
    }
    
    @IBAction func onTakeEditEnd(_ sender: Any) {
        editEnd(textField: sender as? UITextField, valueRef: &takeValue)
    }
    
    @IBAction func onTakeResetTouchUp(_ sender: Any) {
        takeValue = "1"
        takeText.text = takeValue
    }
    
    @IBAction func onSaveTouchUp(_ sender: Any) {
        notifyTextChange(useProject: true, useScene: true, useTake: true)
        closeView()
    }
    
    @IBAction func onCancelTouchUp(_ sender: Any) {
        closeView()
    }
    
    func dismissKeypad() {
        takeText.resignFirstResponder()
    }
    
    private func editEnd(textField: UITextField?, valueRef: inout String) {
        if takeText?.text?.isEmpty ?? true {
            textField?.text = valueRef
        }
        else {
            valueRef = textField?.text ?? valueRef
        }
    }
    
    private func updateTextFields() {
        projectText.text = projectName
        sceneText.text = sceneValue
        takeText.text = "\(takeValue)"
    }
    
    private func notifyTextChange(useProject: Bool, useScene: Bool, useTake: Bool) {
        var userInfo: [AnyHashable: Any] = [:]
        if useProject {
            userInfo[TextKeys.ProjectName] = projectName
        }
        if useScene {
            userInfo[TextKeys.SceneValue] = sceneValue
        }
        if useTake {
            userInfo[TextKeys.TakeValue] = takeValue
        }
        
        if !userInfo.isEmpty {
            NotificationCenter.default.post(
                name: ViewController.notificationName,
                object: nil,
                userInfo: userInfo)
        }
    }
    
    private func closeView() {
        self.dismiss(animated: true, completion: nil)
    }
}
