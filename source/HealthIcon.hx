package;

import openfl.Assets;
import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		if (char == 'senpai-angry' || char == 'bf-car' || char == 'mom-car' || char == 'bf-holding-gf' || char == 'bf-christmas' || char == 'monster-christmas')//temp fix will change
			char = char.split('-')[0];

		if (Assets.exists(Paths.image('icons/icon-$char')))
			loadGraphic(Paths.image('icons/icon-$char'), true, 150, 150);
		else
			loadGraphic(Paths.image('icons/icon-face'), true, 150, 150);
		animation.add('icon', [0, 1], 0);
		animation.play('icon');

		if (isPlayer)
			flipX = !flipX;

		antialiasing = true;

		updateHitbox();

		switch (char)
		{
			case 'bf-pixel' | 'senpai' | 'senpai-angry' | 'spirit':
				antialiasing = false;
		}

		scrollFactor.set();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
