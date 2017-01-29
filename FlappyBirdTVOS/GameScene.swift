//
//  GameScene.swift
//  PlatformGame
//
//  Created on 2016-01-03.
//  Copyright (c) 2015 2D Game World. All rights reserved.
//

import SpriteKit
import AVFoundation
import UIKit

class GameScene: SKScene, SKPhysicsContactDelegate {

//DEFINE THE COLLISION CATEGORIES
    let birdCategory:UInt32 = 0x1 << 0
    let worldCategory: UInt32 = 0x1 << 1
    let pipeCategory:UInt32 = 0x1 << 2
    let scoreCategory: UInt32 = 0x1 << 3

//CREATE THE BIRD ATLAS FOR ANIMATION
    let birdAtlas = SKTextureAtlas(named:"player.atlas")
    var birdSprites = Array<SKTexture>()
    var bird = SKSpriteNode()
   
//CREATE THE FLOOR AND THE PIPES
    var myFloor1 = SKSpriteNode()
    var myFloor2 = SKSpriteNode()

//CREATE AN OUTLINE OF THE PIPES FOR COLLISION PURPOSES
    let myPipesTexture = SKTexture(imageNamed: "pipe")
    var pipeTextureUp:SKTexture!
    var pipeTextureDown:SKTexture!
    var movePipesAndRemove:SKAction!
    var moving:SKNode!
    var pipes:SKNode!
    
//CREATE THE BACKGROUND & sound
    var myBackground = SKSpriteNode()
    var playLoop: AVAudioPlayer?
    var explosionSprite = SKEmitterNode() //explosie bij botsing


//SET AN INITIAL VARIABLE FOR THE RANDOM PIPE SIZE
    var pipeHeight = CGFloat(200)
    var verticalPipeGap = Double() //was 100.0
    
//DETERMINE IF THE GAME HAS STARTED OR NOT
    var playAgain = SKLabelNode()
    var canRestart = Bool()
    var scoreLabelNode:SKLabelNode!
    var score = NSInteger()

    

    
    override func didMove(to view: SKView) {
        
        canRestart = false

        //play sound
        run(SKAction.playSoundFileNamed("Pamgaea.mp3", waitForCompletion: false))
    
         //CREATE A BORDER AROUND THE SCREEN
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        
        //REQUIRED TO DETECT SPECIFIC COLLISIONS
        self.physicsWorld.contactDelegate = self
        
        //SET UP THE BIRD SPRITES FOR ANIMATION
        birdSprites.append(birdAtlas.textureNamed("player1"))
        birdSprites.append(birdAtlas.textureNamed("player2"))
        birdSprites.append(birdAtlas.textureNamed("player3"))
        birdSprites.append(birdAtlas.textureNamed("player4"))
        
        //SET UP THE BACKGROUND IMAGE AND MAKE IT STATIC
        myBackground = SKSpriteNode(imageNamed: "background-image-2")
        myBackground.anchorPoint = CGPoint.zero;
        myBackground.size = self.frame.size
        myBackground.position = CGPoint(x: 0, y: 0);
        myBackground.zPosition = -20
        
        //BLEND THE BACKGROUND IMAGE WITH THE SAME BACKGROUND COLOR
        self.backgroundColor = SKColor(red: 80.0/255.0, green: 192.0/255.0, blue: 203.0/255.0, alpha: 1.0)

        //ADD THE BACKGROUND TO THE SCENE
        addChild(self.myBackground)
        
        //SET UP THE FLOOR AND PIPES INITIAL POSITION AND IMAGE
        myFloor1 = SKSpriteNode(imageNamed: "floor")
        myFloor2 = SKSpriteNode(imageNamed: "floor")

        myFloor1.anchorPoint = CGPoint.zero;
        myFloor1.position = CGPoint(x: 0, y: 0);//was y:20
        
        myFloor1.size.width = self.frame.size.width;
        myFloor2.size.width = self.frame.size.width;
                
        myFloor2.anchorPoint = CGPoint.zero;
        myFloor2.position = CGPoint(x: myFloor1.size.width-1, y: 0);//was y:20


        //ADD THE FLOOR TO THE SCENE
        addChild(self.myFloor1)
        addChild(self.myFloor2)

        //moving pipes
        moving = SKNode()
        self.addChild(moving)
        pipes = SKNode()
        moving.addChild(pipes)

        // create the pipes textures
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest
        
        // create the pipes movement actions
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeTextureUp.size().width)
        let movePipes = SKAction.moveBy(x: -distanceToMove, y:0.0, duration:TimeInterval(0.01 * distanceToMove))
        let removePipes = SKAction.removeFromParent()
        movePipesAndRemove = SKAction.sequence([movePipes, removePipes])
        
