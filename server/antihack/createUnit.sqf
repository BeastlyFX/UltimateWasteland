
//	@file Name: createUnit.sqf
//	@file Author: AgentRev

if (!isServer) exitWith {};

private ["_assignCompileKey", "_assignChecksum", "_assignPacketKey", "_rscParams", "_init"];

_assignCompileKey = [_this, 0, "", [""]] call BIS_fnc_param;
_assignChecksum = [_this, 1, "", [""]] call BIS_fnc_param;
_assignPacketKey = [_this, 2, "", [""]] call BIS_fnc_param;
_rscParams = [_this, 3, "", [""]] call BIS_fnc_param;

_init = "[this, ['" + _assignCompileKey + "', '" + _assignChecksum + "', '" + _assignPacketKey + "', " + _rscParams + "]] call compile preprocessFileLineNumbers 'server\antihack\manageUnit.sqf'";

"Logic" createUnit [[0,0,0], createGroup sideLogic, _init];
