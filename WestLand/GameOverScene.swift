//
//  GameOverScene.swift
//  WestLand
//
//  Created by Padam Rao on 8/6/17.
//  Copyright © 2017 Karan Parikh. All rights reserved.
//

import SpriteKit

class GameOverScene: SKScene{

    let restartLable = SKLabelNode(fontNamed: "Balloony-Regular")

    override func didMove(to view: SKView) {
        
        let background = SKSpriteNode(imageNamed: "desert")
        background.position = CGPoint(x: self.size.width/2 , y: self.size.height/2)
        background.size = self.size
        background.zPosition = 0
        self.addChild(background)
        
        
        let gameOverLabel = SKLabelNode(fontNamed: "Balloony-Regular")
        gameOverLabel.text = "Game Over"
        gameOverLabel.fontSize = 150
        gameOverLabel.fontColor = SKColor.white
        gameOverLabel.position = CGPoint(x:self.size.width*0.5, y: self.size.height*0.7)
        gameOverLabel.zPosition = 1
        self.addChild(gameOverLabel)
        
        
        restartLable.text = "Restart"
        restartLable.fontSize = 90
        restartLable.position = CGPoint(x:self.size.width*0.5, y: self.size.height*0.5)
        restartLable.fontColor = SKColor.white
        restartLable.zPosition = 1
        self.addChild(restartLable)
    
}
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch: AnyObject in touches{
            
            let pointOfTouch = touch.location(in: self)
            
            if restartLable.contains(pointOfTouch){
                
                let sceneToMoveTo = GameScene(size: self.size)
                sceneToMoveTo.scaleMode =  self.scaleMode
                let myTransition = SKTransition.fade(withDuration: 0.5)
                self.view!.presentScene(sceneToMoveTo, transition: myTransition)
                
            }

    }
}
}
