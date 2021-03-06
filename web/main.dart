// Copyright (c) 2015, Hakan Staby. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:js';
import 'package:play_phaser/phaser.dart';

void main() {
  Game game = new Game(800, 600, WEBGL, 'output', new StartScreen());
}

class StartScreen extends State {
  Text greetingsText;
  TileSprite milkyway; //Our neverending milkyway sprite
  Text instructionsText;
  String instructionString;
  Sprite player;
  Sound bgmusic;
  
  preload() {
    // Load assets
    game.load.image('milkyway', 'assets/background/milkyway.png');
    game.load.image('ship_base', 'assets/sprites/ship_base.png');
    game.load.audio('bgmusic', 'assets/sounds/cakewars.ogg');
  }
  
  create() {
    // set bounds for our world
     game.world.setBounds(0, 0, 800, 600);
     //Add physics
     game.physics.startSystem(Physics.ARCADE);
    
     //  The scrolling starfield background
     milkyway = game.add.tileSprite(0, 0, 800, 600, 'milkyway');
    
    //  Text in the middle of the screen
    greetingsText = game.add.text(game.world.centerX, game.world.centerY - game.world.height~/4, 'Cake Wars!', new TextStyle()
      ..font = '84px Arial'
      ..fill = '#fff');
    greetingsText.anchor.setTo(0.5, 0.5);
    greetingsText.visible = true;
    
    instructionString = "Steer with WASD \nShoot with the Spacebar\nClick the screen to start";
    instructionsText = game.add.text(game.world.centerX, game.world.centerY, instructionString, new TextStyle()
    ..font = '34px Arial'
    ..fill = '#fff');
    instructionsText.anchor.setTo(0.5, 0.5);
    
    // Add player
    player = game.add.sprite(game.world.centerX, game.world.centerY*1.5, 'ship_base'); // Spawn in the middle and halfway down.
 
    bgmusic = game.add.audio('bgmusic');
    // Play music
    bgmusic.play('',0,0.01,true);
    
    // Add gamestate
    game.state.add("ShootingAction", new ShootingAction());
    //the "click to start" handler
    game.input.onTap.addOnce(startGame);
    
  }
  update (){
    // Move background
    milkyway.tilePosition.y += 2;
  }
  
  startGame(Pointer pointer, bool doubleTab) {
    game.state.start("ShootingAction");
  }
  
}
// Main game class
class ShootingAction extends State {
  Text scoreText;
  Text waveText;
  Sprite player;
  Sprite<dynamic> enemy;
  TileSprite milkyway; //Our neverending milkyway sprite
  //Keys for input
  Key firebutton, left, right, up, down;
  Sprite bullet;
  Group<Sprite> lives;
  Group<Sprite> bullets;
  Group<Sprite> enemies;    
  Group<Sprite> enemyBullets;
  Group<Sprite> explosions;
  Group<Sprite> fruitbaskets;
  Group<Sprite> healths;
  Sprite fruitbasket;
    
  num bullettime = 0, enemytime = 0, acceltime = 0, firingtime = 0, enemybullettime = 120;
  num ENEMYTIMEDISTANCE = 0;
  num ENEMYDISTANCE = 48;
  num ENEMYVELOCITYMAX = 150;
  num wavesize = 10, enemyamount = 0, gunamount = 0;
  num score = 0, wave = 1;
  String scoreString, waveString;
  num cutoffdirection = 400;
  num boundarydist = 25;
  List<Sprite> livingEnemies = [];
  Text stateText;
  Sound laser, enemylaser, enemyexplosion, newwavesound, playerexplosion, bgmusic;
  Point enemylastposition;
  
  preload() {
    // Load assets
    game.load.image('milkyway', 'assets/background/milkyway.png');
    game.load.image('ship_base', 'assets/sprites/ship_base.png');
    game.load.image('bullet', 'assets/sprites/bullet.png');
    game.load.image('enemy', 'assets/sprites/lovecake.png');
    game.load.image('enemybullet', 'assets/sprites/enemybullet.png');
    game.load.image('fruitbasket', 'assets/sprites/fruitbasket.png');
    game.load.spritesheet('kaboom', 'assets/sprites/explode.png', 32, 32);
    game.load.audio('laser', 'assets/sounds/laser.wav');
    game.load.audio('enemylaser', 'assets/sounds/enemylaser.wav');
    game.load.audio('enemylaser', 'assets/sounds/enemylaser.wav');
    game.load.audio('enemyexplosion', 'assets/sounds/enemyexplosion.wav');  
    game.load.audio('newwavesound', 'assets/sounds/newwavesound.wav');
    game.load.audio('playerexplosion','assets/sounds/playerexplosion.wav');
    game.load.audio('bgmusic', 'assets/sounds/cakewars.ogg');
   
  }

