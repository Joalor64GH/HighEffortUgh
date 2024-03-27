package;

import openfl.Assets;

using StringTools;

class CoolUtil
{
	inline public static function coolTextFile(path:String):Array<String> {
        return Assets.exists(path) ? [for (i in Assets.getText(path).trim().split('\n')) i.trim()] : [];
    }

	public inline static function numberArray(max:Int, ?min = 0):Array<Int>
		return [for (i in min...max) i];
}