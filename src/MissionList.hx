package src;

import haxe.Json;
import mis.MisParser;
import src.ResourceLoader;
import src.Mission;
import src.Util;

@:publicFields
class MissionList {
	static var beginnerMissions:Array<Mission>;
	static var intermediateMissions:Array<Mission>;
	static var advancedMissions:Array<Mission>;
	static var customMissions:Array<Mission>;

	static var missions:Map<String, Mission>;

	static var _build:Bool = false;

	public function new() {}

	/**
		The level that follows this one, rolling on into the next difficulty when a category
		runs out. Null once there is nothing after it. The returned mission carries its own
		index and difficulty so the chain keeps working level after level.
	**/
	public static function getNextMission(mission:Mission):Mission {
		if (mission == null)
			return null;
		buildMissionList();
		var lists = [beginnerMissions, intermediateMissions, advancedMissions];
		var difficulty = mission.difficultyIndex;
		if (difficulty < 0 || difficulty >= lists.length)
			return null;
		var index = mission.index + 1;
		while (difficulty < lists.length) {
			var list = lists[difficulty];
			if (list != null && index < list.length) {
				var next = list[index];
				next.index = index;
				next.difficultyIndex = difficulty;
				return next;
			}
			difficulty++;
			index = 0;
		}
		return null;
	}

	public static function buildMissionList() {
		if (_build)
			return;

		missions = new Map<String, Mission>();

		function parseDifficulty(difficulty:String) {
			#if (hl && !android)
			var difficultyFiles = ResourceLoader.fileSystem.dir("data/missions/" + difficulty);
			#end
			#if (js || android)
			var difficultyFiles = ResourceLoader.fileSystem.dir("missions/" + difficulty);
			#end
			var difficultyMissions = [];
			for (file in difficultyFiles) {
				if (file.extension == "mis") {
					var misParser = new MisParser(Util.toASCII(file.getBytes()));
					var mInfo = misParser.parseMissionInfo();
					var mission = Mission.fromMissionInfo(file.path, mInfo);
					mission.game = "gold";
					missions.set(file.path, mission);
					difficultyMissions.push(mission);
				}
				if (file.isDirectory) {
					var retdir = parseDifficulty(difficulty + "/" + file.name);
					difficultyMissions = difficultyMissions.concat(retdir);
				}
			}
			difficultyMissions.sort((a, b) -> Std.parseInt(a.missionInfo.level) - Std.parseInt(b.missionInfo.level));
			return difficultyMissions;
		}

		beginnerMissions = parseDifficulty("beginner");
		intermediateMissions = parseDifficulty("intermediate");
		advancedMissions = parseDifficulty("advanced");
		customMissions = parseDifficulty("custom");

		// parseCLAList();

		_build = true;
	}

	static function parseCLAList() {
		var claJson:Array<Dynamic> = Json.parse(ResourceLoader.fileSystem.get("data/cla_list.json").getText());

		for (missionData in claJson) {
			var mission = new Mission();
			mission.id = missionData.id;
			mission.artist = missionData.artist;
			mission.title = missionData.name;
			mission.description = missionData.desc;
			mission.qualifyTime = missionData.time;
			mission.goldTime = missionData.goldTime;
			mission.path = missionData.baseName;
			mission.isClaMission = true;

			customMissions.push(mission);
		}
	}
}
