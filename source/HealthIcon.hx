package;

import flixel.FlxSprite;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var id:Int;

	public var defualtIconScale:Float = 1;
	public var iconScale:Float = 1;
	public var iconSize:Float;

	public function new(char:String = 'face', isPlayer:Bool = false, ?_id:Int = -1)
	{
		super();
		if (Config.betterIcons)
		{
			loadGraphic('assets/images/fpsPlus/iconGrid.png', true, 150, 150);
			
			animation.add('bf', [0, 1, 30], 0, false, isPlayer);
			animation.add('tankman', [8, 9, 50], 0, false, isPlayer);
			animation.add('face', [10, 11, 38], 0, false, isPlayer);
			animation.add('dad', [12, 13, 34], 0, false, isPlayer);
			animation.add('bf-old', [14, 15, 39], 0, false, isPlayer);
			animation.add('gf', [16, 49, (_id != -1) ? 49 : 35], 0, false, isPlayer);
		}
		else
		{
			loadGraphic('assets/images/iconGrid.png', true, 150, 150);
			
			animation.add('bf', [0, 1], 0, false, isPlayer);
			animation.add('tankman', [8, 9], 0, false, isPlayer);
			animation.add('face', [10, 11], 0, false, isPlayer);
			animation.add('dad', [12, 13], 0, false, isPlayer);
			animation.add('bf-old', [14, 15], 0, false, isPlayer);
			animation.add('gf', [16], 0, false, isPlayer);
		}

		iconSize = width;

		id = _id;
		
		antialiasing = !pixelIcons.contains(char);
		animation.play(char);
		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		setGraphicSize(Std.int(iconSize * iconScale));
		updateHitbox();

		if (sprTracker != null){
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
			if(Config.betterIcons){
				if(id == FreeplayState.curSelected)
					animation.curAnim.curFrame = 2;
				else
					animation.curAnim.curFrame = 0;
			}
		}			
	}
}