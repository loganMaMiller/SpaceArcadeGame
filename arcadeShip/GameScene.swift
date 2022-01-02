//
//  GameScene.swift
//  arcadeShip
//
//  Created by Logan on 12/15/21.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player:SKSpriteNode!
    
    var scoreLabel:SKLabelNode!
    var score:Int = 0{
        didSet{
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    var gameTimer:Timer!
    
    var possibleAliens = ["enemy", "enemy Red", "enemy Green"]
    
    let alienCategory:UInt32 = 0x1 << 1
    let photonTorpedoCategory:UInt32 = 0x1 << 0
    
    let motionManager = CMMotionManager()
    
    var xAcceleration:CGFloat = 0
    
    override func didMove(to view: SKView) {
        player = SKSpriteNode(imageNamed:"RocketShip")
        player.scale(to: CGSize(width: (scene!.size.height)/(18), height: (scene!.size.height)/(18)))
        player.position = CGPoint( x:0, y: (scene!.size.height)/(-2.25))
        player.zPosition = 10
        
        scene?.addChild(player)
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.position = CGPoint(x: (scene!.size.width)/(-2.8), y: (scene!.size.height)/(2.2))
        scoreLabel.zPosition = 100
        scoreLabel.fontName = "Arial"
        scoreLabel.fontSize = 40
        scene?.addChild(scoreLabel)
        
        gameTimer = Timer.scheduledTimer(timeInterval: 0.75, target: self, selector: #selector(addAlien), userInfo: nil, repeats: true)
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data:CMAccelerometerData?, error:Error?) in
            if let accelerometerData = data{
                let acceleration = accelerometerData.acceleration
                self.xAcceleration = acceleration.x * 0.75 + self.xAcceleration * 0.25
            }
        }
    }
    
    @objc func addAlien() {
        possibleAliens = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: possibleAliens) as! [String]
        let alien = SKSpriteNode(imageNamed: possibleAliens[0])
        alien.scale(to: CGSize(width: (scene!.size.height)/(16), height: (scene!.size.height)/(18)))
        let randomAlienPosition = GKRandomDistribution(lowestValue: Int((scene!.size.width)/(-2)), highestValue: Int((scene!.size.width)/(2)))
        
        alien.position = CGPoint(x: CGFloat(randomAlienPosition.nextInt()), y: self.frame.size.height + alien.size.height)
        
        alien.physicsBody = SKPhysicsBody(rectangleOf: alien.size)
        alien.physicsBody?.isDynamic = true
        
        alien.physicsBody?.categoryBitMask = alienCategory
        alien.physicsBody?.contactTestBitMask = photonTorpedoCategory
        alien.physicsBody?.collisionBitMask = 0
        
        self.addChild(alien)
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: alien.position.x, y: scene!.size.height/(-2)), duration: 8))
        actionArray.append(SKAction.removeFromParent())
        
        alien.run(SKAction.sequence(actionArray))
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        fireBullet()
    }
    
    @objc func fireBullet(){
        
        let bulletNode = SKSpriteNode(imageNamed: "Bullet Player")
        bulletNode.position=player.position
        bulletNode.position.y += (player.size.height/2)
        
        bulletNode.scale(to: CGSize(width: (scene!.size.height)/(36), height: (scene!.size.height)/(36)))
        
        bulletNode.physicsBody = SKPhysicsBody(rectangleOf: bulletNode.size)
        bulletNode.physicsBody?.isDynamic = true
        bulletNode.physicsBody?.categoryBitMask = photonTorpedoCategory
        bulletNode.physicsBody?.contactTestBitMask = alienCategory
        bulletNode.physicsBody?.collisionBitMask = 0
        bulletNode.physicsBody?.usesPreciseCollisionDetection = true
        
        self.addChild(bulletNode)
        
        var actionArray = [SKAction]()
        
        actionArray.append(SKAction.move(to: CGPoint(x: bulletNode.position.x, y: scene!.size.height/(2)), duration: 0.8))
        actionArray.append(SKAction.removeFromParent())
        
        bulletNode.run(SKAction.sequence(actionArray))
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        var firstBody:SKPhysicsBody
        var secondBody:SKPhysicsBody
        
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask{
            firstBody = contact.bodyA
            secondBody = contact.bodyB
        }
        else {
            firstBody = contact.bodyB
            secondBody = contact.bodyA
        }
        if (firstBody.categoryBitMask & photonTorpedoCategory) != 0 && (secondBody.categoryBitMask & alienCategory) != 0{
            torpedoDidCollideWithAlien(bulletNode: firstBody.node as! SKSpriteNode, alienNode: secondBody.node as! SKSpriteNode)
        }
    }
    @objc func torpedoDidCollideWithAlien(bulletNode:SKSpriteNode, alienNode:SKSpriteNode){
        bulletNode.removeFromParent()
        alienNode.removeFromParent()
        score += 10
    }
    
    override func didSimulatePhysics() {
        player.position.x += xAcceleration * self.size.width/30
        if(player.position.x < self.size.width/(-2)){
            player.position.x = self.size.width/(-2)
        }
        if(player.position.x > self.size.width/(2)){
            player.position.x = self.size.width/(2)
        }
    }
}
