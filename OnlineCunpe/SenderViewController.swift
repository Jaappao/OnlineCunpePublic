//
//  SenderViewController.swift
//  OnlineCunpe
//
//  Created by Jaappao on 2022/07/20.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class SenderViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet var senderTextView: UITextView!
    @IBOutlet var roomIDLabel: UILabel!
    
    var db: Firestore!

    var currentRoomId: String!
    var roomDocRef: DocumentReference!
    
    var listener: ListenerRegistration?
    
    var lastMessage: String = ""
    var lastTextViewUpdateTime: Date = Date()
    
    var updateTimer: Timer!
    let autoMessageUpdateInterval: Double = 5.0

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        db = Firestore.firestore()
        senderTextView.text = "input here"
        
        // nilチェック
        guard let currentRoomId = currentRoomId else {
            print("[viewDidLoad] RoomId is not valid")
            return
        }
        guard let roomDocRef = roomDocRef else {
            print("[viewDidLoad] Room Reference is not valid")
            return
        }
        
        senderTextView.delegate = self
        listener = roomDocRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("[snapShotListener] Error fetching document: \(error!)")
                return
            }
            guard let data = document.data() else {
                print("[snapShotListener] Document data was Empty")
                return
            }
            print("[snapShotListener] Current Data: \(data)")
        }
        
        roomIDLabel.text = currentRoomId
        
        updateTimer  = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            // 1. 前回の更新と今のTextFieldの値が異なっていれば続行
            if self.lastMessage == self.senderTextView.text {
                // DB更新を反映する必要なし
                // print("[Timer] Message Need Not be Updated")
                return
            }
            
            // 2. 前回の更新日時から5秒以上経過していれば続行（無入力状態が続いたら自動でDBに反映させる処理を実現したい）
            if abs(self.lastTextViewUpdateTime.timeIntervalSinceNow) < self.autoMessageUpdateInterval {
                // もう少し未入力状態を待つ
                print("[Timer] Wait \(self.autoMessageUpdateInterval)sec for update, reamining \(self.autoMessageUpdateInterval - abs(self.lastTextViewUpdateTime.timeIntervalSinceNow)) sec")
                return
            }
            
            
            // 3. Execute Update
            self.updateMessage()
        })
    }

    func textViewDidChange(_ textView: UITextView) {
        print("[textViewDidChange] updated")
        lastTextViewUpdateTime = Date()
    }
    
    func updateMessage() {
        guard let roomDocRef = roomDocRef else {
            print("[updateMessage] Room Reference is not valid")
            return
        }
        
        guard let message = senderTextView.text else{
            print("[updateMessage] Message is not valid")
            return
        }
        
        roomDocRef.updateData([
            ViewController.DBFieldName.message.rawValue: message,
            ViewController.DBFieldName.updatedAt.rawValue: Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("-[updateMessage] error update message \(self.currentRoomId ?? "nil") \(message)")
                print(error)
                // TODO: Alert か 再送制御するか
                return
            } else{
                // 正常系
                print("-[updateMessage] successfully update message \(self.currentRoomId ?? "nil") -> \(message)")
                self.lastMessage = message
                return
            }
        }
    }
    
    @IBAction func sendButton() {
        // 即座にメッセージをDBに反映させる
        self.updateMessage()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        guard let updateTimer = self.updateTimer else{
            print("[viewwillDisapper] updateTimer nil")
            return
        }
        updateTimer.invalidate()
        
        guard let listener = listener else {
            print("[viewWillDisapper] listener is not valid")
            return
        }
        listener.remove()
        print("[viewWillDisappear] listener removed \(currentRoomId ?? "nil")")
        
        roomDocRef.updateData([
            ViewController.DBFieldName.isUsed.rawValue: false,
            ViewController.DBFieldName.message.rawValue: "この部屋はホストによって閉じられました。また来てね。",
            ViewController.DBFieldName.updatedAt.rawValue: Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("-[viewWillDisapper] error update isUsed \(self.currentRoomId ?? "nil")")
                print(error)
                // TODO: Alert か 再送制御するか
                return
            } else{
                // 正常系
                print("-[viewWillDisapper] successfully update isUsed \(self.currentRoomId ?? "nil")")
                self.lastMessage = "この部屋はホストによって閉じられました。また来てね。"
                return
            }
        }
        
        super.viewWillDisappear(animated)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
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
