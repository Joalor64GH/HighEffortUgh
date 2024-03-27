package;

import openfl.display.FPS;

class Main extends openfl.display.Sprite
{
	public static var fpsDisplay:FPS;
	public static var preload:Bool = !Sys.args().contains("-nopreload");

	public var initialState:Class<FlxState>;

	public function new()
	{
		super();

		initialState = (preload) ? Startup : TitleState;

		addChild(new flixel.FlxGame(0, 0, initialState, 1, 144, 144, true));

		fpsDisplay = new FPS(10, 3, 0xFFFFFF);
		fpsDisplay.visible = false;
		addChild(fpsDisplay);
	}
}