//
//  ReceiverViewController.swift
//  OnlineCunpe
//
//  Created by Jaappao on 2022/07/20.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift
import AVFoundation

class ReceiverViewController: UIViewController {
    
    @IBOutlet var receiverTextView: UITextView!
    @IBOutlet var roomIdLabel: UILabel!
    @IBOutlet var fontSizeSlider: UISlider!
    @IBOutlet var updatedAtLabel: UILabel!
    @IBOutlet var updateNowButton: UIButton!
    
    var db: Firestore!
    
    var currentRoomId: String!
    var roomDocRef: DocumentReference!
    
    var listener: ListenerRegistration?
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        db = Firestore.firestore()
        
        // textView Setting
        receiverTextView.text = "input here"
        receiverTextView.allowsEditingTextAttributes = false
        receiverTextView.isEditable = false
        
        // slider
        fontSizeSlider.maximumValue = 300
        fontSizeSlider.minimumValue = 10
        fontSizeSlider.value = (300 + 10) / 2
        
        // nilチェック
        guard let currentRoomId = currentRoomId else {
            print("[viewDidLoad] RoomId is not valid")
            return
        }
        guard let roomDocRef = roomDocRef else {
            print("[viewDidLoad] Room Reference is not valid")
            return
        }
        
        roomIdLabel.text = currentRoomId
        listener = roomDocRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("-[viewDidLoad] Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("-[viewDidLoad] Document data was Empty")
                return
            }
            print("Current Data: \(data)")
            guard let message = data[ViewController.DBFieldName.message.rawValue] as? String else {
                print("-[viewDidLoad] data doesnt contain message")
                return
            }
            self.updateText(message)
            
