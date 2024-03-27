package;

import flixel.graphics.frames.FlxAtlasFrames;

class Paths
{
    inline static public final soundExt:String = #if !web 'ogg' #else 'mp3' #end;

    public static function getAny(file:String)
        return 'assets/$file';
    
    inline static public function txt(key:String)
        return getAny('data/$key.txt');
    
    inline static public function json(key:String)
        return getAny('data/$key.json');
    
    inline static public function xml(key:String)
        return getAny('data/$key.xml');

    inline static public function music(key:String)
        return getAny('music/$key' + soundExt);
    
    inline static public function sound(key:String)
        return getAny('sounds/$key' + soundExt);
    
    inline static public function soundRandom(key:String, min:Int, max:Int)
        return sound(key + FlxG.random.int(min, max));

    inline static public function image(key:String)
        return getAny('images/$key.png');
    
    inline static public function sparrow(key:String)
        return FlxAtlasFrames.fromSparrow(image(key), getAny('images/$key.xml'));
    
    inline static public function packer(key:String)
        return FlxAtlasFrames.fromSpriteSheetPacker(image(key), getAny('images/$key.txt'));
    
    inline static public function font(key:String)
        return getAny('fonts/$key.ttf');
}