// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'packages/play_phaser/phaser.dart';

void main() {
  
  Game game = new Game(800, 600, WEBGL, 'output', new ShootingAction());
  
}

class ShootingAction extends State {
  Text scoreText;
  Text waveText;
  Sprite player;
  Sprite<dynamic> enemy;
  TileSprite milkyway; //Our neverending milkyway sprite
  //CursorKeys cursors; //Keys for input
  Key firebutton, left, right, up, down;
  Sprite bullet;
  Group<Sprite> lives;
  Group<Sprite> bullets;
  Group<Sprite> enemies;    
  num bullettime = 0;
  num ENEMYDISTANCE = 48;
  num ENEMYVELOCITY = 150;
  num score = 0, wave = 1;
  int tweenindex = 0;
  String scoreString, waveString;
  num cutoffdirection = 400;
  
  
  Tween tween;
  var data;
  
  preload() {
    // Load assets
    // The second parameter is the URL of the image (relative)
    game.load.image('milkyway', 'assets/background/milkyway.png');
    game.load.image('ship_base', 'assets/sprites/ship_base.png');
    game.load.image('bullet', 'assets/sprites/bullet.png');
    game.load.image('enemy', 'assets/sprites/cake.png');
   
    //game.load.image('ship_left', 'assets/background/ship_left.png');
    //game.load.image('ship_right', 'assets/background/ship_right.png');
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
    
    //  Our bullet group
    bullets = game.add.group();
    bullets.enableBody = true;
    bullets.physicsBodyType = Physics.ARCADE;
    bullets.createMultiple(20, 'bullet'); // Create 20 in our group
    bullets.forEach((Sprite s) {
      s.anchor.set(0.5, 1); // The tip is the anchor
      s.outOfBoundsKill = true; // Remove if outside of screen
      s.checkWorldBounds = true; // Check for bounds
    });
    // Add player
    player = game.add.sprite(game.world.centerX, game.world.centerY*1.5, 'ship_base'); // Spawn in the middle and halfway down.
    
    // Add enemy
    //enemy = game.add.sprite(game.world.centerX, 100, 'enemy');
    
    //  Achor in the middle
    player.anchor.set(0.5);
    game.physics.enable(player, Physics.ARCADE); // Give player physics
    player.body.collideWorldBounds = true; // Don't go outside our world.
    //  And some controls to play the game with
    left = game.input.keyboard.addKey(Keyboard.A);
    right = game.input.keyboard.addKey(Keyboard.D);
    up = game.input.keyboard.addKey(Keyboard.W);
    down = game.input.keyboard.addKey(Keyboard.S);
    // FIRE!    
    firebutton = game.input.keyboard.addKey(Keyboard.SPACEBAR);
    
    // Create moving objects
    /*var tweenData = { 'x': 400,'y': 0};
    tween = game.make.tween(tweenData).to({'x':400,'y':700}, 10000, Easing.Linear.None);
    data = tween.generateData(60);*/ // Save the track that enemy will follow
    
    // Create a group of enemies
    enemies = game.add.group();
    enemies.enableBody = true;
    enemies.physicsBodyType = Physics.ARCADE;
    
    createEnemies();
    
    
    /*for (int i=0;i<10;i++) {
      enemies.create(400, -32, 'enemy');
      game.add.tween(enemies).to({'angle': 360}, 2400, Easing.Cubic.In, true, 1000 +400*i);
    }*/
    
    
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
    if (firebutton.isDown /* && player.alive*/) {
      fireBullet();
    }
    
    enemies.forEachAlive((enemy) {
      //print(enemy.y);
      if(enemy.y > cutoffdirection) {
        enemy.body.velocity.setTo(0,0);
        enemy.body.velocity += ENEMYVELOCITY;
        //cutoffdirection = cutoffdirection + Math.random() * 10;
        //print("Outside");
      }
      if (enemy.y > 616 || enemy.x > 816 || enemy.y < -432|| enemy.x < 0 ) {
        enemy.kill();
      }
    });
    // Collision
   // game.physics.arcade.overlap(enemyBullets, player, enemyHitsPlayer);
    game.physics.arcade.overlap(bullets, enemies, collisionHandler);
    
    if (enemies.countLiving() == 0) {
      newwave();
    }
    
  }
  
  fireBullet() {

    //  To avoid them being allowed to fire too fast we set a time limit
    if (game.time.now > bullettime) {
      //  Grab the first bullet we can from the pool
      //for (int i = -10;i < 11;i++) {
        Sprite bullet = bullets.getFirstExists(false);

        if (bullet != null) {
          //  And fire it 16 pixels from the player center
          bullet.reset(player.x, player.y - 16);
          bullet.body.velocity.y = -400;
          //bullet.body.velocity.rotate(0, 0, 270 + i * 15, true, 400);
          //bullet.rotation = Math.degToRad(i * 15);
          bullettime = game.time.now + 200;
        }
      //}
    }

  }
  
  createEnemies() {
    num rndX = Math.random() * 400;
    //game.rnd.integerInRange(0, game.world.width);
    cutoffdirection = 400 - Math.random() * 200;
    print(rndX);
    for (int y = 1; y < 9; y++) {  
      
      enemy = enemies.create(600 - rndX, y * -48, 'enemy'); // Live between 200 and 600 pixels
      enemy.anchor.setTo(0.5, 0.5);
      //alien.animations.add('fly', [ 0, 1, 2, 3 ], 20, true);
      //enemy.play('fly');
      //enemy.body.moves = false;
      game.add.tween(enemy).to({'angle': 180}, 2000, Easing.Cubic.In, true, 1000 ,10,true);
      enemy.body.velocity.y = ENEMYVELOCITY;
    }
    enemies.x = 0;
    enemies.y = 0;

    //  All this does is basically start the invaders moving. Notice we're moving the Group they belong to, rather than the invaders directly.
    /*tween = game.add.tween(enemies)
    .to({
        'y': 0
    }, 5000, Easing.Linear.None, true, 800, 1000, true);*/
    
    
    //game.add.tween(enemies).to({'angle': 360}, 2000, Easing.Cubic.In, true, 1000 ,10,false);


    //  When the tween loops it calls descend
    //tween.onLoop.add(descend);
  }
  
  collisionHandler (bullet,enemy) {
    print("Asplode!");
    enemy.kill();
    bullet.kill();

    score += 20;
    scoreText.text = scoreString + score.toString();
  }
  
  newwave() {
    
    enemies.removeAll();
    createEnemies();
    wave += 1;
    waveText.text = waveString + wave.toString();
  }
  
  
}