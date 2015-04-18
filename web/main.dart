// Copyright (c) 2015, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'packages/play_phaser/phaser.dart';

void main() {
  
  Game game = new Game(800, 600, WEBGL, 'output', new ShootingAction());
  
}


class ShootingAction extends State {
  Text text;
  Sprite image;

  preload() {
    //  You can fill the preloader with as many assets as your game requires

    //  Here we are loading an image. The first parameter is the unique
    //  string by which we'll identify the image later in our code.

    //  The second parameter is the URL of the image (relative)
    game.load.image('car', 'assets/sprites/car.png');

  }

  create() {
    //  This creates a simple sprite that is using our loaded image and
    //  displays it on-screen

    image = game.add.sprite(game.world.centerX, game.world.centerY, 'car');
    
    //  Moves the image anchor to the middle, so it centers inside the game properly
    image.anchor.set(0.5);

  }
  
}