
//	@file Name: postVehicleSave.sqf
//	@file Author: AgentRev

private ["_objCount", "_oldObjCount", "_i"];
_objCount = _this select 1;

_fileName = "Objects" call PDB_objectFileName;
_oldObjCount = [_fileName, "Info", "ObjCount", "NUMBER"] call PDB_read; // iniDB_read

// Reverse-delete old objects
if (_oldObjCount > _objCount) then
{
	for "_i" from _oldObjCount to (_objCount + 1) step -1 do
	{
		[_fileName, format ["Obj%1", _i], false] call PDB_deleteSection; // iniDB_deleteSection
	};
};

if (call A3W_savingMethod == "profile") then
{
	saveProfileNamespace; // this line is crucial to ensure all profileNamespace data submitted to the server is saved
	diag_log "A3W - profileNamespace saved";
};
