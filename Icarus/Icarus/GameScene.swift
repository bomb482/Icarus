//
//  GameScene.swift
//  Icarus
//
//  Created by Andrew Eeckman on 1/10/23.
//

import SpriteKit
import GameplayKit

private var label : SKLabelNode?
private var spinnyNode : SKShapeNode?

enum PhysicalObject {
    static let PLAYER: UInt32 = 0x1 << 0
    static let OBSTACLE: UInt32 = 0x1 << 1
    static let SCOREBOX: UInt32 = 0x1 << 2
    static let WALL: UInt32 = 0x1 << 3
}

enum GamePosition: CGFloat {
    case GROUND = -1
    case PLAYER = 0
    case OBSTACLE = 1
    case SCORE = 2
}



class GameScene: SKScene, SKPhysicsContactDelegate {
    
    let obstacleLeftTexture_Level1 = Textures.textures.texturesAtlas.textureNamed("obstacleLeft_Level1")
    let obstacleRightTexture_Level1 = Textures.textures.texturesAtlas.textureNamed("obstacleRight_Level1")
    var obstacleGap: CGFloat = 200.0
    var obstacles = SKNode()
    
    let square = SKSpriteNode(color: .red, size: CGSize(width: 50, height: 50))
    
    var score = 0
    let scoreLabel = SKLabelNode()
    
    var restart = false
    var velocityTouch: CGFloat = 0
    var velocityTouchLastFrame: CGFloat = 0
    var velocityGravity: CGFloat = 0
    var impulse: CGFloat = 0
    var velocityTotal: CGFloat = 0
    
    ///Vars for Screen
    var menuScreen = true
    var playing = false
    var falling = false
    var gameOverScreen = false
    
    private func initWorld() {
        self.physicsWorld.contactDelegate = self
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    }
    
    private func initWalls() {
        let leftEdge = SKSpriteNode(color: .clear, size: CGSize(width: 10, height: frame.height))
        leftEdge.position = CGPoint(x: (-frame.width / 2) - 10 , y: 0)
        leftEdge.physicsBody = SKPhysicsBody(rectangleOf: leftEdge.size)
        leftEdge.physicsBody?.isDynamic = false
        leftEdge.physicsBody?.restitution = 0
        leftEdge.physicsBody?.categoryBitMask = PhysicalObject.WALL
        addChild(leftEdge)

        let rightEdge = SKSpriteNode(color: .clear, size: CGSize(width: 10, height: self.frame.height))
        rightEdge.position = CGPoint(x: (frame.width / 2) + 10, y: 0)
        rightEdge.physicsBody = SKPhysicsBody(rectangleOf: rightEdge.size)
        rightEdge.physicsBody?.isDynamic = false
        rightEdge.physicsBody?.restitution = 0
        rightEdge.physicsBody?.categoryBitMask = PhysicalObject.WALL
        addChild(rightEdge)
    }
    
    private func initPlayer() {
        square.position = .init(x: frame.midX, y: -frame.height / 4)
        square.physicsBody = SKPhysicsBody(rectangleOf: square.size)
        square.physicsBody?.isDynamic = true
        square.physicsBody?.affectedByGravity = true
        square.physicsBody?.categoryBitMask = PhysicalObject.PLAYER
        square.physicsBody?.collisionBitMask = PhysicalObject.WALL | PhysicalObject.OBSTACLE
        square.physicsBody?.contactTestBitMask = PhysicalObject.OBSTACLE | PhysicalObject.OBSTACLE
        addChild(square)
    }
    
    private func initScoreLabel() {
        scoreLabel.text = "\(score)"
        scoreLabel.position = CGPoint(x: self.frame.midX, y: self.frame.maxY * 3 / 4)
        scoreLabel.fontName = "Courier-Bold"
        scoreLabel.fontSize = 200
        scoreLabel.fontColor = .white
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
        
    }
    