            guard let updatedAt = data[ViewController.DBFieldName.updatedAt.rawValue] as? Timestamp else {
                print("-[viewDidLoad] data doesnt contain updatedAt")
                return
            }
            self.updateUpdatedAtLabel(updatedAt.dateValue())
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        guard let listener = listener else {
            print("[viewWillDisapper] listener is not valid")
            return
        }
        listener.remove()
        print("[viewWillDisappear] listener removed \(currentRoomId ?? "nil")")
        super.viewDidDisappear(animated)
    }
    
    func updateText(_ newtext: String) {
        self.receiverTextView.fadeOut(type: .Normal, completed: {
            MySoundPlayer.arrivalPlay()
            
            self.receiverTextView.text = newtext
            self.scaleTextSize(newtext, fontSize: 150, times: 5) // 5回の再帰内で適切なフォントサイズを見つけるs
            
            self.receiverTextView.fadeIn(type: .SemiSlow, completed: {
                print("[updateText] updated \(newtext)")
            })
        })
    }
    
    // 入力文字列に適切に合うフォントサイズを見つけて、textViewにフォントサイズを反映させる（再帰呼び出しによる焼きなまし法だなこれ）
    func scaleTextSize(_ newtext: String, fontSize: CGFloat, times: Int) {

        let textViewHight: CGFloat = self.receiverTextView.frame.size.height
        let textViewWidth: CGFloat = self.receiverTextView.frame.size.width
        let textViewMenseki = textViewWidth * textViewHight
        
        let font = UIFont.systemFont(ofSize: fontSize)
        let newTextWidth = newtext.widthOfString(usingFont: font)
        let newTextHeight = newtext.heightOfString(usingFont: font)
        let newTextMenseki = newTextWidth * newTextHeight
        
        print("[scaleTextSize] \(fontSize) newTextW:\(newTextWidth) newTextH:\(newTextHeight) newTextMenseki:\(newTextMenseki) -- viewW:\(textViewWidth) viewH:\(textViewHight) viewMenseki:\(textViewMenseki)")
        if times >= 1 {
            if newTextMenseki > textViewMenseki * 0.725 {
                // 新しいテキストをfontSizeで表示すると、表示範囲から溢れる場合
                print("[scaleTextSize] decrease \(fontSize * 0.1 * CGFloat(times-1))")
                scaleTextSize(newtext, fontSize: fontSize - (fontSize * 0.1 * CGFloat(times-1)), times: times-1) // 引数のtimes回数内の再帰しか認めない
            } else if newTextMenseki < (textViewMenseki * 0.5) {
                // 新しいテキストをfontSizeで表示すると、ちっちゃすぎる場合
                print("[scaleTextSize] increase \(5 * CGFloat(times-1))")
                scaleTextSize(newtext, fontSize: fontSize + (5 * CGFloat(times-1)), times: times-1)
            } else {
                // 表示範囲の 75% を超過せず、かつ60%以上の面積を使用している場合
                print("[scaleTextSize] Good Scale \(fontSize)")
                self.receiverTextView.font = UIFont.boldSystemFont(ofSize: fontSize)
                self.fontSizeSlider.setValue(Float(fontSize), animated: true)
                return
            }
        } else {
            // 再帰回数を超過したので、暫定解で表示させる
            print("[scaleTextSize] times exceeded, Final size \(fontSize)")
            self.receiverTextView.font = UIFont.boldSystemFont(ofSize: fontSize)
            self.fontSizeSlider.setValue(Float(fontSize), animated: true)
            return
        }
    }
    
    @IBAction func sliderChanged(_ sender: UISlider) {
        self.receiverTextView.font = UIFont.boldSystemFont(ofSize: CGFloat(sender.value))
    }
    
    func updateUpdatedAtLabel(_ updatedAt: Date) {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.doesRelativeDateFormatting = true
        
        print("[updateUpdatedAtLabel] \(f.string(from: updatedAt))")
        self.updatedAtLabel.text = f.string(from: updatedAt)
    }
    
    @IBAction func updateNowButtonPushed() {
        updateNowButton.isEnabled = false
        roomDocRef.getDocument { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("-[updateNowButton] Error fetching document: \(error!)")
                self.updateNowButton.isEnabled = true
                return
            }
            guard let data = document.data() else {
                print("-[updateNowButton] Document data was Empty")
                self.updateNowButton.isEnabled = true
                return
            }
            print("Current Data: \(data)")
            guard let message = data[ViewController.DBFieldName.message.rawValue] as? String else {
                print("-[updateNowButton] data doesnt contain message")
                self.updateNowButton.isEnabled = true
                return
            }
            self.updateText(message)
            
            guard let updatedAt = data[ViewController.DBFieldName.updatedAt.rawValue] as? Timestamp else {
                print("-[updateNowButton] data doesnt contain updatedAt")
                self.updateNowButton.isEnabled = true
                return
            }
            self.updateUpdatedAtLabel(updatedAt.dateValue())
            self.updateNowButton.isEnabled = true
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

enum FadeType: TimeInterval {
    case
    Normal = 0.2,
    SemiSlow = 0.8,
    Slow = 1.0
}

extension UIView {
   func fadeIn(type: FadeType = .Normal, completed: (() -> ())? = nil) {
        fadeIn(duration: type.rawValue, completed: completed)
    }

    /** For typical purpose, use "public func fadeIn(type: FadeType = .Normal, completed: (() -> ())? = nil)" instead of this */
   func fadeIn(duration: TimeInterval = FadeType.Slow.rawValue, completed: (() -> ())? = nil) {
        alpha = 0
        isHidden = false
        UIView.animate(withDuration: duration,
            animations: {
                self.alpha = 1
            }) { finished in
                completed?()
        }
    }
   func fadeOut(type: FadeType = .Normal, completed: (() -> ())? = nil) {
        fadeOut(duration: type.rawValue, completed: completed)
    }
    /** For typical purpose, use "public func fadeOut(type: FadeType = .Normal, completed: (() -> ())? = nil)" instead of this */
   func fadeOut(duration: TimeInterval = FadeType.Slow.rawValue, completed: (() -> ())? = nil) {
       UIView.animate(withDuration: duration
            , animations: {
                self.alpha = 0
            }) { [weak self] finished in
                self?.isHidden = true
                self?.alpha = 1
                completed?()
        }
    }
}

extension String {
    public func widthOfString(usingFont font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: attributes)
        return size.width
    }

    public func heightOfString(usingFont font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        let size = self.size(withAttributes: attributes)
        return size.height
    }
}
