import SwiftUI
import UIKit

struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.placeholder = placeholder
        tf.textAlignment = .center
        tf.font = .systemFont(ofSize: 32)
        tf.delegate = context.coordinator
        return tf
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        
        init(text: Binding<String>) {
            _text = text
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            text = textField.text ?? ""
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Limit to single emoji
            if string.isEmpty { return true }
            let newText = string.prefix(1)
            textField.text = String(newText)
            text = String(newText)
            return false
        }
    }
}

extension UITextField {
    override open var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return super.textInputMode
    }
}