  create() {
    // set bounds for our world
    game.world.setBounds(0, 0, 800, 600);
    //Add physics
    game.physics.startSystem(Physics.ARCADE);

    //  The scrolling starfield background
    milkyway = game.add.tileSprite(0, 0, 800, 600, 'milkyway');
    
    //  The score
    scoreString = 'Score : ';
    scoreText = game.add.text(10, 10, scoreString + score.toString(), new TextStyle()
      ..font = '34px Helvetica'
      ..fill = '#fff');
    
    //  The wave
    waveString = 'Wave : ';
    waveText = game.add.text(330, 10, waveString + wave.toString(), new TextStyle()
      ..font = '34px Helvetica'
      ..fill = '#fff');
    
    //  Text in the middle of the screen
    stateText = game.add.text(game.world.centerX, game.world.centerY, ' ', new TextStyle()
      ..font = '84px Arial'
      ..fill = '#fff');
    stateText.anchor.setTo(0.5, 0.5);
    stateText.visible = false;
    
    // The lives
    lives = game.add.group();
    game.add.text(game.world.width - 118, 10, 'Lives : ', new TextStyle()
      ..font = '34px Arial'
      ..fill = '#fff');
    print(game.world.width.toString());
    
    for (var i = 0; i < 3; i++) {
      var ship = lives.create(game.world.width - 100 + (30 * i), 60, 'ship_base');
      ship.anchor.setTo(0.5, 0.5);
      ship.angle = 90;
      ship.alpha = 0.4;
    }
    
    //  An explosion pool
    explosions = game.add.group();
    explosions.createMultiple(15, 'kaboom');
    explosions.forEach(setupExplosion);
    
    //  Our bullet group
    bullets = game.add.group();
    bullets.enableBody = true;
    bullets.physicsBodyType = Physics.ARCADE;
    bullets.createMultiple(200, 'bullet'); // Create 20 in our group
    bullets.forEach((Sprite s) {
      s.anchor.set(0.5, 1); // The tip is the anchor
      s.outOfBoundsKill = true; // Remove if outside of screen
      s.checkWorldBounds = true; // Check for bounds
    });
    
    // The enemy's bullets
    enemyBullets = game.add.group();
    enemyBullets.enableBody = true;
    enemyBullets.physicsBodyType = Physics.ARCADE;
    enemyBullets.createMultiple(30, 'enemybullet');
    enemyBullets.forEach((Sprite s) {
      s.anchor.set(0.5, 1);
      s.outOfBoundsKill = true;
      s.checkWorldBounds = true;
    });
    
    // Fruitbasket group
    fruitbaskets = game.add.group();
    fruitbaskets.enableBody = true;
    fruitbaskets.physicsBodyType = Physics.ARCADE;
    fruitbaskets.createMultiple(5, 'fruitbasket');
    fruitbaskets.forEach((Sprite s) {
      s.anchor.set(0.5, 0.5);
      s.outOfBoundsKill = true;
      s.checkWorldBounds = true;
    });
    
    // Health powerup
    healths = game.add.group();
    healths.enableBody = true;
    healths.physicsBodyType = Physics.ARCADE;
    healths.createMultiple(5,'ship_base');
    healths.forEach((Sprite s) {
      s.anchor.set(0.5, 0.5);
      s.outOfBoundsKill = true;
      s.checkWorldBounds = true;
      s.scale = new Point(1.5,1.5);
    });
    
    // Add player
    player = game.add.sprite(game.world.centerX, game.world.centerY*1.5, 'ship_base'); // Spawn in the middle and halfway down.
    
    // Add sounds
    laser = game.add.audio('laser',0.5);
    enemylaser = game.add.audio('enemylaser',0.5);
    enemyexplosion = game.add.audio('enemyexplosion',0.5);
    newwavesound = game.add.audio('newwavesound',0.5);
    playerexplosion = game.add.audio('playerexplosion',0.5);
    bgmusic = game.add.audio('bgmusic');
    
    //  Achor in the middle
    player.anchor.setTo(0.5,0.5);
    game.physics.enable(player, Physics.ARCADE); // Give player physics
    player.body.collideWorldBounds = true; // Don't go outside our world.
    //  And some controls to play the game with
    left = game.input.keyboard.addKey(Keyboard.A);
    right = game.input.keyboard.addKey(Keyboard.D);
    up = game.input.keyboard.addKey(Keyboard.W);
    down = game.input.keyboard.addKey(Keyboard.S);
    // FIRE!    
    firebutton = game.input.keyboard.addKey(Keyboard.SPACEBAR);
    
    // Create a group of enemies
    enemies = game.add.group();
    enemies.enableBody = true;
    enemies.physicsBodyType = Physics.ARCADE;
    
    // Play music
    bgmusic.play('',0,0.2,true);
    
  }
  
