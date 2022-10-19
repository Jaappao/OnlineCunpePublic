//
//  ViewController.swift
//  OnlineCunpe
//
//  Created by Jaappao on 2022/07/20.
//

// やりたいことリスト:
// 最終更新時刻からの経過時間を表示させる
// message stateがdirtyかcleanかを表示するバーを設置する
// messageを独自インスタンス化して、「質問型メッセージ」を選択可能なように
// 端末内でログを取る機能をつける
// RoomへのInviteをDynamicリンクでやる（その前にuidとかを見直した方がいい, Zoomのやつを参考にした方がいいかも, uidとpassは自動発行, passは任意の値を設定可能）
// 前回入室した部屋のIDを記憶させる機能
// 特にMacの時：画面収録を検知したら文字列を見えなくする（ https://screenshieldkit.com/ とか UIScreen.capturedDidChangeNotification とか）
// もうちょとかわいいおとにする

// バグリスト：
// キーボードを隠す処理をつける
// たまに文字サイズが飛び出てしまう問題を解消

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class ViewController: UIViewController {
    
    var db: Firestore!
    
    // DB Version
    let DBVersion = 0
    func getVersion() -> String {
        return "v\(DBVersion)"
    }
    
    // DB Field Name
    enum DBFieldName: String {
        case password = "password"
        case roomname = "roomname"
        case uid = "uid"
        case updatedAt = "updatedAt"
        case message = "message"
        case isUsed = "isUsed"
    }
    
    enum RoomStatus {
        case notSuccessfullyCreated
        case successfullyCreated
        case roomIdDuplicated
        case roomNoPassword
        
        case notExists
        case existsButInvalidPassword
        case existsAndValidPassword
    }
    
    
    
    @IBOutlet var RoomIDTextField: UITextField!
    @IBOutlet var PasswordTextField: UITextField!
    @IBOutlet var RoomNameTextField: UITextField!
    
    var roomIDVerified: String?
    var roomRefVerified: DocumentReference?
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        RoomIDTextField.text = ""
        PasswordTextField.text = ""
        
        db = Firestore.firestore()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "toSender") {
            let vc: SenderViewController = (segue.destination as? SenderViewController)!
            vc.currentRoomId = roomIDVerified
            vc.roomDocRef = roomRefVerified
        } else if (segue.identifier == "toReceiver") {
            let vc: ReceiverViewController = (segue.destination as? ReceiverViewController)!
            vc.currentRoomId = roomIDVerified
            vc.roomDocRef = roomRefVerified
        }
    }
    
    @IBAction func didSenderButton() {
        let roomid = self.RoomIDTextField.text ?? ""
        let password = self.PasswordTextField.text ?? ""
        let roomName = self.RoomNameTextField.text ?? ""
            
        if roomid == "" {
            // TODO: RoomIdを設定するよう警告
            print("[didSenderButton] input roomid")
            return
        }
        
        self.createRoom(roomid: roomid, password: password, roomName: roomName) { status in
            if status == .successfullyCreated {
                self.joinRoom(roomid: roomid, password: password) { status, _ in
                    if status == .existsAndValidPassword {
                        print("[didSenderButton] OK, proceede to SenderView")
                        self.performSegue(withIdentifier: "toSender", sender: nil)
                    } else {
                        print("[didSenderButton] Check Error")
                    }
                }
            }
        }
        
        
    }

    @IBAction func didReceiverButton() {
        let roomid = self.RoomIDTextField.text ?? ""
        let password = self.PasswordTextField.text ?? ""
        
        self.joinRoom(roomid: roomid, password: password) { status, _ in
            if status == .existsAndValidPassword {
                print("[didReceiverButton] OK, proceede to ReceiverView")
                self.performSegue(withIdentifier: "toReceiver", sender: nil)
            } else {
                print("[didReceiverButton] Check Error")
            }
        }
        
    }
    
    func joinRoom(roomid: String, password: String, completion: @escaping (RoomStatus, DocumentReference?) -> ()) {
        let docRef = db.collection(getVersion()).document(roomid)
        
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                // 同一のRoomIDが存在する
                print("[joinRoom] \(roomid) Exists")
                
                // Passwordを取得(フィールドがない場合にはそのままReturnしている)
                guard let documentPasswordField: String = document.data()?[DBFieldName.password.rawValue] as? String else {
                    print("-[joinRoom] Database doesnt hold password")
                    // TODO: Alert この部屋は利用できません。新規Roomを作成してください。
                    return
                }
                
                // Passwordと照合
                if documentPasswordField == password {
                    // 部屋に入る準備OK
                    print("-[joinRoom] \(roomid) Password Auth Passed")
                    
                    // 認証成功時のroomidとroomRefをGlobal変数にBuffer（prepare関数で画面遷移するときに渡す用）
                    self.roomIDVerified = roomid
                    self.roomRefVerified = docRef
                    
                    return completion(.existsAndValidPassword, docRef)
                } else {
                    print("-[joinRoom] \(roomid) Password Auth Not Passed")
                    // TODO: Alert パスワードが違います
                    return completion(.existsButInvalidPassword, nil)
                }
                
            } else {
                print("[joinRoom] \(roomid) Not Exists")
                // TODO: Alert 指定したRoomIDは登録されていません
                return completion(.notExists, nil)
            }
        }
    }
    
    func createRoom(roomid: String, password: String, completion: @escaping (RoomStatus) -> ()){
        self.createRoom(roomid: roomid, password: password, roomName: "", completion: completion)
    }
    
    func createRoom(roomid: String, password: String, roomName: String, completion: @escaping (RoomStatus) -> ()) {
        let colRef = db.collection(getVersion())
        let docRef = colRef.document(roomid)
        
        docRef.getDocument { document, error in
            if let document = document, document.exists {
                print("-[createRoom] \(roomid) Exists")
                
                guard let documentIsUsed: Bool = document.data()?[DBFieldName.isUsed.rawValue] as? Bool else {
                    print("-[createRoom] Database doesnt hold isUsed field")
                    return
                }
                
                if (documentIsUsed) {
                    // 重複したRoomIDがDBにある
                    // FIXME: アプリの強制終了時にboolをfalseにしなかった場合、このエラーが出てしまう
                    print("-[createRoom] \(roomid) is already used, use another RoomID")
                    return completion(.roomIdDuplicated)
                } else {
                    // 重複したRoomIdがDB上にあるんだけど、今はRoom使ってないから使っちゃう
                    print("-[createRoom] \(roomid) duplicated, but not used. so use this RoomID")
                    
                    docRef.setData([
                        DBFieldName.uid.rawValue: roomid,
                        DBFieldName.password.rawValue: password,
                        DBFieldName.roomname.rawValue: roomName,
                        DBFieldName.updatedAt.rawValue: Timestamp(date: Date()),
                        DBFieldName.isUsed.rawValue: true
                    ]) { error in
                        if let error = error {
                            print("--[createRoom] error setting new room \(roomid)")
                            print(error)
                            // TODO: Alert 部屋作れませんでした、時間を置いて再度試してください
                            completion(.notSuccessfullyCreated)
                            return
                        } else{
                            // 正常系
                            print("--[createRoom] Room created, nice \(roomid)")
                            completion(.successfullyCreated)
                            return
                        }
                    }
                }
                
            } else {
                // RoomIDが重複してるdocumentが存在しない
                // いい感じに作れそう or ネットワークエラー？
                // FIXME: もしかすると存在確認後~データセットするまでの間に別のユーザが作っちゃって上書きするかも
                docRef.setData([
                    DBFieldName.uid.rawValue: roomid,
                    DBFieldName.password.rawValue: password,
                    DBFieldName.roomname.rawValue: roomName,
                    DBFieldName.updatedAt.rawValue: Timestamp(date: Date()),
                    DBFieldName.isUsed.rawValue: true
                ]) { error in
                    if let error = error {
                        print("-[createRoom] error setting new room \(roomid)")
                        print(error)
                        // TODO: Alert 部屋作れませんでした、時間を置いて再度試してください
                        completion(.notSuccessfullyCreated)
                        return
                    } else{
                        // 正常系
                        print("-[createRoom] Room created, nice \(roomid)")
                        completion(.successfullyCreated)
                        return
                    }
                }
                
            }
        }
    }

}

