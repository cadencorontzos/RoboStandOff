//
//  GameScene.swift
//  Robo
//
//  Created by Caden Corontzos.
//  Copyright © 2020 Caden Corontzos. All rights reserved.
//
//  All assets were designed by Caden Corontzos using pixilart.com
//
//  Please note that my swift skills are self taught :)


import SpriteKit
import GameplayKit
import AVFoundation

// Allows us to control the physics of our various Nodes
struct Physics{
    static let shooter : UInt32 = 0x1 << 1;
    static let roboNode : UInt32 = 0x1 << 2;
    static let laserNode : UInt32 = 0x1 << 3;
    static let shipNode : UInt32 = 0x1 << 4;
    
}
class GameScene: SKScene,SKPhysicsContactDelegate {
    
    
    var shooter = SKSpriteNode(imageNamed: "Shooter ultra")
    var Robot = SKSpriteNode(imageNamed: "robot ogg")
    var ship = SKSpriteNode(imageNamed: "shippp")
    var infoBar = SKSpriteNode(imageNamed: "block")
    
    // Various Actions
    
    var moveRobo = SKAction()           // Moves robot across screen
    var removeRobo = SKAction()         // Deletes robot from world once off screen
    var moveAndRemove = SKAction()      // A composition of the move and remove robot actions
    
    var shootLaser = SKAction()         // Shoots laser
    var removeLaser = SKAction()        // Deletes the laser once off screen
    var shootAndRemove = SKAction()     // A compostition of the shoot and remove actions
    
    // Other Variables
    
    var hearts = [Int: SKSpriteNode]()  // Holds the hearts which appear at the top left corner
    var fingerLocus = CGPoint()         // The location of the players finger on the screen
    var gameStarted = Bool()            // Whether the game has Started
    var score = Int()                   // Score
    var lives = Int()                   // Lives
    let scoreLabel = SKLabelNode()      // Score Label
    let lifeLabel = SKLabelNode()       // Lives Label
    var tapToStart = SKSpriteNode()     // Starting Screen
    var restart = SKSpriteNode()        // Restart button
    
    var highScore = UserDefaults().integer (forKey: "highScore")
    var highScoreLbl = SKLabelNode()    // Allows us to save highscore between uses; Label for highscore
    
    var SCREEN_HEIGHT = CGFloat()       // Height of the screen
    var SCREEN_WIDTH = CGFloat()        // Width of screen
    


    
    override func didMove(to view: SKView) {
        physicsWorld.contactDelegate = self
        
        // Set screen width and height
        SCREEN_WIDTH = self.frame.width
        SCREEN_HEIGHT = self.frame.height
        
        // Puts the start button on screen
        tapToStart = SKSpriteNode(imageNamed: "starter")
        tapToStart.setScale(5)
        tapToStart.position = CGPoint(x: 0, y: (-SCREEN_HEIGHT/8))
        tapToStart.zPosition = 10
        self.addChild(tapToStart)
    }
    
