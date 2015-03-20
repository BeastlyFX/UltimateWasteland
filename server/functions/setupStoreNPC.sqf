
//	@file Version: 1.0
//	@file Name: setupStoreNPC.sqf
//	@file Author: AgentRev
//	@file Created: 12/10/2013 12:36
//	@file Args:

#define STORE_ACTION_CONDITION "(player distance _target < 3)"
#define SELL_CRATE_CONDITION "(!isNil 'R3F_LOG_joueur_deplace_objet' && {R3F_LOG_joueur_deplace_objet isKindOf 'ReammoBox_F'})"
#define SELL_CONTENTS_CONDITION "(!isNil 'R3F_LOG_joueur_deplace_objet' && {{R3F_LOG_joueur_deplace_objet isKindOf _x} count ['ReammoBox_F','AllVehicles'] > 0})"
#define SELL_VEH_CONTENTS_CONDITION "{!isNull objectFromNetId (player getVariable ['lastVehicleRidden', ''])}"
#define SELL_BIN_CONDITION "(cursorTarget == _target)"

private ["_npc", "_npcName", "_startsWith", "_building"];

_npc = _this select 0;
_npcName = vehicleVarName _npc;
_npc setName [_npcName,"",""];

_npc allowDamage false;
{ _npc disableAI _x } forEach ["MOVE","FSM","TARGET","AUTOTARGET"];

if (hasInterface) then
{
	_startsWith =
	{
		private ["_needle", "_testArr"];
		_needle = _this select 0;
		_testArr = toArray (_this select 1);
		_testArr resize count toArray _needle;
		(toString _testArr == _needle)
	};

	switch (true) do
	{
		case (["GenStore", _npcName] call _startsWith):
		{
			_npc addAction ["<img image='client\icons\store.paa'/> Open General Store", "client\systems\generalStore\loadGenStore.sqf", [], 1, true, true, "", STORE_ACTION_CONDITION];
		};
		case (["GunStore", _npcName] call _startsWith):
		{
			_npc addAction ["<img image='client\icons\store.paa'/> Open Gun Store", "client\systems\gunStore\loadgunStore.sqf", [], 1, true, true, "", STORE_ACTION_CONDITION];
		};
		case (["VehStore", _npcName] call _startsWith):
		{
			_npc addAction ["<img image='client\icons\store.paa'/> Open Vehicle Store", "client\systems\vehicleStore\loadVehicleStore.sqf", [], 1, true, true, "", STORE_ACTION_CONDITION];
		};
	};

	_npc addAction ["<img image='client\icons\money.paa'/> Sell crate", "client\systems\selling\sellCrateItems.sqf", [false, false, true], 0.99, false, true, "", STORE_ACTION_CONDITION + " && " + SELL_CRATE_CONDITION];
	_npc addAction ["<img image='client\icons\money.paa'/> Sell contents", "client\systems\selling\sellCrateItems.sqf", [], 0.98, false, true, "", STORE_ACTION_CONDITION + " && " + SELL_CONTENTS_CONDITION];
	_npc addAction ["<img image='client\icons\money.paa'/> Sell last vehicle contents", "client\systems\selling\sellVehicleItems.sqf", [], 0.97, false, true, "", STORE_ACTION_CONDITION + " && " + SELL_VEH_CONTENTS_CONDITION];
};

if (isServer) then
{
	_facesCfg = configFile >> "CfgFaces" >> "Man_A3";
	_faces = [];

	for "_i" from 0 to (count _facesCfg - 1) do
	{
		_faceCfg = _facesCfg select _i;

		_faceTex = toArray getText (_faceCfg >> "texture");
		_faceTex resize 1;
		_faceTex = toString _faceTex;

		if (_faceTex == "\") then
		{
			_faces pushBack configName _faceCfg;
		};
	};

	_face = _faces call BIS_fnc_selectRandom;
	_npc setFace _face;
	_npc setVariable ["storeNPC_face", _face, true];
}

else{};

if (isServer) then
{
	removeAllWeapons _npc;

	waitUntil {!isNil "storeConfigDone"};

	{
		if (_x select 0 == _npcName) exitWith
		{
			private "_frontOffset";

			//collect our arguments
			_npcPos = _x select 1;
			_deskDirMod = _x select 2;

			if (typeName _deskDirMod == "ARRAY" && {count _deskDirMod > 0}) then
			{
				if (count _deskDirMod > 1) then
				{
					_frontOffset = _deskDirMod select 1;
				};

				_deskDirMod = _deskDirMod select 0;
			};

			_storeOwnerAppearance = [];

			{
				if (_x select 0 == _npcName) exitWith
				{
					_storeOwnerAppearance = _x select 1;
				};
			} forEach (call storeOwnerConfigAppearance);

			{
				_type = _x select 0;
				_classname = _x select 1;

				switch (toLower _type) do
				{
					case "weapon":
					{
						if (_classname != "") then
						{
							diag_log format ["Applying %1 as weapon for %2", _classname, _npcName];
							_npc addWeapon _classname;
						};
					};
					case "uniform":
					{
						if (_classname != "") then
						{
							diag_log format ["Applying %1 as uniform for %2", _classname, _npcName];
							_npc addUniform _classname;
						};
					};
					case "switchMove":
					{
						if (_classname != "") then
						{
							diag_log format ["Applying %1 as switchMove for %2", _classname, _npcName];
							_npc switchMove _classname;
						};
					};
				};
			} forEach _storeOwnerAppearance;

			_pDir = getDir _npc;

			_desk = [_npc, _bPos, _pDir, _deskDirMod] call compile preprocessFileLineNumbers "server\functions\createStoreFurniture.sqf";
			_npc setVariable ["storeNPC_cashDesk", netId _desk, true];

			sleep 1;

			_bbNPC = boundingBoxReal _npc;
			_bbDesk = boundingBoxReal _desk;
			_bcNPC = boundingCenter _npc;
			_bcDesk = boundingCenter _desk;

			_npcHeightRel = (_desk worldToModel (getPosATL _npc)) select 2;

			// must be done twice for the direction to set properly
			for "_i" from 1 to 2 do
			{
				_npc attachTo
				[
					_desk,
					[
						0,

						((_bcNPC select 1) - (_bcDesk select 1)) +
						((_bbNPC select 1 select 1) - (_bcNPC select 1)) -
						((_bbDesk select 1 select 1) - (_bcDesk select 1)) + 0.1,

						_npcHeightRel
					]
				];
				_npc setDir 180;
			};

			detach _npc;
			sleep 1;

			_npc enableSimulation false;
			_desk enableSimulation false;
		};

	} forEach (call storeOwnerConfig);
};

if (isServer) then
{
	_npc setVariable ["storeNPC_setupComplete", true, true];
};