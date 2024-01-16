#include <YSI_Coding\y_hooks>

final ItemType: gWeaponItemType = DefineItemType("Caixa com arma", 2969, 1);

static WEAPON: gPlayerHoldingWeaponID[MAX_PLAYERS];

forward SetPlayerHoldingWeapon(playerid, WEAPON: weaponid);
forward WEAPON: GetPlayerHoldingWeaponID(playerid);
forward bool: IsPlayerHoldingAnyWeapon(playerid);

hook OnScriptInit() {
  SetItemTypeExtraDataMaxSize(gWeaponItemType, 2);
  SetItemTypePreviewRot(gWeaponItemType, -22.5, 0.0, -145.0);
}

hook OnPlayerKeyStateChange(playerid, KEY: newkeys, KEY: oldkeys) {
  if (!IsPlayerHoldingAnyWeapon(playerid)) {
    return;
  }

  if (newkeys & KEY_CTRL_BACK) {
    new data[2];

    data[0] = _: gPlayerHoldingWeaponID[playerid];
    data[1] = 0;

    if (AddItemToContainer(GetPlayerInventoryContainerID(playerid), gWeaponItemType, .data = data) == -5) {
      SendClientMessage(playerid, -1, "Não há espaço vazio em seu inventário.");
      return;
    }

    SetPlayerHoldingWeapon(playerid, WEAPON_FIST);

    SendClientMessageToAll(-1, "* %s coloca de volta uma arma em uma caixa e a guarda.", ReturnPlayerRPName(playerid));
  }
}

hook OnPlayerUpdate(playerid) {
  if (!IsPlayerHoldingAnyWeapon(playerid)) {
    return 1;
  }

  SetPlayerArmedWeapon(playerid, WEAPON_FIST);
  return 1;
}

hook OnContainerItemAdded(Container: containerid, slotid) {
  if (GetContainerItemTypeID(containerid, slotid) == gWeaponItemType) {
    static weaponName[32];

    GetWeaponName(WEAPON: GetContainerItemExtraDataAtCell(containerid, slotid, 0), weaponName);

    SetContainerItemName(containerid, slotid, va_return("%s (com %d balas)", weaponName, GetContainerItemExtraDataAtCell(containerid, slotid, 1)));
  }
}

hook OnPlayerUseContainerItem(playerid, Container: containerid, slotid) {
  if (GetContainerItemTypeID(containerid, slotid) == gWeaponItemType) {
    new WEAPON: weaponid = WEAPON: GetContainerItemExtraDataAtCell(containerid, slotid, 0),
      ammo = GetContainerItemExtraDataAtCell(containerid, slotid, 1),
      WEAPON_SLOT: weaponslotid = GetWeaponSlot(weaponid);

    if (GetPlayerWeapon(playerid) == weaponid) {
      SendClientMessage(playerid, -1, "Você já está segurando esta arma.");
      return 0;
    }

    static weaponData[MAX_WEAPON_SLOTS][2];

    for (new WEAPON_SLOT: i; i < MAX_WEAPON_SLOTS; i++) {
      GetPlayerWeaponData(playerid, i, WEAPON: weaponData[i][0], weaponData[i][1]);

      if (weaponData[i][0] == _: weaponid) {
        SendClientMessage(playerid, -1, "Você já está com esta arma equipada.");
        return 0;
      }

      if (Weapon_IsValid(weaponData[i][0]) && i == weaponslotid) {
        new data[2];

        data[0] = weaponData[i][0];
        data[1] = weaponData[i][1];

        if (AddItemToContainer(containerid, gWeaponItemType, .data = data) == -5) {
          SendClientMessage(playerid, -1, "Você já possui uma arma no mesmo slot e não há espaço vazio no inventário para armazená-la.");
          return 0;
        }

        RemovePlayerWeapon(playerid, WEAPON: data[0]);
      }
    }

    if (!ammo) {
      SetPlayerHoldingWeapon(playerid, weaponid);

      SendClientMessage(playerid, -1, "Você está segurando uma arma sem munição – coloque um carregador nela.");
      SendClientMessage(playerid, -1, "Nota: Pressione \"H\" para colocar a arma de volta no inventário.");
    } else {
      GivePlayerWeapon(playerid, weaponid, ammo);
    }

    SendClientMessageToAll(-1, "* %s pega uma arma de uma caixa e a equipa.", ReturnPlayerRPName(playerid));
  }
  return 1;
}

SetPlayerHoldingWeapon(playerid, WEAPON: weaponid) {
  if (!IsPlayerConnected(playerid)) {
    return 0;
  }

  if (!Weapon_IsValid(_: weaponid)) {
    RemovePlayerAttachedObject(playerid, 0);
    return -1;
  }

  SetPlayerAttachedObject(playerid, 0, Weapon_GetModelID(_: weaponid), 6);

  gPlayerHoldingWeaponID[playerid] = weaponid;
  return 1;
}

WEAPON: GetPlayerHoldingWeaponID(playerid) {
  return gPlayerHoldingWeaponID[playerid];
}

bool: IsPlayerHoldingAnyWeapon(playerid) {
  return IsPlayerHoldingAnyWeapon(playerid);
}
