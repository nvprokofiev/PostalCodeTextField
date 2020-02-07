//
//  ViewController.swift
//  TextFieldValidator
//
//  Created by Nikolai Prokofev on 2020-02-06.
//  Copyright © 2020 Nikolai Prokofev. All rights reserved.
//

import UIKit

protocol TextFiedValidator {
    mutating func validate(onFinish: (Bool)->())
}

struct ValidatorFactory {

    struct ZipCodeValidator: TextFiedValidator {
        
        private let textField: UITextField
        private let pattern: String = "^(\\d{5}(-\\d{4})?|[A-Z]\\d[A-Z] ?\\d[A-Z]\\d)$"
        private let minNumberOfCharacters: Int = 6
        private var isEnabled = false
        
        private var text: String {
            guard let text = textField.text else { return String() }
            return text.replacingOccurrences(of: " ", with: "")
        }
        
        init(for textField: UITextField) {
            self.textField = textField
        }
        
        mutating func shouldValidate() -> Bool {
            
            if isEnabled {
                return true
            }
            if text.count >= minNumberOfCharacters {
                isEnabled = true
                return true
            }
            return false
        }
        
        private var isValid: Bool {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { fatalError("Regex")}
            let range = NSRange(location: 0, length: text.utf8.count)
            let matchString = regex.firstMatch(in: text, options: [], range: range)
            return matchString != nil
        }
        
        mutating func validate(onFinish: (Bool)->()) {
            guard shouldValidate() else { return }
            if isValid {
                onFinish(true)
            } else {
                onFinish(false)
            }
        }
    }
}

class MyViewController : UIViewController {
    
    private var zipCodeTextField: UITextField! {
        didSet {
            validators[zipCodeTextField] = ValidatorFactory.ZipCodeValidator(for: zipCodeTextField)
        }
    }
    private var shouldValidateZipCodeTextField = false
    private var validators: [UITextField: TextFiedValidator] = [:]
    
    override func loadView() {
        let view = UIView()
        view.backgroundColor = .white
        self.view = view
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addTextField()
        zipCodeTextField.delegate = self
        zipCodeTextField.addTarget(self, action: #selector(textFieldDidChange(_:)),for: .editingChanged)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing)))
    }
    
    private func addTextField() {
        zipCodeTextField = UITextField()
        zipCodeTextField.placeholder = "Zip Code"
        zipCodeTextField.translatesAutoresizingMaskIntoConstraints = false
        zipCodeTextField.adjustsFontSizeToFitWidth = true
        zipCodeTextField.autocapitalizationType = .allCharacters
        zipCodeTextField.autocorrectionType = .no
        zipCodeTextField.borderStyle = .roundedRect
        zipCodeTextField.font = UIFont.systemFont(ofSize: 26)
        
        view.addSubview(zipCodeTextField)
        
        NSLayoutConstraint.activate([
            zipCodeTextField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            zipCodeTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            zipCodeTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            zipCodeTextField.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        guard var text = textField.text else { return }
        
        if textField == zipCodeTextField {
            text = text.applyZipCodePattern(pattern: "### ###", replacmentCharacter: "#")
            textField.text = text
        }
        validateTextField(textField)
    }
    
    private func applyValidationStyle(to textField: UITextField, _ isValid: Bool) {
        if isValid {
            textField.backgroundColor = UIColor.green.withAlphaComponent(0.05)
        } else {
            textField.backgroundColor = UIColor.red.withAlphaComponent(0.05)
        }
    }
    
    private func validateTextField(_ textField: UITextField) {
        if var validator = validators[textField] {
            validator.validate { [weak self] isValid in
                self?.applyValidationStyle(to: textField, isValid)
            }
        }
    }
}

extension MyViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        validateTextField(textField)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        validateTextField(textField)
        textField.resignFirstResponder()
        return true
    }
}


extension String {
    
    func applyZipCodePattern(pattern: String, replacmentCharacter: Character) -> String {
        var resultString = self.replacingOccurrences( of: "[^a-zA-Z0-9]", with: "", options: .regularExpression)
        
        for index in 0 ..< pattern.count {
            guard index < resultString.count else { return resultString }
            let stringIndex = String.Index(utf16Offset: index, in: resultString)
            let patternCharacter = pattern[stringIndex]
            guard patternCharacter != replacmentCharacter else { continue }
            resultString.insert(patternCharacter, at: stringIndex)
        }
        return String(resultString.prefix(pattern.count))
    }
}
