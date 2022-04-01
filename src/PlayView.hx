import h2d.col.Point;

enum State {
	WaitingForTouch;
	Playing;
	MissedBall;
	Dead;
}

class PlayView extends GameState {
	final playWidth = 9;
	final playHeight = 16;

	final gameArea = new h2d.Graphics();

	final paddle = new h2d.Graphics();
	final paddleWidth = 2;
	final paddleHeight = 0.5;

	final ball = new h2d.Graphics();
	final ballSize = 0.5;
	var ballVel = new Point();

	final wallSize = 0.5;

	var state = WaitingForTouch;

	final pointsText = new Gui.Text("");
	var points = 0;

	final resetText = new Gui.Text("");
	final resetInteractive = new h2d.Interactive(0, 0);

	override function init() {
		if (height / width > playHeight / playWidth) {
			// Width is limiting factor
			gameArea.scale(width / playWidth);
			gameArea.y = (height - playHeight * gameArea.scaleY) / 2;
		} else {
			// Height is limiting factor
			gameArea.scale(height / playHeight);
			gameArea.x = (width - playWidth * gameArea.scaleX) / 2;
		}
		gameArea.beginFill(0x330000);
		gameArea.drawRect(0, 0, playWidth, playHeight);
		addChild(gameArea);

		final wall = new h2d.Graphics(gameArea);
		wall.beginFill(0xffffff);
		wall.drawRect(0, 0, playWidth, wallSize);

		paddle.beginFill(0xffffff);
		paddle.drawRect(-paddleWidth / 2, 0, paddleWidth, paddleHeight);
		paddle.y = playHeight * 0.8;
		gameArea.addChild(paddle);

		ball.beginFill(0xffffff);
		ball.drawRect(-ballSize / 2, -ballSize / 2, ballSize, ballSize);
		gameArea.addChild(ball);

		pointsText.x = width * 0.5;
		pointsText.y = width * 0.02 + gameArea.y + wallSize * gameArea.scaleY;
		pointsText.textAlign = Center;
		this.addChild(pointsText);

		resetText.text = "reset";
		resetText.x = width - resetText.getBounds().width - width * 0.05;
		resetText.y = width * 0.02 + gameArea.y + wallSize * gameArea.scaleY;
		this.addChild(resetText);
		resetInteractive.width = resetText.getBounds().width;
		resetInteractive.height = resetText.getBounds().height;
		resetInteractive.onClick = e -> {
			setupGame();
		};
		resetText.addChild(resetInteractive);

		final backText = new Gui.Text("&lt;-", this);
		backText.x = width * 0.05;
		backText.y = width * 0.02 + gameArea.y + wallSize * gameArea.scaleY;
		final backInteractive = new h2d.Interactive(backText.getBounds().width, backText.getBounds().height, backText);
		backInteractive.onClick = e -> {
			App.instance.switchState(new MenuView());
		};

		setupGame();

		addEventListener(onEvent);

		final manager = hxd.snd.Manager.get();
		manager.masterVolume = 0.5;
		manager.masterChannelGroup.addEffect(new hxd.snd.effect.Reverb(hxd.snd.effect.ReverbPreset.DRUGGED));
		manager.masterChannelGroup.addEffect(new hxd.snd.effect.Pitch(0.5));
	}

	function setupGame() {
		resetText.visible = false;
		points = 0;
		paddle.x = playWidth / 2;
		ball.x = paddle.x;
		ball.y = paddle.y - ballSize / 2;
		state = WaitingForTouch;
	}

	function onEvent(event:hxd.Event) {
		switch (event.kind) {
			case EPush:
				if (state == WaitingForTouch) {
					state = Playing;
					setRandomBallVel();
					hxd.Res.start.play();
				}
			default:
		}
		paddle.x = (event.relX - gameArea.x) / gameArea.scaleX;
	}

	function setRandomBallVel() {
		ballVel = new Point(0, -(10 + points));
		ballVel.rotate((Math.random() - 0.5) * Math.PI * 0.8);
	}

	override function update(dt:Float) {
		pointsText.text = "" + points;

		if (state == WaitingForTouch || state == Dead)
			return;

		ball.x += ballVel.x * dt;
		ball.y += ballVel.y * dt;

		if (ball.x - ballSize * 0.5 < 0) {
			ball.x = ballSize * 0.5;
			ballVel.x *= -1;
			final s = hxd.Res.blip.play();
		}
		if (ball.x + ballSize * 0.5 > playWidth) {
			ball.x = playWidth - ballSize * 0.5;
			ballVel.x *= -1;
			hxd.Res.blip.play();
		}
		if (ball.y - ballSize * 0.5 < wallSize) {
			ball.y = wallSize + ballSize * 0.5;
			ballVel.y *= -1;
			points += 1;
			hxd.Res.blip.play();
		}
		if (ball.y + ballSize * 0.5 > paddle.y) {
			if (state == Playing && ball.x + ballSize > paddle.x - paddleWidth / 2 && ball.x - ballSize < paddle.x + paddleWidth / 2) {
				ball.y = paddle.y - ballSize * 0.5;
				setRandomBallVel();
				hxd.Res.blip.play();
			} else {
				state = MissedBall;
			}
		}
		if (ball.y - ballSize * 0.5 > playHeight) {
			state = Dead;
			resetText.visible = true;
		}
	}
}