    // Sets up the scene for gameplay.
    func createScene()   {
        // Sets up background
        let background = SKSpriteNode(imageNamed: "backgroundrobo")
        background.position = CGPoint(x: 0, y: 0)
        background.zPosition = 0
        background.setScale(3)
        self.addChild(background)
        
        // Sets up the player's character
        shooter.setScale(0.5)
        shooter.zPosition = 3
        shooter.position = CGPoint(x:0, y: -(self.frame.height/2.75))
        self.addChild(shooter)
        
        // Inserts the score label
        scoreLabel.position = CGPoint(x: -SCREEN_WIDTH/3, y: SCREEN_HEIGHT/2.5)
        scoreLabel.fontName = "GillSans-UltraBold"
        scoreLabel.zPosition = 8
        scoreLabel.fontSize = 60
        scoreLabel.text = ("\(score)")
        self.addChild(scoreLabel)
        
        // Sets the ships various physics and adds to scene
        ship.setScale(2.25)
        ship.zPosition = 4;
        ship.position = CGPoint(x:0, y:-self.frame.height/2)
        ship.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width:SCREEN_WIDTH , height: 50))
        ship.physicsBody?.affectedByGravity = false
        ship.physicsBody?.collisionBitMask = Physics.roboNode
        ship.physicsBody?.categoryBitMask = Physics.shipNode
        ship.physicsBody?.contactTestBitMask = Physics.roboNode
        ship.physicsBody?.isDynamic = false
        self.addChild(ship)
        
        // Adds a decorative bar at the top of the screen, for score and hearts.
        infoBar.position = CGPoint(x: 0, y: SCREEN_HEIGHT/2.60)
        infoBar.setScale(5)
        infoBar.zPosition=6
        self.addChild(infoBar)
        
        
        
        // Sets lives and puts the hearts in the top right corner of the scene.
        lives = 3
        for i in 1...lives
        {
            let heart = SKSpriteNode(imageNamed: "heart")
            heart.setScale(0.5)
            heart.zPosition=7
            heart.position = CGPoint(x: SCREEN_WIDTH/2.25-(100*CGFloat(i)), y: SCREEN_HEIGHT/2.3 )
            self.addChild(heart)
            hearts[i]=heart
        }
        
        // Sets the game perameters.
        gameStarted = false
        score = 0
    }
    
    // Manages collisons and makes sure the game ends after out of lives
    func didBegin(_ contact: SKPhysicsContact) {

        let firstBody : SKPhysicsBody = contact.bodyA
        let secondBody : SKPhysicsBody = contact.bodyB
        let bodyOne = firstBody.categoryBitMask
        let bodyTwo = secondBody.categoryBitMask
        let r = Physics.roboNode
        let l = Physics.laserNode
        let ship = Physics.shipNode
        let point = contact.contactPoint
        if (areInContact(bodyOne: bodyOne, bodyTwo: bodyTwo, nodeOne: l, nodeTwo: r))
        {
            gotShot(Enemy: firstBody.node as! SKSpriteNode, Laser: secondBody.node as! SKSpriteNode,point: point)
        }
        if (areInContact(bodyOne: bodyOne, bodyTwo: bodyTwo, nodeOne: ship, nodeTwo: r))
        {
            robotTouchedShip(NodeOne: firstBody.node as! SKSpriteNode, NodeTwo: secondBody.node as! SKSpriteNode)
        }
        
        if (lives==0) {
            gameStarted = false
            createBTN()
        }
    }
    
    // Removes the Robot and plays an explosion animation
    func robotTouchedShip(NodeOne: SKSpriteNode, NodeTwo: SKSpriteNode)
    {
        if (NodeTwo.name == "Robot"){
            boom(position: NodeTwo.position)
            NodeTwo.removeFromParent()
        }
        else{
            boom(position:NodeOne.position)
            NodeOne.removeFromParent()
        }
        updateLives(by:-1)
    }
    
    // Updates the players lives
    func updateLives(by:Int)
    {
        if (lives>0){
        hearts[lives]!.removeFromParent()
        lives = lives + by
        }
    }
    
    // Returns whether or not the two bodies are in contact
    func areInContact(bodyOne: UInt32, bodyTwo: UInt32,nodeOne: UInt32, nodeTwo: UInt32) -> Bool
    {
        if((bodyOne == nodeOne && bodyTwo == nodeTwo)||(bodyOne == nodeTwo && bodyTwo == nodeOne)){
            return true
        }
        return false
    }
    
    // Removes the Robot and Laser, plays an animaiton, updates Score
    func gotShot (Enemy: SKSpriteNode, Laser: SKSpriteNode, point: CGPoint)
    {
        boom(position: Enemy.position)
        Enemy.removeFromParent()
        Laser.removeFromParent()
        updateScore(num:1)
    }
    
    // Playes an explosion animation at the given point.
    func boom(position: CGPoint){
        let boom = SKSpriteNode(imageNamed: "boom")
        boom.position = position
        self.addChild(boom)
        boom.zPosition = 2
        boom.setScale(0.5)
        let blowUp = SKAction.scale(by: 3, duration: 0.1)
        let delete = SKAction.removeFromParent()
        boom.run(SKAction.sequence([blowUp, delete]))
    }
    
    // Puts the reset Node on the screen
    func createBTN () {
        self.removeAllActions()
        self.removeAllChildren()
        UpdateHS()
        restart = SKSpriteNode(imageNamed: "reset")
        restart.position = CGPoint(x: 0, y: 0)
        restart.zPosition  = 1
        restart.setScale(2)
        self.addChild(restart)
        restart.run(SKAction.scale(to: 2.0, duration: 0.5))
    }

    // Updates the Score
    func updateScore(num: Int)
    {
        score += num;//
        scoreLabel.text = "\(score)"
    
    }
    
    // Updates the HighScore (if applicable) and displays it on the screen
    func UpdateHS(){
        if(score > highScore)
        {
            UserDefaults.standard.set(score, forKey: "highScore")
            highScore = score
            
        }
        highScoreLbl = SKLabelNode(text: "Highscore = \(highScore)")
        highScoreLbl.position = CGPoint(x: 0, y: -SCREEN_HEIGHT/4)
        highScoreLbl.fontName = "GillSans-UltraBold"
        highScoreLbl.fontSize = 60
        highScoreLbl.zPosition = 11
        self.addChild(highScoreLbl)
    }
   
    // Generates the Robots
    func generateEnemies(){
        let roboNode = SKSpriteNode(imageNamed: "robotoriginal");
        
        roboNode.setScale(0.65)
        let limit = (self.frame.width)/2-100
        roboNode.position = CGPoint(x: randNum(min: -limit,max: limit), y: 700)
        roboNode.name = "Robot"
        roboNode.zPosition = 2
        roboNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 100, height: 100))
        roboNode.physicsBody?.affectedByGravity = false;
        roboNode.physicsBody?.isDynamic = true;
        roboNode.physicsBody?.contactTestBitMask = Physics.laserNode;
        roboNode.physicsBody?.collisionBitMask = Physics.laserNode;
        roboNode.physicsBody?.categoryBitMask = Physics.roboNode;
        let height = self.frame.height;
        moveRobo = SKAction.moveBy(x:0 , y: -height, duration: TimeInterval(randNum(min: 5, max: 10)));
        removeRobo = SKAction.removeFromParent();
        moveAndRemove = SKAction.sequence([moveRobo, removeRobo])
        roboNode.run(moveAndRemove)
        
        self.addChild(roboNode)
    }
    
    // Spawns the robot continuously
    func spawnRobots()
    {
        let spawn = SKAction.run( {
            self.generateEnemies()  ;
        })
        let delay = SKAction.wait(forDuration: TimeInterval(randNum(min: 2, max: 4)))
        let SpawnDelay =  SKAction.sequence([spawn,delay])
        let SpawnDelayForever = SKAction.repeatForever(SpawnDelay)
        self.run(SpawnDelayForever)
    }
    
    // Shoots the laser out of the gun
    func shoot(){
        // Sets various aspects of our laser
        let laserNode = SKSpriteNode(imageNamed: "laser")
        laserNode.setScale(0.25)
        // This line was hard to compute, used trial and error.
        // Next time I will make sure to make reference points easier to find when I draw the assets
        laserNode.position = CGPoint(x: shooter.position.x+37, y: shooter.position.y+82)
        laserNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 10, height: 10))
        laserNode.physicsBody?.affectedByGravity = false
        laserNode.physicsBody?.collisionBitMask = Physics.roboNode
        laserNode.zPosition = 1
        laserNode.physicsBody?.categoryBitMask = Physics.laserNode
        laserNode.physicsBody?.contactTestBitMask = Physics.roboNode
        laserNode.physicsBody?.isDynamic = false
        
        // Makes an action so the laser can shoots
        let distance = self.frame.height
        shootLaser = SKAction.moveBy(x: 0, y: distance, duration: TimeInterval(1.25))
        removeLaser = SKAction.removeFromParent()
        shootAndRemove = SKAction.sequence([shootLaser,removeLaser])
        laserNode.run(shootAndRemove)
        
        // Adds the laser
        self.addChild(laserNode)
    }
    
    // Makes our player shoot lasers
    func shootLasers()
    {
        let shootIt = SKAction.run {
            self.shoot();
        }
        let delayed = SKAction.wait(forDuration: 2)
        let shootDelay =  SKAction.sequence([shootIt,delayed])
        let shootDelayForever = SKAction.repeatForever(shootDelay)
        self.run(shootDelayForever)
    }
    
    // Returns a random number between bounds
    func randNum(min: CGFloat, max:CGFloat) -> CGFloat
    {
        return CGFloat.random(in:min...max)
    }
    
    // When touches begin, the game starts
    override func touchesBegan( _ touches: Set<UITouch>, with event: UIEvent?) {
        if(gameStarted == false)
        {
            resetGame()
            gameStarted = true
            shooter.position = CGPoint(x: fingerLocus.x, y: shooter.position.y)
            spawnRobots()
            shootLasers()
        }
    }
    
    //  This function updates the players finger location continuously
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        for touch: AnyObject in touches{
            if gameStarted
            {
                fingerLocus = touch.location(in: self)
                shooter.position = CGPoint(x: fingerLocus.x, y: shooter.position.y)
            }
        }
    }
    
    //  Resets our game
    func resetGame(){
        self.removeAllChildren()
        self.removeAllActions()
        gameStarted = false
        score = 0
        createScene()
    }
    
    
    
}

