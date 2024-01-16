#include <YSI_Coding\y_hooks>

final ItemType: gMagazineItemType = DefineItemType("Carregador de arma", 19995, 1);

hook OnScriptInit() {
  SetItemTypePreviewRot(gMagazineItemType, -22.5, 0.0, -145.0);
}

hook OnPlayerUseContainerItem(playerid, Container: containerid, slotid) {
  if (GetContainerItemTypeID(containerid, slotid) == gMagazineItemType) {
    if (!IsPlayerHoldingAnyWeapon(playerid)) {
      SendClientMessage(playerid, -1, "Você não está segurando uma arma sem munição.");
      return 0;
    }

    SetPlayerHoldingWeapon(playerid, WEAPON_FIST);

    GivePlayerWeapon(playerid, GetPlayerHoldingWeaponID(playerid), 30);

    SendClientMessageToAll(-1, "* %s pega um carregador e o conecta à sua arma.", ReturnPlayerRPName(playerid));
  }
  return 1;
}