  setupExplosion(asplode) {
    asplode.anchor.x = 0.5;
    asplode.anchor.y = 0.5;
    asplode.animations.add('kaboom');
  }
  
  update () {
    // Move background
    milkyway.tilePosition.y += 2;
    
    // Reset movement
    player.body.velocity.setTo(0, 0);
    // Check movement
    if (left.isDown) {
      player.body.velocity.x = -200;
    }
    if (right.isDown) {
      player.body.velocity.x = 200;
    }
    if (up.isDown) {
      player.body.velocity.y = -200;
    }
    if (down.isDown) {
      player.body.velocity.y = 200;
    } 
    
    // Shoot!
    if (firebutton.isDown  && player.alive) {
      fireBullet();
    }
    
    if (game.time.now > firingtime && player.alive) {
      enemyFires();
    }
    
    // Below is probably not needed anymore...
    enemies.forEachAlive((enemy) {
      boundaries (enemy);
      if (enemy.y > 616 || enemy.x > 816 || enemy.y < -432|| enemy.x < 0 ) {
        enemy.kill();
      }
    });
    
    // Collision
    game.physics.arcade.overlap(bullets, enemies, collisionHandler);
    game.physics.arcade.overlap(enemyBullets, player, enemyHitsPlayer);
    game.physics.arcade.overlap(fruitbaskets, player, eatFruit);
    game.physics.arcade.overlap(healths, player, eatHealth);
        
    // Create enemies if the wave isn't full
    if (enemyamount < wavesize) {
      createEnemy();
    } else if (enemies.countLiving() == 0){
      newwave();
    }
    
  }
  
  boundaries(Sprite location) {

    if (location.position.x < boundarydist) {
      location.body.velocity.x += ENEMYVELOCITYMAX;
    } 
    else if (location.position.x > game.world.width -boundarydist) {
      location.body.velocity.x -= ENEMYVELOCITYMAX;
    } 

    if (location.position.y < boundarydist) {
      location.body.velocity.y += ENEMYVELOCITYMAX;
    } 
    else if (location.position.y > game.world.height-boundarydist) {
      location.body.velocity.y -= ENEMYVELOCITYMAX;
      //location.body.velocity.x -= 10;
    } 
    
  } 
  
  enemyFires() {
    //  Grab the first bullet we can from the pool
    Sprite enemyBullet = enemyBullets.getFirstExists(false);

    livingEnemies.clear();

    enemies.forEachAlive((alien) {
      // put every living enemy in an array
      livingEnemies.add(alien);
    });

    if (enemyBullet != null && livingEnemies.length > 0) {

      var random = game.rnd.integerInRange(0, livingEnemies.length - 1);

      // randomly select one of them
      var shooter = livingEnemies[random];
      // And fire the bullet from this enemy
      enemyBullet.reset(shooter.body.x, shooter.body.y);
      // Sound!
      if (firingtime > 0) {
        enemylaser.play();      
      }

      game.physics.arcade.moveToObject(enemyBullet, player, enemybullettime);
      firingtime = game.time.now + 2000;
    }
  }
  
  fireBullet() {

    //  To avoid them being allowed to fire too fast we set a time limit
    if (game.time.now > bullettime) {
      //  Grab the first bullet we can from the pool
      for (int i = -gunamount;i < gunamount+1;i++) {
        Sprite bullet = bullets.getFirstExists(false);

        if (bullet != null) {
          //  And fire it 16 pixels from the player center
          bullet.reset(player.x, player.y - 16);
          bullet.body.velocity.y = -400;
          bullet.body.velocity.rotate(0, 0, 0 + i * 15, true, 400);
          bullet.rotation = Math.degToRad(i * 15);
          bullettime = game.time.now + 200;
        }
      }
        laser.play('',0,0.2); // Sound effect
    }
  }
  
