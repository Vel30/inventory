# Exemplo de uso
```pwn
// Adiciona M4 com 16 balas ao inventário do jogador
AddItemToContainer(GetPlayerInventoryContainerID(playerid), gWeaponItemType, .data = { WEAPON_M4, 16 });
// Adiciona 5 caixas com 8 balas de M4 ao inventário do jogador
AddItemToContainer(GetPlayerInventoryContainerID(playerid), gAmmoItemType, 5, .data = { WEAPON_M4, 8 });
AddItemToContainer(GetPlayerInventoryContainerID(playerid), gMagazineItemType);
```
