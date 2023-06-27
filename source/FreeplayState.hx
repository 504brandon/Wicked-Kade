package;

import flixel.addons.ui.FlxUIInputText;
import flixel.input.gamepad.FlxGamepad;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
#if windows
import Discord.DiscordClient;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var comboText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var grpIcons:FlxTypedGroup<HealthIcon>;

	var songSearch:FlxUIInputText;

	override function create()
	{
		FlxG.mouse.enabled = true;
		FlxG.mouse.visible = true;

		#if windows
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		add(scoreText);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		comboText = new FlxText(diffText.x + 100, diffText.y, 0, "", 24);
		comboText.font = diffText.font;
		add(comboText);

		songSearch = new FlxUIInputText(scoreBG.x - 750, scoreBG.y + 50, 500, '', 21);
		add(songSearch);

		reloadSongs();
		changeDiff();

		#if mobileC
		addVirtualPad(FULL, A_B);
		#end

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['dad'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		comboText.text = combo + '\n';

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.DPAD_UP && !songSearch.hasFocus)
			{
				changeSelection(-1);
			}
			if (gamepad.justPressed.DPAD_DOWN && !songSearch.hasFocus)
			{
				changeSelection(1);
			}
			if (gamepad.justPressed.DPAD_LEFT && !songSearch.hasFocus)
			{
				changeDiff(-1);
			}
			if (gamepad.justPressed.DPAD_RIGHT && !songSearch.hasFocus)
			{
				changeDiff(1);
			}
		}

		if (controls.UP_P && !songSearch.hasFocus)
		{
			changeSelection(-1);
		}
		if (controls.DOWN_P && !songSearch.hasFocus)
		{
			changeSelection(1);
		}

		if (controls.LEFT_P && !songSearch.hasFocus)
			changeDiff(-1);
		if (controls.RIGHT_P && !songSearch.hasFocus)
			changeDiff(1);

		if (controls.BACK #if mobile || FlxG.mobile.justReleased.BACK #end && !songSearch.hasFocus)
		{
			FlxG.switchState(new MainMenuState());
		}

		if (controls.ACCEPT && !songSearch.hasFocus)
		{
			var songFormat = StringTools.replace(songs[curSelected].songName, " ", "-");
			var poop:String = Highscore.formatSong(songFormat, curDifficulty);
			if (openfl.Assets.exists(Paths.json(songs[curSelected].songName + '/' + poop, 'data')))
			{
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				PlayState.storyWeek = songs[curSelected].week;
				trace('CUR WEEK' + PlayState.storyWeek);
				LoadingState.loadAndSwitchState(new PlayState());
			}
		}

		if (songSearch.hasFocus && FlxG.keys.justPressed.ENTER)
		{
			reloadSongs();
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		// adjusting the highscore song name to be compatible (changeDiff)
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");

		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		combo = Highscore.getCombo(songHighscore, curDifficulty);
		#end

		diffText.text = CoolUtil.difficultyFromInt(curDifficulty).toUpperCase();
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// adjusting the highscore song name to be compatible (changeSelection)
		// would read original scores if we didn't change packages
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");

		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		combo = Highscore.getCombo(songHighscore, curDifficulty);
		// lerpScore = 0;
		#end

		#if PRELOAD_ALL
		if (FlxG.save.data.freeplayMusic)
			FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		#end

		var bullShit:Int = 0;

		for (i in 0...grpIcons.length)
		{
			grpIcons.members[i].alpha = 0.6;
		}

		grpIcons.members[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}

	function reloadSongs()
	{
		trace(songSearch.text);

		if (songs != null && songs != [] && songs != [null])
		{
			while (grpSongs.members.length > 0)
			{
				grpSongs.remove(grpSongs.members[0], true);

				for (icon in grpIcons)
				{
					grpIcons.remove(icon, true);
					icon.destroy();
				}

				for (song in songs)
				{
					songs.remove(song);
				}
			}
		}

		if (songSearch.text != '' && songSearch.text != null)
		{
			var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

			for (i in 0...initSonglist.length)
			{
				var data:Array<String> = initSonglist[i].split(':');
				if (data[0].contains(songSearch.text.toLowerCase())
					|| data[0].contains(songSearch.text.toUpperCase())
					|| data[0].contains(songSearch.text))
				{
					addSong(data[0], Std.parseInt(data[2]), data[1]);
				}

				if (songs == [] || songs == null || songs == [null])
					FlxG.switchState(new MainMenuState()); // goober

				for (i in 0...songs.length)
				{
					var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false, true);
					songText.isMenuItem = true;
					songText.targetY = i;
					grpSongs.add(songText);

					var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
					icon.sprTracker = songText;

					// using a FlxGroup is too much fuss!
					grpIcons.add(icon);
					add(icon);
				}
			}
		}
		else
		{
			var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

			for (i in 0...initSonglist.length)
			{
				var data:Array<String> = initSonglist[i].split(':');

				addSong(data[0], Std.parseInt(data[2]), data[1]);
			}

			for (i in 0...songs.length)
			{
				var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false, true);
				songText.isMenuItem = true;
				songText.targetY = i;
				grpSongs.add(songText);

				var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
				icon.sprTracker = songText;
				grpIcons.add(icon);
			}
		}

		curSelected = 0;
		changeSelection();
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
}