        // spawn the pipes
        let spawn = SKAction.run(spawnPipes)
        let delay = SKAction.wait(forDuration: TimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn, delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever)
        
        
        myFloor1.physicsBody = SKPhysicsBody(edgeLoopFrom: myFloor1.frame)
        myFloor2.physicsBody = SKPhysicsBody(edgeLoopFrom: myFloor1.frame)
        
        //CREATE A PHYSICS BODY FOR THE BIRD
        self.physicsBody?.categoryBitMask = birdCategory
        
        //SET UP THE BIRD'S INITIAL POSITION AND IMAGE
        bird = SKSpriteNode(texture:birdSprites[0]) //array of birds in atlas
        bird.position = CGPoint(x:self.frame.midX, y:self.frame.midY);
        bird.size.width = bird.size.width / 10
        bird.size.height = bird.size.height / 10
        
        //CREATE A BIT MASK AROUND THE BIRD
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2.0)
        bird.physicsBody?.isDynamic = true
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.linearDamping = 1.1
        bird.physicsBody?.restitution = 0

        //CHECK IF THE BIRD touches pipe or world
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.physicsBody?.contactTestBitMask = worldCategory | pipeCategory  //bird can colide with world or pipe
        
 
        //ANIMATE THE BIRD AND REPEAT THE ANIMATION FOREVER
        let animateBird = SKAction.animate(with: self.birdSprites, timePerFrame: 0.1)
        let repeatAction = SKAction.repeatForever(animateBird)
        self.bird.run(repeatAction)
        
        //LASTLY, ADD THE BIRD TO THE SCENE
        addChild(self.bird)
        
        // Initialize label and create a label which holds the score
        score = 0
        scoreLabelNode = SKLabelNode(fontNamed:"FlappyBirdy")
        scoreLabelNode.position = CGPoint( x: self.frame.midX, y: 3 * self.frame.size.height / 4 )
        scoreLabelNode.zPosition = 100
        scoreLabelNode.text = String(score)
        self.addChild(scoreLabelNode)
    }
    
    
    //RANDOM NUMBER GENERATOR
    func randomBetweenNumbers(firstNum: CGFloat, secondNum: CGFloat) -> CGFloat{
        return CGFloat(arc4random()) / CGFloat(UINT32_MAX) * abs(firstNum - secondNum) + min(firstNum, secondNum)
    }
    
        func spawnPipes() {
            let pipePair = SKNode()
            pipePair.position = CGPoint( x: self.frame.size.width + pipeTextureUp.size().width * 2, y: 0 )
            pipePair.zPosition = -10
            
            let height = UInt32( self.frame.size.height / 10)//was 4
            let y = Double(arc4random_uniform(height) + height);

            //GENERATE A RANDOM NUMBER BETWEEN 100 AND 240 (THE MAXIMUM GAP BETWEEN THE PIPES)
            verticalPipeGap = Double(randomBetweenNumbers(firstNum: 40.0, secondNum: 150.0))
            
            let pipeDown = SKSpriteNode(texture: pipeTextureDown)
            pipeDown.setScale(0.7)//was 2.0
            pipeDown.position = CGPoint(x: 0.0, y: y + Double(pipeDown.size.height) + verticalPipeGap)
            
            
            pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
            pipeDown.physicsBody?.isDynamic = false
            pipeDown.physicsBody?.categoryBitMask = pipeCategory
            pipeDown.physicsBody?.contactTestBitMask = birdCategory
            pipePair.addChild(pipeDown)
            
            let pipeUp = SKSpriteNode(texture: pipeTextureUp)
            pipeUp.setScale(0.7) //was 2.0
            pipeUp.position = CGPoint(x: 0.0, y: y)
            
            pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
            pipeUp.physicsBody?.isDynamic = false
            pipeUp.physicsBody?.categoryBitMask = pipeCategory
            pipeUp.physicsBody?.contactTestBitMask = birdCategory
            pipePair.addChild(pipeUp)
            
            let contactNode = SKNode()
            contactNode.position = CGPoint( x: pipeDown.size.width + bird.size.width / 2, y: self.frame.midY )
            contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize( width: pipeUp.size.width, height: self.frame.size.height ))
            contactNode.physicsBody?.isDynamic = false
            contactNode.physicsBody?.categoryBitMask = scoreCategory
            contactNode.physicsBody?.contactTestBitMask = birdCategory
            pipePair.addChild(contactNode)
            
            pipePair.run(movePipesAndRemove)
            pipes.addChild(pipePair)
            
        }
    
    
    func resetScene (){

        // Move bird to original position and reset velocity
        bird.position = CGPoint(x:self.frame.midX, y:self.frame.midY);
        bird.physicsBody?.velocity = CGVector( dx: 0, dy: 0.1 ) //was dy: 0
        bird.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        bird.speed = 1.0
        bird.zRotation = 0.0
        
        // Remove all existing pipes
        pipes.removeAllChildren()
        
        // Reset _canRestart
        canRestart = false
        

        // Reset score
        score = 0
        scoreLabelNode.text = String(score)

        //remove the game over text
        playAgain.removeFromParent()
        
        // Restart animation
        moving.speed = 1
        
        
    }
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //USER HAS TOUCHED THE SCREEN, BEGIN THE GAME

         if moving.speed > 0  {

            
            
            for _ in touches { // do we need all touches?
                bird.physicsBody?.isDynamic = true
                bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)//was dy:0
                bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 40))//was 150 40
                bird.physicsBody?.linearDamping = 1.0; //new macasuba
                
            }

         } else if canRestart {
            self.resetScene()
        }
        
        }
 
    
    override func update(_ currentTime: TimeInterval)
    {
        //KEEP THE BIRD CENTERED IN THE MIDDLE OF THE SCREEN
        bird.position.x = self.frame.width / 2
        bird.physicsBody?.allowsRotation = false
        
      
        /* Called before each frame is rendered */
        
        //bird can wiggle when pushed
        //let value = bird.physicsBody!.velocity.dy * ( bird.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001 )
        //bird.zRotation = min( max(-1, value), 0.5 )
        
        
        //POSITION THE FLOOR
        myFloor1.position = CGPoint(x: myFloor1.position.x-5, y: myFloor1.position.y);// was x-8
        myFloor2.position = CGPoint(x: myFloor2.position.x-5, y: myFloor2.position.y);
        
        //REPEAT THE FLOOR IN A CONTINIOUS LOOP
        if (myFloor1.position.x < -myFloor1.size.width ){
            myFloor1.position = CGPoint(x: myFloor2.position.x + myFloor2.size.width, y: myFloor1.position.y);
           // print("1111 \(myFloor1.position.x) ")
        }
        if (myFloor2.position.x < -myFloor2.size.width) {
            myFloor2.position = CGPoint(x: myFloor1.position.x + myFloor1.size.width, y: myFloor2.position.y);
            
        }

    }
 

    
    
    func playSound() {
        guard let sound = NSDataAsset(name: "explosion") else {
            print("asset not found")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            playLoop = try AVAudioPlayer(data: sound.data, fileTypeHint: AVFileTypeMPEGLayer3)
            playLoop!.play()
        } catch let error as NSError {
            print("error: \(error.localizedDescription)")
        }
    }
  
        
        func didBegin(_ contact: SKPhysicsContact) {
            if moving.speed > 0 {
                if ( contact.bodyA.categoryBitMask & scoreCategory ) == scoreCategory || ( contact.bodyB.categoryBitMask & scoreCategory ) == scoreCategory {
                    
                    // Bird has contact with score entity
                    score += 1
                    scoreLabelNode.text = String(score)
                    
                    // Add a little visual feedback for the score increment
                    scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration:TimeInterval(0.1)), SKAction.scale(to: 1.0, duration:TimeInterval(0.1))]))
                    
                    
                } else {
                    
                    
                    playAgain = SKLabelNode.init(text: "Tap to play again")
                    playAgain.fontSize = 40
                    playAgain.fontColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)
                    playAgain.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
                    playAgain.zPosition = 4
                    self.addChild(playAgain)

                    print("BIRD HAS MADE CONTACT")

                    moving.speed = 0
                    
                    bird.physicsBody?.collisionBitMask = worldCategory
                   // bird.run(  SKAction.rotate(byAngle: CGFloat(M_PI) * CGFloat(bird.position.y) * 0.01, duration:1), completion:{self.bird.speed = 0 })
                    
                   self.canRestart = true

                    
                    let animateBird = SKAction.animate(with: self.birdSprites, timePerFrame: 0.1)
                    let repeatAction = SKAction.repeatForever(animateBird)
                    self.bird.run(repeatAction)
                    
                    
                }
            }
    }
    
}