  createEnemy() {
    
    // If enough time has passed. Create enemy
    if (game.time.now > enemytime) {
      num rndX = Math.random() * 400;
      enemy = enemies.create(600 - rndX, -32, 'enemy'); // Live between 200 and 600 pixels
      enemy.anchor.setTo(0.5, 0.5);
      game.add.tween(enemy).to({'angle': 180}, 2000, Easing.Cubic.In, true, 1000 ,10,true);
      // Random acceleration
      enemy.body.acceleration = new Point(Math.random() * ENEMYVELOCITYMAX -ENEMYVELOCITYMAX/2, Math.random() * ENEMYVELOCITYMAX -ENEMYVELOCITYMAX/2);  
      enemy.body.maxVelocity = new Point(ENEMYVELOCITYMAX, ENEMYVELOCITYMAX); // Don't accelerate forever
      
      enemytime = game.time.now + 200;
      // Play wave sound
      if (enemyamount == 0) {
        newwavesound.play();
      }
      enemyamount++;
    }
    // Acceleration is dependent on time instead of wave, meaning it is better to kill waves fast.
    if (game.time.now > acceltime) {
      ENEMYVELOCITYMAX = ENEMYVELOCITYMAX + 50;
      acceltime = game.time.now + 20000;
      print("Accelerate");
    }
  }
  
  collisionHandler (bullet,enemy) {
    //print("Asplode!");
    enemy.kill();
    bullet.kill();
    // Update score
    score += 20;
    scoreText.text = scoreString + score.toString();
    
    //  And create an explosion :)
    var explosion = explosions.getFirstExists(false);
    explosion.reset(enemy.body.x, enemy.body.y);
    explosion.play('kaboom', 30, false, true);
    
    enemyexplosion.play();
  }
  
  enemyHitsPlayer(player, bullet) {
    bullet.kill();
    
    Sprite live = lives.getFirstAlive();
    
    if (live != null) {
      live.kill();
    }
    
    player.alpha = 0;
    game.add.tween(player).to({'alpha': 1}, 500, Easing.Linear.None, true, 0, 3, false);
    
    // Create explosion
    var explosion = explosions.getFirstExists(false);
    explosion.reset(player.body.x+16, player.body.y+16);
    explosion.bringToTop();
    explosion.play('kaboom', 30, false, true);
    // Play a crash
    playerexplosion.play();
    // Only one gun left after being hit
    gunamount = 0;
    
    // When the player dies
    if (lives.countLiving() < 1) {
      print("player kill");
      player.kill();
      enemyBullets.forEach((Sprite s) => s.kill());
      
      stateText.text = " GAME OVER \n Click to restart";
      stateText.visible = true;
      //the "click to restart" handler
      game.input.onTap.addOnce(restart);
    }
  }
  
  eatFruit(player, fruitbasket) {
    fruitbasket.kill();
    if (gunamount < 5)
      gunamount++;
  }
  
  eatHealth(player, health) {
    health.kill();
    Sprite s = lives.getFirstDead();
    if (s != null)
      //resets the life count
      lives.forEach((Sprite s) => s.revive());
  }
  
  // Start new wave. Reset counter. 
  newwave() {
    enemies.removeAll();
    // Give wave kill score
    score += 1000;
    scoreText.text = scoreString + score.toString();
    enemyamount = 0;
    wave += 1;
    enemybullettime += 10;
    waveText.text = waveString + wave.toString();
    var luck = Math.random()*100;
    if (luck > 90){ // Get more health
      sendHealth();
    } else if (luck > 60) { // Get more guns!!
      sendTreats();
    }
  }
  // We need more guns!!
  sendTreats() {
    Sprite fruitbasket = fruitbaskets.getFirstExists(false);
    
    fruitbasket.reset(enemy.x, enemy.y);
    fruitbasket.body.velocity.y = 50;
    fruitbasket.anchor.setTo(0.5, 0.5);
    fruitbasket.alpha = 0.5;
    game.add.tween(fruitbasket).to({'alpha': 1}, 2000, Easing.Linear.None, true, 1000 ,10,true);
  }
  // Full health for you!
  sendHealth() {
    Sprite healthsprite = healths.getFirstExists(false);
    healthsprite.reset(enemy.x, enemy.y);
    healthsprite.body.velocity.y = 50;
    healthsprite.anchor.setTo(0.5, 0.5);
    healthsprite.alpha = 0.5;
    game.add.tween(healthsprite).to({'alpha': 1}, 2000, Easing.Linear.None, true, 1000 ,10,true);
  }
  // Restart from the beginning.
  restart(Pointer pointer, bool doubleTab) {
    //resets the life count
    lives.forEach((Sprite s) => s.revive());
    // And reset everything.
    enemies.removeAll();
    score = 0;
    scoreText.text = scoreString + score.toString();
    wave = 1;
    waveText.text = waveString + wave.toString();
    
    enemyamount = 0;
    bullettime = 0; 
    enemytime = 0; 
    acceltime = 0; 
    firingtime = 0;
    gunamount = 0;
    enemybullettime = 120; //Reset shooting time
    
    ENEMYVELOCITYMAX = 150;
    
    //revives the player
    player.revive();
    //hides the text
    stateText.visible = false;
  }
  
}