    private func spawnOneSetOfObstacles() {
        
        let width = UInt32(self.frame.width / 5)
        let leftObstacleWidth = CGFloat(arc4random_uniform(2 * width + (width / 3)) + width)
        let rightObstacleWidth = self.frame.width - leftObstacleWidth - obstacleGap
        
        print(self.frame.width)
        print(leftObstacleWidth)
        print(rightObstacleWidth)
        
        let obstacleLeft = SKSpriteNode(texture: obstacleLeftTexture_Level1, size: CGSize(width: leftObstacleWidth, height: 50)).then {
            $0.position = CGPoint(x: self.frame.minX + (leftObstacleWidth / 2), y: self.frame.maxY)
            $0.physicsBody = SKPhysicsBody(rectangleOf: $0.size).then {
                $0.isDynamic = false
                $0.categoryBitMask = PhysicalObject.OBSTACLE
                $0.contactTestBitMask = PhysicalObject.PLAYER
            }
        }
    
        let obstacleRight = SKSpriteNode(texture: obstacleRightTexture_Level1, size: CGSize(width: rightObstacleWidth, height: 50)).then {
            $0.position = CGPoint(x: self.frame.minX + leftObstacleWidth + obstacleGap + (rightObstacleWidth / 2), y: self.frame.maxY)
            $0.physicsBody = SKPhysicsBody(rectangleOf: $0.size).then {
                $0.isDynamic = false
                $0.categoryBitMask = PhysicalObject.OBSTACLE
                $0.contactTestBitMask = PhysicalObject.PLAYER
            }
        }
        
        let scoringBox = SKShapeNode(rectOf: CGSize(width: obstacleGap, height: 50)).then {
            $0.fillColor = .green
            $0.strokeColor = .green
            $0.position = CGPoint(x: self.frame.minX + leftObstacleWidth + (obstacleGap / 2), y: self.frame.maxY)
            $0.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: obstacleGap, height: 50)).then {
                $0.isDynamic = false
                $0.categoryBitMask = PhysicalObject.SCOREBOX
                $0.contactTestBitMask = PhysicalObject.PLAYER
            }
        }
        
        let distanceToMove = self.frame.height + (2 * obstacleLeft.size.height)
        
        obstacles.addChild(SKNode().then {
            $0.addChild(obstacleLeft)
            $0.addChild(scoringBox)
            $0.addChild(obstacleRight)
            
            $0.run(SKAction.sequence(
                [SKAction.moveBy(x: 0.0, y: -distanceToMove, duration: TimeInterval(0.005 * distanceToMove)),
                SKAction.removeFromParent()]
            ))
        })
    }
    
    func spawnObstaclesLevelOne() {
        addChild(obstacles)
        let spawn = SKAction.run(spawnOneSetOfObstacles)
        let delay = SKAction.wait(forDuration: 1.2)
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        run(SKAction.repeatForever(spawnThenDelay))
    }
    
    func setScene() {
        initWalls()
        initPlayer()
    }
    
    override func didMove(to view: SKView) {
        initWorld()
        setScene()
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {

    }
    
    func touchUp(atPoint pos : CGPoint) {

    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if restart == true {
            setScene()
            return
        }
        
        for touch in touches {
            if (menuScreen) {
                menuScreen = false
                playing = true
                initScoreLabel()
                spawnObstaclesLevelOne()
            }
            else if (playing) {
                let location = touch.location(in: self)
                  
                if location.x >= self.frame.midX {
                    velocityTouch += 400
                    impulse = 200
                }
                else {
                    velocityTouch -= 400
                    impulse = -200
                }
            }
            else if (gameOverScreen) {
                menuScreen = true
                gameOverScreen = false
                score = 0
                scoreLabel.removeAllActions()
                obstacles.removeAllChildren()
                self.removeAllChildren()
                setScene()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
            let velocityTouchDivisor: CGFloat = 20
            if (velocityTouch > 0) {
                if (velocityTouch < velocityTouchLastFrame) {
                    velocityTouch -= velocityTouchLastFrame/velocityTouchDivisor
                }
                else {
                    velocityTouchLastFrame = velocityTouch
                    velocityTouch -= velocityTouch/velocityTouchDivisor
                    
                }
                
            }
            else if (velocityTouch < 0) {
                if (velocityTouch > velocityTouchLastFrame) {
                    velocityTouch -= velocityTouchLastFrame/velocityTouchDivisor
                }
                else {
                    velocityTouchLastFrame = velocityTouch
                    velocityTouch -= velocityTouch/velocityTouchDivisor
                }
                
            }
            velocityGravity = (self.frame.midX - square.position.x) * 3
            let velocityGravityMax = 400
            if (velocityGravity > CGFloat(velocityGravityMax)) {
                velocityGravity = CGFloat(velocityGravityMax)
            }
            else if (velocityGravity < CGFloat(-velocityGravityMax)) {
                velocityGravity = CGFloat(-velocityGravityMax)
            }
            velocityTotal = velocityTouch+velocityGravity+impulse
            square.physicsBody?.velocity = CGVector(dx: velocityTotal, dy: 0)
            impulse = 0
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        let object1 = contact.bodyA
        let object2 = contact.bodyB

        if contactMask == PhysicalObject.PLAYER | PhysicalObject.WALL {
            square.physicsBody?.velocity = .zero
        }
        
        if ((object1.categoryBitMask & PhysicalObject.SCOREBOX) == PhysicalObject.SCOREBOX || (object2.categoryBitMask & PhysicalObject.SCOREBOX) == PhysicalObject.SCOREBOX) {
            score += 1;
            scoreLabel.text = "\(score)"
        }
        
        if ((object1.categoryBitMask & PhysicalObject.OBSTACLE) == PhysicalObject.OBSTACLE || (object2.categoryBitMask & PhysicalObject.OBSTACLE) == PhysicalObject.OBSTACLE) {
            obstacles.removeFromParent()
            square.removeFromParent()
            
            let scoreLabelDistanceToMove = scoreLabel.position.y
            let fallingAction = SKAction.moveBy(x: 0.0, y: -scoreLabelDistanceToMove, duration: TimeInterval(0.005 * scoreLabelDistanceToMove))
            let shieldOfJustice = SKAction.run {
                self.gameOverScreen = true
            }
            let sequence = SKAction.sequence([fallingAction, shieldOfJustice])
            scoreLabel.run(sequence)
            self.removeAllActions()
            playing = false
            
        }
    }
}
