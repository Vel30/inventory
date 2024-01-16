#include <YSI_Coding\y_hooks>

final ItemType: gAmmoItemType = DefineItemType("Caixa de munição", 2358, 1);

hook OnScriptInit() {
  SetItemTypeExtraDataMaxSize(gAmmoItemType, 2);
  SetItemTypePreviewRot(gAmmoItemType, -22.5, 0.0, -145.0);
}

hook OnContainerItemAdded(Container: containerid, slotid) {
  if (GetContainerItemTypeID(containerid, slotid) == gAmmoItemType) {
    static ammoName[32];

    Weapon_GetAmmoName(GetContainerItemExtraDataAtCell(containerid, slotid, 0), ammoName);

    SetContainerItemName(containerid, slotid, va_return("Cartucho de munição %s (com %d balas)", ammoName, GetContainerItemExtraDataAtCell(containerid, slotid, 1)));
  }
}

hook OnPlayerUseContainerItem(playerid, Container: containerid, slotid) {
  if (GetContainerItemTypeID(containerid, slotid) == gAmmoItemType) {
    if (!GetPlayerWeapon(playerid)) {
      SendClientMessage(playerid, -1, "Você precisa estar segurando uma arma.");
      return 0;
    }

    static ammoName1[32],
      ammoName2[32];

    Weapon_GetAmmoName(GetPlayerWeapon(playerid), ammoName1);
    Weapon_GetAmmoName(GetContainerItemExtraDataAtCell(containerid, slotid, 0), ammoName2);

    if (strcmp(ammoName1, ammoName2)) {
      SendClientMessage(playerid, -1, "Este tipo de munição não corresponde ao tipo de munição da sua arma.");
      return 0;
    }

    SetPlayerAmmo(playerid, GetPlayerWeapon(playerid), GetPlayerAmmo(playerid) + GetContainerItemExtraDataAtCell(containerid, slotid, 1));

    SendClientMessageToAll(-1, "* %s pega um cartucho de munição e carrega sua arma.", ReturnPlayerRPName(playerid));
  }
  return 1;
}
