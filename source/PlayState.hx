package;

import sys.FileSystem;
import Section.SwagSection;
import Song.SwagSong;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;

import Character;

// ROZEBUD I BEG PLEASE FIX YOUR FORMATTING

using StringTools;

class PlayState extends MusicBeatState
{
	public static var curStage:String = '';
	public static var SONG:SwagSong;

	public static var diff:Int;
	
	public static var returnLocation:String = "main";
	public static var returnSong:Int = 0;

	public static var skittles:Bool = false; // easter egg
	
	private var canHit:Bool = false;
	private var noMissCount:Int = 0;

	public static var stageSongs:Array<String>;

	var camFocus:String = "";
	var camTween:FlxTween;

	private var vocals:FlxSound;

	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Boyfriend;

	private var invulnCount:Int = 0;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;
	private var enemyStrums:FlxTypedGroup<FlxSprite>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;
	private var misses:Int = 0;
	private var accuracy:Float = 0.00;
	private var totalNotesHit:Float = 0;
	private var totalPlayed:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var songScore:Int = 0;
	var scoreTxt:FlxText;

	var defaultCamZoom:Float = 1.05;

	var dadBeats:Array<Int> = [0, 2];
	var bfBeats:Array<Int> = [1, 3];

	public function new(diff:Int)
	{
		super();
		this.diff = diff;
	}
	
	override public function create()
	{
		if (FlxG.random.bool(0.1))
			skittles = true;
		
		FlxG.mouse.visible = false;

		FlxG.sound.cache("assets/music/" + SONG.song + "_Inst" + TitleState.soundExt);
		FlxG.sound.cache("assets/music/" + SONG.song + "_Voices" + TitleState.soundExt);
		
		openfl.Lib.current.stage.frameRate = (Config.noFpsCap) ? 999 : 144;

		Conductor.setSafeZone();
		camTween = FlxTween.tween(this, {}, 0);
	
		stageSongs = ["ugh"];
		
		canHit = !Config.noRandomTap;
		noMissCount = 0;
		invulnCount = 0;
	
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.changeBPM(SONG.bpm);
		
			defaultCamZoom = 0.9;
			curStage = 'stage';
			var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic('assets/images/stageback.png');
			bg.antialiasing = true;
			bg.scrollFactor.set(0.9, 0.9);
			bg.active = false;
			add(bg);

			var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic('assets/images/stagefront.png');
			stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
			stageFront.updateHitbox();
			stageFront.antialiasing = true;
			stageFront.scrollFactor.set(0.9, 0.9);
			stageFront.active = false;
			add(stageFront);

			var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic('assets/images/stagecurtains.png');
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			stageCurtains.antialiasing = true;
			stageCurtains.scrollFactor.set(1.3, 1.3);
			stageCurtains.active = false;

			add(stageCurtains);

		switch(SONG.song.toLowerCase()){
			case "tutorial":
				dadBeats = [0, 1, 2, 3];
			case "ugh":
				dadBeats = [0, 1, 2, 3];
				bfBeats = [0, 1, 2, 3];
		}

		var gfVersion:String = 'gf';

		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		dad = new Character(100, 100, SONG.player2);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
			case 'dad':
				camPos.x += 400;
		}

		boyfriend = new Boyfriend(770, 450, SONG.player1);

		add(gf);
		add(dad);
		add(boyfriend);

		Conductor.songPosition = -5000;

		if(Config.downscroll)
			strumLine = new FlxSprite(0, 570).makeGraphic(FlxG.width, 10);
		else 
			strumLine = new FlxSprite(0, 30).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();
		enemyStrums = new FlxTypedGroup<FlxSprite>();

