//
//  GameScene.swift
//  WestLand
//
//  Created by Karan Parikh on 1/6/17.
//  Copyright © 2017 Karan Parikh. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    //Initializing motion
    let motionManager = CMMotionManager()
    var xAcceleration:CGFloat = 0
    
    var player = SKSpriteNode()     //Initializing player
    
    //Inialiing player animation
    var textureAtlas = SKTextureAtlas()
    var textureArray = [SKTexture]()

    
    let fireSound = SKAction.playSoundFileNamed("fire.wav", waitForCompletion: false)  //bullet sound
    let tapToStartLable = SKLabelNode(fontNamed: "Balloony-Regular")

    
    //game state enum
    enum gameState{
        
        case preGame //when the game state is before the start of the game
        case inGame  //when the game state is during the game
        case afterGame //when the game state is after the game
    }
    var currentGameState = gameState.preGame

    //assigning bodys to catagories
    struct physicsBodyCatagory{
    
        static let None: UInt32 = 0
        static let playerBody: UInt32 = 0b1 //1
        static let bulletBody: UInt32 = 0b10//2
        static let enemyBody: UInt32 = 0b100 //4
    }
    
    //function for generating random numbers
    func random() -> CGFloat{
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    func random(min: CGFloat, max: CGFloat) -> CGFloat{
        return random() * (max - min) + min
    }
    
    
    //setting up game area
    let gameArea: CGRect
    
    override init(size: CGSize){
        
        let maxAspectRatio: CGFloat =  16.0/9.0
        let playableWidth = size.height / maxAspectRatio
        let margin = (size.width - playableWidth) / 2
        
        gameArea = CGRect(x: margin, y: 0, width: playableWidth, height: size.height)
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //run as soon as scene loads up
    override func didMove(to view: SKView) {
        
        //Initializing physics contacts
        self.physicsWorld.contactDelegate = self
        
        //setting up two backgrounds
        for i in 0...1 {
            let background = SKSpriteNode(imageNamed: "desert")
            background.size = self.size
            background.anchorPoint = CGPoint(x:0.5, y:0)
            background.position = CGPoint(x: self.size.width/2 , y: self.size.height * CGFloat(i))
            background.zPosition = 0
            background.name = "Background"
            self.addChild(background)
        }
        
        //setting up texture array
        textureAtlas = SKTextureAtlas(named: "player")
        
        for i in 1...textureAtlas.textureNames.count{
            
            let Name = "cowboy_\(i).png"
            textureArray.append(SKTexture(imageNamed: Name))
        }
        
        //setting up player
        player = SKSpriteNode(imageNamed: textureAtlas.textureNames[0])
        player.setScale(3.5)
        player.position = CGPoint(x: self.size.width/2, y: 0 - player.size.height)
        player.zPosition = 2
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody!.affectedByGravity = false
        player.physicsBody!.categoryBitMask = physicsBodyCatagory.playerBody
        player.physicsBody!.collisionBitMask = physicsBodyCatagory.None
        player.physicsBody!.contactTestBitMask = physicsBodyCatagory.enemyBody
        self.addChild(player)
        
        //repeating array for forever
        player.run(SKAction.repeatForever(SKAction.animate(with: textureArray, timePerFrame: 0.1)))
        
        //adding tap to begin
        tapToStartLable.text = "TAP TO BEGIN"
        tapToStartLable.fontSize = 100
        tapToStartLable.fontColor =  SKColor.white
        tapToStartLable.position = CGPoint(x: self.size.width/2 , y: self.size.height/2)
        tapToStartLable.zPosition = 1
        tapToStartLable.alpha = 0
        self.addChild(tapToStartLable)
        
        let fadInAction = SKAction.fadeIn(withDuration: 0.3)
        tapToStartLable.run(fadInAction)
        
        //Getting accelerometer data and setting acceleration
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data: CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data{
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = CGFloat(acceleration.x * 0.75) + self.xAcceleration * 0.25 //for smooth accelarton values may change
            }
        }
    }
    
    
    //setting up moving backgrounds
    var lastTime: TimeInterval = 0
    var deltaTime: TimeInterval = 0
    let movePerSecond: CGFloat = 400.0
    
    
    //this func runs times fps i.e 60 times if fps= 60
    override func update(_ currentTime: TimeInterval) {
        
        if lastTime == 0{
            lastTime = currentTime
        }else{
            deltaTime = currentTime - lastTime
            lastTime = currentTime
        }
        let moveBackground = movePerSecond * CGFloat(deltaTime)
        self.enumerateChildNodes(withName: "Background"){
            background, stop in
            
            if self.currentGameState == gameState.inGame{
                background.position.y -= moveBackground
            }
            //send back to top
            if background.position.y < -self.size.height{
                background.position.y += self.size.height * 2
            }
        }
    }
    
    
    //start the game on touch
    func startGame() {
        
        currentGameState = gameState.inGame
        
        let fadOutAction = SKAction.fadeOut(withDuration: 0.5)
        let deleteAction = SKAction.removeFromParent()
        let deleteSequence = SKAction.sequence([fadOutAction, deleteAction])
        tapToStartLable.run(deleteSequence)
        
        let movePlayerToPosition = SKAction .moveTo(y: self.size.height*0.2, duration: 3)
        let startLevel =  SKAction.run(startNewLevel)
        
        let startSequence  = SKAction.sequence([movePlayerToPosition, startLevel])
        player.run(startSequence)
    }
    
    //startLevel
    func startNewLevel(){
    
        let enemySpawn = SKAction.run(spawnEnemy)
        let waitToSpawn = SKAction.wait(forDuration: 0.5)
        let spawnSequence = SKAction.sequence([enemySpawn, waitToSpawn])
        let spawnRepeat = SKAction.repeatForever(spawnSequence)
        self.run(spawnRepeat)
    }
    
    //gameover function
    func runGameOver(){
        
        currentGameState = gameState.afterGame
        
        self.removeAllActions()
        
        self.enumerateChildNodes(withName: "bullet"){
            bullet, stop in
            bullet.removeAllActions()
        }
        
        self.enumerateChildNodes(withName: "enemy"){
            enemy, stop in
            enemy.removeAllActions()
        }
        
        let changeSceneAction = SKAction.run(changeScene)
        let waitToChangeScene =  SKAction.wait(forDuration: 1)
        let changeSceneSequence = SKAction.sequence([waitToChangeScene, changeSceneAction ])
        self.run(changeSceneSequence)
    }

    //change scene function
    func changeScene(){
        
        let sceneToMoveTo = GameOverScene(size: self.size)
        sceneToMoveTo.scaleMode = self.scaleMode
        let myTransition = SKTransition.fade(withDuration: 0.5)
        self.view!.presentScene(sceneToMoveTo, transition: myTransition)
        
    }

    
    //spawn Enemy
    func spawnEnemy(){
        
            let enemy = SKSpriteNode(imageNamed: "enemy")

            //specifying random X and/or Y position(s) using random()
            let randomXStart = random(min: gameArea.minX + enemy.size.width , max: gameArea.maxX - enemy.size.width)
            
            //specifying start and end point of bubble
            let startPoint = CGPoint(x: randomXStart, y: self.size.height * 1.2)
            let endPoint = CGPoint(x: randomXStart , y: -self.size.height * 0.2)
            
            //crearing an enemy
            enemy.name = "enemy"
            enemy.setScale(0.5)
            enemy.position = startPoint
            enemy.zPosition = 2
            enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
            enemy.physicsBody!.affectedByGravity = false
            enemy.physicsBody!.categoryBitMask = physicsBodyCatagory.enemyBody
            enemy.physicsBody!.collisionBitMask = physicsBodyCatagory.None
            enemy.physicsBody!.contactTestBitMask = physicsBodyCatagory.playerBody | physicsBodyCatagory.bulletBody
            self.addChild(enemy)
        
            //moving across screen
            let moveEnemy = SKAction.move(to: endPoint , duration: 8)
            let deleteEnemy = SKAction.removeFromParent()
            let enemySequence = SKAction.sequence([moveEnemy, deleteEnemy])
        
        if currentGameState == gameState.inGame{
            enemy.run(enemySequence)
        }
    }
    
    
    //function for firing bullets
    func fireBullet() {
        
        
        //setting up bullet
        let bullet = SKSpriteNode(imageNamed: "bullet")
        bullet.name = "bullet"
        bullet.setScale(2)
        bullet.position = player.position
        bullet.zPosition = 1
        bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
        bullet.physicsBody!.affectedByGravity = false;
        bullet.physicsBody!.categoryBitMask = physicsBodyCatagory.bulletBody
        bullet.physicsBody!.collisionBitMask = physicsBodyCatagory.None
        bullet.physicsBody!.contactTestBitMask = physicsBodyCatagory.enemyBody
        self.addChild(bullet)
        
        //setting up sequence to move and remove bullet
        let moveBullet =  SKAction.moveTo(y: self.size.height + bullet.size.height , duration: 1)
        let removeBullet = SKAction.removeFromParent()
        
        //run sequence
        let fireSequence = SKAction.sequence([fireSound, moveBullet, removeBullet])
        
        //        player.isPaused = true
        //        player.texture = SKTexture(imageNamed: "cowboy_fire")
        
        bullet.run(fireSequence)
        
    }
    
    
    //run when touch began
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if currentGameState == gameState.preGame{
            startGame()
        }
            
        else if currentGameState == gameState.inGame {
            fireBullet()
        }
    }
    
    
    //runs when bodys make contact
    func didBegin(_ contact: SKPhysicsContact) {
        
        var body1 = SKPhysicsBody()
        var body2 = SKPhysicsBody()
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            body1 = contact.bodyA
            body2 = contact.bodyB
        }
        else{
            body1 = contact.bodyB
            body2 = contact.bodyA
        }
        
        // Player and Enemy make contact
        if body1.categoryBitMask == physicsBodyCatagory.playerBody &&
            body2.categoryBitMask == physicsBodyCatagory.enemyBody{
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
            
            runGameOver()
        }
        
        // Bullet and Enemy make contact
        if body1.categoryBitMask == physicsBodyCatagory.bulletBody &&
            body2.categoryBitMask == physicsBodyCatagory.enemyBody &&
            body2.node!.position.y < self.size.height
        {
            body1.node?.removeFromParent()
            body2.node?.removeFromParent()
        }
        
    }
    
    
    override func didSimulatePhysics() {
        
        if currentGameState == gameState.inGame{
            player.position.x += xAcceleration * 40 //adjust speed
        }
        
        //locking player in game area
        if player.position.x > gameArea.maxX - player.size.width/2{
            player.position.x = gameArea.maxX - player.size.width/2
        }
        
        if player.position.x < gameArea.minX + player.size.width/2{
            player.position.x = gameArea.minX + player.size.width/2
        }
    }
    
}
