//
//  PlaySound.swift
//  OnlineCunpe
//
//  Created by Jaappao on 2022/08/07.
//

import Foundation
import AVFoundation

class MySoundPlayer {
    static var player: AVAudioPlayer?
    
    static func arrivalPlay() {
        if let soundURL = Bundle.main.url(forResource: "arrival", withExtension: "mp3") {
            do {
                MySoundPlayer.player = try AVAudioPlayer(contentsOf: soundURL)
            } catch {
                print("error")
            }
        }
        
        if let player = MySoundPlayer.player {
            player.play()
        } else {
            print("Cannot play")
        }
    }
}