		generateSong(SONG.song);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON);
		
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, Config.downscroll ? FlxG.height * 0.1 : FlxG.height * 0.875).loadGraphic('assets/images/healthBar.png');
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		
		scoreTxt = new FlxText(healthBarBG.x - 105, (FlxG.height * 0.9) + 36, 800, "", 22);
		scoreTxt.setFormat("assets/fonts/vcr.ttf", 22, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		
		add(healthBar);
		add(iconP2);
		add(iconP1);
		add(scoreTxt);

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];

		healthBar.visible = false;
		healthBarBG.visible = false;
		iconP1.visible = false;
		iconP2.visible = false;
		scoreTxt.visible = false;

		startingSong = true;

		switch (curSong.toLowerCase())
		{
			default:
				startCountdown();
		}

		super.create();
	}

	function updateAccuracy()
		{
			totalPlayed += 1;
			accuracy = totalNotesHit / totalPlayed * 100;
			if (accuracy >= 100.00)
					accuracy = 100;
		}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		healthBar.visible = true;
		healthBarBG.visible = true;
		iconP1.visible = true;
		iconP2.visible = true;
		scoreTxt.visible = true;

		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			if(dadBeats.contains((swagCounter % 4)))
				dad.dance();

			gf.dance();

			if(bfBeats.contains((swagCounter % 4)))
				boyfriend.dance();

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready.png', "set.png", "go.png"]);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			for (value in introAssets.keys())
			{
				if (value == curStage)
				{
					introAlts = introAssets.get(value);
				}
			}

			switch (swagCounter)
			{
				case 0:
					FlxG.sound.play('assets/sounds/intro3' + TitleState.soundExt, 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic('assets/images/' + introAlts[0]);
					ready.scrollFactor.set();
					ready.updateHitbox();

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/intro2' + TitleState.soundExt, 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic('assets/images/' + introAlts[1]);
					set.scrollFactor.set();

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/intro1' + TitleState.soundExt, 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic('assets/images/' + introAlts[2]);
					go.scrollFactor.set();

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play('assets/sounds/introGo' + TitleState.soundExt, 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
			FlxG.sound.playMusic("assets/music/" + SONG.song + "_Inst" + TitleState.soundExt, 1, false);

		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			if(!paused)
			resyncVocals();
		});

	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
		{
			vocals = new FlxSound().loadEmbedded("assets/music/" + curSong + "_Voices" + TitleState.soundExt);
		}
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, false, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, false, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
					swagNote.x += FlxG.width / 2; // general offset
			}
			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var babyArrow:FlxSprite = new FlxSprite(50, strumLine.y);

			switch (curStage)
			{
				default:
					babyArrow.frames = FlxAtlasFrames.fromSparrow('assets/images/NOTE_assets.png', 'assets/images/NOTE_assets.xml');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrowLEFT');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
					}
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				enemyStrums.add(babyArrow);
				babyArrow.animation.finishCallback = function(name:String){
					if(name == "confirm"){
						babyArrow.animation.play('static', true);
						babyArrow.centerOffsets();
					}
				}
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			strumLineNotes.add(babyArrow);
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
				resyncVocals();

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;
		}

		super.closeSubState();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	function truncateFloat( number : Float, precision : Int): Float {
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round( num ) / Math.pow(10, precision);
		return num;
		}

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if (FlxG.keys.justPressed.NINE)
		{
			if (iconP1.animation.curAnim.name == 'bf-old')
				iconP1.animation.play(SONG.player1);
			else
				iconP1.animation.play('bf-old');
		}

		super.update(elapsed);

		switch(Config.accuracy) {
			case "none":
				scoreTxt.text = "Score:" + songScore;
			default:
				scoreTxt.text = "Score:" + songScore + " | Misses:" + misses + " | Accuracy:" + truncateFloat(accuracy, 2) + "%";
		}

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN)
			FlxG.switchState(new ChartingState());

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		//Heath Icons
		if (healthBar.percent < 20){
			iconP1.animation.curAnim.curFrame = 1;
			if(Config.betterIcons){ //Better Icons Win Anim
				iconP2.animation.curAnim.curFrame = 2;
			}
		}
		else if (healthBar.percent > 80){
			iconP2.animation.curAnim.curFrame = 1;
			if(Config.betterIcons){ //Better Icons Win Anim
				iconP1.animation.curAnim.curFrame = 2;
			}
		}
		else{
			iconP2.animation.curAnim.curFrame = 0;
			iconP1.animation.curAnim.curFrame = 0;
		}	

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
			}
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (camFocus != "dad" && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{

				camTween.cancel();
				
				camFocus = "dad";

				var followX = dad.getMidpoint().x + 150;
				var followY = dad.getMidpoint().y - 100;

				camTween = FlxTween.tween(camFollow, {x: followX, y: followY}, 1.9, {ease: FlxEase.quintOut});
			}

			if (camFocus != "bf" && PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				camTween.cancel();

				camFocus = "bf";

				var followX = boyfriend.getMidpoint().x - 100;
				var followY = boyfriend.getMidpoint().y - 100;

				camTween = FlxTween.tween(camFollow, {x: followX, y: followY}, 1.95, {ease: FlxEase.quintOut});
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		// RESET = Quick Game Over Screen
		if (controls.RESET && !startingSong)
		{
			health = 0;
			trace("RESET = True");
		}

		// CHEAT = brandon's a pussy
		if (controls.CHEAT)
		{
			health += 1;
			trace("User is cheating!");
		}

		if (health <= 0)
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y, camFollow.getScreenPosition().x, camFollow.getScreenPosition().y));
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					//trace("DA ALT THO?: " + SONG.notes[Math.floor(curStep / 16)].altAnim);

					if(dad.canAutoAnim){
						switch (Math.abs(daNote.noteData))
						{
							case 2:
								dad.playAnim('singUP' + altAnim, true);
							case 3:
								dad.playAnim('singRIGHT' + altAnim, true);
							case 1:
								dad.playAnim('singDOWN' + altAnim, true);
							case 0:
								dad.playAnim('singLEFT' + altAnim, true);
						}
					}

					enemyStrums.forEach(function(spr:FlxSprite)
					{
						if (Math.abs(daNote.noteData) == spr.ID)
						{
							spr.animation.play('confirm', true);
							if (spr.animation.curAnim.name == 'confirm')
							{
								spr.centerOffsets();
								spr.offset.x -= 13;
								spr.offset.y -= 13;
							}
							else
								spr.centerOffsets();
						}
					});

					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					daNote.destroy();
				}

				if(Config.downscroll){
					daNote.y = (strumLine.y + (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(PlayState.SONG.speed, 2)));
				}
				else {
					daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(PlayState.SONG.speed, 2)));
				}

				//MOVE NOTE TRANSPARENCY CODE BECAUSE REASONS 
				if(daNote.tooLate){
					if (daNote.alpha > 0.3){
						if(Config.newInput){
							noteMiss(daNote.noteData, 0.055, false, true);
							vocals.volume = 0;
						}

						daNote.alpha = 0.3;
					}
				}

				//Guitar Hero Type Held Notes
				if(Config.newInput && daNote.isSustainNote && daNote.mustPress){
					if(daNote.prevNote.tooLate){
						daNote.tooLate = true;
						daNote.destroy();
					}
	
					if(daNote.prevNote.wasGoodHit){
						var upP = controls.UP;
						var rightP = controls.RIGHT;
						var downP = controls.DOWN;
						var leftP = controls.LEFT;
	
						switch(daNote.noteData){
							case 0:
								if(!leftP){
									noteMiss(0, 0.03, true, true);
									vocals.volume = 0;
									daNote.tooLate = true;
									daNote.destroy();
								}
							case 1:
								if(!downP){
									noteMiss(1, 0.03, true, true);
									vocals.volume = 0;
									daNote.tooLate = true;
									daNote.destroy();
								}
							case 2:
								if(!upP){
									noteMiss(2, 0.03, true, true);
									vocals.volume = 0;
									daNote.tooLate = true;
									daNote.destroy();
								}
							case 3:
								if(!rightP){
									noteMiss(3, 0.03, true, true);
									vocals.volume = 0;
									daNote.tooLate = true;
									daNote.destroy();
								}
						}
					}
				}

				if (Config.downscroll ? (daNote.y > strumLine.y + daNote.height + 50) : (daNote.y < strumLine.y - daNote.height - 50))
				{
					if(Config.newInput){

						if (daNote.tooLate){
							daNote.active = false;
							daNote.visible = false;
			
							daNote.destroy();
						}
					}
					else{
						if (daNote.tooLate || !daNote.wasGoodHit){
							
							health -= 0.0475 * Config.healthDrainMultiplier;
							misses += 1;
							updateAccuracy();
							vocals.volume = 0;
						}
		
						daNote.active = false;
						daNote.visible = false;
		
						daNote.destroy();
					}
				}
			});
		}

		keyShit();

		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
	}

	function endSong():Void
	{
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if (SONG.validScore) {
			Highscore.saveScore(SONG.song, songScore, diff);
			FlxG.switchState(new MainMenuState());
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(strumtime:Float):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		if (noteDiff > Conductor.safeZoneOffset * Conductor.shitZone)
			{
				daRating = 'shit';
				if(Config.accuracy == "complex") {
					totalNotesHit += 1 - Conductor.shitZone;
				}
				else {
					totalNotesHit += 1;
				}
				score = 50;
			}
		else if (noteDiff > Conductor.safeZoneOffset * Conductor.badZone)
			{
				daRating = 'bad';
				score = 100;
				if(Config.accuracy == "complex") {
					totalNotesHit += 1 - Conductor.badZone;
				}
				else {
					totalNotesHit += 1;
				}
			}
		else if (noteDiff > Conductor.safeZoneOffset * Conductor.goodZone)
			{
				daRating = 'good';
				if(Config.accuracy == "complex") {
					totalNotesHit += 1 - Conductor.goodZone;
				}
				else {
					totalNotesHit += 1;
				}
				score = 200;
			}
		if (daRating == 'sick')
			totalNotesHit += 1;

		songScore += score;

		rating.loadGraphic('assets/images/' + daRating + ".png");
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic('assets/images/combo.png');
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(rating);

		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.antialiasing = true;
		comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		comboSpr.antialiasing = true;

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic('assets/images/num' + Std.int(i) + '.png');
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;
			numScore.antialiasing = true;
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}

		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function keyShit():Void
	{
		// HOLDING
		var up = controls.UP;
		var right = controls.RIGHT;
		var down = controls.DOWN;
		var left = controls.LEFT;

		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		var upR = controls.UP_R;
		var rightR = controls.RIGHT_R;
		var downR = controls.DOWN_R;
		var leftR = controls.LEFT_R;

		var controlArray:Array<Bool> = [leftP, downP, upP, rightP];

		if ((upP || rightP || downP || leftP) && !boyfriend.stunned && generatedMusic)
		{
			boyfriend.holdTimer = 0;

			var possibleNotes:Array<Note> = [];

			var ignoreList:Array<Int> = [];

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
				{
					// the sorting probably doesn't need to be in here? who cares lol
					possibleNotes.push(daNote);
					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

					ignoreList.push(daNote.noteData);

					if (Config.noRandomTap)
						setCanMiss();
				}
			});

			if (possibleNotes.length > 0)
			{
				var daNote = possibleNotes[0];

				if (perfectMode)
					noteCheck(true, daNote);

				// Jump notes
				if (possibleNotes.length >= 2)
				{
					if (possibleNotes[0].strumTime == possibleNotes[1].strumTime)
					{
						for (coolNote in possibleNotes)
						{
							if (controlArray[coolNote.noteData])
								goodNoteHit(coolNote);
							else
							{
								var inIgnoreList:Bool = false;
								for (shit in 0...ignoreList.length)
								{
									if (controlArray[ignoreList[shit]])
										inIgnoreList = true;
								}
								if (!inIgnoreList)
									badNoteCheck();
							}
						}
					}
					else if (possibleNotes[0].noteData == possibleNotes[1].noteData)
					{
						noteCheck(controlArray[daNote.noteData], daNote);
					}
					else
					{
						for (coolNote in possibleNotes)
							noteCheck(controlArray[coolNote.noteData], coolNote);
					}
				}
				else // regular notes?
					noteCheck(controlArray[daNote.noteData], daNote);

				if (daNote.wasGoodHit)
					daNote.destroy();
			}
			else
				badNoteCheck();
		}

		if ((up || right || down || left) && !boyfriend.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
				{
					switch (daNote.noteData)
					{
						// NOTES YOU ARE HOLDING
						case 2:
							if (up)
								goodNoteHit(daNote);
						case 3:
							if (right)
								goodNoteHit(daNote);
						case 1:
							if (down)
								goodNoteHit(daNote);
						case 0:
							if (left)
								goodNoteHit(daNote);
					}
				}
			});
		}

		if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !up && !down && !right && !left)
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing'))
				boyfriend.idleEnd();
		}

		playerStrums.forEach(function(spr:FlxSprite)
		{
			switch (spr.ID)
			{
				case 2:
					if (upP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (!up)
						spr.animation.play('static');
				case 3:
					if (rightP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (!right)
						spr.animation.play('static');
				case 1:
					if (downP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (!down)
						spr.animation.play('static');
				case 0:
					if (leftP && spr.animation.curAnim.name != 'confirm')
						spr.animation.play('pressed');
					if (!left)
						spr.animation.play('static');
			}

			if (spr.animation.curAnim.name == 'confirm')
			{
				spr.centerOffsets();
				spr.offset.x -= 13;
				spr.offset.y -= 13;
			}
			else
				spr.centerOffsets();
		});
	}

	function noteMiss(direction:Int = 1, ?healthLoss:Float = 0.04, ?playAudio:Bool = true, ?skipInvCheck:Bool = false):Void
	{
		if (!boyfriend.stunned && !startingSong && (!boyfriend.invuln || skipInvCheck) )
		{
			health -= healthLoss * Config.healthDrainMultiplier;
			if (combo > 5)
			{
				gf.playAnim('sad');
			}
			misses += 1;
			combo = 0;

			songScore -= 100;
			
			if(playAudio){
				FlxG.sound.play('assets/sounds/missnote' + FlxG.random.int(1, 3) + TitleState.soundExt, FlxG.random.float(0.1, 0.2));
			}

			if(Config.newInput)
				setBoyfriendInvuln(0.08);
			else
				setBoyfriendStunned();

			if(boyfriend.canAutoAnim){
				switch (direction)
				{
					case 2:
						boyfriend.playAnim('singUPmiss', true);
					case 3:
						boyfriend.playAnim('singRIGHTmiss', true);
					case 1:
						boyfriend.playAnim('singDOWNmiss', true);
					case 0:
						boyfriend.playAnim('singLEFTmiss', true);
				}
			}

			updateAccuracy();
		}
	}

	function noteMissWrongPress(direction:Int = 1, ?healthLoss:Float = 0.0475):Void
		{
			if (!startingSong && !boyfriend.invuln)
			{
				health -= healthLoss * Config.healthDrainMultiplier;
				if (combo > 5)
					gf.playAnim('sad');
				combo = 0;
	
				songScore -= 25;
				
				FlxG.sound.play('assets/sounds/missnote' + FlxG.random.int(1, 3) + TitleState.soundExt, FlxG.random.float(0.1, 0.2));
	
				setBoyfriendInvuln(0.04);
	
				if(boyfriend.canAutoAnim){
					switch (direction)
					{
						case 2:
							boyfriend.playAnim('singUPmiss', true);
						case 3:
							boyfriend.playAnim('singRIGHTmiss', true);
						case 1:
							boyfriend.playAnim('singDOWNmiss', true);
						case 0:
							boyfriend.playAnim('singLEFTmiss', true);
					}
				}
			}
		}

	function badNoteCheck()
	{
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!
		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		if(Config.noRandomTap && !canHit){}
		else{

			switch(Config.newInput){
				case true:
					if (leftP)
						noteMissWrongPress(0);
					if (upP)
						noteMissWrongPress(2);
					if (rightP)
						noteMissWrongPress(3);
					if (downP)
						noteMissWrongPress(1);
	
				case false:
					if (leftP)
						noteMiss(0);
					if (upP)
						noteMiss(2);
					if (rightP)
						noteMiss(3);
					if (downP)
						noteMiss(1);

			}
		}
	}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		if (keyP)
			goodNoteHit(note);
		else
			badNoteCheck();
	}

	function setBoyfriendInvuln(time:Float = 5 / 60){

		invulnCount++;
		var invulnCheck = invulnCount;

		boyfriend.invuln = true;

		new FlxTimer().start(time, function(tmr:FlxTimer)
		{
			if(invulnCount == invulnCheck)
				boyfriend.invuln = false;
		});
	}

	function setCanMiss(time:Float = 0.185) 
	{
		noMissCount++;
		var noMissCheck = noMissCount;

		canHit = true;

		new FlxTimer().start(time, function(tmr:FlxTimer)
		{
			if(noMissCheck == noMissCount)
				canHit = false;
		});
	}

	function setBoyfriendStunned(time:Float = 5 / 60) 
	{
		boyfriend.stunned = true;

		new FlxTimer().start(time, function(tmr:FlxTimer)
		{
			boyfriend.stunned = false;
		});
	}

	function goodNoteHit(note:Note):Void
	{
		//Guitar Hero Styled Hold Notes
		if(Config.newInput && note.isSustainNote && !note.prevNote.wasGoodHit){
			noteMiss(note.noteData, 0.05, true, true);
			note.prevNote.tooLate = true;
			note.prevNote.destroy();
			vocals.volume = 0;
		}

		else if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				popUpScore(note.strumTime);
				combo += 1;
			}
			else
				totalNotesHit += 1;

			if (note.noteData >= 0){
				switch(Config.newInput){
					case true:
						health += 0.015 * Config.healthMultiplier;
					case false:
						health += 0.023 * Config.healthMultiplier;
				}
			}
			else{
				switch(Config.newInput){
					case true:
						health += 0.0015 * Config.healthMultiplier;
					case false:
						health += 0.004 * Config.healthMultiplier;
				}
			}
				
			if(boyfriend.canAutoAnim){
				switch (note.noteData)
				{
					case 2:
						boyfriend.playAnim('singUP', true);
					case 3:
						boyfriend.playAnim('singRIGHT', true);
					case 1:
						boyfriend.playAnim('singDOWN', true);
					case 0:
						boyfriend.playAnim('singLEFT', true);
				}
			}

			if(Config.newInput && !note.isSustainNote){
				setBoyfriendInvuln(0.02);
			}

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			note.destroy();
			
			updateAccuracy();
		}
	}

	override function stepHit()
	{
		if (SONG.needsVoices)
		{
			if (vocals.time > Conductor.songPosition + 20 || vocals.time < Conductor.songPosition - 20)
			{
				resyncVocals();
			}
		}

		super.stepHit();
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			else
				Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
				if(dadBeats.contains(curBeat % 4) && dad.canAutoAnim)
					dad.dance();
		}
		else{
			if(dadBeats.contains(curBeat % 4))
				dad.dance();
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && totalBeats % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (curBeat % 1 == 0) 
		{
			iconP1.iconScale = iconP1.defualtIconScale * 1.25;
			iconP2.iconScale = iconP2.defualtIconScale * 1.25;

			FlxTween.tween(iconP1, {iconScale: iconP1.defualtIconScale}, 0.2, {ease: FlxEase.quintOut});
			FlxTween.tween(iconP2, {iconScale: iconP2.defualtIconScale}, 0.2, {ease: FlxEase.quintOut});
		}

		if (totalBeats % gfSpeed == 0)
		{
			gf.dance();
		}

		if(bfBeats.contains(curBeat % 4) && boyfriend.canAutoAnim)
			boyfriend.dance();
	}
}